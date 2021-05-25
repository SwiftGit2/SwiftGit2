
import Clibgit2
import Essentials

public extension Repository {
    func HEAD() -> Result<Reference, Error> {
        var pointer: OpaquePointer? = nil
        
        return _result( { Reference(pointer!) }, pointOfFailure: "git_repository_head") {
            git_repository_head(&pointer, self.pointer)
        }
    }
    
    var headIsUnborn: Bool 		{ git_repository_head_unborn(self.pointer) == 1 }
    var headIsDetached: Bool 	{ git_repository_head_detached(self.pointer) == 1 }
    
}

public enum DetachedHeadFix {
    case notNecessary
    case fixed
    case ambiguous(branches: [String])
}

public extension Repository {
    func detachedHeadFix() -> Result<DetachedHeadFix, Error> {
        guard headIsDetached else {
            return .success(.notNecessary)
        }
        
        let headOID = HEAD()
            .flatMap{ $0.commitOID }
        
        let br_infos = branches(.local)
            .flatMap { $0.flatMap { Branch_Info.create(from: $0) } }
        
        return combine(br_infos, headOID)
            .map { br_infos, headOid in br_infos.filter { $0.oid == headOid } }
            .flatMap(  if  : { $0.count == 1 },
                       then: { $0.checkoutFirst(in: self).map { _ in DetachedHeadFix.fixed } },
                       else: { .success(.ambiguous(branches: $0.map { $0.branch.name })) })
    }
}

private extension Array where Element == Branch_Info {
    func checkoutFirst(in repo: Repository) -> Result<(), Error> {
        first.asResult { repo.checkout(branch: $0.branch) }
    }
}

private struct Branch_Info {
    let branch : Branch
    let oid : OID
    
    static func create(from branch: Branch) -> Result<Branch_Info,Error> {
        branch.commitOID
            .map { Branch_Info(branch: branch, oid: $0) }
    }
}

extension DetachedHeadFix : Equatable {
    public static func == (lhs: DetachedHeadFix, rhs: DetachedHeadFix) -> Bool {
        switch (lhs, rhs) {
        case (.fixed, .fixed): return true
        case (.notNecessary, .notNecessary): return true
        case let (.ambiguous(a_l), .ambiguous(a_r)):
            return a_l == a_r
        default: return false
        }
    }
}
