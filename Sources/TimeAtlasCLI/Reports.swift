import Foundation
import TimeAtlas

func dateQuery(_ atlas: TimeAtlas, _ from: String, _ to: String, notes: Bool, summary: Bool) throws {
    let days = try atlas.getDates(from, to)
    if days.isEmpty { print("No date events found between \(from) and \(to)."); return }
    for day in days {
        print("=== \(day.date)" + (day.start.map { "  (\($0.formatted()) - \(day.end?.formatted() ?? "--:--"), UTC offset \($0.offsetSeconds)s)" } ?? ""))
        guard let start = day.start, let end = day.end else { print("  (no start/end time for this date)\n"); continue }
        if notes, let event = try atlas.getDateEvent(day.date) { try printNotes(atlas, event.meta.id, indent: "  ") }
        var totals: [String: (meters: Double, seconds: Double, steps: UInt64)] = [:]
        var anyEvents = false
        for type in ["placevisit", "movement", "workout", "eventgroup", "trip", "nodataperiod"] {
            for event in try atlas.getEvents(type, start.date, end.date) {
                anyEvents = true
                var duration = ""
                if let s = OffsetDate(event.startAt), let e = OffsetDate(event.endAt), e.date >= s.date { duration = " [\(hm(e.date.timeIntervalSince(s.date)))]" }
                print("  \(time(event.startAt))-\(time(event.endAt))\(duration)  \(label(event))")
                if event.type.rawValue == 3 {
                    for move in event.movement.moveActivities where !move.activity.isEmpty {
                        var parts = [getActivityName(move.activity)]
                        if move.distanceMeters > 0 { parts.append(distance(Double(move.distanceMeters))) }
                        if move.steps > 0 { parts.append("\(move.steps) steps") }
                        if move.durationSecs > 0 { parts.append(hm(Double(move.durationSecs))) }
                        print("    - \(parts.joined(separator: "  "))")
                        let old = totals[move.activity] ?? (0, 0, 0)
                        totals[move.activity] = (old.meters + Double(move.distanceMeters), old.seconds + Double(move.durationSecs), old.steps + UInt64(move.steps))
                    }
                }
                if notes && event.type.rawValue == 2 { try printNotes(atlas, event.meta.id) }
            }
        }
        let books = try atlas.getBooks(day.date, day.date)
        if !books.isEmpty { print("  Books read:") }
        for book in books {
            var text = book.title.isEmpty ? "(untitled)" : book.title
            if !book.authors.isEmpty { text += "  by \(book.authors.joined(separator: ", "))" }
            text += stars(book.stars)
            if book.numberOfPages > 0 { text += "  (\(book.numberOfPages) pages)" }
            print("    - \(text)")
            if notes { printReview(book.myReview) }
        }
        let movies = try atlas.getMoviesAndTv(start.date, end.date)
        if !movies.isEmpty { print("  Watched:") }
        for movie in movies {
            var text = movie.title.isEmpty ? "(untitled)" : movie.title
            if movie.year != 0 { text += " (\(movie.year))" }
            var details: [String] = []
            if !movie.season.isEmpty { details.append("season \(movie.season)") }
            if !movie.episodeNumber.isEmpty { details.append("episode \(movie.episodeNumber)") }
            if details.isEmpty && !movie.type.isEmpty { details.append(movie.type) }
            if !details.isEmpty { text += "  [\(details.joined(separator: ", "))]" }
            print("    - \(text)\(stars(movie.stars))")
            if notes { printReview(movie.review) }
        }
        let tracks = try atlas.getLastFmTracks(start.date, end.date)
        if !tracks.isEmpty { print("  Music:") }
        for track in tracks {
            var stamp = TimestampWithOffset(); stamp.utcTimestamp = track.playedAt; stamp.utcOffsetSeconds = Int32(start.offsetSeconds)
            let name = track.artist.isEmpty ? (track.name.isEmpty ? "(untitled)" : track.name) : "\(track.artist) - \(track.name)"
            print("    \(time(stamp))  \(name)\(track.album.isEmpty ? "" : "  (\(track.album))")\(track.favorited ? "  <3" : "")")
        }
        let sleeps = try atlas.getEvents("sleep", start.date, end.date)
        let sleepSeconds = sleeps.reduce(0.0) { $0 + Double($1.sleep.asleepSecs) }
        if !anyEvents && sleeps.isEmpty { print("  (no events)") }
        if summary {
            var lines: [String] = []
            if !tracks.isEmpty { lines.append("Music: \(tracks.count) tracks") }
            if sleepSeconds > 0 { lines.append("Sleep total: \(hm(sleepSeconds))") }
            let codes = totals.keys.filter { let t = totals[$0]!; return t.meters > 0 || t.seconds > 0 || t.steps > 0 }.sorted()
            if !codes.isEmpty {
                lines.append("Total distance: \(distance(totals.values.reduce(0) { $0 + $1.meters }))")
                for code in codes {
                    let total = totals[code]!
                    var parts: [String] = []
                    if total.meters > 0 { parts.append(distance(total.meters)) }
                    if total.seconds > 0 { parts.append(hm(total.seconds)) }
                    if total.steps > 0 { parts.append("\(total.steps) steps") }
                    lines.append("  \(getActivityName(code)): \(parts.joined(separator: ", "))")
                }
            }
            if !lines.isEmpty { print("  --"); lines.forEach { print("  \($0)") } }
        }
        print()
    }
}
private func stars(_ value: Double) -> String { value == 0 ? "" : "  \(String(format: "%g", value))/5" }
private func printReview(_ value: String) { for line in value.components(separatedBy: .newlines) where !line.trimmingCharacters(in: .whitespaces).isEmpty { print("      > \(line)") } }

func knownPlaces(_ atlas: TimeAtlas, _ name: String, notes: Bool) throws {
    let places = try atlas.getKnownPlace(name: name)
    if places.isEmpty { print("No known places with name '\(name)'.") }
    let db = try atlas.connect()
    for place in places {
        print("=== \(place.name) (id: \(place.meta.id))")
        if !place.address.isEmpty { print("    Address: \(place.address)") }
        let location = [place.cityOrCounty, place.region, place.countryCode].filter { !$0.isEmpty }.joined(separator: " / ")
        if !location.isEmpty { print("    Location: \(location)") }
        if place.hasLocation { print(String(format: "    Coords: %.5f, %.5f", place.location.lat, place.location.lon)) }
        let visits = try db.messages(Event.self, "SELECT data FROM events_place_visits WHERE known_place_id = ? ORDER BY start_at", [.text(place.meta.id)])
        print("    \(visits.count) place visit(s):")
        for event in visits {
            let start = OffsetDate(event.startAt)?.formatted("yyyy-MM-dd HH:mm") ?? "---"
            let end = OffsetDate(event.endAt)?.formatted("yyyy-MM-dd HH:mm") ?? "---"
            print("      \(start)  →  \(end)")
            if notes { try printNotes(atlas, event.meta.id, indent: "        ") }
        }
        print()
    }
}
