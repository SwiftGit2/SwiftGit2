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
            .flatMap { _ in self.pullAndPush(.firstRemote, .HEAD, fetchOptions: fetchOptions, pushOptions: pushOptions, signature: signature)}
    }

    func _pullAndPush(_ target: BranchTarget, fetchOptions: FetchOptions = FetchOptions(auth: .auto), pushOptions: PushOptions = PushOptions(), signature: Signature) -> R<PullPushResult> {
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

public extension Repository {
    func pullAndPush(_ remoteTarget: RemoteTarget, _ branchTarget: BranchTarget, fetchOptions: FetchOptions = FetchOptions(auth: .auto), pushOptions: PushOptions = PushOptions(), signature: Signature) -> R<PullPushResult> {
        return upstreamExistsFor(.HEAD)
            .if(\.self, then: { _ in
                    self._pullAndPush(.HEAD, fetchOptions: fetchOptions, pushOptions: pushOptions, signature: signature)
            }, else: { _ in
                remoteTarget.with(self).createUpstream(for: branchTarget)
                    .map { _ in .success }
                    
                
                //return .failure(WTF("upstreamExistsFor"))
            })
    }
}
