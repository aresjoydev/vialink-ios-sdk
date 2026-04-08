import Foundation

/// 이벤트 페이로드 모델
struct EventPayload: Codable, Sendable {
    let linkId: Int?
    let eventName: String
    let eventData: [String: String]?
    let timestamp: Date

    init(linkId: Int? = nil, eventName: String, eventData: [String: String]? = nil, timestamp: Date = Date()) {
        self.linkId = linkId
        self.eventName = eventName
        self.eventData = eventData
        self.timestamp = timestamp
    }

    /// /v1/events 요청용 딕셔너리
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "event_name": eventName,
            "link_id": linkId ?? 0
        ]
        if let data = eventData {
            dict["event_data"] = data
        }
        return dict
    }

    /// /v1/events/batch 요청용 간략 딕셔너리
    func toBatchItem() -> [String: Any] {
        return [
            "link_id": linkId ?? 0,
            "event_name": eventName
        ]
    }
}
