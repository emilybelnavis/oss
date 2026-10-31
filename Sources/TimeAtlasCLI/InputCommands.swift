import Foundation
import TimeAtlas

func insertLog(_ atlas: TimeAtlas, _ args: Arguments) throws {
    try args.count(3...3, usage: "insert-log NAME VALUE UNIT [--who WHO] [-d DATE] [-c CATEGORY]")
    guard let value = Float(args.positional[1]), value.isFinite else { throw AtlasError("VALUE must be a finite number") }
    let date = try validateDate(args.options["--date"] ?? today())
    guard let event = try atlas.getDateEvent(date), !event.meta.id.isEmpty else { throw AtlasError("No date event with an ID found for \(date). Run 'timeatlas sync' first.") }
    var tally = Tally()
    tally.eventID = event.meta.id
    tally.name = args.positional[0]; tally.value = value; tally.unit = args.positional[2]
    tally.who = args.options["--who"] ?? "self"; tally.category = args.options["--category"] ?? ""
    tally.time = makeTimestamp()
    let path = try atlas.insertTallies([tally])
    print("Tally inserted: \(tally.name) = \(value) \(tally.unit) (who: \(tally.who))")
    print("  Date: \(date) (event \(event.meta.id))\n  Written to: \(path)")
}
func addNote(_ atlas: TimeAtlas, _ args: Arguments) throws {
    try args.count(0...0, usage: "addnote [-f FILE | -w] [-d DATE]")
    if args.options["--file"] != nil && args.flags.contains("--window") { throw AtlasError("Choose either --file or --window") }
    let date = try validateDate(args.options["--date"] ?? today())
    var text: String
    if let file = args.options["--file"] { text = try String(contentsOfFile: file, encoding: .utf8) }
    else if args.flags.contains("--window") {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("timeatlas-note-\(UUID().uuidString).txt")
        try Data().write(to: path)
        defer { try? FileManager.default.removeItem(at: path) }
        // Match the original: EDITOR is an executable path, not a shell command.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [ProcessInfo.processInfo.environment["EDITOR"] ?? "vi", path.path]
        try process.run(); process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw AtlasError("Editor exited with status \(process.terminationStatus)") }
        text = try String(contentsOf: path, encoding: .utf8)
    } else {
        stderr("Enter your note. Finish with two empty lines (or Ctrl-D).")
        var lines: [String] = []; var blanks = 0
        while let line = readLine() {
            blanks = line.isEmpty ? blanks + 1 : 0
            if blanks == 2 { break }
            lines.append(line)
        }
        text = lines.joined(separator: "\n")
    }
    while text.last == "\n" { text.removeLast() }
    stderr("Wrote note to \(try atlas.writeNote(text, date: date))")
}

func activityReplace(_ atlas: TimeAtlas) throws {
    print("Enter date range (YYYY-MM-DD).")
    let from = try validateDate(prompt("From date: "))
    let endInput = try prompt("  To date: ")
    let to = try validateDate(endInput.isEmpty ? from : endInput)
    guard from <= to else { throw AtlasError("Start date must be on or before end date") }
    let days = try atlas.getDates(from, to)
    guard let start = days.first?.start, let end = days.last?.end else { throw AtlasError("No complete date range found. Run 'timeatlas sync' first.") }
    let source = try pickActivity("Change FROM activity:")
    let target = try pickActivity("Change TO activity:")
    guard source != target else { print("Source and target are the same. Nothing to do."); return }
    var changed: [Event] = []; var count = 0; var meters = 0.0
    for var event in try atlas.getEvents("movement", start.date, end.date) {
        var didChange = false
        for index in event.movement.moveActivities.indices where event.movement.moveActivities[index].activity == source {
            event.movement.moveActivities[index].activity = target
            count += 1; meters += Double(event.movement.moveActivities[index].distanceMeters); didChange = true
        }
        if didChange { changed.append(event) }
    }
    guard !changed.isEmpty else { print("No '\(source)' activities found in the date range."); return }
    print("Replacing '\(source)' (\(getActivityName(source))) → '\(target)' (\(getActivityName(target)))")
    print("Date range: \(from) .. \(to)")
    print("Found \(count) activities to change across \(changed.count) movement event(s).")
    print(String(format: "Total distance affected: %.1f km", meters / 1000))
    let answer = try prompt("Proceed? [y/N] ").lowercased()
    guard ["y", "yes"].contains(answer) else { print("Aborted."); return }
    print("Update written to: \(try atlas.updateObjects(changed))")
    print("Run 'timeatlas sync' to apply the changes to the local database.")
}
private func pickActivity(_ message: String) throws -> String {
    let codes = activityNames.keys.sorted()
    print(message)
    for (index, code) in codes.enumerated() { print(String(format: "  %2d. %@ (%@)", index + 1, code, getActivityName(code))) }
    while true {
        if let number = Int(try prompt("Enter number: ")), (1...codes.count).contains(number) { return codes[number - 1] }
        print("Invalid choice, try again.")
    }
}
