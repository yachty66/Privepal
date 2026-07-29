import SwiftUI

// "Your privacy, itemized": what is proven, what is architecture,
// and what still needs trust. Mirrors privepal.com/shield.
struct ShieldView: View {
    let channelOk: Bool?
    let chatCount: Int
    let messageCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    item(
                        badge: channelOk == true ? .verified : .design,
                        title: "Encrypted channel to confidential hardware",
                        body: channelOk == true
                            ? "Live check passed: the encryption proxy has verified the AI hardware's cryptographic attestation and holds an end-to-end encrypted channel into it."
                            : "Live check unavailable right now. When the channel is down, chat does not work at all: there is no unencrypted fallback."
                    )
                    item(
                        badge: .verified,
                        title: "Chats live only on this device",
                        body: "This device holds \(chatCount) chat\(chatCount == 1 ? "" : "s") with \(messageCount) message\(messageCount == 1 ? "" : "s"), encrypted at rest by iOS Data Protection. We have no database for your conversations. Delete the app and they are gone forever."
                    )
                    item(
                        badge: .design,
                        title: "AI runs inside sealed hardware",
                        body: "Inference runs on NVIDIA H100 GPUs in confidential-computing mode inside AMD SEV-SNP encrypted VMs, operated by Privatemode (Edgeless Systems, Germany). Neither the operator nor the datacenter can read prompts, and nothing is retained after the response."
                    )
                    item(
                        badge: .design,
                        title: "No account, no tracking",
                        body: "No sign-up, no analytics, no third-party connections of any kind. There is nothing to link your conversations to you."
                    )
                    auditSection

                    item(
                        badge: .trust,
                        title: "Our relay server",
                        body: "Your message passes through our server on its way to the encrypted channel, and today you have to trust that we do not log it. We do not, but honesty requires the label. On our roadmap: verification moves into this app, so our server becomes a blind pipe."
                    )
                }
                .padding(20)
            }
            .background(Color.black)
            .navigationTitle("Your privacy, itemized")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private let auditPrompt = "privepal.com is a private AI chat that claims: chat history is stored only client-side, no tracking and no analytics, a CSP blocks all third-party network connections, and messages are relayed to confidential-compute inference without being logged or stored. Fetch https://privepal.com/audit-bundle.txt : it contains the complete source code of the privacy-critical files of the running app. Verify each claim against the actual code and give an honest verdict, including what cannot be verified from source code alone."

    private var auditLinks: [(String, URL)] {
        let q = auditPrompt.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) ?? ""
        return [
            ("Ask Claude", URL(string: "https://claude.ai/new?q=\(q)")!),
            ("Ask ChatGPT", URL(string: "https://chatgpt.com/?q=\(q)")!),
        ]
    }

    private var auditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Don't take our word for it")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
            Text("Our code is open source. One tap sends it to an AI you already trust, with the question: is this really as private as they claim?")
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.6))
            HStack(spacing: 10) {
                ForEach(auditLinks, id: \.0) { name, url in
                    Link(destination: url) {
                        Text(name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(white: 0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(white: 0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(white: 0.2), lineWidth: 1)
        )
    }

    private enum Badge {
        case verified, design, trust
        var label: String {
            switch self {
            case .verified: "VERIFIED LIVE"
            case .design: "BY DESIGN"
            case .trust: "YOU TRUST US"
            }
        }
    }

    private func item(badge: Badge, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(badge.label)
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        badge == .verified
                            ? AnyShapeStyle(.white)
                            : AnyShapeStyle(.clear)
                    )
                    .foregroundStyle(
                        badge == .verified ? .black : Color(white: 0.55)
                    )
                    .overlay(
                        Capsule().stroke(
                            Color(white: badge == .verified ? 0 : 0.35),
                            lineWidth: badge == .verified ? 0 : 0.5
                        )
                    )
                    .clipShape(Capsule())
            }
            Text(body)
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
