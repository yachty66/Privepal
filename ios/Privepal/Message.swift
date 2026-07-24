import Foundation

struct Message: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    let isUser: Bool
    var ttftMs: Int?
}

struct Chat: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var model: String
    var messages: [Message]
    var updatedAt: Date

    static func new(model: String) -> Chat {
        Chat(title: "New chat", model: model, messages: [], updatedAt: .now)
    }
}

enum AIModel: String, CaseIterable, Identifiable {
    case fast = "gpt-oss-120b"
    case smart = "kimi-k2.6"

    var id: String { rawValue }
    var label: String {
        switch self {
        case .fast: "Fast"
        case .smart: "Smart"
        }
    }
}
