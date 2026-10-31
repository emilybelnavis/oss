# Time Atlas tools

This project is implemented in Swift. The user's requested Python-to-Swift
migration supersedes the historical Python implementation described in earlier
versions of this document.

- Build with `swift build`; run `swift run timeatlas --help`.
- Validate with `swift run timeatlas-checks`. Checks use temporary fixtures.
- `Sources/TimeAtlas` contains the reusable library and generated protobuf models.
- `Sources/TimeAtlasCLI` contains the command-line tools, native weather plotting,
  and the Photos usage-description plist.
- `timeatlas.proto` is the source for generated models. Regenerate
  `Sources/TimeAtlas/timeatlas.pb.swift` with SwiftProtobuf 1.31.0 after edits.
- Preserve SQLite table/column names and protobuf field numbers for compatibility.
- Sync each input file transactionally, including all protobuf members of a ZIP.
- Exercise write operations against a temporary directory during development;
  real application data lives in the configured iCloud folder.
- Keep README command examples and migration notes current.
