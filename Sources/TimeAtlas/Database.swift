import Foundation
import CSQLite
import SwiftProtobuf

public struct AtlasError: Error, CustomStringConvertible {
    public let description: String
    public init(_ message: String) { description = message }
}

public enum SQLValue: Equatable {
    case null, text(String), integer(Int64), real(Double), blob(Data)
    public var string: String? { if case let .text(v) = self { return v }; return nil }
    public var number: Double? {
        switch self { case let .real(v): return v; case let .integer(v): return Double(v); default: return nil }
    }
}

/// A connection is intended for serial use. Every sync file is one transaction.
public final class Database {
    private var handle: OpaquePointer?
    public init(path: String, readOnly: Bool = false) throws {
        let flags = readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK else {
            let reason = handle.map { String(cString: sqlite3_errmsg($0)) } ?? path
            if let handle { sqlite3_close(handle) }
            handle = nil
            throw AtlasError("Cannot open database: \(reason)")
        }
        sqlite3_busy_timeout(handle, 5000)
    }
    deinit { sqlite3_close(handle) }
    public func query(_ sql: String, _ values: [SQLValue] = []) throws -> [[String: SQLValue]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else { throw error(sql) }
        defer { sqlite3_finalize(statement) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch value {
            case .null: result = sqlite3_bind_null(statement, index)
            case let .text(v): result = sqlite3_bind_text(statement, index, v, -1, transient)
            case let .integer(v): result = sqlite3_bind_int64(statement, index, v)
            case let .real(v): result = sqlite3_bind_double(statement, index, v)
            case let .blob(v):
                result = v.isEmpty ? sqlite3_bind_zeroblob(statement, index, 0) : v.withUnsafeBytes { sqlite3_bind_blob(statement, index, $0.baseAddress, Int32($0.count), transient) }
            }
            guard result == SQLITE_OK else { throw error(sql) }
        }
        var rows: [[String: SQLValue]] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { return rows }
            guard result == SQLITE_ROW else { throw error(sql) }
            var row: [String: SQLValue] = [:]
            for i in 0..<sqlite3_column_count(statement) {
                let key = String(cString: sqlite3_column_name(statement, i))
                switch sqlite3_column_type(statement, i) {
                case SQLITE_INTEGER: row[key] = .integer(sqlite3_column_int64(statement, i))
                case SQLITE_FLOAT: row[key] = .real(sqlite3_column_double(statement, i))
                case SQLITE_TEXT: row[key] = .text(String(cString: sqlite3_column_text(statement, i)))
                case SQLITE_BLOB:
                    let count = Int(sqlite3_column_bytes(statement, i))
                    row[key] = .blob(count == 0 ? Data() : Data(bytes: sqlite3_column_blob(statement, i)!, count: count))
                default: row[key] = .null
                }
            }
            rows.append(row)
        }
    }
    public func execute(_ sql: String, _ values: [SQLValue] = []) throws { _ = try query(sql, values) }
    public func transaction(_ action: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE")
        do { try action(); try execute("COMMIT") }
        catch { try? execute("ROLLBACK"); throw error }
    }
    public func messages<M: SwiftProtobuf.Message>(_ type: M.Type, _ sql: String, _ values: [SQLValue] = []) throws -> [M] {
        try query(sql, values).map { row in
            guard case let .blob(data) = row["data"] else { throw AtlasError("Missing protobuf data") }
            return try M(serializedBytes: data)
        }
    }
    private func error(_ sql: String) -> AtlasError { AtlasError("SQLite: \(String(cString: sqlite3_errmsg(handle))) [\(sql)]") }
}

func scalar(_ value: String) -> SQLValue { value.isEmpty ? .null : .text(value) }
func scalar(_ value: Bool) -> SQLValue { .integer(value ? 1 : 0) }
func scalar<T: BinaryInteger>(_ value: T) -> SQLValue { .integer(Int64(value)) }
func scalar(_ value: Double) -> SQLValue { .real(value) }
func scalar(_ value: Float) -> SQLValue { .real(Double(value)) }
func scalar<E: SwiftProtobuf.Enum>(_ value: E) -> SQLValue { .text(enumName(value)) }
func timestamp(_ value: Google_Protobuf_Timestamp) -> Double? {
    value.seconds == 0 && value.nanos == 0 ? nil : Double(value.seconds) + Double(value.nanos) / 1e9
}
func timestamp(_ value: TimestampWithOffset) -> Double? { value.hasUtcTimestamp ? timestamp(value.utcTimestamp) : nil }
func timeValue(_ value: Google_Protobuf_Timestamp) -> SQLValue { timestamp(value).map(SQLValue.real) ?? .null }
func timeValue(_ value: TimestampWithOffset) -> SQLValue { timestamp(value).map(SQLValue.real) ?? .null }
