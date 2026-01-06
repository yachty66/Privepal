import Foundation

protocol ChatServiceProtocol {
    func getResponse(for messages: [Message]) async throws -> String
}

class TinfoilService: ChatServiceProtocol {
    func getResponse(for messages: [Message]) async throws -> String {
        // Simulating network delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // This is where the real Tinfoil API call will go eventually
        return "This is a hardcoded response from the new TinfoilService architecture!"
    }
}
