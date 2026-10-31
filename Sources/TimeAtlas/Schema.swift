// SQLite mappings ported from sync.py. Keep column names compatible with existing databases.
import Foundation
import SwiftProtobuf

struct TableDefinition {
    let name: String
    let columns: [(String, String)]
    let indexes: [String]
    let links: [(String, String, String)]
}
let tableDefinitions: [TableDefinition] = [
    TableDefinition(name: "journal_entries", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("event_id", "TEXT"), ("source", "TEXT"), ("text", "TEXT"), ("reply_id", "TEXT"), ("is_dictated", "INTEGER"), ("is_ai_rewritten", "INTEGER")], indexes: [], links: [("journal_entry_media_ids", "journal_entry_id", "media_id"), ("journal_entry_tags", "journal_entry_id", "tag"), ("journal_entry_people", "journal_entry_id", "person"), ("journal_entry_activities", "journal_entry_id", "activity")]),
    TableDefinition(name: "known_places", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("name", "TEXT"), ("city_or_county", "TEXT"), ("country_code", "TEXT"), ("address", "TEXT"), ("region", "TEXT"), ("external_id", "TEXT")], indexes: [], links: [("known_place_categories", "known_place_id", "category"), ("known_place_wifi_ids", "known_place_id", "wifi_id")]),
    TableDefinition(name: "media", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("created_timestamp", "REAL"), ("modified_timestamp", "REAL"), ("format", "TEXT"), ("path", "TEXT"), ("public_url", "TEXT"), ("apple_cloud_identifier", "TEXT"), ("filename", "TEXT"), ("imported", "INTEGER"), ("ai_summary", "TEXT"), ("app_asset_name", "TEXT"), ("legacy_path", "TEXT")], indexes: [], links: []),
    TableDefinition(name: "pat_messages", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("recipient", "TEXT"), ("content_plain", "TEXT"), ("transport", "TEXT"), ("in_reply_to", "TEXT"), ("subject", "TEXT"), ("external_id", "TEXT")], indexes: [], links: []),
    TableDefinition(name: "tallies", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("time", "REAL"), ("event_id", "TEXT"), ("journal_entry_id", "TEXT"), ("source", "TEXT"), ("name", "TEXT"), ("unit", "TEXT"), ("value", "REAL"), ("who", "TEXT"), ("category", "TEXT"), ("emoji", "TEXT")], indexes: [], links: []),
    TableDefinition(name: "ai_profiles", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("purpose", "TEXT"), ("version", "INTEGER"), ("prompt", "TEXT"), ("computed_input", "TEXT"), ("model", "TEXT"), ("profile_text", "TEXT")], indexes: [], links: []),
    TableDefinition(name: "embeddings", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("version", "TEXT"), ("model", "TEXT"), ("embedding_type", "TEXT"), ("source_id", "TEXT")], indexes: [], links: []),
    TableDefinition(name: "patterns", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("pattern_type", "TEXT")], indexes: [], links: []),
    TableDefinition(name: "chat_learnings", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("learning", "TEXT")], indexes: [], links: []),
    TableDefinition(name: "weather", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("observed_at", "REAL"), ("condition_description", "TEXT"), ("symbol_name", "TEXT"), ("temperature_celsius", "REAL"), ("apparent_temperature_celsius", "REAL"), ("humidity", "REAL"), ("pressure_millibars", "REAL"), ("dew_point_celsius", "REAL"), ("cloud_cover", "REAL"), ("visibility_meters", "REAL"), ("wind_speed_meters_per_sec", "REAL"), ("wind_direction_degrees", "REAL"), ("uv_index", "INTEGER"), ("is_daylight", "INTEGER")], indexes: [], links: []),
    TableDefinition(name: "calendar_events", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("created_at", "REAL"), ("last_modified_at", "REAL"), ("uid", "TEXT"), ("summary", "TEXT"), ("is_all_day", "INTEGER"), ("location", "TEXT"), ("description", "TEXT"), ("timezone", "TEXT")], indexes: [], links: []),
    TableDefinition(name: "settings_values", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("asked_for_review", "REAL"), ("daily_email", "INTEGER"), ("disable_ai", "INTEGER"), ("timeline_most_recent_first", "INTEGER"), ("disable_scooting_detection", "INTEGER"), ("hide_timeline_details", "INTEGER"), ("store_image_previews", "INTEGER"), ("enable_daily_notification", "INTEGER"), ("disable_pat_responses", "INTEGER"), ("disable_population_comparisons", "INTEGER"), ("disable_automatic_log_inference", "INTEGER"), ("use_tiles_for_trp", "INTEGER"), ("show_photos_on_timeline", "INTEGER"), ("show_media_metadata_overlay", "INTEGER"), ("submit_to_apple_health", "INTEGER"), ("deduplicate_week_photos", "INTEGER"), ("default_transport_method", "TEXT"), ("day_end_offset_secs", "INTEGER"), ("disable_automatic_photo_days", "INTEGER"), ("disable_automatic_photo_events", "INTEGER"), ("grandfathered_subscription", "TEXT"), ("disable_cycling_detection", "INTEGER")], indexes: [], links: []),
    TableDefinition(name: "lastfm_tracks", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("played_at", "REAL"), ("name", "TEXT"), ("artist", "TEXT"), ("album", "TEXT"), ("artist_mbid", "TEXT"), ("url", "TEXT"), ("now_playing", "INTEGER"), ("favorited", "INTEGER")], indexes: ["played_at"], links: []),
    TableDefinition(name: "books", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("title", "TEXT"), ("isbn", "TEXT"), ("isbn13", "TEXT"), ("number_of_pages", "INTEGER"), ("publication_year", "INTEGER"), ("original_publication_year", "INTEGER"), ("read_date", "TEXT"), ("my_review", "TEXT"), ("stars", "REAL"), ("source", "TEXT")], indexes: ["read_date"], links: [("book_authors", "book_id", "author")]),
    TableDefinition(name: "movies_and_tv", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("watched_at", "REAL"), ("title", "TEXT"), ("year", "INTEGER"), ("episode_number", "TEXT"), ("season", "TEXT"), ("imdb_id", "TEXT"), ("tmdb_id", "TEXT"), ("media_type", "TEXT"), ("review", "TEXT"), ("stars", "REAL"), ("url", "TEXT"), ("source", "TEXT")], indexes: ["watched_at"], links: []),
    TableDefinition(name: "primary_devices", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("app_id", "TEXT"), ("user_action", "INTEGER")], indexes: [], links: []),
    TableDefinition(name: "events_unspecified", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
    TableDefinition(name: "events_dates", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT"), ("date", "TEXT"), ("favorite", "INTEGER"), ("hide_summary", "INTEGER")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
    TableDefinition(name: "events_place_visits", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT"), ("name", "TEXT"), ("secondary_name", "TEXT"), ("requires_reverse_geo", "INTEGER"), ("city_or_county", "TEXT"), ("country_code", "TEXT"), ("region", "TEXT"), ("known_place_id", "TEXT"), ("is_user_labeled", "INTEGER"), ("is_user_corrected", "INTEGER")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
    TableDefinition(name: "events_movements", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT"), ("name", "TEXT"), ("synthetic", "INTEGER")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
    TableDefinition(name: "events_no_data_periods", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT"), ("reason", "TEXT")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
    TableDefinition(name: "events_workouts", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT"), ("healthkit_activity_type", "INTEGER"), ("activity_name", "TEXT"), ("duration_secs", "INTEGER"), ("workout_source", "TEXT"), ("moloc_activity", "TEXT"), ("steps", "INTEGER"), ("distance_meters", "INTEGER"), ("indoors", "INTEGER"), ("kcal", "INTEGER"), ("healthkit_identifier", "TEXT"), ("device_name", "TEXT"), ("device_manufacturer", "TEXT"), ("device_model", "TEXT")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
    TableDefinition(name: "events_sleeps", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT"), ("asleep_secs", "INTEGER"), ("sleep_type", "TEXT"), ("device_name", "TEXT"), ("device_manufacturer", "TEXT"), ("device_model", "TEXT")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
    TableDefinition(name: "events_event_groups", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT"), ("name", "TEXT"), ("user_set_name", "INTEGER"), ("group_type", "TEXT")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
    TableDefinition(name: "events_trips", columns: [("id", "TEXT PRIMARY KEY"), ("data", "BLOB NOT NULL"), ("meta_created_at", "REAL"), ("meta_updated_at", "REAL"), ("start_at", "REAL"), ("end_at", "REAL"), ("event_type", "TEXT"), ("source", "TEXT"), ("app_id", "TEXT"), ("diagnostics_json", "TEXT"), ("name", "TEXT")], indexes: ["start_at", "end_at"], links: [("event_media_ids", "event_id", "media_id"), ("event_hidden_from_feed_dates", "event_id", "date")]),
]

extension TimeAtlas {
    public func createTables(_ db: Database) throws {
        for table in tableDefinitions {
            let columns = table.columns.map { "\($0.0) \($0.1)" }.joined(separator: ", ")
            try db.execute("CREATE TABLE IF NOT EXISTS \(table.name) (\(columns))")
            for column in table.indexes {
                try db.execute("CREATE INDEX IF NOT EXISTS idx_\(table.name)_\(column) ON \(table.name) (\(column))")
            }
            for (name, parent, value) in table.links {
                try db.execute("CREATE TABLE IF NOT EXISTS \(name) (\(parent) TEXT NOT NULL, \(value) TEXT NOT NULL)")
                try db.execute("CREATE INDEX IF NOT EXISTS idx_\(name)_\(parent) ON \(name) (\(parent))")
            }
        }
        try db.execute("CREATE TABLE IF NOT EXISTS sync_state (filename TEXT PRIMARY KEY, synced_at REAL NOT NULL)")
    }

    public func processFullDirectory(_ directory: FullDirectory, database db: Database) throws {
        for event in directory.events { try processEvent(event, db) }
        for message in directory.journalEntries {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("journal_entries", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.eventID),
                scalar(message.source),
                scalar(message.text),
                scalar(message.replyID),
                scalar(message.isDictated),
                scalar(message.isAiRewritten),
            ]
            try upsert("journal_entries", ["id", "data", "meta_created_at", "meta_updated_at", "event_id", "source", "text", "reply_id", "is_dictated", "is_ai_rewritten"], values, db)
            try replaceLinks("journal_entry_media_ids", "journal_entry_id", "media_id", id, message.mediaIds, db)
            try replaceLinks("journal_entry_tags", "journal_entry_id", "tag", id, message.tags, db)
            try replaceLinks("journal_entry_people", "journal_entry_id", "person", id, message.people, db)
            try replaceLinks("journal_entry_activities", "journal_entry_id", "activity", id, message.activities, db)
        }
        for message in directory.knownPlaces {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("known_places", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.name),
                message.hasCityOrCounty ? scalar(message.cityOrCounty) : .null,
                message.hasCountryCode ? scalar(message.countryCode) : .null,
                message.hasAddress ? scalar(message.address) : .null,
                message.hasRegion ? scalar(message.region) : .null,
                message.hasExternalID ? scalar(message.externalID) : .null,
            ]
            try upsert("known_places", ["id", "data", "meta_created_at", "meta_updated_at", "name", "city_or_county", "country_code", "address", "region", "external_id"], values, db)
            try replaceLinks("known_place_categories", "known_place_id", "category", id, message.categories, db)
            try replaceLinks("known_place_wifi_ids", "known_place_id", "wifi_id", id, message.wifiIds, db)
        }
        for message in directory.media {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("media", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                timeValue(message.createdTimestamp),
                timeValue(message.modifiedTimestamp),
                scalar(message.format),
                message.hasPath ? scalar(message.path) : .null,
                message.hasPublicURL ? scalar(message.publicURL) : .null,
                message.hasAppleCloudIdentifier ? scalar(message.appleCloudIdentifier) : .null,
                message.hasFilename ? scalar(message.filename) : .null,
                scalar(message.imported),
                message.hasAiSummary ? scalar(message.aiSummary) : .null,
                message.hasAppAssetName ? scalar(message.appAssetName) : .null,
                message.hasLegacyPath ? scalar(message.legacyPath) : .null,
            ]
            try upsert("media", ["id", "data", "meta_created_at", "meta_updated_at", "created_timestamp", "modified_timestamp", "format", "path", "public_url", "apple_cloud_identifier", "filename", "imported", "ai_summary", "app_asset_name", "legacy_path"], values, db)
        }
        for message in directory.patMessages {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("pat_messages", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.recipient),
                scalar(message.contentPlain),
                scalar(message.transport),
                scalar(message.inReplyTo),
                scalar(message.subject),
                message.hasExternalID ? scalar(message.externalID) : .null,
            ]
            try upsert("pat_messages", ["id", "data", "meta_created_at", "meta_updated_at", "recipient", "content_plain", "transport", "in_reply_to", "subject", "external_id"], values, db)
        }
        for message in directory.tallies {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("tallies", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                timeValue(message.time),
                scalar(message.eventID),
                scalar(message.journalEntryID),
                scalar(message.source),
                scalar(message.name),
                scalar(message.unit),
                scalar(message.value),
                scalar(message.who),
                scalar(message.category),
                scalar(message.emoji),
            ]
            try upsert("tallies", ["id", "data", "meta_created_at", "meta_updated_at", "time", "event_id", "journal_entry_id", "source", "name", "unit", "value", "who", "category", "emoji"], values, db)
        }
        for message in directory.aiProfiles {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("ai_profiles", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.purpose),
                scalar(message.version),
                scalar(message.prompt),
                scalar(message.computedInput),
                scalar(message.model),
                scalar(message.profileText),
            ]
            try upsert("ai_profiles", ["id", "data", "meta_created_at", "meta_updated_at", "purpose", "version", "prompt", "computed_input", "model", "profile_text"], values, db)
        }
        for message in directory.embeddings {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("embeddings", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.version),
                scalar(message.model),
                scalar(message.type),
                scalar(message.sourceID),
            ]
            try upsert("embeddings", ["id", "data", "meta_created_at", "meta_updated_at", "version", "model", "embedding_type", "source_id"], values, db)
        }
        for message in directory.patterns {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("patterns", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.type),
            ]
            try upsert("patterns", ["id", "data", "meta_created_at", "meta_updated_at", "pattern_type"], values, db)
        }
        for message in directory.chatLearnings {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("chat_learnings", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.learning),
            ]
            try upsert("chat_learnings", ["id", "data", "meta_created_at", "meta_updated_at", "learning"], values, db)
        }
        for message in directory.weather {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("weather", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                timeValue(message.observedAt),
                scalar(message.conditionDescription),
                scalar(message.symbolName),
                scalar(message.temperatureCelsius),
                scalar(message.apparentTemperatureCelsius),
                scalar(message.humidity),
                scalar(message.pressureMillibars),
                scalar(message.dewPointCelsius),
                scalar(message.cloudCover),
                scalar(message.visibilityMeters),
                scalar(message.windSpeedMetersPerSec),
                scalar(message.windDirectionDegrees),
                scalar(message.uvIndex),
                scalar(message.isDaylight),
            ]
            try upsert("weather", ["id", "data", "meta_created_at", "meta_updated_at", "observed_at", "condition_description", "symbol_name", "temperature_celsius", "apparent_temperature_celsius", "humidity", "pressure_millibars", "dew_point_celsius", "cloud_cover", "visibility_meters", "wind_speed_meters_per_sec", "wind_direction_degrees", "uv_index", "is_daylight"], values, db)
        }
        for message in directory.calendarEvents {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("calendar_events", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                timeValue(message.startAt),
                timeValue(message.endAt),
                timeValue(message.createdAt),
                timeValue(message.lastModifiedAt),
                scalar(message.uid),
                scalar(message.summary),
                scalar(message.isAllDay),
                message.hasLocation ? scalar(message.location) : .null,
                message.hasDescription_p ? scalar(message.description_p) : .null,
                message.hasTimezone ? scalar(message.timezone) : .null,
            ]
            try upsert("calendar_events", ["id", "data", "meta_created_at", "meta_updated_at", "start_at", "end_at", "created_at", "last_modified_at", "uid", "summary", "is_all_day", "location", "description", "timezone"], values, db)
        }
        for message in directory.settingsValues {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("settings_values", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                timeValue(message.askedForReview),
                scalar(message.dailyEmail),
                scalar(message.disableAi),
                scalar(message.timelineMostRecentFirst),
                scalar(message.disableScootingDetection),
                scalar(message.hideTimelineDetails),
                scalar(message.storeImagePreviews),
                scalar(message.enableDailyNotification),
                scalar(message.disablePatResponses),
                scalar(message.disablePopulationComparisons),
                scalar(message.disableAutomaticLogInference),
                scalar(message.useTilesForTrp),
                scalar(message.showPhotosOnTimeline),
                scalar(message.showMediaMetadataOverlay),
                scalar(message.submitToAppleHealth),
                scalar(message.deduplicateWeekPhotos),
                scalar(message.defaultTransportMethod),
                scalar(message.dayEndOffsetSecs),
                scalar(message.disableAutomaticPhotoDays),
                scalar(message.disableAutomaticPhotoEvents),
                scalar(message.grandfatheredSubscription),
                scalar(message.disableCyclingDetection),
            ]
            try upsert("settings_values", ["id", "data", "meta_created_at", "meta_updated_at", "asked_for_review", "daily_email", "disable_ai", "timeline_most_recent_first", "disable_scooting_detection", "hide_timeline_details", "store_image_previews", "enable_daily_notification", "disable_pat_responses", "disable_population_comparisons", "disable_automatic_log_inference", "use_tiles_for_trp", "show_photos_on_timeline", "show_media_metadata_overlay", "submit_to_apple_health", "deduplicate_week_photos", "default_transport_method", "day_end_offset_secs", "disable_automatic_photo_days", "disable_automatic_photo_events", "grandfathered_subscription", "disable_cycling_detection"], values, db)
        }
        for message in directory.lastfmTracks {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("lastfm_tracks", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                timeValue(message.playedAt),
                scalar(message.name),
                scalar(message.artist),
                message.hasAlbum ? scalar(message.album) : .null,
                message.hasArtistMbid ? scalar(message.artistMbid) : .null,
                message.hasURL ? scalar(message.url) : .null,
                scalar(message.nowPlaying),
                scalar(message.favorited),
            ]
            try upsert("lastfm_tracks", ["id", "data", "meta_created_at", "meta_updated_at", "played_at", "name", "artist", "album", "artist_mbid", "url", "now_playing", "favorited"], values, db)
        }
        for message in directory.books {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("books", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.title),
                scalar(message.isbn),
                scalar(message.isbn13),
                scalar(message.numberOfPages),
                scalar(message.publicationYear),
                scalar(message.originalPublicationYear),
                scalar(message.readDate),
                scalar(message.myReview),
                scalar(message.stars),
                scalar(message.source),
            ]
            try upsert("books", ["id", "data", "meta_created_at", "meta_updated_at", "title", "isbn", "isbn13", "number_of_pages", "publication_year", "original_publication_year", "read_date", "my_review", "stars", "source"], values, db)
            try replaceLinks("book_authors", "book_id", "author", id, message.authors, db)
        }
        for message in directory.moviesAndTv {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("movies_and_tv", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                timeValue(message.watchedAt),
                scalar(message.title),
                scalar(message.year),
                scalar(message.episodeNumber),
                scalar(message.season),
                scalar(message.imdbID),
                scalar(message.tmdbID),
                scalar(message.type),
                scalar(message.review),
                scalar(message.stars),
                scalar(message.url),
                scalar(message.source),
            ]
            try upsert("movies_and_tv", ["id", "data", "meta_created_at", "meta_updated_at", "watched_at", "title", "year", "episode_number", "season", "imdb_id", "tmdb_id", "media_type", "review", "stars", "url", "source"], values, db)
        }
        for message in directory.primaryDevices {
            let id = message.meta.id
            guard !id.isEmpty else { continue }
            if timestamp(message.meta.deletedAt) != nil {
                try deleteEntity("primary_devices", id, db)
                continue
            }
            let values: [SQLValue] = [
                .text(id), .blob(try message.serializedData()), timeValue(message.meta.createdAt), timeValue(message.meta.updatedAt),
                scalar(message.appID),
                scalar(message.userAction),
            ]
            try upsert("primary_devices", ["id", "data", "meta_created_at", "meta_updated_at", "app_id", "user_action"], values, db)
        }
    }

    private func processEvent(_ event: Event, _ db: Database) throws {
        let id = event.meta.id
        guard !id.isEmpty else { return }
        let table: String
        var columns = ["id", "data", "meta_created_at", "meta_updated_at", "start_at", "end_at", "event_type", "source", "app_id", "diagnostics_json"]
        var values: [SQLValue] = [.text(id), .blob(try event.serializedData()), timeValue(event.meta.createdAt), timeValue(event.meta.updatedAt), timeValue(event.startAt), timeValue(event.endAt), scalar(event.type), scalar(event.source), event.hasAppID ? scalar(event.appID) : .null, event.hasDiagnosticsJson ? scalar(event.diagnosticsJson) : .null]
        switch event.type.rawValue {
        case 1:
            table = "events_dates"
            columns += ["date", "favorite", "hide_summary"]
            values += [scalar(event.dateEvent.date), scalar(event.dateEvent.favorite), scalar(event.dateEvent.hideSummary)]
        case 2:
            table = "events_place_visits"
            columns += ["name", "secondary_name", "requires_reverse_geo", "city_or_county", "country_code", "region", "known_place_id", "is_user_labeled", "is_user_corrected"]
            values += [event.placeVisit.hasName ? scalar(event.placeVisit.name) : .null, event.placeVisit.hasSecondaryName ? scalar(event.placeVisit.secondaryName) : .null, scalar(event.placeVisit.requiresReverseGeo), event.placeVisit.hasCityOrCounty ? scalar(event.placeVisit.cityOrCounty) : .null, event.placeVisit.hasCountryCode ? scalar(event.placeVisit.countryCode) : .null, event.placeVisit.hasRegion ? scalar(event.placeVisit.region) : .null, event.placeVisit.hasKnownPlaceID ? scalar(event.placeVisit.knownPlaceID) : .null, scalar(event.placeVisit.isUserLabeled), scalar(event.placeVisit.isUserCorrected)]
        case 3:
            table = "events_movements"
            columns += ["name", "synthetic"]
            values += [event.movement.hasName ? scalar(event.movement.name) : .null, scalar(event.movement.synthetic)]
        case 4:
            table = "events_no_data_periods"
            columns += ["reason"]
            values += [event.noDataPeriod.hasReason ? scalar(event.noDataPeriod.reason) : .null]
        case 5:
            table = "events_workouts"
            columns += ["healthkit_activity_type", "activity_name", "duration_secs", "workout_source", "moloc_activity", "steps", "distance_meters", "indoors", "kcal", "healthkit_identifier", "device_name", "device_manufacturer", "device_model"]
            values += [scalar(event.workout.healthkitActivityType), scalar(event.workout.activityName), scalar(event.workout.durationSecs), scalar(event.workout.source), event.workout.hasMolocActivity ? scalar(event.workout.molocActivity) : .null, scalar(event.workout.steps), scalar(event.workout.distanceMeters), scalar(event.workout.indoors), scalar(event.workout.kcal), event.workout.hasHealthkitIdentifier ? scalar(event.workout.healthkitIdentifier) : .null, event.workout.hasDeviceName ? scalar(event.workout.deviceName) : .null, event.workout.hasDeviceManufacturer ? scalar(event.workout.deviceManufacturer) : .null, event.workout.hasDeviceModel ? scalar(event.workout.deviceModel) : .null]
        case 6:
            table = "events_sleeps"
            columns += ["asleep_secs", "sleep_type", "device_name", "device_manufacturer", "device_model"]
            values += [scalar(event.sleep.asleepSecs), scalar(event.sleep.type), event.sleep.hasDeviceName ? scalar(event.sleep.deviceName) : .null, event.sleep.hasDeviceManufacturer ? scalar(event.sleep.deviceManufacturer) : .null, event.sleep.hasDeviceModel ? scalar(event.sleep.deviceModel) : .null]
        case 7:
            table = "events_event_groups"
            columns += ["name", "user_set_name", "group_type"]
            values += [event.eventGroup.hasName ? scalar(event.eventGroup.name) : .null, scalar(event.eventGroup.userSetName), scalar(event.eventGroup.groupType)]
        case 8:
            table = "events_trips"
            columns += ["name"]
            values += [event.trip.hasName ? scalar(event.trip.name) : .null]
        default: table = "events_unspecified"
        }
        for other in tableDefinitions where other.name.hasPrefix("events_") && other.name != table {
            try db.execute("DELETE FROM \(other.name) WHERE id = ?", [.text(id)])
        }
        if timestamp(event.meta.deletedAt) != nil {
            try deleteEntity(table, id, db)
            return
        }
        try upsert(table, columns, values, db)
        try replaceLinks("event_media_ids", "event_id", "media_id", id, event.mediaIds, db)
        try replaceLinks("event_hidden_from_feed_dates", "event_id", "date", id, event.hiddenFromFeedDates, db)
    }
}

private func upsert(_ table: String, _ columns: [String], _ values: [SQLValue], _ db: Database) throws {
    let placeholders = Array(repeating: "?", count: columns.count).joined(separator: ", ")
    let updates = columns.filter { $0 != "id" }.map { "\($0) = excluded.\($0)" }.joined(separator: ", ")
    try db.execute("INSERT INTO \(table) (\(columns.joined(separator: ", "))) VALUES (\(placeholders)) ON CONFLICT(id) DO UPDATE SET \(updates)", values)
}
private func deleteEntity(_ table: String, _ id: String, _ db: Database) throws {
    try db.execute("DELETE FROM \(table) WHERE id = ?", [.text(id)])
    for (name, parent, _) in tableDefinitions.first(where: { $0.name == table })!.links {
        try db.execute("DELETE FROM \(name) WHERE \(parent) = ?", [.text(id)])
    }
}
private func replaceLinks(_ table: String, _ parent: String, _ value: String, _ id: String, _ values: [String], _ db: Database) throws {
    try db.execute("DELETE FROM \(table) WHERE \(parent) = ?", [.text(id)])
    for item in values { try db.execute("INSERT INTO \(table) (\(parent), \(value)) VALUES (?, ?)", [.text(id), .text(item)]) }
}
