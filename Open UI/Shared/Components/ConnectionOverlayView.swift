import SwiftUI

/// Non-dismissible overlay shown when the server or internet connection is lost.
///
/// Appears after a 1.5s debounce (controlled by ``ServerConnectionMonitor``)
/// to avoid flickering on transient blips. Blocks user interaction with the
/// app content behind it, and automatically dismisses when the connection
/// is restored.
///
/// When the current server is unreachable and other saved servers exist,
/// a "Switch Server" button is shown so the user is never fully stuck.
struct ConnectionOverlayView: View {
    let monitor: ServerConnectionMonitor

    /// Called when the user taps "Switch Server".
    /// The caller should transition `AuthViewModel.phase` to `.serverSwitcher`.
    var onSwitchServer: (() -> Void)? = nil

    @Environment(\.theme) private var theme

    /// Elapsed time since disconnect, updated every second.
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        if monitor.isShowingOverlay {
            ZStack {
                // Semi-transparent background blocking interaction
                Color.black.opacity(0.55)
                    .ignoresSafeArea()

                // Centered card
                VStack(spacing: Spacing.lg) {
                    // Animated icon
                    iconView
                        .padding(.top, Spacing.sm)

                    // Title
                    Text(monitor.disconnectTitle)
                        .scaledFont(size: 20, weight: .semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    // Message
                    Text(monitor.disconnectMessage)
                        .scaledFont(size: 14)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    // Status row: spinner + attempt counter
                    statusRow

                    // Elapsed time
                    if let since = monitor.disconnectedSince {
                        Text(formattedElapsed(since: since))
                            .scaledFont(size: 12)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    // "Switch Server" escape hatch — only when current server is down
                    // (not internet down) and the user has other saved servers.
                    if monitor.connectionState == .serverDown,
                       monitor.canSwitchServer,
                       let onSwitchServer {
                        Button(action: onSwitchServer) {
                            Label("Switch Server", systemImage: "arrow.left.arrow.right.circle")
                                .scaledFont(size: 14, weight: .medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.18))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Switch to a different server"))
                    }
                }
                .padding(Spacing.xl)
                .frame(maxWidth: 300)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            }
            .transition(.opacity.animation(.easeInOut(duration: AnimDuration.medium)))
            .onAppear { startTimer() }
            .onDisappear { stopTimer() }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("\(monitor.disconnectTitle). \(monitor.disconnectMessage)"))
            .accessibilityAddTraits(.isModal)
        }
    }

    // MARK: - Icon

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 72, height: 72)

            Image(systemName: monitor.disconnectIcon)
                .scaledFont(size: 28, weight: .medium)
                .foregroundStyle(.white.opacity(0.9))
                .symbolEffect(.pulse, isActive: monitor.connectionState != .connected)
        }
    }

    // MARK: - Status Row

    private var statusRow: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(.white)
                .controlSize(.small)

            if monitor.reconnectAttempt > 1 {
                Text("Attempt \(monitor.reconnectAttempt)")
                    .scaledFont(size: 13, weight: .medium)
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                Text(monitor.connectionState == .internetDown
                     ? "Waiting for connection…"
                     : "Reconnecting…")
                    .scaledFont(size: 13, weight: .medium)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        updateElapsed()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateElapsed()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsed() {
        if let since = monitor.disconnectedSince {
            elapsedTime = Date().timeIntervalSince(since)
        }
    }

    private func formattedElapsed(since: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(since))
        if seconds < 60 {
            return "Disconnected \(seconds)s ago"
        } else {
            let minutes = seconds / 60
            return "Disconnected \(minutes)m ago"
        }
    }
}
