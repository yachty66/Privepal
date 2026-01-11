#!/usr/bin/swift
import Foundation

print("🚀 Starting Tinfoil Test Script...")

func sendTinfoilRequest() async {
    // 1. Get API key
    let apiKey = "***REMOVED***"
    
    if apiKey.isEmpty {
        print("❌ Error: TINFOIL_API_KEY environment variable is not set.")
        print("💡 Usage: TINFOIL_API_KEY='your-key' swift HeyTest.swift")
        return
    }

    let model = "gpt-oss-120b"
    let endpoint = URL(string: "https://api.tinfoil.sh/v1/chat/completions")!
    
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let payload: [String: Any] = [
        "model": model,
        "messages": [
            ["role": "user", "content": "hello"]
        ]
    ]
    
    print("📡 Sending 'hello' to \(model)...")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type received.")
            return
        }
        
        if httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                print("\n✅ Success!")
                print("🤖 AI: \(content)")
            } else {
                let raw = String(data: data, encoding: .utf8) ?? "binary data"
                print("\n✅ Received 200 but couldn't parse JSON. Raw response: \(raw)")
            }
        } else {
            print("❌ Request failed with status code: \(httpResponse.statusCode)")
            let errorBody = String(data: data, encoding: .utf8) ?? "no body"
            print("Error details: \(errorBody)")
        }
    } catch {
        print("❌ Networking error: \(error.localizedDescription)")
    }
}

// Execute the async function
let semaphore = DispatchSemaphore(value: 0)
Task {
    await sendTinfoilRequest()
    semaphore.signal()
}
semaphore.wait()
