import Foundation
import SwiftProtobuf

public struct AtlasPaths {
    public var database: String
    public var iCloud: String
    public init(database: String? = nil, iCloud: String? = nil) {
        let env = ProcessInfo.processInfo.environment
        self.database = database ?? env["TIMEATLAS_DB"] ?? URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("timeatlas.db").path
        self.iCloud = iCloud ?? env["TIMEATLAS_ICLOUD_DIR"] ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Mobile Documents/iCloud~com~timeatlaslabs~Pat/Documents").path
    }
}

/// Keeps the stored UTC offset alongside the absolute instant.
public struct OffsetDate: Equatable {
    public let date: Date
    public let offsetSeconds: Int
    public init?(_ value: TimestampWithOffset) {
        guard let seconds = timestamp(value) else { return nil }
        date = Date(timeIntervalSince1970: seconds)
        offsetSeconds = Int(value.utcOffsetSeconds)
    }
    public func formatted(_ format: String = "HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: offsetSeconds)
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    public var iso8601: String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: offsetSeconds)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

public struct AtlasDay {
    public let date: String
    public let start: OffsetDate?
    public let end: OffsetDate?
}

public let activityNames: [String: String] = [
    "aeb": "E-Biking", "air": "Airplane", "boa": "Boat", "bsw": "Beach walking",
    "bus": "Bus", "car": "Car", "cyc": "Cycling", "dhs": "Downhill skiing",
    "dsw": "Dog and stroller walk", "dwk": "Dog-walking", "hke": "Hiking", "ice": "Ice skating",
    "mtc": "Motorcycle", "pdl": "Paddling", "pub": "Public Transport", "rbd": "Rollerblading",
    "run": "Running", "sct": "Scooting", "ski": "Cross-country skiing", "slb": "Sailing",
    "sbd": "Snowboarding", "sub": "Subway", "swk": "Stroller walk", "swm": "Swimming",
    "tax": "Taxi", "trm": "Tram", "trn": "Train", "trp": "Transport", "tsw": "Twin-stroller walk", "wlk": "Walking"
]
public func getActivityName(_ code: String) -> String { activityNames[code] ?? code }
public func resolveActivityCode(_ value: String) -> String {
    let value = value.lowercased()
    if activityNames[value] != nil { return value }
    let codes = activityNames.keys.sorted()
    if let exact = codes.first(where: { activityNames[$0]!.lowercased() == value }) { return exact }
    return codes.first(where: { activityNames[$0]!.lowercased().contains(value) || value.contains(activityNames[$0]!.lowercased()) }) ?? value
}

public let eventTables = ["date": "events_dates", "placevisit": "events_place_visits", "movement": "events_movements", "nodataperiod": "events_no_data_periods", "no_data_period": "events_no_data_periods", "workout": "events_workouts", "sleep": "events_sleeps", "eventgroup": "events_event_groups", "event_group": "events_event_groups", "trip": "events_trips"]

public final class TimeAtlas {
    public let paths: AtlasPaths
    public init(paths: AtlasPaths = AtlasPaths()) { self.paths = paths }
    public func connect(readOnly: Bool = true) throws -> Database { try Database(path: paths.database, readOnly: readOnly) }
    public func getDateEvent(_ date: String) throws -> Event? {
        try connect().messages(Event.self, "SELECT data FROM events_dates WHERE date = ? LIMIT 1", [.text(date)]).first
    }
    public func getDateDateRange(_ date: String) throws -> AtlasDay? {
        try getDateEvent(date).map { AtlasDay(date: date, start: OffsetDate($0.startAt), end: OffsetDate($0.endAt)) }
    }
    public func getDates(_ from: String, _ to: String) throws -> [AtlasDay] {
        try connect().messages(Event.self, "SELECT data FROM events_dates WHERE date >= ? AND date <= ? ORDER BY date", [.text(from), .text(to)]).map { AtlasDay(date: $0.dateEvent.date, start: OffsetDate($0.startAt), end: OffsetDate($0.endAt)) }
    }
    public func getEvents(_ type: String, _ from: Date, _ to: Date) throws -> [Event] {
        guard let table = eventTables[type.lowercased()] else { throw AtlasError("Unknown event type: \(type)") }
        return try connect().messages(Event.self, "SELECT data FROM \(table) WHERE start_at <= ? AND (end_at IS NULL OR end_at >= ?) ORDER BY start_at", [.real(to.timeIntervalSince1970), .real(from.timeIntervalSince1970)])
    }
    public func getKnownPlace(id: String) throws -> KnownPlace? {
        try connect().messages(KnownPlace.self, "SELECT data FROM known_places WHERE id = ? LIMIT 1", [.text(id)]).first
    }
    public func getKnownPlace(name: String) throws -> [KnownPlace] {
        try connect().messages(KnownPlace.self, "SELECT data FROM known_places WHERE name = ?", [.text(name)])
    }
    public func getJournalEntriesForEvent(_ id: String) throws -> [JournalEntry] {
        guard !id.isEmpty else { return [] }
        return try connect().messages(JournalEntry.self, "SELECT data FROM journal_entries WHERE event_id = ? ORDER BY meta_created_at", [.text(id)])
    }
    public func getMediaForJournalEntry(_ id: String) throws -> [Media] {
        guard !id.isEmpty else { return [] }
        return try connect().messages(Media.self, "SELECT data FROM media WHERE id IN (SELECT media_id FROM journal_entry_media_ids WHERE journal_entry_id = ?)", [.text(id)])
    }
    public func getBooks(_ from: String, _ to: String) throws -> [Book] {
        try connect().messages(Book.self, "SELECT data FROM books WHERE read_date >= ? AND read_date <= ? ORDER BY read_date, title", [.text(String(from.prefix(10))), .text(String(to.prefix(10)))])
    }
    public func getMoviesAndTv(_ from: Date, _ to: Date) throws -> [MovieAndTv] {
        try connect().messages(MovieAndTv.self, "SELECT data FROM movies_and_tv WHERE watched_at >= ? AND watched_at <= ? ORDER BY watched_at", [.real(from.timeIntervalSince1970), .real(to.timeIntervalSince1970)])
    }
    public func getLastFmTracks(_ from: Date, _ to: Date) throws -> [LastFmTrack] {
        try connect().messages(LastFmTrack.self, "SELECT data FROM lastfm_tracks WHERE played_at >= ? AND played_at <= ? ORDER BY played_at", [.real(from.timeIntervalSince1970), .real(to.timeIntervalSince1970)])
    }
}

public func makeTimestamp(_ date: Date = Date()) -> TimestampWithOffset {
    var value = TimestampWithOffset()
    let seconds = floor(date.timeIntervalSince1970)
    value.utcTimestamp.seconds = Int64(seconds)
    value.utcTimestamp.nanos = Int32((date.timeIntervalSince1970 - seconds) * 1e9)
    value.utcOffsetSeconds = Int32(TimeZone.current.secondsFromGMT(for: date))
    return value
}
public func validateDate(_ value: String) throws -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.isLenient = false
    guard let date = formatter.date(from: value), formatter.string(from: date) == value else { throw AtlasError("Invalid date '\(value)'; expected YYYY-MM-DD") }
    return value
}
public func today() -> String {
    let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: Date())
}
