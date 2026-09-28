# ViaLink iOS SDK

[![ViaLink — 6개 플랫폼 딥링크를 무료로 시작하세요](docs/banner-ko.png)](https://vialink.app/?lang=ko&utm_source=github&utm_medium=readme&utm_campaign=ios-sdk)

[English](README.md) | **한국어**

ViaLink 딥링크 인프라 서비스를 위한 iOS SDK입니다.

링크 하나로 iOS · Android · Web을 자동 분기합니다. 앱이 설치돼 있지 않으면 App Store로
보낸 뒤, 설치 후 첫 실행에서 원래 의도한 화면으로 정확히 연결합니다(디퍼드 딥링킹).
클릭 → 설치 → 실행 → 이벤트 → 결제까지 하나의 파이프라인에서 어트리뷰션으로 이어집니다.

많은 딥링크 · 어트리뷰션 도구가 영업 문의와 연간 계약을 요구하는 것과 달리
**ViaLink는 무료로 시작합니다.** 카드 등록 없이, 가입 즉시 6개 플랫폼 SDK를 모두 쓸 수 있습니다.

**→ [vialink.app](https://vialink.app/?lang=ko&utm_source=github&utm_medium=readme&utm_campaign=ios-sdk)**

## 인앱 브라우저에서도 앱이 열립니다

카카오톡·네이버·LINE·인스타그램·Threads에 공유된 링크는 각 앱의 내장 브라우저에서 열리고,
이 환경에서는 Universal Link / App Link가 동작하지 않는 경우가 많습니다. ViaLink 링크 서버는
인앱 브라우저를 감지해 그 환경에서 동작하는 경로를 고릅니다.

- **카카오톡 · 네이버 · LINE (iOS)** — Safari로 자동 전환해 Universal Link가 동작하게 합니다
- **Android 인앱 브라우저** — `intent://` URL로 앱을 실행하고, 미설치 시 스토어로 보냅니다
- **인스타그램 · 페이스북 · Threads 등** — 등록된 커스텀 URL 스킴으로 앱 실행을 시도하고, "외부 브라우저로 열기" 안내를 함께 보여줍니다

링크 서버에서 처리되므로 SDK 코드를 추가할 필요가 없습니다.

## 특징

- **딥링크 라우팅** — Universal Links / Custom URL Scheme 자동 처리
- **디퍼드 딥링킹** — 앱 설치 후 첫 실행 시 핑거프린트 기반 매칭
- **이벤트 추적** — 커스텀 이벤트 배치 전송
- **결제 어트리뷰션** — 결제 시도 기록 + 자동 link_id 첨부
- **링크 생성** — 앱 내에서 딥링크 생성 (static/dynamic)

## 요구사항

- iOS 15.0+
- Swift 5.9+
- Xcode 15+

## 설치

### Swift Package Manager

```
Xcode > File > Add Package Dependencies
URL: https://github.com/aresjoydev/vialink-ios-sdk
```

## 사용법

### 1. 초기화 및 수신

```swift
import ViaLinkCore

@main
struct iosApp: App {
    init() {
        ViaLinkSDK.shared.configure(apiKey: "YOUR_API_KEY")
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
```

### 2. 딥링크 콜백

```swift
// Universal Link / 커스텀 스킴 수신
ViaLinkSDK.shared.onDeepLink { data in
    print("경로: \(data.path)")
    print("파라미터: \(data.params)")
}

// 디퍼드 딥링크 (첫 설치 후 매칭)
ViaLinkSDK.shared.onDeferredDeepLink { data, error in
    if let error = error {
        print("매칭 실패: \(error.message)")
        return
    }
    if let data = data {
        print("디퍼드: \(data.path)")
    } else {
        print("매칭 결과 없음 (Organic)")
    }
}
```

### 3. Pull API

```swift
// 동기 (캐시된 값 즉시 반환)
let deepLink = ViaLinkSDK.shared.getDeepLinkData()
let deferred = ViaLinkSDK.shared.getDeferredLinkData()

// 비동기 (결과 도착까지 대기)
Task {
    let deepLinkAsync = try? await ViaLinkSDK.shared.awaitDeepLinkData()    // 3초 타임아웃
    let deferredAsync = try? await ViaLinkSDK.shared.awaitDeferredLinkData() // 첫 실행: 매칭 결과까지 대기 / 이후 실행: 즉시 nil
}
```

### 4. 이벤트 추적

```swift
ViaLinkSDK.shared.track("purchase", data: [
    "product_id": "12345",
    "revenue": "29900",
    "currency": "KRW"
])
```

### 5. 결제 추적

```swift
Task {
    do {
        let result = try await ViaLinkSDK.shared.payment.initiated(
            PaymentInitiatedArgs(
                orderId: "ORDER-1234",
                amount: 29900,
                currency: "KRW",
                paymentMethod: "apple_pay"
            )
        )
        print("Success: \(result.success), EventId: \(result.paymentEventId)")
    } catch {
        print("Payment Error: \(error.localizedDescription)")
    }
}
```

### 6. 링크 생성

```swift
Task {
    do {
        let url = try await ViaLinkSDK.shared.createLink(
            path: "/product/12345",
            data: ["promo_code": "FRIEND_SHARE"],
            campaign: "referral",
            linkType: "dynamic" // 클릭 추적 필요 시
        )
        print("생성된 링크: \(url)")
    } catch {
        print("생성 실패: \(error.localizedDescription)")
    }
}
```

## 샘플 프로젝트

`sample/ViaLinkSample/` 디렉토리에서 실행 가능한 Xcode 샘플 프로젝트를 확인하세요.

## 문서

- [SDK 가이드](https://docs.vialink.app/#sdk-ios-install)

## 라이선스

MIT License — Aresjoy Inc.
