import SwiftUI
import UIKit
import ViaLinkCore

struct ContentView: View {
    // Result 모달 상태 (spec §4.2)
    @State private var pendingResult: ViaLinkResult?
    @State private var lastDeepLink: DeepLinkData?

    // Spec §3.2 — 상단 타이틀 고정값
    private let sdkVersion = ViaLinkSDK.sdkVersion
    private let apiKey = "0b8edff0b2979ce9efd925f43208b6debfae9db87c970367ba594c76238b16a9"

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        statusCard
                        section1Events
                        Divider()
                        section2LinkCreation
                        Divider()
                        section3PullApi
                        Divider()
                        section4Payment
                        Divider()
                        bottomInfoCard
                    }
                    .padding()
                }
            }
            .navigationTitle("ViaLink SDK Sample")
            .navigationBarTitleDisplayMode(.inline)
        }
        .viaLinkToastHost()
        .onReceive(NotificationCenter.default.publisher(for: .viaLinkResult)) { note in
            guard let result = note.object as? ViaLinkResult else { return }
            pendingResult = result
        }
        .alert(item: $pendingResult) { result in
            if let copy = result.copyableText {
                return Alert(
                    title: Text(result.title),
                    message: Text(result.message),
                    primaryButton: .default(Text("복사하기")) {
                        UIPasteboard.general.string = copy
                        DeepLinkBus.toast("📋 링크가 복사되었습니다")
                    },
                    secondaryButton: .cancel(Text("확인"))
                )
            } else {
                return Alert(
                    title: Text(result.title),
                    message: Text(result.message),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SDK 상태").font(.subheadline.bold())
                Spacer()
                Circle().fill(Color.green).frame(width: 8, height: 8)
                Text("Initialized").font(.caption).foregroundColor(.secondary)
            }
            HStack {
                Text("Version").foregroundColor(.secondary).font(.caption)
                Spacer()
                Text(sdkVersion).font(.caption.bold())
            }
            HStack {
                Text("API Key").foregroundColor(.secondary).font(.caption)
                Spacer()
                Text(apiKey.prefix(8) + "…")
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    // MARK: - Section 1: 이벤트 추적 (spec §3.3 표 1)

    private var section1Events: some View {
        SectionContainer(title: "1. 이벤트 추적") {
            actionButton(label: "회원가입 이벤트 전송") {
                ViaLinkSDK.shared.track("signup")
                NSLog("[ViaLink] track signup")
                DeepLinkBus.toast("✅ 회원가입 이벤트 전송 완료")
            }
            actionButton(label: "구매 이벤트 전송") {
                ViaLinkSDK.shared.track("purchase", data: [
                    "product_id": "PROD-001",
                    "revenue": "29900",
                    "currency": "KRW"
                ])
                NSLog("[ViaLink] track purchase")
                DeepLinkBus.toast("✅ 구매 이벤트 전송 완료")
            }
            actionButton(label: "장바구니 추가 이벤트 전송") {
                ViaLinkSDK.shared.track("add_to_cart", data: [
                    "product_id": "PROD-001"
                ])
                NSLog("[ViaLink] track add_to_cart")
                DeepLinkBus.toast("✅ 장바구니 추가 이벤트 전송 완료")
            }
        }
    }

    // MARK: - Section 2: 링크 생성

    private var section2LinkCreation: some View {
        SectionContainer(title: "2. 링크 생성") {
            actionButton(label: "딥링크 생성 (referral, dynamic)") {
                createLink(linkType: "dynamic", path: "/product/12345", campaign: "referral")
            }
            actionButton(label: "정적 링크 생성 (notice, static)") {
                createLink(linkType: "static", path: "/static/notice/123", campaign: nil)
            }
        }
    }

    // MARK: - Section 3: Pull API (spec §3.3 표 3)

    private var section3PullApi: some View {
        SectionContainer(title: "3. 데이터 가져오기 (Pull API)") {
            actionButton(label: "딥링크 가져오기 (Sync)") {
                let data = ViaLinkSDK.shared.getDeepLinkData()
                showPull(title: "딥링크 (Sync)", data: data)
            }
            actionButton(label: "딥링크 대기 (Async)") {
                Task {
                    DeepLinkBus.toast("⏳ 딥링크 대기 중…")
                    do {
                        let data = try await ViaLinkSDK.shared.awaitDeepLinkData()
                        showPull(title: "딥링크 (Await)", data: data)
                    } catch {
                        DeepLinkBus.post(ViaLinkResult(
                            title: "딥링크 대기 실패",
                            message: error.localizedDescription
                        ))
                    }
                }
            }
            actionButton(label: "디퍼드 딥링크 (Sync)") {
                let data = ViaLinkSDK.shared.getDeferredLinkData()
                showPull(title: "디퍼드 (Sync)", data: data)
            }
            actionButton(label: "디퍼드 딥링크 대기 (Async)") {
                Task {
                    DeepLinkBus.toast("⏳ 디퍼드 매칭 대기 중…")
                    do {
                        let data = try await ViaLinkSDK.shared.awaitDeferredLinkData()
                        showPull(title: "디퍼드 (Await)", data: data)
                    } catch {
                        DeepLinkBus.post(ViaLinkResult(
                            title: "디퍼드 대기 실패",
                            message: error.localizedDescription
                        ))
                    }
                }
            }
        }
    }

    // MARK: - Section 4: 결제 추적

    private var section4Payment: some View {
        SectionContainer(title: "4. 결제 추적") {
            actionButton(label: "결제 시도 (initiated)") {
                Task {
                    DeepLinkBus.toast("💳 결제 시도 요청 중…")
                    let orderId = "ORDER-\(Int.random(in: 1000...9999))"
                    do {
                        let result = try await ViaLinkSDK.shared.payment.initiated(
                            PaymentInitiatedArgs(
                                orderId: orderId,
                                amount: 29900,
                                currency: "KRW",
                                paymentMethod: "apple_pay",
                                metadata: ["user_tier": "gold", "channel": "ios_sample"]
                            )
                        )
                        NSLog("[ViaLink] payment.initiated success=\(result.success) eventId=\(result.paymentEventId)")
                        DeepLinkBus.post(ViaLinkResult(
                            title: "결제 시도 결과",
                            message: """
                            success: \(result.success)
                            paymentEventId: \(result.paymentEventId)
                            orderId: \(orderId)
                            """
                        ))
                    } catch let err as PaymentError {
                        NSLog("[ViaLink] payment.initiated failed: \(err)")
                        DeepLinkBus.post(ViaLinkResult(
                            title: "결제 시도 실패",
                            message: "\(err)"
                        ))
                    } catch {
                        NSLog("[ViaLink] payment.initiated error: \(error.localizedDescription)")
                        DeepLinkBus.post(ViaLinkResult(
                            title: "결제 시도 실패",
                            message: error.localizedDescription
                        ))
                    }
                }
            }
        }
    }

    // MARK: - Bottom Info Card (spec §3.3 하단 안내)

    private var bottomInfoCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("정보").font(.subheadline.bold())
            Group {
                Text("• SDK 버전: \(sdkVersion)")
                Text("• 딥링크/디퍼드 결과는 AlertDialog로 표시됩니다.")
                Text("• 콘솔 로그 태그: [ViaLink]")
                Text("• 이벤트는 30초마다 배치 전송됩니다.")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    // MARK: - Helpers

    private func showPull(title: String, data: DeepLinkData?) {
        if let data = data {
            lastDeepLink = data
            DeepLinkBus.post(ViaLinkResult(
                title: title,
                message: """
                path: \(data.path)
                shortCode: \(data.shortCode ?? "-")
                linkId: \(data.linkId.map(String.init) ?? "-")
                params: \(data.params)
                """,
                copyableText: data.shortCode
            ))
        } else {
            DeepLinkBus.post(ViaLinkResult(
                title: title,
                message: "수신/캐시된 데이터가 없습니다 (null)"
            ))
        }
    }

    private func createLink(linkType: String, path: String, campaign: String?) {
        Task {
            DeepLinkBus.toast("🔗 \(linkType) 링크 생성 요청 중…")
            do {
                let url = try await ViaLinkSDK.shared.createLink(
                    path: path,
                    data: ["source": "ios_sample"],
                    campaign: campaign,
                    linkType: linkType
                )
                NSLog("[ViaLink] createLink \(linkType) → \(url)")
                DeepLinkBus.post(ViaLinkResult(
                    title: "링크 생성 성공",
                    message: "url: \(url)",
                    copyableText: url
                ))
            } catch {
                NSLog("[ViaLink] createLink failed: \(error.localizedDescription)")
                DeepLinkBus.post(ViaLinkResult(
                    title: "링크 생성 실패",
                    message: error.localizedDescription
                ))
            }
        }
    }

    private func actionButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
}

// MARK: - SectionContainer

private struct SectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            VStack(spacing: 8) { content() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Identifiable conformance for alert(item:)

extension ViaLinkResult: Identifiable {
    var id: String { "\(title)-\(message.hashValue)" }
}
