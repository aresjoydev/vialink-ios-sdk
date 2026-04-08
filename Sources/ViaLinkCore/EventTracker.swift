import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// 이벤트 큐 + 배치 전송 (30초 간격)
final class EventTracker: @unchecked Sendable {
    private let client: NetworkClient
    private var queue: [EventPayload] = []
    private let lock = NSLock()
    private let maxQueueSize = 100
    private var timer: Timer?

    init(client: NetworkClient) {
        self.client = client
        queue = Storage.loadPendingEvents()
    }

    /// 이벤트 추가
    func track(_ eventName: String, linkId: Int? = nil, data: [String: String]? = nil) {
        let event = EventPayload(linkId: linkId, eventName: eventName, eventData: data)
        withLock { queue.append(event) }

        if queue.count >= maxQueueSize {
            Task { await flush() }
        }
    }

    /// 배치 전송 타이머 시작
    func startBatchTimer(interval: TimeInterval = 30) {
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                Task { await self?.flush() }
            }
        }

        #if canImport(UIKit) && !os(watchOS) && !os(macOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        #endif
    }

    #if canImport(UIKit) && !os(watchOS) && !os(macOS)
    @objc private func appDidEnterBackground() {
        Task { await flush() }
        withLock { Storage.savePendingEvents(queue) }
    }
    #endif

    /// 큐 전송
    func flush() async {
        let events: [EventPayload] = withLock {
            let e = queue
            queue = []
            return e
        }

        guard !events.isEmpty else { return }

        do {
            if events.count == 1, let event = events.first {
                _ = try await client.post("/v1/events", body: event.toDictionary())
            } else {
                let body: [String: Any] = [
                    "events": events.map { $0.toBatchItem() }
                ]
                _ = try await client.post("/v1/events/batch", body: body)
            }
            Storage.clearPendingEvents()
        } catch {
            withLock {
                queue.insert(contentsOf: events, at: 0)
                Storage.savePendingEvents(queue)
            }
            ViaLinkLog.error("이벤트 전송 실패: \(error.localizedDescription)")
        }
    }

    /// NSLock 래퍼 (async context 경고 방지)
    @discardableResult
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    deinit {
        timer?.invalidate()
    }
}
