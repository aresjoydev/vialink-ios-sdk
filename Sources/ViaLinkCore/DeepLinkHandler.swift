import Foundation

/// Universal Link URL 파싱 + 서버에서 딥링크 데이터 조회
struct DeepLinkHandler {

    /// Universal Link URL에서 short_code 추출
    /// URL 형식: https://dev.aresjoy.com:51000/c/{shortCode}?fp={fingerprint}
    static func parseShortCode(from url: URL) -> String? {
        let components = url.pathComponents // ["/", "c", "aB3xK"]
        guard components.count >= 3, components[1] == "c" else { return nil }
        return components[2]
    }

    /// 서버에서 딥링크 데이터 조회
    /// POST /v1/resolve — App Links/Universal Links로 앱이 직접 열렸을 때 short code로 딥링크 데이터 조회
    static func fetchLinkData(shortCode: String, client: NetworkClient) async -> DeepLinkData? {
        do {
            let body: [String: Any] = ["short_code": shortCode]
            let data = try await client.post("/v1/resolve", body: body)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let matched = json["matched"] as? Bool, matched,
                  let path = json["deeplink_path"] as? String else {
                return nil
            }

            var params: [String: String] = [:]
            if let rawParams = json["deeplink_data"] as? [String: Any] {
                for (key, value) in rawParams {
                    params[key] = "\(value)"
                }
            }

            return DeepLinkData(path: path, params: params, shortCode: shortCode)
        } catch {
            ViaLinkLog.error("딥링크 데이터 조회 실패: \(error.localizedDescription)")
            return nil
        }
    }
}
