import Foundation

extension TimeAtlas {
    /// Synchronizes files in filename order; a failed archive rolls back in full.
    public func sync(reset: Bool = false, progress: (String) -> Void = { print($0) }) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: paths.iCloud, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw AtlasError("iCloud directory not found: \(paths.iCloud)")
        }
        if reset {
            for suffix in ["", "-wal", "-shm"] where FileManager.default.fileExists(atPath: paths.database + suffix) {
                try FileManager.default.removeItem(atPath: paths.database + suffix)
            }
        }
        let db = try connect(readOnly: false)
        try createTables(db)
        let synced = Set(try db.query("SELECT filename FROM sync_state").compactMap { $0["filename"]?.string })
        let files = try FileManager.default.contentsOfDirectory(atPath: paths.iCloud).filter {
            !$0.hasPrefix("ip") && ($0.hasSuffix(".pb") || $0.hasSuffix(".zip")) && !synced.contains($0)
        }.sorted()
        progress(files.isEmpty ? "Already up to date." : "Syncing \(files.count) new file(s)...")
        for filename in files {
            progress("  Processing \(filename)...")
            let url = URL(fileURLWithPath: paths.iCloud).appendingPathComponent(filename)
            try db.transaction {
                try processFile(url, database: db)
                let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                let modified = (attrs[.modificationDate] as? Date ?? Date()).timeIntervalSince1970
                try db.execute("INSERT INTO sync_state (filename, synced_at) VALUES (?, ?)", [.text(filename), .real(modified)])
            }
        }
        if !files.isEmpty { progress("Sync complete.") }
        progress("\n--- Database summary ---")
        for table in tableDefinitions.map(\.name) + ["sync_state"] {
            let count = try db.query("SELECT COUNT(*) AS count FROM \(table)").first?["count"]?.number ?? 0
            if count > 0 { progress("  \(table): \(Int(count))") }
        }
    }

    public func processFile(_ url: URL, database db: Database) throws {
        if url.pathExtension == "zip" {
            // unzip streams each member to stdout; no archive paths are extracted.
            let listing = try runProcess("/usr/bin/unzip", ["-Z1", url.path])
            guard let names = String(data: listing, encoding: .utf8) else { throw AtlasError("Invalid ZIP directory: \(url.path)") }
            for name in names.split(separator: "\n").map(String.init).filter({ $0.hasSuffix(".pb") }).sorted() {
                let raw = try runProcess("/usr/bin/unzip", ["-p", url.path, escapeZipPattern(name)])
                try processFullDirectory(FullDirectory(serializedBytes: raw), database: db)
            }
        } else if url.pathExtension == "pb" {
            try processFullDirectory(FullDirectory(serializedBytes: Data(contentsOf: url)), database: db)
        }
    }
}

private func escapeZipPattern(_ name: String) -> String {
    name.reduce("") { $0 + ("[]*?\\".contains($1) ? "\\" : "") + String($1) }
}

/// Reads stdout while the child is running so large protobuf members cannot fill a pipe.
@discardableResult
public func runProcess(_ executable: String, _ arguments: [String]) throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    let output = Pipe()
    process.standardOutput = output
    // Inherit stderr, avoiding an unconsumed error pipe.
    try process.run()
    let result = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw AtlasError("\(executable) exited with status \(process.terminationStatus)") }
    return result
}
