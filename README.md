# Time Atlas tools (Swift)

Native macOS tools for reading Time Atlas iCloud data, syncing it into SQLite,
querying your timeline, and writing notes, tallies, and updates back to the app.
All runtime code is Swift. Requires macOS 13+ and Swift 5.10+ (Xcode or Apple's
Command Line Tools). SQLite, Photos, and AppKit come with macOS.

## Build and run

```sh
swift build -c release
swift run timeatlas-checks
swift run timeatlas sync
```

Swift Package Manager downloads the pinned Apple SwiftProtobuf dependency on the
first build. The generated protobuf models are checked in; protoc is only needed
when changing the schema.

The default database is `timeatlas.db` in the source checkout. The default iCloud
folder is `~/Library/Mobile Documents/iCloud~com~timeatlaslabs~Pat/Documents`.
The existing Python-created SQLite database and iCloud protobuf files are
compatible, so no data migration is required. Sync imports `.pb` files and `.pb`
members of ZIP archives in filename order, skipping `ip`-prefixed files and files
already recorded in `sync_state`. ZIP members stream into memory without being
extracted to disk. Each complete input file is committed in a single transaction.

Override paths with `--database PATH` and `--icloud-dir PATH` after the command,
or with `TIMEATLAS_DB` and `TIMEATLAS_ICLOUD_DIR`. For a binary copied outside this
checkout, set `TIMEATLAS_DB` explicitly. Keep the generated
`TimeAtlasTools_TimeAtlas.bundle` alongside the binary for activity colors.

```sh
swift run timeatlas sync --database /tmp/example.db --icloud-dir /path/to/export
# Removes the selected database and rebuilds it from the selected sync folder:
swift run timeatlas sync --reset
```

Run sync before using the query tools. Writes create files for the Time Atlas app
to ingest; run sync again to import protobuf updates into the local database.
Note JSON is consumed by the Time Atlas app, not by this SQLite sync tool.

## Commands

```sh
# Events, distances, steps, sleep totals, books, watched media, Last.fm tracks.
swift run timeatlas date-query 2026-04-20
swift run timeatlas date-query 2026-04-01 2026-04-07 --show-notes
swift run timeatlas date-query 2026-04-20 --no-summary

# Exact known-place name, addresses, and visits.
swift run timeatlas knownplaces "Starbucks"
swift run timeatlas knownplaces "Gym" --show-notes

# Points for visits and colored LineStrings for movement trajectories.
swift run timeatlas geojson 2026-04-20
swift run timeatlas geojson 2026-04-01 2026-04-07 -o april.geojson
swift run timeatlas geojson 2026-04-01 2026-04-07 --activity cycling -o rides.geojson
swift run timeatlas geojson 2026-04-20 --activity wlk

# Note entry: two empty lines or EOF ends interactive input.
swift run timeatlas addnote
swift run timeatlas addnote -f note.txt -d 2026-04-15
EDITOR=vi swift run timeatlas addnote -w

# Tallies require a synced date event. Name and unit must be lowercase.
swift run timeatlas insert-log water 200 ml
swift run timeatlas insert-log wine 2 glass --category white
swift run timeatlas insert-log weight 4.3 kg --who baby --date 2026-04-20

# Prompts for date range, source/target activities, and confirmation.
swift run timeatlas activity-replace

# Weather ranges and condition histogram; native PNG/PDF plotting.
swift run timeatlas weather 2026-04-01 2026-04-07
swift run timeatlas weather 2026-04-01 2026-04-07 -v
swift run timeatlas weather 2026-04-01 2026-04-07 -v -o april-weather.png
swift run timeatlas weather 2026-04-01 2026-04-07 -v -o april-weather.pdf

# Notes plus matched Apple Photos assets.
swift run timeatlas get-notes-with-photos 2026-04-20
```

Underscore command names such as `date_query` and `insert_log` are accepted as
aliases. `timeatlas --help` lists every command and its options.

Weather plotting uses AppKit instead of matplotlib. With `-v` and no `-o`, a
temporary PNG opens in the default viewer. Output supports PNG and PDF.

Photo lookup uses Apple's Photos framework instead of osxphotos. The first photo
lookup requests permission; the CLI embeds a Photos usage description. Assets
match by original filename, with modified time (within two seconds) resolving
ambiguities. Matched originals are exported to a temporary folder and opened in
the default viewer. iCloud-only originals may download. Photo access and launching
viewers require an interactive macOS session. Other commands do not request Photos
access. This Swift port targets macOS; the original Windows support is not retained.

## Library

`Sources/TimeAtlas` is a reusable library with public generated protobuf models.
`TimeAtlas` exposes the original helper operations as throwing Swift methods:
`getDates`, `getDateDateRange`, `getDateEvent`, `getEvents`, `getKnownPlace(id:)`,
`getKnownPlace(name:)`, `getJournalEntriesForEvent`, `getMediaForJournalEntry`,
`getBooks`, `getMoviesAndTv`, `getLastFmTracks`, `insertTallies`, `insertBooks`,
`insertMoviesAndTvs`, and `updateObjects` (including mixed message types).
`AtlasPaths` selects paths. `OffsetDate` retains both an absolute `Date` and its
stored UTC offset. Insert/update methods return the path of the written file.
Connections are intended for serial use. Validation errors are thrown before
writing files. Existing IDs and unknown protobuf fields survive updates.

```swift
import TimeAtlas

let atlas = TimeAtlas()
let days = try atlas.getDates("2026-04-01", "2026-04-07")
if let start = days.first?.start, let end = days.last?.end {
    let movements = try atlas.getEvents("movement", start.date, end.date)
    print(movements.count)
}
```

## Changing protobuf models

Install Google's `protoc` and Apple's `protoc-gen-swift` version 1.31.0, then run:

```sh
protoc -I . --swift_out=Sources/TimeAtlas --swift_opt=Visibility=Public timeatlas.proto
```

The generator and runtime must use matching SwiftProtobuf versions. Follow the
[official SwiftProtobuf generator instructions](https://github.com/apple/swift-protobuf/blob/1.31.0/Documentation/PLUGIN.md).
When changing fields, also update `Schema.swift` mappings and `EnumNames.swift`.

## Tests

The checks executable needs no XCTest installation and uses temporary databases and sync folders. Coverage includes protobuf
round trips, SQLite queries, offsets, relationships, deletion and event type
changes, ZIP import and rollback/retry, GeoJSON, validation, inserts, updates, and
note JSON. Tests do not read personal iCloud data or request photo access.

Time Atlas stores sync data in iCloud. Join the community on
[Discord](https://discord.gg/zwJEYNdsPE).
