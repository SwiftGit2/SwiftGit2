//
//  Credentials.swift
//  SwiftGit2
//
//  Created by Tom Booth on 29/02/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

import Clibgit2

public enum Credentials {
    case none // always fail
    case `default`
    case sshAgent
    case plaintext(username: String, password: String)
    case sshMemory(username: String, publicKey: String, privateKey: String, passphrase: String)
    case ssh(publicKey: String, privateKey: String, passphrase: String)
}

extension Credentials {
    static var sshDefault: Credentials {
        let sshDir = URL.userHome.appendingPathComponent(".ssh")
        let publicKey = sshDir.appendingPathComponent("id_rsa.pub")
        let privateKey = sshDir.appendingPathComponent("id_rsa")

        guard publicKey.exists else { return .none }
        guard privateKey.exists else { return .none }

        return .ssh(publicKey: publicKey.path, privateKey: privateKey.path, passphrase: "")
    }

    func isSsh() -> Bool {
        switch self {
        case .ssh:
            return true
        default:
            return false
        }
    }
}

// Debug output with HIDDEN sensetive information
// example: Credentials.plaintext(username: example@gmail.com, password: ***************)
extension Credentials : CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "Credentials.none"
        case .default:
            return "Credentials.default"
        case .sshAgent:
            return "Credentials.sshAgent"
        case .plaintext(username: let username, password: let password):
            return "Credentials.plaintext(username: \(username), password: \(password.asPassword))"
        case .sshMemory(username: let username, publicKey: _, privateKey: _, passphrase: _):
            return "Credentials.sshMemory(username: \(username) ...)"
        case .ssh(publicKey: let publicKey, privateKey: _, passphrase: _):
            return "Credentials.ssh(publicKey: \(publicKey) ...)"
        }
    }
}

private extension String {
    var asPassword : String {
        return String(self.map { _ in "*" })
    }
}
