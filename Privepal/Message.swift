import Foundation

struct Message: Identifiable {
    let id = UUID()
    var text: String
    let isUser: Bool
    let thoughtDuration: Int? // nil for user
}
