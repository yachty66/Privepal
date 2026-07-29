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
        // "-demo" launch argument seeds sample chats for App Store screenshots
        if CommandLine.arguments.contains("-demo"), store.chats.isEmpty {
            seedDemoData()
        }
        activeChatId = store.chats.first?.id
        if CommandLine.arguments.contains("-chat2"), store.chats.count > 1 {
            activeChatId = store.chats[1].id
        }
        runVerification()
    }

    private func seedDemoData() {
        var travel = Chat.new(model: AIModel.fast.rawValue)
        travel.title = "Weekend trip to the Alps"
        travel.messages = [
            Message(text: "Plan me a 2-day hiking trip near Garmisch, nothing too hard", isUser: true),
            Message(
                text: "Here's a relaxed 2-day plan:\n\nDay 1: Partnach Gorge and Eckbauer\nStart at the Olympic ski stadium, walk the dramatic Partnach Gorge (about 30 minutes), then take the easy trail up to Eckbauer Alm for lunch with a view. Cable car back down.\n\nDay 2: Eibsee loop\nTrain to Eibsee and walk the lake loop, about 7 km of flat, stunning trail beneath the Zugspitze. Finish with a swim spot on the north shore.\n\nBoth days are beginner-friendly with mountain-hut food along the way. Want me to add rain alternatives?",
                isUser: false, ttftMs: 214
            ),
        ]
        var health = Chat.new(model: AIModel.smart.rawValue)
        health.title = "Question I'd rather keep private"
        health.messages = [
            Message(text: "I've been having trouble sleeping and I don't want this saved anywhere", isUser: true),
            Message(
                text: "Understood, and just so you know: this conversation exists only on your phone.\n\nA few evidence-backed things that help most people:\n\n1. Fixed wake time, even on weekends. It anchors your whole rhythm.\n2. No screens in the last 30 minutes, dim, boring light instead.\n3. If you can't sleep after 20 minutes, get up and read something dull until drowsy.\n4. Caffeine has a 6-hour half-life. A 4 pm coffee is still half active at 10 pm.\n\nIf this has lasted more than a month, a doctor can rule out the medical causes. Want a simple wind-down routine to try this week?",
                isUser: false, ttftMs: 189
            ),
        ]
        var code = Chat.new(model: AIModel.fast.rawValue)
        code.title = "Explain confidential computing"
        code.messages = [
            Message(text: "how do you keep my messages private?", isUser: true),
            Message(
                text: "Your messages are processed inside sealed hardware:\n\n1. On-device storage: your chats live only on this iPhone, encrypted at rest.\n2. Sealed inference: the AI runs in confidential-computing enclaves. The memory is encrypted with keys held in the silicon itself.\n3. Verified hardware: before anything is sent, the hardware cryptographically proves what code it is running.\n\nNobody can read your conversations. Not the operator, not the datacenter, not even Privepal.",
                isUser: false, ttftMs: 203
            ),
        ]
        store.chats = [code, health, travel]
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
