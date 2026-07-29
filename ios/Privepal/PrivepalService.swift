import Foundation

// Talks to the Privepal backend, which relays to confidential compute
// (Privatemode) over an attested, end-to-end encrypted channel.
// No API keys live in this app.

enum PrivepalAPI {
    static let base = URL(string: "https://privepal.com")!
}

struct StreamDelta {
    var content: String?
    var reasoning: String?
}

struct ShieldStatus: Decodable {
    let proxyOk: Bool
    let models: [String]
}

protocol ChatServiceProtocol {
    func getStreamingResponse(for messages: [Message], model: String)
        -> AsyncThrowingStream<StreamDelta, Error>
    func shieldStatus() async throws -> ShieldStatus
    func serverReachable() async -> Bool
}

class PrivepalService: ChatServiceProtocol {

    func serverReachable() async -> Bool {
        let url = PrivepalAPI.base.appendingPathComponent("api/version")
        guard let (_, resp) = try? await URLSession.shared.data(from: url)
        else { return false }
        return (resp as? HTTPURLResponse)?.statusCode == 200
    }

    func shieldStatus() async throws -> ShieldStatus {
        let url = PrivepalAPI.base.appendingPathComponent("api/shield")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ShieldStatus.self, from: data)
    }

    func getStreamingResponse(
        for messages: [Message], model: String
    ) -> AsyncThrowingStream<StreamDelta, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var req = URLRequest(
                        url: PrivepalAPI.base.appendingPathComponent("api/chat")
                    )
                    req.httpMethod = "POST"
                    req.setValue(
                        "application/json", forHTTPHeaderField: "Content-Type"
                    )
                    let payload: [String: Any] = [
                        "model": model,
                        "messages": messages.map {
                            [
                                "role": $0.isUser ? "user" : "assistant",
                                "content": $0.text,
                            ]
                        },
                    ]
                    req.httpBody = try JSONSerialization.data(
                        withJSONObject: payload
                    )

                    let (bytes, response) = try await URLSession.shared.bytes(
                        for: req
                    )
                    guard let http = response as? HTTPURLResponse,
                          http.statusCode == 200
                    else {
                        let code =
                            (response as? HTTPURLResponse)?.statusCode ?? -1
                        throw NSError(
                            domain: "Privepal", code: code,
                            userInfo: [
                                NSLocalizedDescriptionKey: code == 429
                                    ? "Rate limit reached. Try again in a minute."
                                    : "Connection failed (\(code))."
                            ]
                        )
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let json = line.dropFirst(5).trimmingCharacters(
                            in: .whitespaces
                        )
                        if json == "[DONE]" { break }
                        guard let data = json.data(using: .utf8),
                              let obj = try? JSONSerialization.jsonObject(
                                  with: data
                              ) as? [String: Any],
                              let choices = obj["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"]
                                  as? [String: Any]
                        else { continue }
                        var out = StreamDelta()
                        out.content = delta["content"] as? String
                        out.reasoning =
                            (delta["reasoning"] as? String)
                            ?? (delta["reasoning_content"] as? String)
                        if out.content?.isEmpty == false
                            || out.reasoning?.isEmpty == false
                        {
                            continuation.yield(out)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
