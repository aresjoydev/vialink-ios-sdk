import SwiftUI
import ViaLinkCore

@main
struct iosApp: App {
    init() {
        // ViaLink SDK 초기화 (앱 진입점)
        ViaLinkSDK.shared.configure(apiKey: "0b8edff0b2979ce9efd925f43208b6debfae9db87c970367ba594c76238b16a9")
        NSLog("[ViaLink] SDK 초기화 완료 (version=\(ViaLinkSDK.sdkVersion))")

        // 딥링크/디퍼드 콜백을 진입점에서 등록 → NotificationCenter로 UI에 전달
        DeepLinkBus.registerCallbacks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    NSLog("[ViaLink] onOpenURL: \(url.absoluteString)")
                    _ = ViaLinkSDK.shared.handleURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    NSLog("[ViaLink] onContinueUserActivity: \(userActivity.webpageURL?.absoluteString ?? "-")")
                    _ = ViaLinkSDK.shared.handleUniversalLink(userActivity)
                }
        }
    }
}
