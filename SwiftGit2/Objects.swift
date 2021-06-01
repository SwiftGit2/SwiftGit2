//
//  Objects.swift
//  SwiftGit2
//
//  Created by Matt Diephouse on 12/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

import Clibgit2
import Foundation

/// A git object.
public protocol ObjectType {
    static var type: git_object_t { get }

    /// The OID of the object.
    var oid: OID { get }

    /// Create an instance with the underlying libgit2 type.
    init(_ pointer: OpaquePointer)
}

public extension ObjectType {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.oid == rhs.oid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(oid)
    }
}

/// An annotated git tag.
public struct Tag: ObjectType, Hashable {
    public static let type = GIT_OBJECT_TAG

    /// The OID of the tag.
    public let oid: OID

    /// The tagged object.
    public let target: Pointer

    /// The name of the tag.
    public let name: String

    /// The tagger (author) of the tag.
    public let tagger: git_signature

    /// The message of the tag.
    public let message: String

    /// Create an instance with a libgit2 `git_tag`.
    public init(_ pointer: OpaquePointer) {
        oid = OID(git_object_id(pointer).pointee)
        let targetOID = OID(git_tag_target_id(pointer).pointee)
        target = Pointer(oid: targetOID, type: git_tag_target_type(pointer))!
        name = String(validatingUTF8: git_tag_name(pointer))!
        tagger = git_tag_tagger(pointer).pointee
        message = String(validatingUTF8: git_tag_message(pointer))!
    }
}
