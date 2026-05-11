# ViaLink iOS SDK

ViaLink 딥링크 인프라 서비스를 위한 iOS SDK입니다.

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

- [SDK 가이드](https://docs.vialink.app/sdk/ios)

## 라이선스

MIT License — Aresjoy Inc.
