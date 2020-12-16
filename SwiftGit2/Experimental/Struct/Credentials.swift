//
//  Credentials.swift
//  SwiftGit2-OSX
//
//  Created by loki on 16.12.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public class Credentials {
	var pointer : UnsafeMutablePointer<git_credential>? = UnsafeMutablePointer.allocate(capacity: 1)
	
	public init(username: String, publicKey: String, privateKey: String, passphrase: String) {
		
		pointer?.pointee = git_credential()
		
		
		_ = username.withCString { user in
			publicKey.withCString { public_key in
				privateKey.withCString { private_key in
					passphrase.withCString { pass in
						git_credential_ssh_key_new(&pointer, user, public_key, private_key, pass)
					}
				}
			}
		}
		
		
	}
	
	deinit {
		git_credential_free(pointer)
		pointer?.deallocate()
	}
}
