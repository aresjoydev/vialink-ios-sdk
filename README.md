# ViaLink iOS SDK

ViaLink 딥링크 인프라 서비스를 위한 iOS SDK입니다.

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

```swift
import ViaLinkCore

// 초기화
ViaLinkSDK.shared.configure(apiKey: "YOUR_API_KEY")

// 딥링크 콜백
ViaLinkSDK.shared.onDeepLink { data in
    print("경로: \(data.path)")
    print("파라미터: \(data.params)")
}

// 디퍼드 딥링크 콜백
ViaLinkSDK.shared.onDeferredDeepLink { data in
    print("디퍼드: \(data.path)")
}

// 이벤트 추적
ViaLinkSDK.shared.track("purchase", data: [
    "product_id": "12345",
    "revenue": "29900"
])

// 링크 생성
let shortUrl = try await ViaLinkSDK.shared.createLink(
    path: "/product/12345",
    data: ["promo_code": "FRIEND_SHARE"],
    campaign: "referral"
)
```

## 문서

- [SDK 가이드](https://docs.vialink.app)
