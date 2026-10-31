import Foundation
import TimeAtlas

func notesWithPhotos(_ atlas: TimeAtlas, date: String?) async throws {
    let date = try validateDate(date ?? prompt("Date (YYYY-MM-DD): "))
    guard let day = try atlas.getDateDateRange(date), let start = day.start, let end = day.end else { print("No complete date event found for \(date)."); return }
    var events: [Event] = []
    if let event = try atlas.getDateEvent(date) { events.append(event) }
    events += try atlas.getEvents("placevisit", start.date, end.date)
    let library = PhotoLibrary(); var loaded = false; var photos: [String] = []
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("timeatlas-photos-\(UUID().uuidString)")
    for event in events {
        let entries = try atlas.getJournalEntriesForEvent(event.meta.id)
        if entries.isEmpty { continue }
        print("--- \(time(event.startAt))  \(label(event)) ---")
        for entry in entries {
            if !entry.text.isEmpty { print("\(entry.text)\n") }
            for media in try atlas.getMediaForJournalEntry(entry.meta.id) where media.hasFilename {
                if !loaded { stderr("Loading Apple Photos library..."); try await library.load(); loaded = true }
                if let url = try await library.exportPhotoForMedia(media, to: directory) {
                    photos.append(url.path); print("  [photo: \(media.filename)]")
                } else { print("  [photo not found in library: \(media.filename)]") }
            }
        }
    }
    if photos.isEmpty { print("\nNo photos to open.") }
    else { print("\nOpening \(photos.count) photo(s)..."); try runProcess("/usr/bin/open", photos) }
}
