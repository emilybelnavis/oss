import Foundation
import TimeAtlas

struct Arguments {
    var positional: [String] = []
    var options: [String: String] = [:]
    var flags: Set<String> = []
    init(_ args: [String], values: Set<String>, switches: Set<String>) throws {
        let aliases = ["-h": "--help", "-o": "--output", "-d": "--date", "-f": "--file", "-w": "--window", "-v": "--visualize", "-c": "--category"]
        var i = 0
        while i < args.count {
            let raw = args[i]
            if raw == "--" { positional += args.dropFirst(i + 1); break }
            let pair = raw.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            let key = aliases[pair[0]] ?? pair[0]
            if values.contains(key) {
                if pair.count == 2 { options[key] = pair[1] }
                else {
                    i += 1
                    guard i < args.count else { throw AtlasError("Missing value for \(key)") }
                    options[key] = args[i]
                }
            } else if switches.contains(key) || key == "--help" {
                guard pair.count == 1 else { throw AtlasError("\(key) does not take a value") }
                flags.insert(key)
            } else if raw.hasPrefix("-") && Double(raw) == nil { throw AtlasError("Unknown option: \(raw)") }
            else { positional.append(raw) }
            i += 1
        }
    }
    func count(_ range: ClosedRange<Int>, usage: String) throws {
        guard range.contains(positional.count) else { throw AtlasError("Usage: timeatlas \(usage)") }
    }
    func dates() throws -> (String, String) {
        try count(1...2, usage: "<command> FROM_DATE [TO_DATE]")
        let from = try validateDate(positional[0]), to = try validateDate(positional.count == 2 ? positional[1] : from)
        guard from <= to else { throw AtlasError("Start date must be on or before end date") }
        return (from, to)
    }
}
func stderr(_ text: String) { FileHandle.standardError.write(Data((text + "\n").utf8)) }
func prompt(_ text: String) throws -> String {
    print(text, terminator: ""); fflush(stdout)
    guard let answer = readLine() else { throw AtlasError("Input ended") }
    return answer.trimmingCharacters(in: .whitespacesAndNewlines)
}
func hm(_ seconds: Double) -> String { let minutes = Int(max(0, seconds)) / 60; return String(format: "%dh%02dm", minutes / 60, minutes % 60) }
func distance(_ meters: Double) -> String { meters >= 1000 ? String(format: "%.2f km", meters / 1000) : "\(Int(meters)) m" }
func time(_ stamp: TimestampWithOffset) -> String { OffsetDate(stamp)?.formatted() ?? "--:--" }
func label(_ event: Event) -> String {
    switch event.type.rawValue {
    case 1: return "Day note"
    case 2:
        let place = event.placeVisit
        let name = !place.name.isEmpty ? place.name : (!place.secondaryName.isEmpty ? place.secondaryName : "(unnamed)")
        let location = [place.cityOrCounty, place.region, place.countryCode].first { !$0.isEmpty }
        return "PLACEVISIT  \(name)" + (location.map { "  (\($0))" } ?? "")
    case 3: return "MOVEMENT    \(event.movement.name)"
    case 4: return "NO DATA     \(event.noDataPeriod.reason)"
    case 5:
        let w = event.workout
        var parts: [String] = []
        if w.distanceMeters > 0 { parts.append(distance(Double(w.distanceMeters))) }
        if w.kcal > 0 { parts.append("\(w.kcal) kcal") }
        return "WORKOUT     \(w.activityName.isEmpty ? "workout" : w.activityName)" + (parts.isEmpty ? "" : "  (\(parts.joined(separator: ", ")))")
    case 7: return "GROUP       \(event.eventGroup.name.isEmpty ? enumName(event.eventGroup.groupType) : event.eventGroup.name)"
    case 8: return "TRIP        \(event.trip.name.isEmpty ? "(unnamed)" : event.trip.name)"
    default: return enumName(event.type)
    }
}
func printNotes(_ atlas: TimeAtlas, _ id: String, indent: String = "    ") throws {
    for entry in try atlas.getJournalEntriesForEvent(id) where !entry.text.isEmpty {
        for (i, line) in entry.text.components(separatedBy: .newlines).enumerated() {
            print("\(indent)\(i == 0 ? "> " : "  ")\(line)")
        }
    }
}

@main
struct TimeAtlasCLI {
    static func main() async {
        do { try await run(Array(CommandLine.arguments.dropFirst())) }
        catch { stderr("Error: \(error)"); exit(1) }
    }
    static func run(_ raw: [String]) async throws {
        guard let first = raw.first, first != "--help", first != "-h" else { print(help); return }
        let command = first.replacingOccurrences(of: "_", with: "-").replacingOccurrences(of: ".py", with: "")
        let values: Set<String>
        let switches: Set<String>
        switch command {
        case "sync": values = []; switches = ["--reset"]
        case "date-query": values = []; switches = ["--show-notes", "--no-summary"]
        case "knownplaces": values = []; switches = ["--show-notes"]
        case "geojson": values = ["--output", "--activity"]; switches = []
        case "weather": values = ["--output"]; switches = ["--visualize"]
        case "insert-log": values = ["--who", "--date", "--category"]; switches = []
        case "addnote": values = ["--file", "--date"]; switches = ["--window"]
        case "activity-replace", "get-notes-with-photos": values = []; switches = []
        default: throw AtlasError("Unknown command: \(first)\n\(help)")
        }
        let args = try Arguments(Array(raw.dropFirst()), values: values.union(["--database", "--icloud-dir"]), switches: switches)
        if args.flags.contains("--help") { print(help); return }
        let atlas = TimeAtlas(paths: AtlasPaths(database: args.options["--database"], iCloud: args.options["--icloud-dir"]))
        switch command {
        case "sync":
            try args.count(0...0, usage: "sync [--reset]")
            print("Database: \(atlas.paths.database)")
            try atlas.sync(reset: args.flags.contains("--reset"))
        case "date-query": let (from, to) = try args.dates(); try dateQuery(atlas, from, to, notes: args.flags.contains("--show-notes"), summary: !args.flags.contains("--no-summary"))
        case "knownplaces": try args.count(1...1, usage: "knownplaces NAME [--show-notes]"); try knownPlaces(atlas, args.positional[0], notes: args.flags.contains("--show-notes"))
        case "geojson":
            let (from, to) = try args.dates()
            let data = try atlas.buildGeoJSON(from, to, activityFilter: args.options["--activity"])
            if let output = args.options["--output"] { try data.write(to: URL(fileURLWithPath: output)); stderr("Wrote GeoJSON to \(output)") }
            else { print(String(decoding: data, as: UTF8.self)) }
        case "insert-log": try insertLog(atlas, args)
        case "addnote": try addNote(atlas, args)
        case "activity-replace": try args.count(0...0, usage: "activity-replace"); try activityReplace(atlas)
        case "weather":
            let (from, to) = try args.dates()
            try weather(atlas, from, to, visualize: args.flags.contains("--visualize"), output: args.options["--output"])
        case "get-notes-with-photos": try args.count(0...1, usage: "get-notes-with-photos [DATE]"); try await notesWithPhotos(atlas, date: args.positional.first)
        default: break
        }
    }
    static let help = """
    Time Atlas tools — Swift
    Usage: timeatlas COMMAND [arguments] [options]

      sync [--reset]                              Sync iCloud protobuf/ZIP files
      date-query FROM [TO] [--show-notes] [--no-summary]
      knownplaces NAME [--show-notes]              List places and visits
      geojson FROM [TO] [--activity CODE] [-o FILE]
      weather FROM [TO] [-v] [-o FILE.png|FILE.pdf] Report or plot weather
      insert-log NAME VALUE UNIT [--who WHO] [-c CATEGORY] [-d DATE]
      addnote [-f FILE | -w] [-d DATE]             Write an iCloud note
      activity-replace                           Interactive activity replacement
      get-notes-with-photos [DATE]                Show notes and open photos

    Dates use YYYY-MM-DD. Underscore command names are also accepted.
    All commands accept --database PATH and --icloud-dir PATH.
    Environment: TIMEATLAS_DB, TIMEATLAS_ICLOUD_DIR.
    """
}
