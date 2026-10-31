import Foundation
import Darwin
import SwiftProtobuf

public func validateTally(_ tally: Tally) throws {
    if tally.eventID.isEmpty { throw AtlasError("tally-event-id-empty") }
    if timestamp(tally.time) == nil { throw AtlasError("tally-time-invalid") }
    if tally.name.isEmpty { throw AtlasError("tally-name-empty") }
    if tally.name != tally.name.lowercased() { throw AtlasError("tally-name-not-lower-case") }
    if tally.who.isEmpty { throw AtlasError("tally-who-empty") }
    if tally.unit.isEmpty && tally.category.isEmpty { throw AtlasError("tally-unit-and-category-empty") }
    if tally.unit != tally.unit.lowercased() { throw AtlasError("tally-unit-not-lower-case") }
    if !tally.value.isFinite { throw AtlasError("tally-value-not-finite") }
    if tally.value > 16_777_216 { throw AtlasError("tally-too-large") }
    if tally.value < 0 { throw AtlasError("tally-negative") }
}
public func validateBook(_ book: Book) throws {
    if book.title.isEmpty { throw AtlasError("book-title-empty") }
    if book.stars != 0 && !(1...5).contains(book.stars) { throw AtlasError("book-stars-out-of-range") }
}
public func validateMovieAndTv(_ movie: MovieAndTv) throws {
    if movie.title.isEmpty { throw AtlasError("movie-title-empty") }
    if movie.stars != 0 && !(1...5).contains(movie.stars) { throw AtlasError("movie-stars-out-of-range") }
}

extension TimeAtlas {
    public func insertTallies(_ tallies: [Tally]) throws -> String {
        var directory = FullDirectory()
        directory.tallies = try tallies.map { value in
            try validateTally(value)
            var value = value; value.meta = newMeta(); return value
        }
        return try writeUpdateFile(directory)
    }
    public func insertBooks(_ books: [Book]) throws -> String {
        var directory = FullDirectory()
        directory.books = try books.map { value in
            try validateBook(value)
            var value = value; value.meta = newMeta(); return value
        }
        return try writeUpdateFile(directory)
    }
    public func insertMoviesAndTvs(_ movies: [MovieAndTv]) throws -> String {
        var directory = FullDirectory()
        directory.moviesAndTv = try movies.map { value in
            try validateMovieAndTv(value)
            var value = value; value.meta = newMeta(); return value
        }
        return try writeUpdateFile(directory)
    }
    public func writeUpdateFile(_ directory: FullDirectory) throws -> String {
        try writeSyncFile(try directory.serializedData(), prefix: "", suffix: "_update.pb")
    }
    public func writeNote(_ text: String, date: String = today()) throws -> String {
        _ = try validateDate(date)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AtlasError("No note text provided") }
        let record = ["text": text, "source": "user:oss", "timestamp": OffsetDate(makeTimestamp())!.iso8601, "date": date]
        var data = try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        data.append(10)
        return try writeSyncFile(data, prefix: "note_", suffix: ".json")
    }
    private func writeSyncFile(_ data: Data, prefix: String, suffix: String) throws -> String {
        var directory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: paths.iCloud, isDirectory: &directory), directory.boolValue else { throw AtlasError("iCloud directory not found: \(paths.iCloud)") }
        // Publish only complete files; RENAME_EXCL prevents collisions between writers.
        let temporary = URL(fileURLWithPath: paths.iCloud).appendingPathComponent(".timeatlas-\(UUID().uuidString).tmp")
        try data.write(to: temporary, options: .withoutOverwriting)
        defer { try? FileManager.default.removeItem(at: temporary) }
        var millis = Int64(Date().timeIntervalSince1970 * 1000)
        while true {
            let url = URL(fileURLWithPath: paths.iCloud).appendingPathComponent("\(prefix)\(millis)\(suffix)")
            if renamex_np(temporary.path, url.path, UInt32(RENAME_EXCL)) == 0 { return url.path }
            let code = errno
            if code == EEXIST { millis += 1; continue }
            throw AtlasError("Cannot publish sync file: \(String(cString: strerror(code)))")
        }
    }
}
private func newMeta() -> Meta {
    var meta = Meta(); meta.id = UUID().uuidString.lowercased()
    meta.createdAt = makeTimestamp(); meta.updatedAt = meta.createdAt
    return meta
}
