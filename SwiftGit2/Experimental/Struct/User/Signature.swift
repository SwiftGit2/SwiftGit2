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
    
    func makeUnsafeSignature() -> Result<UnsafeMutablePointer<git_signature>, Error> {
        return .failure(WTF("wtf"))
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
    private var pointer: UnsafeMutablePointer<git_signature>? = nil

    init(_ signature: UnsafeMutablePointer<git_signature>? = nil) {
        self.pointer = signature
    }
    
    deinit {
        git_signature_free(pointer)
    }
    
    

    /// Return an unsafe pointer to the `git_signature` struct.
    /// Caller is responsible for freeing it with `git_signature_free`.
//    func makeUnsafeSignature() -> Result<UnsafeMutablePointer<git_signature>, Error> {
//        var signature: UnsafeMutablePointer<git_signature>? = nil
//        let time = git_time_t(self.time.timeIntervalSince1970)    // Unix epoch time
//        let offset = Int32(timeZone.secondsFromGMT(for: self.time) / 60)
//        let signatureResult = git_signature_new(&signature, name, email, time, offset)
//        guard signatureResult == GIT_OK.rawValue, let signatureUnwrap = signature else {
//            let err = NSError(gitError: signatureResult, pointOfFailure: "git_signature_new")
//            return .failure(err)
//        }
//        return .success(signatureUnwrap)
//    }
}

extension SignatureInternal {
    public var name: String     { String(cString: pointer!.pointee.name) }
    public var email: String    { String(cString: pointer!.pointee.email) }
    public var time: Date       { Date(timeIntervalSince1970: TimeInterval(pointer!.pointee.when.time)) }
}
