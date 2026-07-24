import SwiftUI

// The verification ceremony: a ring fills per step, turns green with a
// drawn checkmark once the encrypted channel is confirmed live.
struct VerifyRingView: View {
    let step: Int
    let channelOk: Bool?

    private let steps = [
        "Connecting securely",
        "Verifying sealed hardware",
        "Locking encrypted channel",
    ]

    private var progress: CGFloat { CGFloat(min(step, 3)) / 3.0 }
    private var done: Bool { step == 3 }
    private var success: Bool { done && channelOk == true }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(white: 0.15), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        success ? Color.green : .white,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.7), value: progress)
                    .animation(.easeOut(duration: 0.4), value: success)

                if success {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }
                if done && channelOk != true {
                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 96, height: 96)
            .animation(.bouncy(duration: 0.5), value: success)

            if !done {
                VStack(spacing: 4) {
                    Text("VERIFYING PRIVATE CHANNEL")
                        .font(.system(size: 10, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(Color(white: 0.4))
                    Text(steps[min(step, 2)] + "...")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(white: 0.7))
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    statusRow(
                        ok: channelOk == true,
                        text: channelOk == true
                            ? "Encrypted channel to sealed AI hardware: live"
                            : "Encrypted channel down. Chat is disabled."
                    )
                    statusRow(ok: true, text: "Chats stored only on this device")
                    statusRow(ok: true, text: "No account, no tracking")
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeOut(duration: 0.4), value: done)
    }

    private func statusRow(ok: Bool, text: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(ok ? .white : Color(white: 0.3))
                .frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(Color(white: 0.7))
        }
    }
}
