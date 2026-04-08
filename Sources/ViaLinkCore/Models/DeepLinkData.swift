import Foundation

/// 딥링크 데이터 모델
public struct DeepLinkData: Sendable {
    /// 앱 내 이동 경로 (예: "/product/12345")
    public let path: String
    /// 추가 파라미터 (예: ["product_id": "12345", "promo_code": "SUMMER"])
    public let params: [String: String]
    /// Short Code (예: "aB3xK")
    public let shortCode: String?

    public init(path: String, params: [String: String] = [:], shortCode: String? = nil) {
        self.path = path
        self.params = params
        self.shortCode = shortCode
    }
}
