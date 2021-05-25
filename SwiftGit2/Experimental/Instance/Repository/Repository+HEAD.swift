
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
	case ambiguous(branches: [BranchInfo])
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

public extension Repository {
	func detachedHeadFix() -> Result<DetachedHeadFix, Error> {
		guard headIsDetached else {
			return .success(.notNecessary)
		}
		
		let headOID = HEAD()
			.flatMap{ $0.commitOID }
		
//		return combine(branches(.local), headOID)
//			.flatMap { branches, headOid in branches.filter { (try! $0.commitOID.get()) == headOid } }
//			.flatMap(  if: { $0.count == 1 },
//					 then: { $0.checkoutFirst(in: self).map { _ in DetachedHeadFix.fixed } },
//					 else: { .success(.ambiguous(branches: $0)) })
		
		return combine(branchInfos(.local), headOID)
			.map { infos, headOid in infos.filter{ $0.localCommitOid == headOid } } // branches pointing to HEAD
			.flatMap(  if: { $0.count == 1 },
					 then: { $0.checkoutFirst(in: self).map { _ in DetachedHeadFix.fixed } },
					 else: { .success(.ambiguous(branches: $0)) })
	}
}

private extension Array where Element == BranchInfo {
	func checkoutFirst(in repo: Repository) -> Result<(), Error> {
		guard let first = self.first else { return .failure(WTF("checkoutFirst: zero elements")) }
		
		return repo.reference(name: first.localName)
			.flatMap{ $0.asBranch() }
			.flatMap { repo.checkout(branch: $0, strategy: .Safe, progress: nil) }
	}
}

private extension Array where Element == Branch {
	func checkoutFirst(in repo: Repository) -> Result<(), Error> {
		guard let first = self.first else { return .failure(WTF("checkoutFirst: zero elements")) }
		
		return repo.checkout(branch: first, strategy: .Safe, progress: nil)
		
//		return repo.reference(name: first.localName)
//			.flatMap{ $0.asBranch() }
//			.flatMap { repo.checkout(branch: $0, strategy: .Safe, progress: nil) }
	}
}
