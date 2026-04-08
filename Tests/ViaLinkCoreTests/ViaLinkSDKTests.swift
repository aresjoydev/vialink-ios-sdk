import XCTest
@testable import ViaLinkCore

final class ViaLinkSDKTests: XCTestCase {

    func test_deepLinkData_생성() {
        let data = DeepLinkData(
            path: "/product/123",
            params: ["id": "123", "promo": "SUMMER"],
            shortCode: "aB3xK"
        )
        XCTAssertEqual(data.path, "/product/123")
        XCTAssertEqual(data.shortCode, "aB3xK")
        XCTAssertEqual(data.params["id"], "123")
    }

    func test_deepLinkHandler_URL_파싱() {
        let url = URL(string: "https://example.com/c/xYz12")!
        let code = DeepLinkHandler.parseShortCode(from: url)
        XCTAssertEqual(code, "xYz12")
    }

    func test_deepLinkHandler_잘못된_URL() {
        let url = URL(string: "https://example.com/other/path")!
        let code = DeepLinkHandler.parseShortCode(from: url)
        XCTAssertNil(code)
    }

    func test_deepLinkHandler_루트_URL() {
        let url = URL(string: "https://example.com/")!
        let code = DeepLinkHandler.parseShortCode(from: url)
        XCTAssertNil(code)
    }

    func test_eventPayload_딕셔너리() {
        let event = EventPayload(linkId: 1, eventName: "purchase", eventData: ["revenue": "29900"])
        let dict = event.toDictionary()
        XCTAssertEqual(dict["event_name"] as? String, "purchase")
        XCTAssertEqual(dict["link_id"] as? Int, 1)
    }

    func test_eventPayload_배치() {
        let event = EventPayload(eventName: "view")
        let batch = event.toBatchItem()
        XCTAssertEqual(batch["event_name"] as? String, "view")
        XCTAssertEqual(batch["link_id"] as? Int, 0)
    }

    // MARK: - fp 파라미터 테스트

    func test_storage_fp_저장_로드_삭제() {
        // 저장
        Storage.saveFp("test_fp_12345")
        // 로드 (1회성 — 읽으면 삭제됨)
        let fp = Storage.loadFp()
        XCTAssertEqual(fp, "test_fp_12345")
        // 이미 삭제되었으므로 nil
        let fpAgain = Storage.loadFp()
        XCTAssertNil(fpAgain)
    }

    func test_URL에서_fp_파라미터_추출() {
        let url = URL(string: "https://example.com/c/xYz12?fp=abc123def456")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let fp = components?.queryItems?.first(where: { $0.name == "fp" })?.value
        XCTAssertEqual(fp, "abc123def456")
    }

    func test_URL에서_fp_없으면_nil() {
        let url = URL(string: "https://example.com/c/xYz12")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let fp = components?.queryItems?.first(where: { $0.name == "fp" })?.value
        XCTAssertNil(fp)
    }

    func test_URL에서_fp_빈값() {
        let url = URL(string: "https://example.com/c/xYz12?fp=")!
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let fp = components?.queryItems?.first(where: { $0.name == "fp" })?.value
        // 빈 문자열은 nil이 아니라 "" 반환
        XCTAssertEqual(fp, "")
    }
}
