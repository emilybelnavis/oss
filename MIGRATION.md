# Python to Swift migration

| Previous Python source | Swift implementation |
| --- | --- |
| `timeatlas_pb2.py` | `Sources/TimeAtlas/timeatlas.pb.swift` (generated from the unchanged schema) |
| `timeatlas.py` | `TimeAtlas.swift`, `Database.swift`, `Writes.swift`, `Updates.swift`, `EnumNames.swift` |
| `sync.py` | `Sync.swift`, `Schema.swift` |
| `photos.py` | `Photos.swift` (native Photos framework) |
| `tools/date_query.py` | `Sources/TimeAtlasCLI/Reports.swift` → `date-query` |
| `tools/knownplaces.py` | `Sources/TimeAtlasCLI/Reports.swift` → `knownplaces` |
| `tools/geojson.py` | `Sources/TimeAtlas/GeoJSON.swift` → `geojson` |
| `tools/weather.py` | `Sources/TimeAtlasCLI/Weather.swift` → `weather` |
| `tools/addnote.py` | `Sources/TimeAtlasCLI/InputCommands.swift` → `addnote` |
| `tools/insert_log.py` | `Sources/TimeAtlasCLI/InputCommands.swift` → `insert-log` |
| `tools/activity_replace.py` | `Sources/TimeAtlasCLI/InputCommands.swift` → `activity-replace` |
| `tools/get_notes_with_photos.py` | `Sources/TimeAtlasCLI/PhotoCommand.swift` → `get-notes-with-photos` |

Paths for library filenames above are relative to `Sources/TimeAtlas` unless
otherwise shown. `CLI.swift` supplies shared argument parsing and dispatch.

No Python runtime is required. Python dependency requirements have been replaced
by `Package.swift` and `Package.resolved`. The protobuf schema, activity colors,
and tally-validation reference data remain in the repository.

Compatibility verification used synthetic data covering every entity and event
type: all 35 SQLite table definitions, scalar columns, and relationship rows
matched the original Python sync. GeoJSON also matched after timestamp-format
normalization. The original Python protobuf implementation decoded Swift-written
tallies and movement updates, including preserved unknown protobuf fields.

Intentional differences:

- macOS 13+ is the supported platform, with native Photos and AppKit integration.
- One CLI replaces individual Python entry points. Underscore command aliases
  are accepted; use `timeatlas COMMAND` instead of `python tools/COMMAND.py`.
- Weather plots use native PNG/PDF output and the default viewer.
- Photo originals are exported to temporary files and opened with the default
  viewer. Library permission is required. Real Photos access and external viewer
  launches require manual verification in an interactive session.
- Non-finite tally values, malformed dates, reversed CLI ranges, and unknown
  options produce errors. Update filenames are protected against collisions and
  files are published only after serialization completes.
- Library inserts and updates use Swift value types and return the output path;
  callers' original message values are not mutated.

Run `swift run timeatlas-checks` for repeatable, isolated checks without XCTest.
