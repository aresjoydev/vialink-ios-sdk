import SwiftUI
import ViaLinkCore

@main
struct iosApp: App {
    init() {
        // ViaLink SDK 초기화
        ViaLinkSDK.shared.configure(apiKey: "0b8edff0b2979ce9efd925f43208b6debfae9db87c970367ba594c76238b16a9")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Custom URL Scheme 수신
                    ViaLinkSDK.shared.handleURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    // Universal Link 수신
                    ViaLinkSDK.shared.handleUniversalLink(userActivity)
                }
        }
    }
}
