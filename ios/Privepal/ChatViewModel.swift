import Foundation
import Observation

@Observable
class ChatViewModel {
    var store = ChatStore()
    var activeChatId: UUID?
    var messageText: String = ""
    var isLoading: Bool = false
    var isThinking: Bool = false
    var model: AIModel = .fast

    // verification ceremony
    var verifyStep: Int = 0
    var channelOk: Bool? = nil
    var ready: Bool { verifyStep == 3 && channelOk == true }

    private let service: ChatServiceProtocol
    private var streamTask: Task<Void, Never>?

    init(service: ChatServiceProtocol = PrivepalService()) {
        self.service = service
        activeChatId = store.chats.first?.id
        runVerification()
    }

    var activeChat: Chat? {
        guard let id = activeChatId else { return nil }
        return store.chats.first { $0.id == id }
    }

    func runVerification() {
        verifyStep = 0
        channelOk = nil
        Task { @MainActor in
            async let check: Void = {
                do {
                    let status = try await service.shieldStatus()
                    self.channelOk = status.proxyOk
                } catch {
                    self.channelOk = false
                }
            }()
            try? await Task.sleep(for: .milliseconds(900))
            verifyStep = 1
            try? await Task.sleep(for: .milliseconds(1100))
            verifyStep = 2
            await check
            try? await Task.sleep(for: .milliseconds(900))
            verifyStep = 3
        }
    }

    func newChat() {
        let chat = Chat.new(model: model.rawValue)
        store.upsert(chat)
        activeChatId = chat.id
    }

    func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading, ready else { return }

        var chat = activeChat ?? Chat.new(model: model.rawValue)
        if chat.messages.isEmpty {
            chat.title = String(text.prefix(40))
        }
        chat.model = model.rawValue
        chat.messages.append(Message(text: text, isUser: true))
        chat.updatedAt = .now
        store.upsert(chat)
        activeChatId = chat.id

        messageText = ""
        isLoading = true
        isThinking = false

        let history = chat.messages
        let chatId = chat.id
        let started = Date()

        streamTask = Task { @MainActor in
            var acc = ""
            var ttft: Int?
            do {
                var working = chat
                working.messages.append(Message(text: "", isUser: false))
                store.upsert(working)

                let stream = service.getStreamingResponse(
                    for: history, model: model.rawValue
                )
                for try await delta in stream {
                    if delta.reasoning != nil, acc.isEmpty {
                        isThinking = true
                    }
                    if let content = delta.content {
                        if ttft == nil {
                            ttft = Int(
                                Date().timeIntervalSince(started) * 1000
                            )
                            isThinking = false
                            isLoading = false
                        }
                        acc += content
                        if var current = store.chats.first(
                            where: { $0.id == chatId }
                        ), let last = current.messages.indices.last {
                            current.messages[last].text = acc
                            current.messages[last].ttftMs = ttft
                            current.updatedAt = .now
                            store.upsert(current)
                        }
                    }
                }
            } catch {
                if !Task.isCancelled,
                   var current = store.chats.first(where: { $0.id == chatId })
                {
                    let msg = "Something went wrong. \(error.localizedDescription)"
                    if let last = current.messages.indices.last,
                       !current.messages[last].isUser,
                       current.messages[last].text.isEmpty
                    {
                        current.messages[last].text = msg
                    } else {
                        current.messages.append(
                            Message(text: msg, isUser: false)
                        )
                    }
                    store.upsert(current)
                }
            }
            isLoading = false
            isThinking = false
        }
    }

    func stop() {
        streamTask?.cancel()
        isLoading = false
        isThinking = false
    }

    func deleteChat(_ chat: Chat) {
        store.delete(chat)
        if activeChatId == chat.id { activeChatId = store.chats.first?.id }
    }

    func wipeAll() {
        stop()
        store.wipeAll()
        activeChatId = nil
    }
}
