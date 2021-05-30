//
//  Credentials.swift
//  SwiftGit2
//
//  Created by Tom Booth on 29/02/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

import Clibgit2

public enum Credentials {
    case none 		// always fail
    case `default`
    case sshAgent
    case plaintext(username: String, password: String)
    case sshMemory(username: String, publicKey: String, privateKey: String, passphrase: String)
    case ssh(publicKey: String, privateKey: String, passphrase: String)
}

extension Credentials {
    static var sshDefault : Credentials {
        let sshDir = URL.userHome.appendingPathComponent(".ssh")
        let publicKey = sshDir.appendingPathComponent("id_rsa.pub")
        let privateKey = sshDir.appendingPathComponent("id_rsa")
        
        guard publicKey.exists else { return .none }
        guard privateKey.exists else { return .none }
        
        return .ssh(publicKey: publicKey.path, privateKey: privateKey.path, passphrase: "")
    }
    
    func isSsh() -> Bool {
        switch self {
        case .ssh(_,_,_):
            return true
        default:
            return false
        }
    }
}
