import Foundation
import Observation

// Persists chats on-device only, encrypted at rest via iOS Data Protection
// (complete file protection: readable only while the device is unlocked).
@Observable
class ChatStore {
    var chats: [Chat] = []

    private static var fileURL: URL {
        let dir = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        try? FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true
        )
        return dir.appendingPathComponent("chats.json")
    }

    init() {
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let decoded = try? JSONDecoder().decode([Chat].self, from: data)
        else { return }
        chats = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(chats) else { return }
        try? data.write(
            to: Self.fileURL,
            options: [.atomic, .completeFileProtection]
        )
    }

    func upsert(_ chat: Chat) {
        if let i = chats.firstIndex(where: { $0.id == chat.id }) {
            chats[i] = chat
        } else {
            chats.insert(chat, at: 0)
        }
        chats.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func delete(_ chat: Chat) {
        chats.removeAll { $0.id == chat.id }
        save()
    }

    func wipeAll() {
        chats.removeAll()
        try? FileManager.default.removeItem(at: Self.fileURL)
    }
}
