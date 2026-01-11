import Foundation
import OSLog

/// A simple logging utility to track application behavior, especially network requests and responses.
/// Logs are visible in the Xcode Console (Cmd+Shift+Y) and the macOS Console app.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.privepal.app"
    
    /// Logger category for network-related events
    static let network = Logger(subsystem: subsystem, category: "Network")
    
    /// Logger category for general application events
    static let general = Logger(subsystem: subsystem, category: "General")
    
    /// Logs a chat request being sent to the server
    /// - Parameters:
    ///   - model: The model identifier being used
    ///   - messages: The array of messages being sent
    static func logRequest(model: String, messages: [Message]) {
        network.debug("------------------- 📤 API REQUEST START -------------------")
        network.debug("Model: \(model)")
        network.debug("Message Count: \(messages.count)")
        
        for (index, msg) in messages.enumerated() {
            let role = msg.isUser ? "USER" : "ASSISTANT"
            network.debug("Message[\(index)] [\(role)]: \(msg.text)")
        }
        network.debug("-------------------- 📤 API REQUEST END --------------------")
    }

    /// Logs a raw request with any details
    static func logRawRequest(model: String, details: String) {
        network.debug("------------------- 📤 API REQUEST START -------------------")
        network.debug("Model: \(model)")
        network.debug("Details: \(details)")
        network.debug("-------------------- 📤 API REQUEST END --------------------")
    }
    
    /// Logs a raw dictionary or any object being sent/received (for debugging types)
    static func logDebug(_ label: String, _ value: Any) {
        network.debug("🔍 DEBUG [\(label)]: \(String(describing: value))")
    }
    
    /// Logs a response received from the server
    /// - Parameter content: The text content received
    static func logResponse(_ content: String) {
        network.debug("------------------- 📥 API RESPONSE START ------------------")
        network.debugContent(content)
        network.debug("-------------------- 📥 API RESPONSE END -------------------")
    }
    
    /// Logs a streaming chunk
    static func logStreamingChunk(_ chunk: String) {
        network.debug("🌊 Stream Chunk: \(chunk)")
    }
    
    /// Logs an error with context
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: Description of where or why the error occurred
    static func logError(_ error: Error, context: String) {
        network.error("❌ ERROR in \(context): \(error.localizedDescription)")
        if let decodingError = error as? DecodingError {
            network.error("   Detail: \(String(describing: decodingError))")
        }
    }
}

private extension Logger {
    func debugContent(_ content: String) {
        // Break long content into chunks if necessary for console readability
        self.debug("\(content)")
    }
}
