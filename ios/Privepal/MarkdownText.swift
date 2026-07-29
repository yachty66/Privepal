import SwiftUI

// Lightweight markdown renderer: splits code fences into monospaced boxes,
// renders headings, lists and inline markdown natively. No WebView, no
// dependencies, no network: consistent with the privacy posture.
struct MarkdownText: View {
    let text: String

    private enum Block: Identifiable {
        case paragraph(AttributedString)
        case heading(String)
        case code(String)
        case bullet([AttributedString])

        var id: UUID { UUID() }
    }

    private var blocks: [Block] {
        var out: [Block] = []
        // split on fenced code blocks first
        let parts = text.components(separatedBy: "```")
        for (i, part) in parts.enumerated() {
            if i % 2 == 1 {
                // inside a fence: drop an optional language tag on line 1
                var lines = part.split(separator: "\n", omittingEmptySubsequences: false)
                if let first = lines.first, !first.contains(" "), first.count < 20, lines.count > 1 {
                    lines.removeFirst()
                }
                let code = lines.joined(separator: "\n")
                    .trimmingCharacters(in: .newlines)
                if !code.isEmpty { out.append(.code(code)) }
            } else {
                out.append(contentsOf: textBlocks(part))
            }
        }
        return out
    }

    private func inline(_ s: String) -> AttributedString {
        (try? AttributedString(
            markdown: s,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(s)
    }

    private func textBlocks(_ segment: String) -> [Block] {
        var out: [Block] = []
        // group consecutive list lines, split paragraphs on blank lines
        var paragraph: [String] = []
        var bullets: [AttributedString] = []

        func flushParagraph() {
            let joined = paragraph.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { out.append(.paragraph(inline(joined))) }
            paragraph = []
        }
        func flushBullets() {
            if !bullets.isEmpty { out.append(.bullet(bullets)); bullets = [] }
        }

        for raw in segment.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flushParagraph(); flushBullets()
            } else if trimmed.hasPrefix("### ") || trimmed.hasPrefix("## ") || trimmed.hasPrefix("# ") {
                flushParagraph(); flushBullets()
                out.append(.heading(trimmed.drop(while: { $0 == "#" || $0 == " " }).description))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")
                || trimmed.range(of: #"^\d+\. "#, options: .regularExpression) != nil {
                flushParagraph()
                let content = trimmed.replacingOccurrences(
                    of: #"^(-|\*|\d+\.)\s+"#, with: "", options: .regularExpression)
                bullets.append(inline(content))
            } else {
                flushBullets()
                paragraph.append(line)
            }
        }
        flushParagraph(); flushBullets()
        return out
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(blocks) { block in
                switch block {
                case .paragraph(let s):
                    Text(s)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.9))
                case .heading(let s):
                    Text(s)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 2)
                case .code(let s):
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(s)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color(white: 0.85))
                            .padding(10)
                    }
                    .background(Color(white: 0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                case .bullet(let items):
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•").foregroundStyle(Color(white: 0.5))
                                Text(item)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(white: 0.9))
                            }
                        }
                    }
                }
            }
        }
    }
}
