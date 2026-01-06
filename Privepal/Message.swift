import Foundation

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let thoughtDuration: Int? // nil for user
}
