import SwiftProtobuf

public func enumName<E: SwiftProtobuf.Enum>(_ value: E) -> String {
    switch E.self {
    case is AIProfilePurpose.Type:
        return [0: "AIPP_NOT_SPECIFIED", 1: "ACTIVITY", 2: "WORK", 3: "PEOPLE", 4: "HEALTH_FITNESS", 5: "ROUTINE"][value.rawValue] ?? String(value.rawValue)
    case is AttendeeRole.Type:
        return [0: "ATTENDEE_ROLE_UNSPECIFIED", 1: "ATTENDEE_ROLE_REQUIRED", 2: "ATTENDEE_ROLE_OPTIONAL", 3: "ATTENDEE_ROLE_NON_PARTICIPANT", 4: "ATTENDEE_ROLE_CHAIR"][value.rawValue] ?? String(value.rawValue)
    case is AttendeeStatus.Type:
        return [0: "ATTENDEE_STATUS_UNSPECIFIED", 1: "ATTENDEE_STATUS_NEEDS_ACTION", 2: "ATTENDEE_STATUS_ACCEPTED", 3: "ATTENDEE_STATUS_DECLINED", 4: "ATTENDEE_STATUS_TENTATIVE", 5: "ATTENDEE_STATUS_DELEGATED"][value.rawValue] ?? String(value.rawValue)
    case is DashboardSection.Type:
        return [0: "FACTOIDS", 1: "ACTIVITIES", 2: "TIMESPENT", 3: "MAPS", 4: "LOCALESTATS", 5: "TRIPS", 6: "TALLIES", 7: "JOURNAL_STATS", 8: "PERSONAL_WEATHER", 9: "KNOWN_PLACES", 10: "ALTITUDE"][value.rawValue] ?? String(value.rawValue)
    case is EmbeddingType.Type:
        return [0: "EMBT_NOT_SPECIFIED", 1: "JOURNAL_ENTRY", 2: "EVENT"][value.rawValue] ?? String(value.rawValue)
    case is EventGroupType.Type:
        return [0: "OUTING_GROUP", 1: "TRANSPORT_GROUP", 2: "AREA_VISIT_GROUP"][value.rawValue] ?? String(value.rawValue)
    case is EventType.Type:
        return [0: "ET_NOT_SPECIFIED", 1: "DATE", 2: "PLACEVISIT", 3: "MOVEMENT", 4: "NO_DATA_PERIOD", 5: "WORKOUT", 6: "SLEEP", 7: "EVENT_GROUP", 8: "TRIP"][value.rawValue] ?? String(value.rawValue)
    case is HighlightInclusionMode.Type:
        return [0: "HIGHLIGHT_INCLUDE", 1: "HIGHLIGHT_NO_DESCRIPTION", 2: "HIGHLIGHT_EXCLUDE"][value.rawValue] ?? String(value.rawValue)
    case is IntroductionContent.Type:
        return [0: "DAYVIEW", 1: "BOX_STARTMOVING", 2: "BOX_VISITAPLACE", 3: "BOX_NAMEPLACES", 4: "BOX_ADDPHOTOS", 5: "CHAT", 6: "DASHBOARD", 7: "BENTO_CUSTOM", 8: "LIGHT_MODE", 9: "TRIP_VIEW", 12: "INVITE"][value.rawValue] ?? String(value.rawValue)
    case is Orientation.Type:
        return [0: "ORIENT_NOT_SET", 1: "HORIZONTAL", 2: "VERTICAL"][value.rawValue] ?? String(value.rawValue)
    case is PatternType.Type:
        return [0: "PT_NOT_SPECIFIED", 1: "MOVEMENT_ACTIVITY", 2: "TALLY", 3: "MANUAL_WORKOUT"][value.rawValue] ?? String(value.rawValue)
    case is Recipient.Type:
        return [0: "RT_NOT_SPECIFIED", 1: "USER", 2: "PAT"][value.rawValue] ?? String(value.rawValue)
    case is SleepType.Type:
        return [0: "ST_NOT_SPECIFIED", 1: "IN_BED", 2: "ASLEEP", 3: "AWAKE", 4: "CORE", 5: "DEEP", 6: "REM"][value.rawValue] ?? String(value.rawValue)
    case is Transport.Type:
        return [0: "T_NOT_SPECIFIED", 1: "EMAIL"][value.rawValue] ?? String(value.rawValue)
    case is TripViewSection.Type:
        return [0: "TRIPVIEW_NOTSPECIFIED", 1: "TRIPVIEW_HEADLINEPHOTO", 2: "TRIPVIEW_DESCRIPTION", 3: "TRIPVIEW_DAYS", 4: "TRIPVIEW_TOPLIST", 5: "TRIPVIEW_HIGHLIGHTS", 6: "TRIPVIEW_PHOTOS", 7: "TRIPVIEW_WEATHER", 8: "TRIPVIEW_MAPS", 9: "TRIPVIEW_TOTALS", 10: "TRIPVIEW_CHARTS", 11: "TRIPVIEW_DIARY"][value.rawValue] ?? String(value.rawValue)
    default: return String(value.rawValue)
    }
}
