import Foundation

// A standalone runner also works with Command Line Tools installations lacking XCTest.
private func failed(_ message: String, file: StaticString, line: UInt) -> Never {
    FileHandle.standardError.write(Data("FAIL: \(file):\(line): \(message)\n".utf8)); exit(1)
}
func checkEqual<T: Equatable>(_ lhs: @autoclosure () throws -> T, _ rhs: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) {
    do { let a = try lhs(), b = try rhs(); if a != b { failed("\(a) != \(b)", file: file, line: line) } }
    catch { failed("Unexpected error: \(error)", file: file, line: line) }
}
func checkNotEqual<T: Equatable>(_ lhs: @autoclosure () throws -> T, _ rhs: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) {
    do { if try lhs() == rhs() { failed("Expected different values", file: file, line: line) } }
    catch { failed("Unexpected error: \(error)", file: file, line: line) }
}
func checkTrue(_ value: @autoclosure () throws -> Bool, file: StaticString = #filePath, line: UInt = #line) {
    do { if try !value() { failed("Expected true", file: file, line: line) } }
    catch { failed("Unexpected error: \(error)", file: file, line: line) }
}
func checkFalse(_ value: @autoclosure () throws -> Bool, file: StaticString = #filePath, line: UInt = #line) {
    do { if try value() { failed("Expected false", file: file, line: line) } }
    catch { failed("Unexpected error: \(error)", file: file, line: line) }
}
func checkThrows<T>(_ body: @autoclosure () throws -> T, file: StaticString = #filePath, line: UInt = #line) {
    do { _ = try body() } catch { return }
    failed("Expected an error", file: file, line: line)
}
func require<T>(_ value: T?) throws -> T {
    guard let value else { throw NSError(domain: "TimeAtlasChecks", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected a non-nil value"]) }
    return value
}
@main struct ChecksRunner {
    static func main() {
        let checks: [(String, (TimeAtlasTests) throws -> Void)] = [
            ("Sync, queries, GeoJSON and idempotence", { try $0.testSyncQueriesAndGeoJSON() }),
            ("Deletion, event type changes and relationships", { try $0.testDeletionTypeChangesAndLinks() }),
            ("ZIP rollback, retry and literal member names", { try $0.testArchiveRollbackAndRetry() }),
            ("Validation, inserts, mixed updates and note JSON", { try $0.testInsertsUpdatesAndValidation() }),
            ("Calendar validation, offsets and enums", { try $0.testDatesOffsetsAndEnums() })
        ]
        do {
            for (name, check) in checks { let suite = try TimeAtlasTests(); try check(suite); print("PASS: \(name)") }
            print("All \(checks.count) checks passed.")
        } catch { FileHandle.standardError.write(Data("FAIL: \(error)\n".utf8)); exit(1) }
    }
}
