//
//  Signature.swift
//  SwiftGit2-OSX
//
//  Created by loki on 31.05.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2
import Essentials

public struct Signature {
    let name : String
    let email : String
    
    public init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}

internal extension Signature {
    func make() -> Result<SignatureInternal,Error> {
        var out: UnsafeMutablePointer<git_signature>? = nil
        
        let time = Date()
        let _time = git_time_t(time.timeIntervalSince1970)    // Unix epoch time
        let _timeZone: TimeZone = TimeZone.autoupdatingCurrent
        let _offset = Int32(_timeZone.secondsFromGMT(for: time) / 60)
        
        return git_try("git_signature_new") {
            git_signature_new(&out, name, email, _time, _offset)
        }.map { SignatureInternal(out) }
    }
}


internal class SignatureInternal {
    private(set) var pointer: UnsafeMutablePointer<git_signature>? = nil

    init(_ signature: UnsafeMutablePointer<git_signature>? = nil) {
        self.pointer = signature
    }
    
    deinit {
        git_signature_free(pointer)
    }
}
