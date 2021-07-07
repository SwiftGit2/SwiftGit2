import Clibgit2
import Essentials
import Foundation

public enum PullPushResult {
    case conflict(Index)
    case success
}

public extension Repository {
    
    func sync(msg: String, fetchOptions: FetchOptions = FetchOptions(auth: .auto), pushOptions: PushOptions = PushOptions(), signature: Signature) -> R<PullPushResult> {
        commit(message: msg, signature: signature)
            .flatMap { _ in sync(.firstRemote, .HEAD, fetchOptions: fetchOptions, pushOptions: pushOptions, signature: signature)}
    }
    
    func sync(_ remoteTarget: RemoteTarget, _ branchTarget: BranchTarget, fetchOptions: FetchOptions = FetchOptions(auth: .auto), pushOptions: PushOptions = PushOptions(), signature: Signature) -> R<PullPushResult> {
        return upstreamExistsFor(.HEAD)
            .if(\.self, then: { _ in
                
                pullAndPush(.HEAD, fetchOptions: fetchOptions, pushOptions: pushOptions, signature: signature)
            }, else: { _ in
                
                remoteTarget.with(self).createUpstream(for: branchTarget, force: true)
                    | { _ in push(options: pushOptions) }
                    | { .success }
            })
    }

    func pullAndPush(_ target: BranchTarget, fetchOptions: FetchOptions, pushOptions: PushOptions, signature: Signature) -> R<PullPushResult> {
        switch pull(target, options: fetchOptions, signature: signature) {
        case let .success(result):
            switch result {
            case let .threeWayConflict(index):
                return .success(.conflict(index))
            default:
                return push(options: pushOptions)
                    .map { .success }
            }
        case let .failure(error):
            return .failure(error)
        }
    }

}

