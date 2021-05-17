
import Foundation
import Clibgit2

public typealias CheckoutProgressBlock = (String?, Int, Int) -> Void

public class CheckoutOptions {
    private var checkout_options = git_checkout_options()
    
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

extension CheckoutOptions {
    func with_git_checkout_options<T>(_ body: (inout git_checkout_options) -> T) -> T {
        
        return body(&checkout_options)
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
