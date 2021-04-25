//
//  CheckOutOptions.swift
//  SwiftGit2-OSX
//
//  Created by loki on 24.04.2021.
//  Copyright © 2021 GitHub, Inc. All rights reserved.
//

import Foundation
import Clibgit2

public typealias CheckoutProgressBlock = (String?, Int, Int) -> Void

public struct CheckoutOptions {
	var checkout_options = git_checkout_options()
	
	public init(strategy: CheckoutStrategy = .Safe, progress: CheckoutProgressBlock? = nil) {
		git_checkout_options_init(&checkout_options, UInt32(GIT_CHECKOUT_OPTIONS_VERSION))
		
		checkout_options.checkout_strategy = strategy.gitCheckoutStrategy.rawValue
		
		if progress != nil {
			checkout_options.progress_cb = checkoutProgressCallback
			let blockPointer = UnsafeMutablePointer<CheckoutProgressBlock>.allocate(capacity: 1)
			blockPointer.initialize(to: progress!)
			checkout_options.progress_payload = UnsafeMutableRawPointer(blockPointer)
		}
	}
}

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
