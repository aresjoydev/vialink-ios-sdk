import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// ViaLink 내부 로거
enum ViaLinkLog {
    static func info(_ message: String) {
        print("[ViaLink] \(message)")
    }
    static func error(_ message: String) {
        print("[ViaLink] ERROR: \(message)")
    }
}

/// ViaLink iOS SDK
///
/// 딥링크 라우팅, 디퍼드 딥링킹, 이벤트 추적을 제공합니다.
///
/// ```swift
/// // 초기화 (AppDelegate 또는 @main App)
/// ViaLinkSDK.shared.configure(apiKey: "YOUR_API_KEY")  // 서버 주소는 SDK 내부에 고정
///
/// // 딥링크 콜백
/// ViaLinkSDK.shared.onDeepLink { data in
///     navigate(to: data.path, with: data.params)
/// }
///
/// // Universal Link 처리 (SceneDelegate)
/// func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
///     ViaLinkSDK.shared.handleUniversalLink(userActivity)
/// }
/// ```
public final class ViaLinkSDK: @unchecked Sendable {

    // MARK: - 싱글턴

    public static let shared = ViaLinkSDK()
    private init() {}

    // MARK: - API 서버 주소 (빌드 시 고정, 외부 변경 불가)

    private static let apiBaseURL = "https://vialink.app"

    // MARK: - 내부 상태

    private var networkClient: NetworkClient?
    private var eventTracker: EventTracker?
    private var deviceInfo: DeviceInfo?
    private var isConfigured = false

    private var deepLinkHandler: ((DeepLinkData) -> Void)?
    private var deferredDeepLinkHandler: ((DeepLinkData) -> Void)?
    // Universal Link에서 전달받은 fp 파라미터 (디퍼드 딥링킹용)
    private var pendingFp: String?

    // MARK: - 공개 API: 초기화

    /// SDK 초기화
    /// - Parameters:
    ///   - apiKey: 대시보드에서 발급받은 API Key
    public func configure(apiKey: String) {
        guard !isConfigured else {
            ViaLinkLog.info("이미 초기화되었습니다")
            return
        }

        let client = NetworkClient(baseURL: Self.apiBaseURL, apiKey: apiKey)
        self.networkClient = client
        self.eventTracker = EventTracker(client: client)
        self.deviceInfo = DeviceInfo.collect()
        self.isConfigured = true

        // 배치 전송 타이머 시작 (30초)
        eventTracker?.startBatchTimer()

        ViaLinkLog.info("SDK 초기화 완료 (apiKey: \(apiKey.prefix(8))...)")

        // 첫 실행 체크 → 디퍼드 딥링크 매칭
        if !Storage.hasLaunched {
            Storage.hasLaunched = true
            attemptDeferredMatch()
            track("app.install")
        } else {
            track("app.open")
        }
    }

    // MARK: - 공개 API: 딥링크 콜백

    /// 딥링크 수신 콜백 등록
    /// Universal Link로 앱이 실행되었을 때 호출됩니다.
    public func onDeepLink(_ handler: @escaping (DeepLinkData) -> Void) {
        self.deepLinkHandler = handler
    }

    /// 디퍼드 딥링크 콜백 등록
    /// 앱 첫 설치 후 핑거프린트 매칭이 성공했을 때 호출됩니다.
    public func onDeferredDeepLink(_ handler: @escaping (DeepLinkData) -> Void) {
        self.deferredDeepLinkHandler = handler
    }

    // MARK: - 공개 API: Universal Link 처리

    /// Universal Link 처리 (SceneDelegate에서 호출)
    ///
    /// ```swift
    /// func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    ///     ViaLinkSDK.shared.handleUniversalLink(userActivity)
    /// }
    /// ```
    @discardableResult
    public func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL,
              let shortCode = DeepLinkHandler.parseShortCode(from: url) else {
            return false
        }

        // fp 파라미터 저장 (디퍼드 딥링킹용 — 설치 후 첫 실행 시 사용)
        if let fp = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "fp" })?.value {
            pendingFp = fp
            Storage.saveFp(fp)
            ViaLinkLog.info("fp 파라미터 저장: \(fp.prefix(16))...")
        }

        ViaLinkLog.info("Universal Link 수신: \(shortCode)")

        guard let client = networkClient else {
            ViaLinkLog.error("SDK가 초기화되지 않았습니다")
            return false
        }

        Task {
            let data = await DeepLinkHandler.fetchLinkData(shortCode: shortCode, client: client)
            if let data = data {
                await MainActor.run {
                    self.deepLinkHandler?(data)
                }
                self.track("app.deeplink", data: ["short_code": shortCode])
            }
        }

        return true
    }

    /// URL 처리 (SwiftUI onOpenURL 또는 URL Scheme)
    ///
    /// ```swift
    /// .onOpenURL { url in
    ///     ViaLinkSDK.shared.handleURL(url)
    /// }
    /// ```
    @discardableResult
    public func handleURL(_ url: URL) -> Bool {
        guard let shortCode = DeepLinkHandler.parseShortCode(from: url) else {
            return false
        }

        // fp 파라미터 저장 (디퍼드 딥링킹용 — 설치 후 첫 실행 시 사용)
        if let fp = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "fp" })?.value {
            pendingFp = fp
            Storage.saveFp(fp)
            ViaLinkLog.info("fp 파라미터 저장: \(fp.prefix(16))...")
        }

        ViaLinkLog.info("URL 수신: \(shortCode)")

        guard let client = networkClient else {
            ViaLinkLog.error("SDK가 초기화되지 않았습니다")
            return false
        }

        Task {
            let data = await DeepLinkHandler.fetchLinkData(shortCode: shortCode, client: client)
            if let data = data {
                await MainActor.run {
                    self.deepLinkHandler?(data)
                }
            }
        }

        return true
    }

    // MARK: - 공개 API: 이벤트 추적

    /// 커스텀 이벤트 추적
    ///
    /// ```swift
    /// ViaLinkSDK.shared.track("purchase", data: ["product_id": "123", "revenue": "29900"])
    /// ```
    public func track(_ eventName: String, data: [String: String]? = nil) {
        guard isConfigured else {
            ViaLinkLog.error("SDK가 초기화되지 않았습니다")
            return
        }
        eventTracker?.track(eventName, data: data)
    }

    // MARK: - 공개 API: 링크 생성

    /// 앱 내에서 딥링크 생성
    ///
    /// ```swift
    /// let url = try await ViaLinkSDK.shared.createLink(
    ///     path: "/product/123",
    ///     data: ["promo_code": "FRIEND"],
    ///     campaign: "referral"
    /// )
    /// ```
    public func createLink(
        path: String,
        data: [String: String]? = nil,
        campaign: String? = nil
    ) async throws -> String {
        guard let client = networkClient else {
            throw CreateLinkError.notConfigured
        }

        var body: [String: Any] = ["deeplinkPath": path]
        if let data = data { body["deeplinkData"] = data }
        if let campaign = campaign { body["campaign"] = campaign }

        let responseData = try await client.post("/api/links", body: body)
        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let shortUrl = json["shortUrl"] as? String else {
            throw CreateLinkError.invalidResponse
        }

        return shortUrl
    }

    public enum CreateLinkError: Error, LocalizedError {
        case notConfigured
        case invalidResponse

        public var errorDescription: String? {
            switch self {
            case .notConfigured: return "SDK가 초기화되지 않았습니다"
            case .invalidResponse: return "서버 응답 파싱 실패"
            }
        }
    }

    // MARK: - 내부: 디퍼드 딥링크 매칭

    private func attemptDeferredMatch() {
        guard let client = networkClient, let info = deviceInfo else { return }

        Task {
            // 저장된 fp 파라미터가 있으면 함께 전달 (직접 매칭)
            let fp = self.pendingFp ?? Storage.loadFp()
            let matcher = DeferredDeepLinkMatcher(client: client, deviceInfo: info)
            let data = await matcher.match(fp: fp)
            if let data = data {
                ViaLinkLog.info("디퍼드 딥링크 매칭 성공: \(data.path)")
                await MainActor.run {
                    self.deferredDeepLinkHandler?(data)
                }
            }
        }
    }
}
