import Foundation
import AppKit
import TimeAtlas

private struct Observation { let timestamp: Double; let temperature: Double }
func weather(_ atlas: TimeAtlas, _ from: String, _ to: String, visualize: Bool, output: String?) throws {
    let dates = try atlas.getDates(from, to)
    if dates.isEmpty { print("No date entries between \(from) and \(to)."); return }
    let db = try atlas.connect()
    var allConditions: [String: Int] = [:]; var observations: [Observation] = []
    for day in dates {
        guard let start = day.start, let end = day.end else { print("\(day.date)  (no date range)"); continue }
        let rows = try db.query("SELECT observed_at, temperature_celsius, condition_description FROM weather WHERE observed_at >= ? AND observed_at <= ? ORDER BY observed_at", [.real(start.date.timeIntervalSince1970), .real(end.date.timeIntervalSince1970)])
        if rows.isEmpty { print("\(day.date)  (no weather)"); continue }
        var counts: [String: Int] = [:]; var temps: [Double] = []
        for row in rows {
            if let temp = row["temperature_celsius"]?.number, temp.isFinite {
                temps.append(temp)
                if let stamp = row["observed_at"]?.number { observations.append(Observation(timestamp: stamp, temperature: temp)) }
            }
            if let condition = row["condition_description"]?.string, !condition.isEmpty {
                counts[condition, default: 0] += 1; allConditions[condition, default: 0] += 1
            }
        }
        let range = temps.min().map { String(format: "%5.1f°C – %5.1f°C", $0, temps.max()!) } ?? "temperature n/a"
        let conditions = ranked(counts).prefix(3).map { "\($0.key) (\($0.value))" }.joined(separator: ", ")
        print("\(day.date)  \(range)  \(conditions)")
    }
    print("\nConditions histogram:")
    let maximum = allConditions.values.max() ?? 0
    let width = allConditions.keys.map(\.count).max() ?? 0
    if maximum == 0 { print("  (no conditions recorded)") }
    for (condition, count) in ranked(allConditions) {
        let bar = String(repeating: "#", count: max(1, Int((Double(count) / Double(maximum) * 40).rounded())))
        print("  \(condition.padding(toLength: width, withPad: " ", startingAt: 0))  \(bar) \(count)")
    }
    if visualize {
        guard !observations.isEmpty else { stderr("No weather data to plot."); return }
        let destination = output ?? FileManager.default.temporaryDirectory.appendingPathComponent("timeatlas-weather-\(UUID().uuidString).png").path
        try plotWeather(observations.sorted { $0.timestamp < $1.timestamp }, destination, offset: dates.compactMap(\.start).first?.offsetSeconds ?? 0)
        if output == nil { try runProcess("/usr/bin/open", [destination]) }
        else { stderr("Saved plot to \(destination)") }
    }
}
private func ranked(_ counts: [String: Int]) -> [(key: String, value: Int)] {
    counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
}
private func plotWeather(_ rows: [Observation], _ output: String, offset: Int) throws {
    let ext = URL(fileURLWithPath: output).pathExtension.lowercased()
    guard ["png", "pdf"].contains(ext) else { throw AtlasError("Weather plots support .png and .pdf output") }
    let width = 1200, height = 500
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0), let context = NSGraphicsContext(bitmapImageRep: bitmap) else { throw AtlasError("Cannot create weather chart") }
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }
    func text(_ string: String, _ x: Double, _ y: Double, size: Double = 13) {
        (string as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: [.font: NSFont.systemFont(ofSize: size), .foregroundColor: NSColor.black])
    }
    NSColor.white.setFill(); NSRect(x: 0, y: 0, width: width, height: height).fill()
    text("Time Atlas — temperature over time", 80, 455, size: 22)
    let left = 85.0, bottom = 85.0, chartWidth = 1070.0, chartHeight = 335.0
    let first = rows.first!.timestamp, last = rows.last!.timestamp
    let start = first == last ? first - 1800 : first
    let end = first == last ? last + 1800 : last
    let minimum = rows.map(\.temperature).min()! - 1, maximum = rows.map(\.temperature).max()! + 1
    for i in 0...5 {
        let ratio = Double(i) / 5, y = bottom + ratio * chartHeight
        NSColor(white: 0.87, alpha: 1).setStroke()
        let line = NSBezierPath(); line.move(to: NSPoint(x: left, y: y)); line.line(to: NSPoint(x: left + chartWidth, y: y)); line.stroke()
        text(String(format: "%.1f°C", minimum + ratio * (maximum - minimum)), 15, y - 7)
        let date = Date(timeIntervalSince1970: start + ratio * (end - start))
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.timeZone = TimeZone(secondsFromGMT: offset); formatter.dateFormat = "MM-dd HH:mm"
        text(formatter.string(from: date), left + ratio * chartWidth - 35, 60)
    }
    let path = NSBezierPath(); path.lineWidth = 2
    NSColor.systemBlue.setStroke(); NSColor.systemBlue.setFill()
    for (index, row) in rows.enumerated() {
        let point = NSPoint(x: left + (row.timestamp - start) / (end - start) * chartWidth, y: bottom + (row.temperature - minimum) / (maximum - minimum) * chartHeight)
        if index == 0 { path.move(to: point) } else { path.line(to: point) }
        NSBezierPath(ovalIn: NSRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)).fill()
    }
    path.stroke(); text("Time (UTC offset \(offset)s)", 500, 25)
    context.flushGraphics()
    let data: Data
    if ext == "png" {
        guard let png = bitmap.representation(using: .png, properties: [:]) else { throw AtlasError("Cannot encode PNG chart") }
        data = png
    } else {
        let view = NSImageView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        let image = NSImage(size: view.frame.size); image.addRepresentation(bitmap); view.image = image
        data = view.dataWithPDF(inside: view.bounds)
    }
    try data.write(to: URL(fileURLWithPath: output))
}
