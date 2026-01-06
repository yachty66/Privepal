import Foundation
import Observation

@Observable
class ChatViewModel {
    var messages: [Message] = []
    var messageText: String = ""
    var isLoading: Bool = false
    
    private let chatService: ChatServiceProtocol
    
    init(chatService: ChatServiceProtocol = TinfoilService()) {
        self.chatService = chatService
    }
    
    func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // 1. Add user message
        let userMsg = Message(text: trimmedText, isUser: true, thoughtDuration: nil)
        messages.append(userMsg)
        
        // 2. Clear input and start loading
        let currentInput = trimmedText
        messageText = ""
        isLoading = true
        
        // 3. Get AI response
        Task {
            do {
                let response = try await chatService.getResponse(for: messages)
                
                await MainActor.run {
                    let aiMsg = Message(text: response, isUser: false, thoughtDuration: 3) // Hardcoded thought duration for now
                    self.messages.append(aiMsg)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMsg = Message(text: "Error: \(error.localizedDescription)", isUser: false, thoughtDuration: nil)
                    self.messages.append(errorMsg)
                    self.isLoading = false
                }
            }
        }
    }
}
