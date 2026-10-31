import Foundation

extension TimeAtlas {
    public func buildGeoJSON(_ from: String, _ to: String, activityFilter: String? = nil) throws -> Data {
        let dates = try getDates(from, to)
        var features: [[String: Any]] = []
        let colors = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: Bundle.module.url(forResource: "activity_colors", withExtension: "json")!))
        if let start = dates.compactMap(\.start).first, let end = dates.compactMap(\.end).last {
            let activity = activityFilter.map(resolveActivityCode)
            if activity == nil {
                for event in try getEvents("placevisit", start.date, end.date) where event.placeVisit.hasLocation {
                    let place = event.placeVisit
                    let name = !place.name.isEmpty ? place.name : place.secondaryName
                    var properties: [String: Any] = ["type": "placevisit", "name": name.isEmpty ? NSNull() : name as Any]
                    if let start = OffsetDate(event.startAt) { properties["start"] = start.iso8601 }
                    if let end = OffsetDate(event.endAt) { properties["end"] = end.iso8601 }
                    if !event.meta.id.isEmpty { properties["event_id"] = event.meta.id }
                    features.append(["type": "Feature", "geometry": ["type": "Point", "coordinates": [place.location.lon, place.location.lat]], "properties": properties])
                }
            }
            for event in try getEvents("movement", start.date, end.date) {
                for move in event.movement.moveActivities where move.trajectory.count >= 2 && (activity == nil || move.activity == activity) {
                    var properties: [String: Any] = ["type": "movement", "activity": move.activity.isEmpty ? NSNull() : move.activity as Any]
                    properties["stroke"] = colors[move.activity] ?? colors["trp"]
                    if let start = OffsetDate(move.startAt) ?? OffsetDate(event.startAt) { properties["start"] = start.iso8601 }
                    if move.distanceMeters > 0 { properties["distance_meters"] = move.distanceMeters }
                    if move.durationSecs > 0 { properties["duration_secs"] = move.durationSecs }
                    if !event.meta.id.isEmpty { properties["event_id"] = event.meta.id }
                    features.append(["type": "Feature", "geometry": ["type": "LineString", "coordinates": move.trajectory.map { [$0.lon, $0.lat] }], "properties": properties])
                }
            }
        }
        return try JSONSerialization.data(withJSONObject: ["type": "FeatureCollection", "features": features], options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }
}
