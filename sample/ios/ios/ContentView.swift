import SwiftUI
import ViaLinkCore

struct ContentView: View {
    @State private var sdkStatus: String = "Initialized"
    @State private var lastLinkData: DeepLinkData?
    @State private var logs: [String] = []
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // SDK 버전 및 API Key (샘플용)
    private let sdkVersion = ViaLinkSDK.sdkVersion
    private let apiKey = "0b8edff0b2979ce9efd925f43208b6debfae9db87c970367ba594c76238b16a9"

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Header & Status Card
                        statusCard
                        
                        // 2. Deep Link Result Card
                        linkResultCard
                        
                        // 3. Action Sections
                        eventSection
                        linkCreationSection
                        pullApiSection
                        paymentSection
                        
                        // 4. Log Section
                        logSection
                    }
                    .padding()
                }
            }
            .navigationTitle("ViaLinkSample")
            .onAppear {
                setupCallbacks()
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("확인")))
            }
        }
    }

    // MARK: - Components

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SDK Status")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text(sdkStatus)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            HStack {
                Text("Version")
                    .foregroundColor(.secondary)
                Spacer()
                Text(sdkVersion)
                    .bold()
            }
            
            HStack {
                Text("API Key")
                    .foregroundColor(.secondary)
                Spacer()
                Text(apiKey.prefix(8) + "...")
                    .font(.system(.subheadline, design: .monospaced))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var linkResultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Deep Link Data")
                .font(.headline)
            
            if let data = lastLinkData {
                VStack(alignment: .leading, spacing: 8) {
                    detailRow(label: "Path", value: data.path)
                    detailRow(label: "ShortCode", value: data.shortCode ?? "-")
                    detailRow(label: "LinkId", value: data.linkId != nil ? "\(data.linkId!)" : "-")
                    
                    if !data.params.isEmpty {
                        Text("Parameters:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        ForEach(data.params.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            HStack {
                                Text(key).font(.caption).bold()
                                Spacer()
                                Text(value).font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(4)
                        }
                    }
                }
            } else {
                Text("수신된 딥링크 데이터가 없습니다.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Tracking")
                .font(.headline)
            
            HStack(spacing: 12) {
                actionButton(title: "App Open", icon: "arrow.up.circle") {
                    ViaLinkSDK.shared.track("app.open")
                    addLog("Event: app.open tracked")
                }
                
                actionButton(title: "Purchase", icon: "cart.fill") {
                    ViaLinkSDK.shared.track("purchase", data: ["item": "iPhone 15", "price": "1500000"])
                    addLog("Event: purchase tracked")
                }
            }
        }
    }

    private var linkCreationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link Creation")
                .font(.headline)
            
            HStack(spacing: 12) {
                actionButton(title: "Static Link", icon: "link") {
                    createLink(type: "static")
                }
                
                actionButton(title: "Dynamic Link", icon: "sparkles") {
                    createLink(type: "dynamic")
                }
            }
        }
    }

    private var pullApiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pull APIs (Async/Sync)")
                .font(.headline)
            
            VStack(spacing: 10) {
                Button(action: {
                    if let data = ViaLinkSDK.shared.getDeepLinkData() {
                        showLinkAlert(title: "Sync Pull Success", data: data)
                    } else {
                        showAlert(title: "DeepLink", message: "수신된 데이터 없음")
                    }
                }) {
                    Text("getDeepLinkData() - Sync")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    if let data = ViaLinkSDK.shared.getDeferredLinkData() {
                        showLinkAlert(title: "Deferred Sync Success", data: data)
                    } else {
                        showAlert(title: "Deferred Link", message: "매칭 결과 대기 중")
                    }
                }) {
                    Text("getDeferredLinkData() - Sync")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    Task {
                        do {
                            addLog("Awaiting deferred link...")
                            if let data = try await ViaLinkSDK.shared.awaitDeferredLinkData() {
                                showLinkAlert(title: "Deferred Link Data", data: data)
                            } else {
                                addLog("Organic Install (No match)")
                                showAlert(title: "Deferred Result", message: "결과 없음 (Organic)")
                            }
                        } catch {
                            addLog("Deferred Error: \(error.localizedDescription)")
                            showAlert(title: "Deferred Error", message: error.localizedDescription)
                        }
                    }
                }) {
                    Text("awaitDeferredLinkData() - Async")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    Task {
                        addLog("Awaiting deep link...")
                        do {
                            if let data = try await ViaLinkSDK.shared.awaitDeepLinkData() {
                                showLinkAlert(title: "Await DeepLink Success", data: data)
                            } else {
                                addLog("Await Timeout (No link)")
                                showAlert(title: "DeepLink Result", message: "수신된 딥링크가 없습니다.")
                            }
                        } catch {
                            addLog("Await Error: \(error.localizedDescription)")
                        }
                    }
                }) {
                    Text("awaitDeepLinkData() - Async Wait")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Tracking")
                .font(.headline)
            
            Button(action: {
                Task {
                    do {
                        addLog("Initiating payment...")
                        let result = try await ViaLinkSDK.shared.payment.initiated(
                            PaymentInitiatedArgs(
                                orderId: "ORDER-\(Int.random(in: 1000...9999))",
                                amount: 29900,
                                currency: "KRW",
                                paymentMethod: "apple_pay"
                            )
                        )
                        addLog("Payment Initiated: \(result.success ? "Success" : "Failed")")
                        showAlert(title: "Payment Result", message: "Success: \(result.success)\nEventId: \(result.paymentEventId)")
                    } catch {
                        addLog("Payment Error: \(error.localizedDescription)")
                        showAlert(title: "Payment Error", message: error.localizedDescription)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "creditcard.and.123")
                    Text("Initiate Payment (29,900 KRW)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Event Logs")
                    .font(.headline)
                Spacer()
                Button("Clear") { logs.removeAll() }
                    .font(.caption)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logs.reversed(), id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .padding(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.03))
                            .cornerRadius(4)
                    }
                }
            }
            .frame(height: 150)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
    }

    // MARK: - Helpers

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
        }
    }

    private func addLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        logs.append("[\(formatter.string(from: Date()))] \(message)")
    }

    private func setupCallbacks() {
        // 딥링크 콜백 등록
        ViaLinkSDK.shared.onDeepLink { data in
            self.lastLinkData = data
            self.addLog("DeepLink Received: \(data.path)")
            self.showLinkAlert(title: "New Deep Link", data: data)
        }
        
        // 디퍼드 딥링크 콜백 등록
        ViaLinkSDK.shared.onDeferredDeepLink { data, error in
            if let error = error {
                self.addLog("Deferred Match Failed: \(error.message)")
                if error.code == .timeout {
                    self.showAlert(title: "Deferred Timeout", message: "매칭 응답이 5초를 초과했습니다. organic install로 간주하거나 수동 확인이 필요합니다.")
                }
                return
            }
            
            if let data = data {
                self.lastLinkData = data
                self.addLog("Deferred Match Success: \(data.path)")
                self.showLinkAlert(title: "Deferred Deep Link", data: data)
            } else {
                self.addLog("Organic Install (No Match)")
            }
        }
    }

    private func createLink(type: String) {
        Task {
            do {
                addLog("Creating \(type) link...")
                let url = try await ViaLinkSDK.shared.createLink(
                    path: "/product/demo",
                    data: ["foo": "bar"],
                    campaign: "ios_sample",
                    linkType: type
                )
                addLog("Link Created: \(url)")
                showAlert(title: "Link Created", message: url)
            } catch {
                addLog("Create Link Failed: \(error.localizedDescription)")
                showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    private func showLinkAlert(title: String, data: DeepLinkData) {
        alertTitle = title
        alertMessage = "Path: \(data.path)\nParams: \(data.params)\nShortCode: \(data.shortCode ?? "N/A")"
        showingAlert = true
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}
