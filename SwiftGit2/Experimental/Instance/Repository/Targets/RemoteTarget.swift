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
    func createUpstream(for target: BranchTarget, force: Bool) -> R<Branch> {
        target.with(repo).branchInstance | { _createUpstream(for: $0, force: force) }
    }
}

public extension Duo where T1 == RemoteTarget, T2 == Repository {
    var remoteInstance: R<Remote> { value.0.remote(in: value.1) }
    var repo : Repository { value.1 }
    var target : RemoteTarget { value.0 }
}

//***************************************************************************
private extension Duo where T1 == RemoteTarget, T2 == Repository {
    func _createUpstream(for branch: Branch, force: Bool) -> R<Branch> {
        let oid = branch.targetOID
        let referenceName = remoteInstance | { branch.nameAsReference.replace(of: "heads", to: "remotes/\($0.name)") }
        let upstreamName  = referenceName  | { $0.replace(of: "refs/remotes/", to: "") }
        
        return combine(referenceName, oid)
            | { repo.createReference(name: $0, oid: $1, force: force, reflog: "TaoSync: upstream for \(branch.nameAsReference)") }
            | { _ in upstreamName }
            | { branch.setUpstream(name: $0)}
    }
}
