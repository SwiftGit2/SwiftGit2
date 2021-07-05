import Clibgit2
import Foundation
import Essentials

public protocol DuoUser {}

public extension DuoUser {
    func with<T2>(_ t2: T2) -> Duo<Self,T2> {
        return Duo(self, t2)
    }
}

public enum RemoteTarget : DuoUser {
    case firstRemote
    case namedRemote(String)
    case exactRemote(Remote)
    
    func remote(in repo: Repository) -> R<Remote> {
        switch self {
        case .firstRemote:               return repo.getRemoteFirst()
        case let .namedRemote(name):     return repo.remote(name: name)
        case let .exactRemote(remote):   return .success(remote)
        }
    }
}

public extension Duo where T1 == RemoteTarget, T2 == Repository {
    var remoteInstance: R<Remote> { value.0.remote(in: value.1) }
    
    func createUpstream(for target: BranchTarget) -> R<Branch> {
        target.with(value.1).branchInstance | { createUpstream(for: $0) }
    }
    
    func createUpstream(for branch: Branch) -> R<Branch> {
        return remoteInstance
            | { branch.nameAsReference.replace(of: "heads", to: "remotes/\($0.name)") }
            | { branch.setUpstream(name: $0)}
    }
}
