
import Clibgit2
import Essentials

public enum ReferenceName {
    case full(String)
    case branch(String)
    case remote(String)
}

public extension Repository {
    func rename(reference: String, to newName: ReferenceName) -> Result<Reference, Error> {
        return self.reference(name: reference)
            .flatMap { $0.rename(newName) }
    }
}

public extension Reference {
    func rename(_ name: ReferenceName, force: Bool = false) -> Result<Reference, Error> {
        switch name {
        case let .full(name):
            return rename(name, force: force)

        case let .branch(name):
            if isBranch {
                return rename("refs/heads/\(name)", force: force)
            } else {
                return .failure(WTF("can't rename reference in 'refs/heads' namespace: \(nameAsReference)"))
            }

        case let .remote(name):
            let sections = nameAsReference.split(separator: "/")

            if isRemote, sections.count >= 3 {
                let origin = sections[2]
                return rename("refs/remotes/\(origin)/\(name)", force: force)
            } else {
                return .failure(WTF("can't rename reference in 'refs/remotes' namespace: \(nameAsReference)"))
            }
        }
    }

    private func rename(_ newName: String, force: Bool = false) -> Result<Reference, Error> {
        var pointer: OpaquePointer?

        return targetOID.flatMap { oid in
            let logMsg = "Reference.rename: [OID: \(oid)] \(self.nameAsReference) -> \(newName)"

            return git_try("git_reference_rename") {
                git_reference_rename(&pointer, self.pointer, newName, force ? 1 : 0, logMsg)
            }
        }.map { Reference(pointer!) }
    }

    func set(target: OID, message: String) -> Result<Reference, Error> {
        guard isDirect else { return .failure(WTF("can't set target OID for symbolic reference: \(nameAsReference)")) }

        var pointer: OpaquePointer?
        var oid: git_oid = target.oid

        return git_try("git_reference_set_target") {
            git_reference_set_target(&pointer, self.pointer, &oid, message)
        }.map { Reference(pointer!) }
    }

    func set(target: String, message: String) -> Result<Reference, Error> {
        guard isSymbolic else { return .failure(WTF("can't set target string for direct reference: \(nameAsReference)")) }

        var pointer: OpaquePointer?

        return git_try("git_reference_symbolic_set_target") {
            git_reference_symbolic_set_target(&pointer, self.pointer, target, message)
        }.map { Reference(pointer!) }
    }
}

public extension Branch {
    func delete() -> Result<Void, Error> {
        return git_try("git_branch_delete") {
            git_branch_delete(self.pointer)
        }
    }
}
