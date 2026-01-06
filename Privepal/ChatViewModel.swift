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
        messageText = ""
        isLoading = true
        
        // 3. Get AI response with streaming
        Task {
            do {
                // Create placeholders for the AI message
                await MainActor.run {
                    let aiMsg = Message(text: "", isUser: false, thoughtDuration: nil)
                    self.messages.append(aiMsg)
                }
                
                let stream = chatService.getStreamingResponse(for: messages.dropLast()) // Send history except the empty AI message
                
                for try await chunk in stream {
                    await MainActor.run {
                        if let lastIndex = self.messages.indices.last {
                            self.messages[lastIndex].text += chunk
                        }
                        // Stop loading once we start receiving content
                        if self.isLoading {
                            self.isLoading = false
                        }
                    }
                }
                
                await MainActor.run {
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