//
//  Submodule.swift
//  SwiftGit2-OSX
//
//  Created by UKS on 06.10.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public class Submodule: InstanceProtocol {
	public let pointer: OpaquePointer
	
	public required init(_ pointer: OpaquePointer) {
		self.pointer = pointer
	}
	
	deinit {
		git_submodule_free(pointer)
	}
}

public extension Submodule {
	var name 	 : String { String(cString: git_submodule_name(self.pointer)) }
	///Get the path to the submodule. RELATIVE! Almost allways the same as "name" parameter
	var path 	 : String { String(cString: git_submodule_path(self.pointer)) }
	
	/// Url to remote repo (https or ssh)
	var url  	 : String { String(cString: git_submodule_url(self.pointer)) }
	
	/// Get the OID for the submodule in the current working directory.
	var Oid      : OID   { OID( git_submodule_wd_id(self.pointer).pointee ) }
	
	/// Get the OID for the submodule in the current HEAD tree.
	var headOID  : OID   { OID( git_submodule_head_id(self.pointer).pointee ) }
	
	/// Open the repository for a submodule.
	func repo() -> Result<Repository, NSError> {
		var pointer: OpaquePointer? = nil
		
		return _result( { Repository(pointer!) }, pointOfFailure: "") {
			git_submodule_open( &pointer, self.pointer )
		}
	}
}

public extension Duo where T1 == Submodule, T2 == Repository {
	func getSubmoduleAbsPath() -> Result<String, NSError> {
		let (submodule, repo) = self.value
		
		return repo.directoryURL.flatMap { url in
			.success("\(url.path)/\(submodule.path)")
		}
	}
	
	func fetchRecurseValueSet(_ bool: Bool ) -> Result<(),NSError> {
		let (submodule, repo) = self.value
		
		let valToSet = git_submodule_recurse_t(rawValue:  bool ? 1 : 0 )
		
		return _result( { () }, pointOfFailure: "git_submodule_set_fetch_recurse_submodules" ) {
			submodule.name.withCString{ submoduleName in
				git_submodule_set_fetch_recurse_submodules(repo.pointer, submoduleName, valToSet)
			}
		}
	}
	
	//TODO: Test Me -- this must be string or Branch?
	func branchGet() -> String {
		let (submodule, _) = self.value
	
		if let brPointer = git_submodule_branch(submodule.pointer) {
			return String(cString: brPointer)
		}
		
		return ""
	}
	
	//TODO: Test Me
	/// Set the branch for the submodule in the configuration
	func branchSetAndSync(branchName: String) -> Result<(), NSError> {
		let (submodule, repo) = self.value
		
		return _result( { () }, pointOfFailure: "git_submodule_set_branch" ) {
			branchName.withCString { brName in
				submodule.name.withCString{ submoduleName in
					git_submodule_set_branch(repo.pointer, submoduleName, brName)
				}
			}
		}
		.flatMap{ submodule.sync() }
	}
	
	// WTF? What this fucking THING is doing? I have no idea.
	//   .resolveUrl() -> "git@gitlab.com:sergiy.vynnychenko/AppCore.git"
	//            .url -> "git@gitlab.com:sergiy.vynnychenko/AppCore.git"
	//
	//Resolve a submodule url relative to the given repository.
	func resolveUrl() -> Result<String, NSError> {
		let (submodule, repo) = self.value

		let buf_ptr = UnsafeMutablePointer<git_buf>.allocate(capacity: 1)
		buf_ptr.pointee = git_buf(ptr: nil, asize: 0, size: 0)

		return _result( { Buffer(pointer: buf_ptr) }, pointOfFailure: "git_submodule_resolve_url") {
			submodule.url.withCString { relativeUrl in
				git_submodule_resolve_url(buf_ptr, repo.pointer, relativeUrl)
			}
		}
		.flatMap { $0.asStringRez() }
	}
	
	
	//TODO: Test Me
	/// Set the URL for the submodule in the configuration
	func submoduleSetUrlAndSync(newRelativeUrl: String) -> Result<(), NSError> {
		let (submodule, repo) = self.value
		
		return _result({()}, pointOfFailure: "git_submodule_set_url") {
			submodule.name.withCString { submoduleName in
				newRelativeUrl.withCString { newUrl in
					git_submodule_set_url(repo.pointer, submoduleName, newUrl)
				}
			}
		}
		.flatMap {
			submodule.sync()
		}
	}
}

public extension Submodule {
	func fetchRecurseValueGet() -> Bool {
		//"result == 1"
		return git_submodule_fetch_recurse_submodules(self.pointer) == git_submodule_recurse_t(rawValue: 1)
	}
	
	//TODO: Test Me
	///Copy submodule remote info into submodule repo.
	func sync() -> Result<(), NSError> {
		return _result( {()}, pointOfFailure:"git_submodule_sync" ){
			git_submodule_sync(self.pointer);
		}
	}
	
	//TODO: Test Me. // don't know how to test
	///Reread submodule info from config, index, and HEAD |
	///Call this to reread cached submodule information for this submodule if you have reason to believe that it has changed.
	func reload(force: Bool = false) -> Result<(), NSError> {
		let forceInt: Int32 = force ? 1 : 0
		
		return _result( {()}, pointOfFailure: "git_submodule_reload") {
			git_submodule_reload(self.pointer, forceInt)
		}
	}
	
	//TODO: Test Me.
	///Update a submodule.
	///This will clone a missing submodule and checkout the subrepository to the commit specified in the index of the containing repository.
	///If the submodule repository doesn't contain the target commit (e.g. because fetchRecurseSubmodules isn't set),
	///then the submodule is fetched using the fetch options supplied in options.
	func update( options: UnsafeMutablePointer<git_submodule_update_options>?,
				 initBeforeUpdate: Bool = false ) -> Result<(), NSError> {
		let initBeforeUpdateInt: Int32 = initBeforeUpdate ? 1 : 0
		
		return _result({()}, pointOfFailure: "git_submodule_update") {
			git_submodule_update(self.pointer, initBeforeUpdateInt, options )
		}
	}
	
	//TODO: Test Me --- not sure how to test
	///Add current submodule HEAD commit to index of superproject.
	/// writeIndex -- if true - should immediately write the index file. If you pass this as false, you will have to get the git_index and explicitly call `git_index_write()` on it to save the change
	func addToIndex( writeIndex: Bool = true) -> Result<(), NSError> {
		let writeIndex:Int32 = writeIndex ? 1 : 0
		
		return _result({()}, pointOfFailure: "git_submodule_add_to_index") {
			git_submodule_add_to_index(self.pointer, writeIndex);
		}
		
	}
	
	//TODO: Test Me
	/// Resolve the setup of a new git submodule. |
	///This should be called on a submodule once you have called add setup and done the clone of the submodule.
	///This adds the .gitmodules file and the newly cloned submodule to the index to be ready to be committed (but doesn't actually do the commit).
	func finalize () -> Result<(),NSError> {
		return _result( {()}, pointOfFailure: "git_submodule_add_finalize") {
			git_submodule_add_finalize(self.pointer);
		}
	}
	
	//TODO: Test Me. Especially "overwrite"
	func initSub (overwrite: Bool = false) -> Result<(),NSError> {
		let overwriteInt: Int32 = overwrite ? 1 : 0
		
		return _result( {()}, pointOfFailure: "git_submodule_init") {
			git_submodule_init(self.pointer, overwriteInt)
		}
	}
}

//TODO: Test Me
public class SubmoduleUpdateOptions {
	private var optionsPointer = UnsafeMutablePointer<git_submodule_update_options>.allocate(capacity: 1)
	public var options: git_submodule_update_options { optionsPointer.pointee }
	
	private let GIT_SUBMODULE_UPDATE_OPTIONS_VERSION = UInt32(1) //have no idea what is this
	
	func create() -> Result<SubmoduleUpdateOptions, NSError> {
		return _result( self , pointOfFailure: "git_submodule_update_options_init") {
			git_submodule_update_options_init(optionsPointer, GIT_SUBMODULE_UPDATE_OPTIONS_VERSION )
		}
	}
	
	deinit {
		optionsPointer.deallocate()
	}
}

public enum SubmoduleIgnore : Int32 {
	case unspecified = -1 	//GIT_SUBMODULE_IGNORE_UNSPECIFIED  = -1, /**< use the submodule's configuration */
	case none        = 1	//GIT_SUBMODULE_IGNORE_NONE      = 1,  /**< any change or untracked == dirty */
	case untracked   = 2	//GIT_SUBMODULE_IGNORE_UNTRACKED = 2,  /**< dirty if tracked files change */
	case ignoreDirty = 3	//GIT_SUBMODULE_IGNORE_DIRTY     = 3,  /**< only dirty if HEAD moved */
	case ignoreAll   = 4	//GIT_SUBMODULE_IGNORE_ALL       = 4,  /**< never dirty */
}

/*
UNUSED:
	git_submodule_add_setup
	git_submodule_clone
	git_submodule_ignore -- need to use SubmoduleIgnore enum here
	git_submodule_set_ignore
	git_submodule_repo_init
	git_submodule_set_update
	git_submodule_status
	git_submodule_update_strategy
	git_submodule_owner -- NEVER USE THIS SHIT. It's killing pointer too fast for you, buddy
*/
