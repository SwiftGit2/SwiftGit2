
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
            .flatMap{ $0.targetOID }
        
        let br_infos = branches(.local)
            .flatMap { $0.flatMap { Branch_Info.create(from: $0) } }
        
        return combine(br_infos, headOID)
            .map { br_infos, headOid in br_infos.filter { $0.oid == headOid } }
            .map { $0.map { $0.branch.nameAsReference } }
            .if({ $0.count == 1 },
                then: { $0.checkoutFirst(in: self).map { _ in DetachedHeadFix.fixed } },
                else: { .success(.ambiguous(branches: $0)) })
    }
    
    
    // possible solution
    // not in use yet
    private func resolveAmbiguity(branches: [String]) -> Result<DetachedHeadFix, Error> {
        // if there are two branches
        // then checkout NOT master
        guard branches.count == 2,
              let masterIdx = branches.masterIdx else { return .success(.ambiguous(branches: branches))}
        
        if masterIdx == 0 {
            return self.checkout(branch: branches[1]).map { .fixed }
        } else {
            return self.checkout(branch: branches[0]).map { .fixed }
        }
    }
}

private extension Array where Element == String {
    var masterIdx : Int? {
        self.firstIndex(of: "refs/heads/master")
    }

    func checkoutFirst(in repo: Repository) -> Result<(), Error> {
        first.asResult { repo.checkout(branch: $0) }
    }
}

private struct Branch_Info {
    let branch : Branch
    let oid : OID
    
    static func create(from branch: Branch) -> Result<Branch_Info,Error> {
        branch.targetOID
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
