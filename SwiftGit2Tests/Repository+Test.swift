
import Foundation
import XCTest
import Essentials
@testable import SwiftGit2

extension Repository {
    static func t_randomRepo() -> Result<Repository,Error>  {
        URL.randomTempDirectory()
            .flatMap { Repository.create(at: $0) }
    }
    
    func t_commit(file: TestFile = .fileA, with content: TestFileContent = .oneLine1, msg: String) -> Result<Commit,Error> {
        t_write(file: file, with: content)
            .flatMap { file in self.index().flatMap { $0.add(paths: [file]) } }
            .flatMap { _ in self.commit(message: msg, signature: GitTest.signature) }
    }
    
    func t_write(file: TestFile, with content: TestFileContent) -> Result<String, Error> {
        return self.directoryURL
            .map { $0.appendingPathComponent(file.rawValue) }
            .flatMap { $0.write(content: content.get()) }
            .map { _ in file.rawValue }
    }
}

enum TestFile : String {
    case fileA = "fileA.txt"
    case fileB = "fileB.txt"
}

enum TestFileContent: String {
    case random
    case oneLine1 = "oneLine1"
    case oneLine2 = "oneLine2"
    
    case content1 = """
        01 The White Rabbit put on his spectacles.  "Where shall I begin,
        02 please your Majesty?" he asked.
        03
        04 "Begin at the beginning," the King said gravely, "and go on
        05 till you come to the end; then stop."
        06
        07
        08
        09
        """
    
    case content2 = """
        01 << LINE REPLACEMENT >>
        02 please your Majesty?" he asked.
        03
        04 "Begin at the beginning," the King said gravely, "and go on
        05 till you come to the end; then stop."
        06
        07
        08
        09  << LINE INSERTION >>
        """
}

extension TestFileContent {
    func get() -> String {
        switch self {
        case .random:
            return UUID().uuidString
        default:
            return self.rawValue
        }
    }
}
