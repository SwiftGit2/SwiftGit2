//
//  SFTP.swift
//  SwiftGit2
//
//  A small blocking SFTP client over the libssh2 that libgit2 already links.
//  Not thread-safe: use one SFTPSession from one thread at a time.
//

import Foundation
import Darwin
internal import Clibssh2

// MARK: - Errors

public struct SFTPError: Error, CustomStringConvertible {
	public enum Kind {
		/// DNS lookup or TCP connect failed.
		case connect
		/// SSH handshake failed (no common algorithms, protocol error, timeout).
		case handshake
		/// The server rejected the credentials.
		case authentication
		/// An SFTP operation failed; `sftpStatus` holds the server's status code.
		case sftp
		/// A local file could not be read.
		case localFile
		/// The caller's `shouldAbort` returned true.
		case aborted
	}

	public let kind: Kind
	/// libssh2 error code (negative), or 0.
	public let code: Int32
	/// SFTP status code (`SSH_FX_*`) when `kind == .sftp`, else 0.
	public let sftpStatus: UInt
	/// Diagnostic text from libssh2 / the OS. Not localized.
	public let message: String

	/// True when the server reported that the path does not exist.
	public var isNoSuchFile: Bool { kind == .sftp && sftpStatus == UInt(LIBSSH2_FX_NO_SUCH_FILE) }

	public var description: String { message }
}

// MARK: - Authentication

public enum SFTPAuth {
	case password(String)
	/// `privateKey` is the PEM / OpenSSH private key text; the public key is derived from it.
	case privateKey(String, passphrase: String)
}

// MARK: - Directory entries

public struct SFTPEntry {
	public let name: String
	public let isDirectory: Bool
	public let size: UInt64
}

// MARK: - Session

public final class SFTPSession {

	/// Host key fingerprint in OpenSSH form, e.g. `SHA256:nThbg6kXUpJWGl7E1IGOCspRomTxdCARLviKw6E5SY8`.
	public let hostKeyFingerprint: String
	/// Host key algorithm name, e.g. `ssh-ed25519`.
	public let hostKeyType: String

	private var socket: Int32
	private var session: OpaquePointer?
	private var sftp: OpaquePointer?

	private static let initialized: Bool = { libssh2_init(0) == 0 }()

	/// Opens the TCP connection and performs the SSH handshake. No credentials
	/// are sent yet: check `hostKeyFingerprint` first, then call `authenticate`.
	public init(host: String, port: Int = 22, timeout: TimeInterval = 30) throws {
		_ = SFTPSession.initialized
		socket = try SFTPSession.connectSocket(host: host, port: port, timeout: timeout)

		guard let session = libssh2_session_init_ex(nil, nil, nil, nil) else {
			Darwin.close(socket)
			throw SFTPError(kind: .handshake, code: 0, sftpStatus: 0, message: "libssh2_session_init failed")
		}
		self.session = session
		libssh2_session_set_blocking(session, 1)
		libssh2_session_set_timeout(session, Int(timeout * 1000))

		let rc = libssh2_session_handshake(session, socket)
		guard rc == 0 else {
			let error = SFTPSession.lastError(session, kind: .handshake, code: rc)
			libssh2_session_free(session)
			Darwin.close(socket)
			throw error
		}

		var keyLength = 0
		var keyType: Int32 = 0
		_ = libssh2_session_hostkey(session, &keyLength, &keyType)
		hostKeyType = SFTPSession.hostKeyTypeName(keyType)

		if let hash = libssh2_hostkey_hash(session, LIBSSH2_HOSTKEY_HASH_SHA256) {
			let data = Data(bytes: hash, count: 32)
			let base64 = data.base64EncodedString().replacingOccurrences(of: "=", with: "")
			hostKeyFingerprint = "SHA256:" + base64
		} else {
			hostKeyFingerprint = ""
		}
	}

	deinit {
		close()
	}

	/// Authenticates and starts the SFTP subsystem.
	public func authenticate(username: String, auth: SFTPAuth) throws {
		guard let session else { throw closedError() }
		let rc: Int32
		switch auth {
		case .password(let password):
			rc = libssh2_userauth_password_ex(
				session,
				username, UInt32(username.utf8.count),
				password, UInt32(password.utf8.count),
				nil
			)
		case .privateKey(let privateKey, let passphrase):
			rc = libssh2_userauth_publickey_frommemory(
				session,
				username, username.utf8.count,
				nil, 0,
				privateKey, privateKey.utf8.count,
				passphrase
			)
		}
		guard rc == 0 else { throw SFTPSession.lastError(session, kind: .authentication, code: rc) }

		guard let sftp = libssh2_sftp_init(session) else {
			throw SFTPSession.lastError(session, kind: .sftp, code: libssh2_session_last_errno(session))
		}
		self.sftp = sftp
	}

	/// Shuts down SFTP, disconnects, and closes the socket. Safe to call twice.
	public func close() {
		if let sftp {
			libssh2_sftp_shutdown(sftp)
			self.sftp = nil
		}
		if let session {
			libssh2_session_disconnect_ex(session, SSH_DISCONNECT_BY_APPLICATION, "Bye", "")
			libssh2_session_free(session)
			self.session = nil
		}
		if socket >= 0 {
			Darwin.close(socket)
			socket = -1
		}
	}

	// MARK: - Operations

	/// Returns whether `path` exists and is a directory, or nil if it doesn't exist.
	public func isDirectory(_ path: String) throws -> Bool? {
		let sftp = try requireSFTP()
		var attrs = LIBSSH2_SFTP_ATTRIBUTES()
		let rc = libssh2_sftp_stat_ex(sftp, path, UInt32(path.utf8.count), LIBSSH2_SFTP_STAT, &attrs)
		if rc != 0 {
			let error = sftpError(code: rc, path: path)
			if error.isNoSuchFile { return nil }
			throw error
		}
		return SFTPSession.isDirectory(attrs)
	}

	/// Creates `path` and any missing parents (like `mkdir -p`).
	public func createDirectory(_ path: String, mode: Int = 0o755) throws {
		let sftp = try requireSFTP()
		if try isDirectory(path) == true { return }

		let parent = (path as NSString).deletingLastPathComponent
		if !parent.isEmpty, parent != path, parent != "/", try isDirectory(parent) == nil {
			try createDirectory(parent, mode: mode)
		}

		let rc = libssh2_sftp_mkdir_ex(sftp, path, UInt32(path.utf8.count), mode)
		if rc != 0 {
			let error = sftpError(code: rc, path: path)
			// Lost a race with another creator, or the server reports a generic
			// failure for "exists": accept it if a directory is there now.
			if try isDirectory(path) == true { return }
			throw error
		}
	}

	/// Lists a directory (without `.` and `..`).
	public func contentsOfDirectory(_ path: String) throws -> [SFTPEntry] {
		let sftp = try requireSFTP()
		guard let handle = libssh2_sftp_open_ex(
			sftp, path, UInt32(path.utf8.count), 0, 0, LIBSSH2_SFTP_OPENDIR
		) else {
			throw sftpError(code: libssh2_session_last_errno(session), path: path)
		}
		defer { libssh2_sftp_close_handle(handle) }

		var entries: [SFTPEntry] = []
		var buffer = [CChar](repeating: 0, count: 1024)
		while true {
			var attrs = LIBSSH2_SFTP_ATTRIBUTES()
			let n = libssh2_sftp_readdir_ex(handle, &buffer, buffer.count, nil, 0, &attrs)
			if n == 0 { break }
			if n < 0 { throw sftpError(code: n, path: path) }
			let name = String(decoding: buffer.prefix(Int(n)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
			if name == "." || name == ".." { continue }
			entries.append(SFTPEntry(
				name: name,
				isDirectory: SFTPSession.isDirectory(attrs),
				size: attrs.filesize
			))
		}
		return entries
	}

	/// Uploads a local file to `remotePath`, replacing any existing file.
	///
	/// The data is written to `remotePath + ".partial"` first and renamed into
	/// place, so an interrupted upload never leaves a truncated file at the
	/// final path.
	public func upload(
		from localURL: URL,
		to remotePath: String,
		progress: ((Int64) -> Void)? = nil,
		shouldAbort: (() -> Bool)? = nil
	) throws {
		let sftp = try requireSFTP()
		guard let input = InputStream(url: localURL) else {
			throw SFTPError(kind: .localFile, code: 0, sftpStatus: 0, message: "Cannot open \(localURL.path)")
		}
		input.open()
		defer { input.close() }

		let partial = remotePath + ".partial"
		let flags = UInt(LIBSSH2_FXF_WRITE | LIBSSH2_FXF_CREAT | LIBSSH2_FXF_TRUNC)
		guard let handle = libssh2_sftp_open_ex(
			sftp, partial, UInt32(partial.utf8.count), flags, 0o644, LIBSSH2_SFTP_OPENFILE
		) else {
			throw sftpError(code: libssh2_session_last_errno(session), path: partial)
		}

		var written: Int64 = 0
		var buffer = [UInt8](repeating: 0, count: 256 * 1024)
		do {
			while true {
				if shouldAbort?() == true {
					throw SFTPError(kind: .aborted, code: 0, sftpStatus: 0, message: "Aborted")
				}
				let n = input.read(&buffer, maxLength: buffer.count)
				if n < 0 {
					throw SFTPError(kind: .localFile, code: 0, sftpStatus: 0,
					                message: input.streamError?.localizedDescription ?? "Read error")
				}
				if n == 0 { break }
				var offset = 0
				while offset < n {
					let sent = buffer.withUnsafeBytes { raw -> Int in
						let base = raw.baseAddress!.advanced(by: offset).assumingMemoryBound(to: CChar.self)
						return libssh2_sftp_write(handle, base, n - offset)
					}
					if sent < 0 { throw sftpError(code: Int32(sent), path: partial) }
					offset += sent
				}
				written += Int64(n)
				progress?(written)
			}
		} catch {
			libssh2_sftp_close_handle(handle)
			_ = try? removeFile(partial)
			throw error
		}

		let closeRC = libssh2_sftp_close_handle(handle)
		if closeRC != 0 {
			_ = try? removeFile(partial)
			throw sftpError(code: closeRC, path: partial)
		}
		try rename(partial, to: remotePath)
	}

	/// Renames, replacing the destination. Falls back to delete-then-rename on
	/// servers (SFTP v3, e.g. OpenSSH) that refuse to rename over an existing file.
	public func rename(_ source: String, to destination: String) throws {
		let sftp = try requireSFTP()
		let flags = Int(LIBSSH2_SFTP_RENAME_OVERWRITE | LIBSSH2_SFTP_RENAME_ATOMIC | LIBSSH2_SFTP_RENAME_NATIVE)
		var rc = libssh2_sftp_rename_ex(
			sftp, source, UInt32(source.utf8.count),
			destination, UInt32(destination.utf8.count), flags
		)
		if rc != 0 {
			_ = try? removeFile(destination)
			rc = libssh2_sftp_rename_ex(
				sftp, source, UInt32(source.utf8.count),
				destination, UInt32(destination.utf8.count), flags
			)
		}
		if rc != 0 { throw sftpError(code: rc, path: destination) }
	}

	/// Deletes a file. Returns false if it didn't exist.
	@discardableResult
	public func removeFile(_ path: String) throws -> Bool {
		let sftp = try requireSFTP()
		let rc = libssh2_sftp_unlink_ex(sftp, path, UInt32(path.utf8.count))
		if rc != 0 {
			let error = sftpError(code: rc, path: path)
			if error.isNoSuchFile { return false }
			throw error
		}
		return true
	}

	/// Removes an empty directory. Returns false if it didn't exist.
	@discardableResult
	public func removeDirectory(_ path: String) throws -> Bool {
		let sftp = try requireSFTP()
		let rc = libssh2_sftp_rmdir_ex(sftp, path, UInt32(path.utf8.count))
		if rc != 0 {
			let error = sftpError(code: rc, path: path)
			if error.isNoSuchFile { return false }
			throw error
		}
		return true
	}

	// MARK: - Private helpers

	private func requireSFTP() throws -> OpaquePointer {
		guard let sftp else { throw closedError() }
		return sftp
	}

	private func closedError() -> SFTPError {
		SFTPError(kind: .sftp, code: 0, sftpStatus: 0, message: "SFTP session is not open")
	}

	private func sftpError(code: Int32, path: String) -> SFTPError {
		var status: UInt = 0
		if code == LIBSSH2_ERROR_SFTP_PROTOCOL, let sftp {
			status = libssh2_sftp_last_error(sftp)
		}
		let base = session.map { SFTPSession.lastError($0, kind: .sftp, code: code).message } ?? ""
		let detail = status != 0 ? "\(SFTPSession.statusName(status)) (\(path))" : "\(base) (\(path))"
		return SFTPError(kind: .sftp, code: code, sftpStatus: status, message: detail)
	}

	private static func lastError(_ session: OpaquePointer, kind: SFTPError.Kind, code: Int32) -> SFTPError {
		var messagePointer: UnsafeMutablePointer<CChar>?
		var length: Int32 = 0
		_ = libssh2_session_last_error(session, &messagePointer, &length, 0)
		let message = messagePointer.map { String(cString: $0) } ?? "libssh2 error \(code)"
		return SFTPError(kind: kind, code: code, sftpStatus: 0, message: message)
	}

	private static func isDirectory(_ attrs: LIBSSH2_SFTP_ATTRIBUTES) -> Bool {
		guard attrs.flags & UInt(LIBSSH2_SFTP_ATTR_PERMISSIONS) != 0 else { return false }
		return attrs.permissions & UInt(LIBSSH2_SFTP_S_IFMT) == UInt(LIBSSH2_SFTP_S_IFDIR)
	}

	private static func hostKeyTypeName(_ type: Int32) -> String {
		switch type {
		case LIBSSH2_HOSTKEY_TYPE_RSA:       return "ssh-rsa"
		case LIBSSH2_HOSTKEY_TYPE_DSS:       return "ssh-dss"
		case LIBSSH2_HOSTKEY_TYPE_ECDSA_256: return "ecdsa-sha2-nistp256"
		case LIBSSH2_HOSTKEY_TYPE_ECDSA_384: return "ecdsa-sha2-nistp384"
		case LIBSSH2_HOSTKEY_TYPE_ECDSA_521: return "ecdsa-sha2-nistp521"
		case LIBSSH2_HOSTKEY_TYPE_ED25519:   return "ssh-ed25519"
		default:                             return "unknown"
		}
	}

	private static func statusName(_ status: UInt) -> String {
		switch status {
		case UInt(LIBSSH2_FX_NO_SUCH_FILE):        return "No such file"
		case UInt(LIBSSH2_FX_PERMISSION_DENIED):   return "Permission denied"
		case UInt(LIBSSH2_FX_FAILURE):             return "Failure"
		case UInt(LIBSSH2_FX_FILE_ALREADY_EXISTS): return "File already exists"
		case UInt(LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM), UInt(LIBSSH2_FX_QUOTA_EXCEEDED):
			return "No space left on server"
		default:                                   return "SFTP status \(status)"
		}
	}

	/// Resolves `host` and connects with a timeout, trying each address in turn.
	private static func connectSocket(host: String, port: Int, timeout: TimeInterval) throws -> Int32 {
		var hints = addrinfo()
		hints.ai_family = AF_UNSPEC
		hints.ai_socktype = SOCK_STREAM
		hints.ai_protocol = IPPROTO_TCP

		var result: UnsafeMutablePointer<addrinfo>?
		let gai = getaddrinfo(host, String(port), &hints, &result)
		guard gai == 0, let first = result else {
			let message = String(cString: gai_strerror(gai))
			throw SFTPError(kind: .connect, code: gai, sftpStatus: 0, message: "\(host): \(message)")
		}
		defer { freeaddrinfo(result) }

		var lastErrno: Int32 = 0
		var cursor: UnsafeMutablePointer<addrinfo>? = first
		while let info = cursor {
			cursor = info.pointee.ai_next
			let fd = Darwin.socket(info.pointee.ai_family, info.pointee.ai_socktype, info.pointee.ai_protocol)
			if fd < 0 { lastErrno = errno; continue }

			var on: Int32 = 1
			setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))

			let flags = fcntl(fd, F_GETFL, 0)
			_ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
			var rc = Darwin.connect(fd, info.pointee.ai_addr, info.pointee.ai_addrlen)
			if rc != 0 && errno == EINPROGRESS {
				var pfd = pollfd(fd: fd, events: Int16(POLLOUT), revents: 0)
				let ready = poll(&pfd, 1, Int32(timeout * 1000))
				if ready == 1 {
					var soError: Int32 = 0
					var len = socklen_t(MemoryLayout<Int32>.size)
					getsockopt(fd, SOL_SOCKET, SO_ERROR, &soError, &len)
					rc = soError == 0 ? 0 : -1
					if soError != 0 { errno = soError }
				} else {
					rc = -1
					if ready == 0 { errno = ETIMEDOUT }
				}
			}
			if rc == 0 {
				_ = fcntl(fd, F_SETFL, flags)
				return fd
			}
			lastErrno = errno
			Darwin.close(fd)
		}
		let message = String(cString: strerror(lastErrno))
		throw SFTPError(kind: .connect, code: lastErrno, sftpStatus: 0, message: "\(host):\(port): \(message)")
	}
}
