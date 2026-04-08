import Foundation

/// 디퍼드 딥링크 매칭 (POST /v1/open)
/// 앱 첫 실행 시 핑거프린트 기반으로 서버에서 매칭 시도
struct DeferredDeepLinkMatcher {
    let client: NetworkClient
    let deviceInfo: DeviceInfo

    /// 매칭 시도 — 성공 시 DeepLinkData 반환, 실패 시 nil
    /// - Parameter fp: Universal Link에서 전달받은 fingerprint 파라미터 (있으면 서버에서 100% 정확 매칭, 없으면 핑거프린트 폴백)
    func match(fp: String? = nil) async -> DeepLinkData? {
        var body: [String: Any] = [
            "device_info": deviceInfo.toDictionary(),
            "is_first_launch": true
        ]
        if let fp = fp {
            body["fp"] = fp
        }
        ViaLinkLog.info("[디퍼드] POST /v1/open 요청 (fp: \(fp?.prefix(16) ?? "없음"))")

        do {
            let data = try await client.post("/v1/open", body: body)
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

            return DeepLinkData(
                path: path,
                params: params,
                shortCode: json["link_click_id"] as? String
            )
        } catch {
            ViaLinkLog.error("디퍼드 매칭 실패: \(error.localizedDescription)")
            return nil
        }
    }
}
