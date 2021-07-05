import Clibgit2
import Foundation
import Essentials

public enum BranchTarget {
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
