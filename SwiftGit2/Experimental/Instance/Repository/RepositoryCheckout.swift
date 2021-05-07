//
//  RepositoryCheckout.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 21.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

// SetHEAD and Checkout
public extension Repository {
	func checkout(branch: Branch, strategy: CheckoutStrategy = .Safe,
				  progress: CheckoutProgressBlock? = nil) -> Result<(), Error> {
		
		setHEAD(branch).flatMap {
			self.checkoutHead(strategy: strategy, progress: progress)
		}
	}
	
	func checkout(commit: Commit, strategy: CheckoutStrategy = .Safe,
				  progress: CheckoutProgressBlock? = nil) -> Result<(), Error>  {
		
		checkout(commit.oid, strategy: strategy, progress: progress)
	}
	
	/// Set HEAD to the given oid (detached).
	///
	/// :param: oid The OID to set as HEAD.
	/// :returns: Returns a result with void or the error that occurred.
	fileprivate func setHEAD(_ oid: OID) -> Result<(), Error> {
		var oid = oid.oid
		let result = git_repository_set_head_detached(self.pointer, &oid)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_set_head_detached"))
		}
		return Result.success(())
	}
	
	/// Set HEAD to the given reference.
	///
	/// :param: reference The reference to set as HEAD.
	/// :returns: Returns a result with void or the error that occurred.
	fileprivate func setHEAD(_ reference: Branch) -> Result<(), Error> {
		let result = git_repository_set_head(self.pointer, reference.name)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_set_head"))
		}
		
		return Result.success(())
	}
	
	/// Check out HEAD.
	///
	/// :param: strategy The checkout strategy to use.
	/// :param: progress A block that's called with the progress of the checkout.
	/// :returns: Returns a result with void or the error that occurred.
	fileprivate func checkoutHead(strategy: CheckoutStrategy, progress: CheckoutProgressBlock? = nil) -> Result<(), Error> {
		var options = checkoutOptions(strategy: strategy, progress: progress)

		let result = git_checkout_head(self.pointer, &options)
		guard result == GIT_OK.rawValue else {
			return Result.failure(NSError(gitError: result, pointOfFailure: "git_checkout_head"))
		}

		return Result.success(())
	}
	
	/// Check out the given OID.
	///
	/// :param: oid The OID of the commit to check out.
	/// :param: strategy The checkout strategy to use.
	/// :param: progress A block that's called with the progress of the checkout.
	/// :returns: Returns a result with void or the error that occurred.
	fileprivate func checkout(_ oid: OID, strategy: CheckoutStrategy,
						 progress: CheckoutProgressBlock? = nil) -> Result<(), Error> {
		
		return setHEAD(oid).flatMap {
			self.checkoutHead(strategy: strategy, progress: progress)
		}
	}

	/// Check out the given reference.
	///
	/// :param: reference The reference to check out.
	/// :param: strategy The checkout strategy to use.
	/// :param: progress A block that's called with the progress of the checkout.
	/// :returns: Returns a result with void or the error that occurred.
	fileprivate func checkout(_ reference: Reference, strategy: CheckoutStrategy,
						 progress: CheckoutProgressBlock? = nil) -> Result<(), Error> {
		
		return setHEAD(reference).flatMap {
			self.checkoutHead(strategy: strategy, progress: progress)
		}
	}
}


//HELPERS

/// Helper function used as the libgit2 progress callback in git_checkout_options.
/// This is a function with a type signature of git_checkout_progress_cb.
fileprivate func checkoutProgressCallback(path: UnsafePointer<Int8>?, completedSteps: Int, totalSteps: Int,
									  payload: UnsafeMutableRawPointer?) {
	if let payload = payload {
		let buffer = payload.assumingMemoryBound(to: CheckoutProgressBlock.self)
		let block: CheckoutProgressBlock
		if completedSteps < totalSteps {
			block = buffer.pointee
		} else {
			block = buffer.move()
			buffer.deallocate()
		}
		block(path.flatMap(String.init(validatingUTF8:)), completedSteps, totalSteps)
	}
}

/// Helper function for initializing libgit2 git_checkout_options.
///
/// :param: strategy The strategy to be used when checking out the repo, see CheckoutStrategy
/// :param: progress A block that's called with the progress of the checkout.
/// :returns: Returns a git_checkout_options struct with the progress members set.
fileprivate func checkoutOptions(strategy: CheckoutStrategy,
							 progress: CheckoutProgressBlock? = nil) -> git_checkout_options {
	// Do this because GIT_CHECKOUT_OPTIONS_INIT is unavailable in swift
	let pointer = UnsafeMutablePointer<git_checkout_options>.allocate(capacity: 1)
	git_checkout_init_options(pointer, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
	var options = pointer.move()
	pointer.deallocate()

	options.checkout_strategy = strategy.gitCheckoutStrategy.rawValue

	if progress != nil {
		if checkoutProgressCallback != nil {
			options.progress_cb = checkoutProgressCallback
		}
		let blockPointer = UnsafeMutablePointer<CheckoutProgressBlock>.allocate(capacity: 1)
		blockPointer.initialize(to: progress!)
		options.progress_payload = UnsafeMutableRawPointer(blockPointer)
	}

	return options
}
