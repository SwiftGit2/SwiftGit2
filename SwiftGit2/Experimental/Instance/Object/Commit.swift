//
//  CommitInstance.swift
//  SwiftGit2-OSX
//
//  Created by loki on 08.08.2020.
//  Copyright © 2020 GitHub, Inc. All rights reserved.
//

import Clibgit2

public class Commit : Object {
    public var pointer: OpaquePointer
    
    public required init(_ pointer: OpaquePointer) {
        self.pointer = pointer
    }
    
    deinit {
        git_commit_free(pointer)
    }
    
    ///Subject
    public var summary  : String 	{ String(validatingUTF8: git_commit_summary(pointer)) ?? "" }
    ///Description
    public var body     : String	{
        if let commitBody = git_commit_body(pointer) {
            return String(validatingUTF8: commitBody ) ?? ""
        }
        return ""
    }
    ///Description + \n\n + Subject
    //public var message 	: String 	{ String(validatingUTF8: git_commit_message(pointer)) ?? "" }
    
    public var author 	: git_signature { git_commit_author(pointer).pointee }
    public var commiter	: git_signature { git_commit_committer(pointer).pointee }
    public var time		: Date 		{ Date(timeIntervalSince1970: Double(git_commit_time(pointer))) }
}

public extension Commit {
    func parents() -> Result<[Commit], Error> {
        var result: [Commit] = []
        let parentsCount = git_commit_parentcount(self.pointer)
        
        
        for i in 0..<parentsCount {
            var commit: OpaquePointer? = nil
            let gitResult = git_commit_parent(&commit, self.pointer, i )
            
            if gitResult == GIT_OK.rawValue {
                result.append(Commit(commit!))
            } else {
                return Result.failure(NSError(gitError: gitResult, pointOfFailure: "git_commit_parent"))
            }
        }
        
        return .success(result)
    }
    
    func tree() -> Result<Tree, Error> {
        git_instance(of: Tree.self, "git_commit_tree") { pointer in
            git_commit_tree( &pointer, self.pointer )
        }
    }
}

extension Commit : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Git2.Commit: [\(time)] - <\(String(cString: author.email))> : " + summary
    }
}
