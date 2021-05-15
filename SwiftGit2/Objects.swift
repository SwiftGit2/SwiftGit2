//
//  Objects.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

/// A git object.
public protocol ObjectType {
	static var type: git_object_t { get }

	/// The OID of the object.
	var oid: OID { get }

	/// Create an instance with the underlying libgit2 type.
	init(_ pointer: OpaquePointer)
}

public extension ObjectType {
	static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.oid == rhs.oid
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(oid)
	}
}

public struct Signature {
	/// The name of the person.
	public let name: String

	/// The email of the person.
	public let email: String

	/// The time when the action happened.
	public let time: Date

	/// The time zone that `time` should be interpreted relative to.
	public let timeZone: TimeZone

	/// Create an instance with custom name, email, dates, etc.
	public init(name: String, email: String, time: Date = Date(), timeZone: TimeZone = TimeZone.autoupdatingCurrent) {
		self.name = name
		self.email = email
		self.time = time
		self.timeZone = timeZone
	}

	/// Create an instance with a libgit2 `git_signature`.
	public init(_ signature: git_signature) {
		name = String(validatingUTF8: signature.name)!
		email = String(validatingUTF8: signature.email)!
		time = Date(timeIntervalSince1970: TimeInterval(signature.when.time))
		timeZone = TimeZone(secondsFromGMT: 60 * Int(signature.when.offset))!
	}

	/// Return an unsafe pointer to the `git_signature` struct.
	/// Caller is responsible for freeing it with `git_signature_free`.
	func makeUnsafeSignature() -> Result<UnsafeMutablePointer<git_signature>, Error> {
		var signature: UnsafeMutablePointer<git_signature>? = nil
		let time = git_time_t(self.time.timeIntervalSince1970)	// Unix epoch time
		let offset = Int32(timeZone.secondsFromGMT(for: self.time) / 60)
		let signatureResult = git_signature_new(&signature, name, email, time, offset)
		guard signatureResult == GIT_OK.rawValue, let signatureUnwrap = signature else {
			let err = NSError(gitError: signatureResult, pointOfFailure: "git_signature_new")
			return .failure(err)
		}
		return .success(signatureUnwrap)
	}
}

extension Signature: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(email)
		hasher.combine(time)
	}
}

/// An annotated git tag.
public struct Tag: ObjectType, Hashable {
	public static let type = GIT_OBJECT_TAG

	/// The OID of the tag.
	public let oid: OID

	/// The tagged object.
	public let target: Pointer

	/// The name of the tag.
	public let name: String

	/// The tagger (author) of the tag.
	public let tagger: Signature

	/// The message of the tag.
	public let message: String

	/// Create an instance with a libgit2 `git_tag`.
	public init(_ pointer: OpaquePointer) {
		oid = OID(git_object_id(pointer).pointee)
		let targetOID = OID(git_tag_target_id(pointer).pointee)
		target = Pointer(oid: targetOID, type: git_tag_target_type(pointer))!
		name = String(validatingUTF8: git_tag_name(pointer))!
		tagger = Signature(git_tag_tagger(pointer).pointee)
		message = String(validatingUTF8: git_tag_message(pointer))!
	}
}
