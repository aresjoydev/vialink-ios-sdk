import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// 디바이스 정보 모델
struct DeviceInfo: Codable, Sendable {
    let os: String
    let osVersion: String
    let model: String
    let screenWidth: Int
    let screenHeight: Int
    let language: String
    let country: String

    /// 현재 디바이스 정보 수집
    static func collect() -> DeviceInfo {
        #if canImport(UIKit) && !os(watchOS)
        let screen = UIScreen.main.nativeBounds
        let locale = Locale.current
        return DeviceInfo(
            os: "iOS",
            osVersion: UIDevice.current.systemVersion,
            model: Self.deviceModel(),
            screenWidth: Int(screen.width),
            screenHeight: Int(screen.height),
            language: locale.identifier,
            country: {
                if #available(iOS 16.0, *) {
                    return locale.region?.identifier ?? "Unknown"
                } else {
                    return (locale as NSLocale).countryCode ?? "Unknown"
                }
            }()
        )
        #else
        return DeviceInfo(
            os: "iOS", osVersion: "Unknown", model: "Unknown",
            screenWidth: 0, screenHeight: 0, language: "en", country: "US"
        )
        #endif
    }

    /// utsname 기반 디바이스 모델명
    private static func deviceModel() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    /// /v1/open 요청용 딕셔너리
    func toDictionary() -> [String: Any] {
        return [
            "os": os,
            "os_version": osVersion,
            "device_model": model,
            "screen_width": screenWidth,
            "screen_height": screenHeight,
            "language": language,
            "country": country
        ]
    }
}
