import SwiftUI

/// 경량 Toast — 상단에서 슬라이드인, 1.6초 후 자동 디스미스.
struct ToastBar: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
            Text(message)
                .font(.subheadline)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.85))
        )
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct ToastHostModifier: ViewModifier {
    @State private var current: String?
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let msg = current {
                ToastBar(message: msg)
                    .padding(.top, 8)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .onReceive(NotificationCenter.default.publisher(for: .viaLinkToast)) { note in
            guard let msg = note.object as? String else { return }
            show(msg)
        }
    }

    private func show(_ message: String) {
        dismissTask?.cancel()
        current = message
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if !Task.isCancelled {
                current = nil
            }
        }
    }
}

extension View {
    func viaLinkToastHost() -> some View {
        modifier(ToastHostModifier())
    }
}
