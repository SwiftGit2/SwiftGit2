import Clibgit2
import Foundation
import Essentials

public enum RemoteTarget {
    case firstRemote(BranchTarget)
    case namedRemote(String, BranchTarget)
    case exactRemote(Remote, BranchTarget)
    
    var branchTarget : BranchTarget {
        switch self {
        case let .firstRemote(target): return target
        case let .namedRemote(_, target): return target
        case let .exactRemote(_, target): return target
        }
    }
    
    func remote(in repo: Repository) -> R<Remote> {
        switch self {
        case .firstRemote(_):               return repo.getRemoteFirst()
        case let .namedRemote(name, _):     return repo.remote(name: name)
        case let .exactRemote(remote, _):   return .success(remote)
        }
    }
}

