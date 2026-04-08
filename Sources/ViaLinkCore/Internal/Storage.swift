import Foundation

/// UserDefaults 기반 영속 저장소
struct Storage {
    private static let prefix = "com.vialink.sdk."

    /// 첫 실행 여부 확인
    static var hasLaunched: Bool {
        get { UserDefaults.standard.bool(forKey: prefix + "has_launched") }
        set { UserDefaults.standard.set(newValue, forKey: prefix + "has_launched") }
    }

    /// 미전송 이벤트 저장
    static func savePendingEvents(_ events: [EventPayload]) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: prefix + "pending_events")
    }

    /// 미전송 이벤트 로드
    static func loadPendingEvents() -> [EventPayload] {
        guard let data = UserDefaults.standard.data(forKey: prefix + "pending_events"),
              let events = try? JSONDecoder().decode([EventPayload].self, from: data) else {
            return []
        }
        return events
    }

    /// 미전송 이벤트 삭제
    static func clearPendingEvents() {
        UserDefaults.standard.removeObject(forKey: prefix + "pending_events")
    }

    /// 디퍼드 딥링킹용 fp 파라미터 저장
    static func saveFp(_ fp: String) {
        UserDefaults.standard.set(fp, forKey: prefix + "pending_fp")
    }

    /// 저장된 fp 파라미터 로드 후 삭제
    static func loadFp() -> String? {
        let fp = UserDefaults.standard.string(forKey: prefix + "pending_fp")
        if fp != nil {
            UserDefaults.standard.removeObject(forKey: prefix + "pending_fp")
        }
        return fp
    }
}
