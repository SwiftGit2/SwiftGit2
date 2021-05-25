import Foundation
import SwiftUI
import Essentials

public extension Repository {
	func localBranchesInfo() -> Result<[BranchInfo], Error> {
		combine(branchInfos(.local), HEAD() )
			.map { SwiftGit2.merge(locals: $0.0, remotes: [], head: $0.1) }
			.map { $0.sorted(by: sortFunc(_:_:)) }
	}
	
	func allBranchesInfo() -> Result<[BranchInfo], Error> {
		combine(branchInfos(.local), branchInfos(.remote), HEAD() )
			.map { SwiftGit2.merge(locals: $0.0, remotes: $0.1, head: $0.2) }
			.map { $0.sorted(by: sortFunc(_:_:)) }
	}
	
	func branchInfos( _ location: BranchLocation) -> Result<[BranchInfo], Error> {
		branches(location)
			.map { branch in
				branch.map { self.info(branch: $0) }
					.filter { $0.shortNameUnified != "HEAD" }
			}
	}
	
	func info(branch: Branch) -> BranchInfo {
		if branch.isRemoteBranch {
			return BranchInfo(remote: branch)
		}
		
		if let upstream = try? self.upstreamName(branchName: branch.name).get() {
			return BranchInfo(local: branch, upstreamName: upstream)
		}
		
		return BranchInfo(local: branch)
	}
}

public struct BranchInfo {
	public let localName: String
	public let upstreamName: String
	
	/// On case of Local and LocalAndRemote taken from Local.
	/// In case of Remote - taken from Remote.
	public let shortNameUnified: String
	public var shortNameUnifiedFromUpstream: String? {
		if isLocalOnly { return nil }
		
		var components = upstreamName.components(separatedBy: "/")
		
		components.remove(atOffsets: [0,1,2] )
		
		return components.joined(separator: "/")
	}
	
	public let type: BranchType
	
	public var isHead: Bool = false
	public let isHeadDetached: Bool
	
	public var localCommitOid: OID?
	
	public init(detachedHead: Reference) {
		var oidStr = "ERROR"
		
		let headOid = try? detachedHead.commitOID.get()
		if let headOid = headOid{
			oidStr = headOid.description.substring(from: 30)
		}
		
		self.init(nameUnified: "[DETACHED] \(oidStr)",
				  localName: "[DETACHED] \(oidStr)",
				  upstreamName: "[DETACHED] \(oidStr)" ,
				  type: .detachedHead,
				  oid: headOid)
		
		self.isHead = true
	}
	
	public init (local branch: Branch, upstreamName: String = "") {
		let type = upstreamName == "" ? BranchType.local : .localAndRemote
		
		let oid = try? branch.commitOID.get()
		
		self.init(nameUnified: branch.shortNameUnified,
				  localName: branch.name,
				  upstreamName: upstreamName,
				  type: type,
				  oid: oid)
	}
	
	init (remote branch: Branch ) {
		self.init(nameUnified: branch.shortNameUnified,
				  localName: "",
				  upstreamName: branch.name ,
				  type: .remote,
				  oid: nil)
	}
	
	private init (nameUnified: String, localName: String, upstreamName: String, type: BranchType, oid: OID?) {
		self.shortNameUnified = nameUnified
		self.localName = localName
		self.type = type
		self.upstreamName = upstreamName
		self.localCommitOid = oid
		self.isHeadDetached = type == .detachedHead
	}
}

public extension BranchInfo {
	var isLocal: Bool { return type == .local || type == .localAndRemote}
	var isLocalOnly: Bool { return type == .local}
	var isRemote: Bool { return type == .remote || type == .localAndRemote}
	var isRemoteOnly: Bool { return type == .remote}
	
	var shortName: String {
		let rez = self.shortNameUnified.components(separatedBy: "/").last
		return (rez != nil) ? rez! : shortNameUnified
	}
	
	var path: String {
		var rez = self.shortNameUnified.components(separatedBy: "/")
		rez.removeLast()

		return "\(rez.joined(separator: "/"))/"
	}
	
	var isLocalAndRemoteNameDifferent: Bool {
		if isHeadDetached { return false }

		var local = localName.split(separator: "/")
		var remote = upstreamName.split(separator: "/")
		
		if (local.count > 0 && remote.count > 0){
			local.removeSubrange(0...1)
			let localPath = local.joined(separator: "/")
			
			remote.removeSubrange(0...2)
			let remotePath = remote.joined(separator: "/")

			return localPath != remotePath
		}
		
		return false
	}
	
	var pathLocal: String { get{ return "refs/heads/" } }

	var pathRemote: String {
		let components = upstreamName.components(separatedBy: "/")

		if components.count >= 2 {
			let origin = components[2]
			return "refs/remotes/\(origin)"

		}

		return ""
	}
}

public extension BranchInfo {
	enum BranchType: Comparable  {
		case local
		case remote
		case localAndRemote
		case detachedHead
		
		private var sortOrder: Int {
			switch self {
				case .detachedHead:
					return 0
				case .localAndRemote:
					return 1
				case .local:
					return 2
				case .remote:
					return 3
			}
		}

		public static func ==(lhs: BranchType, rhs: BranchType) -> Bool {
			return lhs.sortOrder == rhs.sortOrder
		}

		public static func <(lhs: BranchType, rhs: BranchType) -> Bool {
		   return lhs.sortOrder < rhs.sortOrder
		}
	}
}

public extension Branch {
	var shortNameUnified: String {
		if ( self.isLocalBranch ) {
			return shortName
		}
		else {
			let sn = shortName
			
			var path = sn.split(separator: "/")
			path.remove(at: 0)
			let newName = path.joined(separator: "/")
			
			return newName
		}
	}
}



////////////////////////////////////////////////////////////
/// HELPERS
////////////////////////////////////////////////////////////
private func merge(locals: [BranchInfo], remotes: [BranchInfo], head: Reference) -> [BranchInfo] {
	let localsDic = locals.toDictionary(key: \.shortNameUnified)
	let remotesFiltered = remotes.filter { !localsDic.keys.contains($0.shortNameUnified) }
	
	var locals = locals
	
	if let headBranch = try? head.asBranch().get() {
		return locals.withHEAD(name: headBranch.name) + remotesFiltered
	} else {
		return locals + remotesFiltered + [BranchInfo(detachedHead: head)]
	}
}

private func sortFunc(_ one: BranchInfo, _ another: BranchInfo) -> Bool {
	guard one.type == another.type else {
		// Sort by type
		return one.type < another.type
	}
	
	//Sort by name
	return one.shortNameUnified < another.shortNameUnified
}

//BranchInfo


fileprivate extension Array where Element == BranchInfo {
	mutating func withHEAD(name: String?) -> Self {
		if let name = name,
		   let idx = firstIndex(where: { $0.localName == name }) {
		
			self[idx].isHead = true
		}
		return self
	}
}
