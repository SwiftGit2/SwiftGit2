import Clibgit2
import Foundation
import Essentials

public enum BranchTarget : DuoUser {
    case HEAD
    case branch(Branch)
    case branchShortName(String)
    
    func branch(in repo: Repository) -> R<Branch> {
        switch self {
        case .HEAD: return repo.HEAD()
                    .flatMap { $0.asBranch() }
        case let .branch(branch): return .success(branch)
            
        case let .branchShortName(name):
            return repo.branchLookup(name: "refs/heads/\(name)")
        }
    }
}

public extension Duo where T1 == BranchTarget, T2 == Repository {
    var branchInstance: R<Branch> { value.0.branch(in: value.1) }
    var commitInstance: R<Commit> { branchInstance | { $0.targetOID } | { value.1.commit(oid: $0) }}
}
