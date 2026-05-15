import SwiftUI

/// A strip showing queued messages above the chat input composer.
/// Each row has a ↪ icon, the message preview, and Send Now / Edit / Delete actions.
struct MessageQueueView: View {
    let queue: [QueuedMessage]
    var onSendNow: (UUID) -> Void
    var onEdit: (UUID) -> Void
    var onDelete: (UUID) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            ForEach(queue) { item in
                MessageQueueRow(
                    item: item,
                    onSendNow: { onSendNow(item.id) },
                    onEdit: { onEdit(item.id) },
                    onDelete: { onDelete(item.id) }
                )
                if item.id != queue.last?.id {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
        .background(theme.cardBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.cardBorder.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(
            color: Color.black.opacity(theme.isDark ? 0.25 : 0.07),
            radius: 6, x: 0, y: 2
        )
    }
}

private struct MessageQueueRow: View {
    let item: QueuedMessage
    var onSendNow: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 10) {
            // Queue icon
            Image(systemName: "arrow.turn.down.right")
                .scaledFont(size: 13, weight: .medium)
                .foregroundStyle(theme.textTertiary)
                .frame(width: 20, alignment: .center)

            // Message preview (truncated)
            Text(item.text)
                .scaledFont(size: 14)
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Action buttons
            HStack(spacing: 4) {
                // Send Now
                Button {
                    Haptics.play(.light)
                    onSendNow()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .scaledFont(size: 20)
                        .foregroundStyle(theme.brandPrimary)
                }
                .accessibilityLabel("Send now")
                .buttonStyle(.plain)

                // Edit
                Button {
                    Haptics.play(.light)
                    onEdit()
                } label: {
                    Image(systemName: "pencil.circle")
                        .scaledFont(size: 20)
                        .foregroundStyle(theme.textSecondary)
                }
                .accessibilityLabel("Edit")
                .buttonStyle(.plain)

                // Delete
                Button {
                    Haptics.play(.light)
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle")
                        .scaledFont(size: 20)
                        .foregroundStyle(theme.textTertiary)
                }
                .accessibilityLabel("Remove from queue")
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
