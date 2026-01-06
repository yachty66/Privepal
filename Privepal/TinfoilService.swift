import Foundation
import TinfoilAI
import OpenAI

protocol ChatServiceProtocol {
    func getResponse(for messages: [Message]) async throws -> String
}

class TinfoilService: ChatServiceProtocol {
    private var client: TinfoilAI?
    
    func getResponse(for messages: [Message]) async throws -> String {
        // 1. Initialize client if needed
        if client == nil {
            let apiKey = ProcessInfo.processInfo.environment["TINFOIL_API_KEY"] ?? Secrets.tinfoilApiKey
            client = try await TinfoilAI.create(apiKey: apiKey)
        }
        
        guard let client = client else {
            throw NSError(domain: "TinfoilService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create Tinfoil client"])
        }
        
        // 2. Map messages to Tinfoil format
        let queryMessages: [ChatQuery.ChatCompletionMessageParam] = messages.map { msg in
            if msg.isUser {
                return .user(.init(content: .string(msg.text)))
            } else {
                return .assistant(.init(content: .textContent(msg.text)))
            }
        }
        
        // 3. Prepare the query
        let chatQuery = ChatQuery(
            messages: queryMessages,
            model: "kimi-k2-thinking"
        )
        
        // 4. Make the request
        let response = try await client.chats(query: chatQuery)
        
        // 5. Extract and return the content
        if let content = response.choices.first?.message.content {
            return content
        } else {
            throw NSError(domain: "TinfoilService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No response content received"])
        }
    }
}

