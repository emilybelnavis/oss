import SwiftProtobuf

extension TimeAtlas {
    public func updateObjects(_ objects: [any SwiftProtobuf.Message]) throws -> String {
        guard !objects.isEmpty else { throw AtlasError("No objects to update") }
        var directory = FullDirectory()
        for object in objects {
            switch object {
            case var value as Event:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.events.append(value)
            case var value as JournalEntry:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.journalEntries.append(value)
            case var value as KnownPlace:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.knownPlaces.append(value)
            case var value as Media:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.media.append(value)
            case var value as PatMessage:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.patMessages.append(value)
            case var value as Tally:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.tallies.append(value)
            case var value as AIProfile:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.aiProfiles.append(value)
            case var value as Embedding:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.embeddings.append(value)
            case var value as Pattern:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.patterns.append(value)
            case var value as ChatLearning:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.chatLearnings.append(value)
            case var value as Weather:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.weather.append(value)
            case var value as CalendarEvent:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.calendarEvents.append(value)
            case var value as SettingsValues:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.settingsValues.append(value)
            case var value as PrimaryDevice:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.primaryDevices.append(value)
            case var value as LastFmTrack:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.lastfmTracks.append(value)
            case var value as Book:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.books.append(value)
            case var value as MovieAndTv:
                guard value.hasMeta && !value.meta.id.isEmpty else { throw AtlasError("Object missing meta.ID") }
                value.meta.updatedAt = makeTimestamp()
                directory.moviesAndTv.append(value)
            default: throw AtlasError("Unsupported message type: \(type(of: object))")
            }
        }
        return try writeUpdateFile(directory)
    }
}
