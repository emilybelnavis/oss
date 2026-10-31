import Foundation
import TimeAtlas

final class TimeAtlasTests {
    var root: URL!
    var atlas: TimeAtlas!
    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("timeatlas-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        atlas = TimeAtlas(paths: AtlasPaths(database: root.appendingPathComponent("test.db").path, iCloud: root.path))
    }
    deinit { try? FileManager.default.removeItem(at: root) }
    func fixture() -> FullDirectory {
        var directory = FullDirectory()
        var day = Event(); day.meta.id = "day"; day.type = .date
        day.dateEvent.date = "2026-04-20"
        day.startAt = makeTimestamp(Date(timeIntervalSince1970: 1_776_657_600))
        day.startAt.utcOffsetSeconds = -14400
        day.endAt = makeTimestamp(Date(timeIntervalSince1970: 1_776_743_999))
        day.endAt.utcOffsetSeconds = -14400
        var visit = Event(); visit.meta.id = "visit"; visit.type = .placevisit
        visit.startAt = day.startAt; visit.endAt = day.endAt
        visit.placeVisit.name = "Gym"; visit.placeVisit.knownPlaceID = "place"
        visit.placeVisit.location.lat = 43.65; visit.placeVisit.location.lon = -79.38
        var movement = Event(); movement.meta.id = "move"; movement.type = .movement
        movement.startAt = day.startAt; movement.endAt = day.endAt
        var activity = MoveActivity(); activity.activity = "wlk"; activity.distanceMeters = 1200
        activity.durationSecs = 900; activity.steps = 1600; activity.startAt = day.startAt
        activity.trajectory = [visit.placeVisit.location, .with { $0.lat = 43.66; $0.lon = -79.37 }]
        movement.movement.moveActivities = [activity]
        directory.events = [day, visit, movement]
        var place = KnownPlace(); place.meta.id = "place"; place.name = "Gym"; place.categories = ["fitness", "sport"]
        directory.knownPlaces = [place]
        var entry = JournalEntry(); entry.meta.id = "entry"; entry.eventID = "visit"; entry.text = "A good day 🌞"
        entry.tags = ["exercise"]; entry.mediaIds = ["photo"]
        directory.journalEntries = [entry]
        var media = Media(); media.meta.id = "photo"; media.filename = "test.jpg"
        directory.media = [media]
        return directory
    }
    func testSyncQueriesAndGeoJSON() throws {
        let directory = fixture()
        try directory.serializedData().write(to: root.appendingPathComponent("100.pb"))
        try atlas.sync(progress: { _ in })
        let days = try atlas.getDates("2026-04-20", "2026-04-20")
        checkEqual(days.count, 1); checkEqual(days[0].start?.offsetSeconds, -14400)
        let start = try require(days[0].start), end = try require(days[0].end)
        checkEqual(try atlas.getEvents("placevisit", start.date, end.date).first?.placeVisit.name, "Gym")
        checkEqual(try atlas.getJournalEntriesForEvent("visit").first?.text, "A good day 🌞")
        checkEqual(try atlas.getMediaForJournalEntry("entry").first?.filename, "test.jpg")
        checkEqual(try atlas.getKnownPlace(id: "place")?.categories, ["fitness", "sport"])
        checkEqual(try atlas.getKnownPlace(name: "Gym").count, 1)
        let all = try JSONSerialization.jsonObject(with: atlas.buildGeoJSON("2026-04-20", "2026-04-20")) as! [String: Any]
        checkEqual((all["features"] as! [Any]).count, 2)
        let filtered = try JSONSerialization.jsonObject(with: atlas.buildGeoJSON("2026-04-20", "2026-04-20", activityFilter: "Walking")) as! [String: Any]
        let features = filtered["features"] as! [[String: Any]]
        checkEqual(features.count, 1)
        checkEqual((features[0]["properties"] as! [String: Any])["distance_meters"] as? Int, 1200)
        try atlas.sync(progress: { _ in })
        checkEqual(try atlas.connect().query("SELECT COUNT(*) AS n FROM sync_state")[0]["n"], .integer(1))
    }
    func testDeletionTypeChangesAndLinks() throws {
        let db = try atlas.connect(readOnly: false); try atlas.createTables(db)
        var directory = fixture(); try atlas.processFullDirectory(directory, database: db)
        var event = directory.events[1]; event.type = .movement
        directory = FullDirectory(); directory.events = [event]
        try atlas.processFullDirectory(directory, database: db)
        checkTrue(try db.query("SELECT id FROM events_place_visits").isEmpty)
        checkEqual(try db.query("SELECT id FROM events_movements").count, 2)
        var entry = JournalEntry(); entry.meta.id = "entry"; entry.meta.deletedAt = makeTimestamp()
        event.meta.deletedAt = makeTimestamp(); directory.events = [event]; directory.journalEntries = [entry]
        try atlas.processFullDirectory(directory, database: db)
        checkTrue(try db.query("SELECT * FROM journal_entries").isEmpty)
        checkTrue(try db.query("SELECT * FROM journal_entry_media_ids").isEmpty)
        checkTrue(try db.query("SELECT * FROM journal_entry_tags").isEmpty)
    }
    func testArchiveRollbackAndRetry() throws {
        let archiveDir = root.appendingPathComponent("archive")
        try FileManager.default.createDirectory(at: archiveDir, withIntermediateDirectories: true)
        try fixture().serializedData().write(to: archiveDir.appendingPathComponent("a.pb"))
        try Data([0xff]).write(to: archiveDir.appendingPathComponent("b.pb"))
        let zip = root.appendingPathComponent("100.zip")
        try runProcess("/usr/bin/zip", ["-j", zip.path, archiveDir.appendingPathComponent("a.pb").path, archiveDir.appendingPathComponent("b.pb").path])
        checkThrows(try atlas.sync(progress: { _ in }))
        let db = try atlas.connect()
        checkTrue(try db.query("SELECT * FROM events_dates").isEmpty)
        checkTrue(try db.query("SELECT * FROM sync_state").isEmpty)
        try FileManager.default.removeItem(at: zip)
        // Member names requiring escaping are read literally, including brackets.
        let name = archiveDir.appendingPathComponent("a[1].pb")
        try fixture().serializedData().write(to: name)
        try runProcess("/usr/bin/zip", ["-j", zip.path, name.path])
        try atlas.sync(progress: { _ in })
        checkEqual(try atlas.getDates("2026-04-20", "2026-04-20").count, 1)
    }
    func testInsertsUpdatesAndValidation() throws {
        var tally = Tally(); tally.eventID = "day"; tally.name = "water"; tally.unit = "ml"
        tally.value = 200; tally.who = "self"; tally.time = makeTimestamp()
        let path = try atlas.insertTallies([tally])
        let written = try FullDirectory(serializedBytes: Data(contentsOf: URL(fileURLWithPath: path)))
        checkFalse(written.tallies[0].meta.id.isEmpty)
        checkTrue(written.tallies[0].meta.hasCreatedAt)
        var invalid = tally; invalid.name = "Water"; checkThrows(try validateTally(invalid))
        invalid = tally; invalid.value = .nan; checkThrows(try validateTally(invalid))
        invalid = tally; invalid.value = -1; checkThrows(try validateTally(invalid))
        invalid = tally; invalid.value = 16_777_218; checkThrows(try validateTally(invalid))
        checkThrows(try validateTally(Tally()))
        var book = Book(); checkThrows(try validateBook(book)); book.title = "Book"; book.stars = 6
        checkThrows(try validateBook(book)); book.stars = 4.5
        var movie = MovieAndTv(); checkThrows(try validateMovieAndTv(movie)); movie.title = "Movie"; movie.stars = -1
        checkThrows(try validateMovieAndTv(movie)); movie.stars = 5
        let bookPath = try atlas.insertBooks([book]), moviePath = try atlas.insertMoviesAndTvs([movie])
        checkNotEqual(path, bookPath); checkNotEqual(bookPath, moviePath)
        checkThrows(try atlas.updateObjects([]))
        checkThrows(try atlas.updateObjects([Event()]))
        let updatePath = try atlas.updateObjects([fixture().events[2], written.tallies[0]])
        let update = try FullDirectory(serializedBytes: Data(contentsOf: URL(fileURLWithPath: updatePath)))
        checkEqual(update.events.count, 1); checkEqual(update.tallies.count, 1)
        checkTrue(update.events[0].meta.hasUpdatedAt)
        let notePath = try atlas.writeNote("Hello 🌞", date: "2026-04-20")
        let note = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: notePath))) as! [String: String]
        checkEqual(note["text"], "Hello 🌞"); checkEqual(note["source"], "user:oss"); checkEqual(note["date"], "2026-04-20")
        checkThrows(try atlas.writeNote("  "))
    }
    func testDatesOffsetsAndEnums() throws {
        checkThrows(try validateDate("2026-02-30"))
        checkThrows(try validateDate("2026-2-01"))
        checkEqual(try validateDate("2024-02-29"), "2024-02-29")
        var value = makeTimestamp(Date(timeIntervalSince1970: 1_000_000)); value.utcOffsetSeconds = -18000
        checkTrue(OffsetDate(value)!.iso8601.hasSuffix("-05:00"))
        checkEqual(enumName(EventType.placevisit), "PLACEVISIT")
        checkEqual(enumName(EventType.UNRECOGNIZED(99)), "99")
        checkEqual(resolveActivityCode("CYCLING"), "cyc")
        checkEqual(resolveActivityCode("unknown"), "unknown")
    }
}
