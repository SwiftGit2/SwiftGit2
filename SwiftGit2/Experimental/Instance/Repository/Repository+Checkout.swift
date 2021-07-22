//
//  RepositoryCheckout.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Essentials

// SetHEAD and Checkout
public extension Repository {
    func checkout(branch name: String, strategy: CheckoutStrategy = .Safe, progress: CheckoutProgressBlock? = nil) -> Result<Void, Error> {
        reference(name: name)
            .flatMap { $0.asBranch() }
            .flatMap { self.checkout(branch: $0, strategy: strategy, progress: progress) }
    }

    func checkout(branch: Branch, strategy: CheckoutStrategy = .Safe, progress: CheckoutProgressBlock? = nil) -> Result<Void, Error> {
        setHEAD(branch)
            .flatMap { self.checkoutHead(strategy: strategy, progress: progress) }
    }

    func checkout(commit: Commit, strategy: CheckoutStrategy = .Safe, progress: CheckoutProgressBlock? = nil) -> Result<Void, Error> {
        checkout(commit.oid, strategy: strategy, progress: progress) | { _ in () }
    }
    
    func checkout(_ oid: OID, strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil) -> Result<Repository, Error> {
        setHEAD_detached(oid)
            | { checkoutHead(strategy: strategy, progress: progress) }
            | { self }
    }

}

internal extension Repository {
    func setHEAD_detached(_ oid: OID) -> Result<Void, Error> {
        var oid = oid.oid
        return _result((), pointOfFailure: "git_repository_set_head_detached") {
            git_repository_set_head_detached(self.pointer, &oid)
        }
    }

    func setHEAD(_ reference: Branch) -> Result<Void, Error> {
        return _result((), pointOfFailure: "git_repository_set_head") {
            return git_repository_set_head(self.pointer, reference.nameAsReference)
        }
    }

    func checkoutHead(strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil) -> Result<Void, Error> {
        return git_try("git_checkout_head") {
            CheckoutOptions(strategy: strategy, progress: progress)
                .with_git_checkout_options { git_checkout_head(self.pointer, &$0) }
        }
    }

    func checkout(reference: Reference, strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil) -> Result<Reference, Error> {
        setHEAD(reference)
            .flatMap { checkoutHead(strategy: strategy, progress: progress) }
            .map { reference }
    }

    func checkout(index: Index, strategy: CheckoutStrategy) -> Result<Void, Error> {
        let options = CheckoutOptions(strategy: strategy)
        return git_try("git_checkout_index") {
            options.with_git_checkout_options { opt in
                git_checkout_index(self.pointer, index.pointer, &opt)
            }
        }
    }
}


////////////////////////////
//HELPERS
////////////////////////////
fileprivate class FS {
    static func delete(_ path : String, silent: Bool = true) {
        if !silent {
            print("FS: going to delete file: \(path)")
        }
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: path)
        } catch let error {
            if !silent {
                print("FS: cant delete \(path)")
                print(error)
            }
        }
    }

}
