import Foundation
import ViaLinkCore

extension Notification.Name {
    static let viaLinkResult = Notification.Name("viaLinkResult")
    static let viaLinkToast = Notification.Name("viaLinkToast")
}

struct ViaLinkResult {
    let title: String
    let message: String
    let copyableText: String?

    init(title: String, message: String, copyableText: String? = nil) {
        self.title = title
        self.message = message
        self.copyableText = copyableText
    }
}

enum DeepLinkBus {
    static func registerCallbacks() {
        ViaLinkSDK.shared.onDeepLink { data in
            NSLog("[ViaLink] DeepLink received: path=\(data.path) params=\(data.params)")
            post(ViaLinkResult(
                title: "딥링크 진입",
                message: format(data),
                copyableText: data.shortCode
            ))
        }

        ViaLinkSDK.shared.onDeferredDeepLink { data, error in
            if let error = error {
                NSLog("[ViaLink] Deferred error: code=\(error.code) message=\(error.message) retryable=\(error.retryable)")
                post(ViaLinkResult(
                    title: "디퍼드 매칭 실패",
                    message: "code: \(error.code)\nmessage: \(error.message)\nretryable: \(error.retryable)"
                ))
            } else if let data = data {
                NSLog("[ViaLink] Deferred matched: path=\(data.path) linkId=\(String(describing: data.linkId))")
                post(ViaLinkResult(
                    title: "디퍼드 딥링크 매칭",
                    message: format(data),
                    copyableText: data.shortCode
                ))
            } else {
                NSLog("[ViaLink] Organic install (no match)")
                post(ViaLinkResult(
                    title: "디퍼드 딥링크",
                    message: "매칭 결과 없음 (organic install)"
                ))
            }
        }
    }

    static func post(_ result: ViaLinkResult) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .viaLinkResult, object: result)
        }
    }

    static func toast(_ message: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .viaLinkToast, object: message)
        }
    }

    private static func format(_ data: DeepLinkData) -> String {
        var lines: [String] = []
        lines.append("path: \(data.path)")
        if let s = data.shortCode { lines.append("shortCode: \(s)") }
        if let l = data.linkId { lines.append("linkId: \(l)") }
        if !data.params.isEmpty {
            let params = data.params.sorted { $0.key < $1.key }
                .map { "  \($0.key): \($0.value)" }
                .joined(separator: "\n")
            lines.append("params:\n\(params)")
        }
        return lines.joined(separator: "\n")
    }
}
