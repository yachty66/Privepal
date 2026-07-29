import Foundation

// One-click "audit us with your own AI" deep links, shared between the
// empty state and the shield screen. Mirrors the web app's lib/audit.ts.
enum AuditLinks {
    static let prompt = "privepal.com is a private AI chat that claims: chat history is stored only client-side, no tracking and no analytics, a CSP blocks all third-party network connections, and messages are relayed to confidential-compute inference without being logged or stored. Fetch https://privepal.com/audit-bundle.txt : it contains the complete source code of the privacy-critical files of the running app. Verify each claim against the actual code and give an honest verdict, including what cannot be verified from source code alone."

    static var links: [(name: String, url: URL)] {
        let q = prompt.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) ?? ""
        return [
            ("Claude", URL(string: "https://claude.ai/new?q=\(q)")!),
            ("ChatGPT", URL(string: "https://chatgpt.com/?q=\(q)")!),
        ]
    }
}
