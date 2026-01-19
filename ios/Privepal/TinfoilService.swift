import Foundation
import TinfoilAI
import OpenAI

protocol ChatServiceProtocol {
    func getResponse(for messages: [Message]) async throws -> String
    func getStreamingResponse(for messages: [Message]) -> AsyncThrowingStream<String, Error>
}

class TinfoilService: ChatServiceProtocol {
    private var client: TinfoilAI?
    
    private func getClient() async throws -> TinfoilAI {
        if let client = client { return client }
        let apiKey = ProcessInfo.processInfo.environment["TINFOIL_API_KEY"] ?? Secrets.tinfoilApiKey
        let newClient = try await TinfoilAI.create(apiKey: apiKey)
        self.client = newClient
        return newClient
    }
    
    func getResponse(for messages: [Message]) async throws -> String {
        let client = try await getClient()
        
        let queryMessages: [ChatQuery.ChatCompletionMessageParam] = messages.map { msg in
            if msg.isUser {
                return .user(.init(content: .string(msg.text)))
            } else {
                return .assistant(.init(content: .textContent(msg.text)))
            }
        }
        
        let chatQuery = ChatQuery(
            messages: queryMessages,
            model: "gpt-oss-120b"
        )
        
        let response = try await client.chats(query: chatQuery)
        
        if let content = response.choices.first?.message.content {
            return content
        } else {
            throw NSError(domain: "TinfoilService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No response content received"])
        }
    }
    
    func getStreamingResponse(for messages: [Message]) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let client = try await getClient()
                    
                    let queryMessages: [ChatQuery.ChatCompletionMessageParam] = messages.map { msg in
                        if msg.isUser {
                            return .user(.init(content: .string(msg.text)))
                        } else {
                            return .assistant(.init(content: .textContent(msg.text)))
                        }
                    }
                    
                    let chatQuery = ChatQuery(
                        messages: queryMessages,
                        model: "gpt-oss-120b"
                    )
                    
                    for try await result in client.chatsStream(query: chatQuery) {
                        if let content = result.choices.first?.delta.content {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}


