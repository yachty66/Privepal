import SwiftUI
import TinfoilAI
import OpenAI

struct TinfoilAPITest: View {
    @State private var responseText: String = "Tap 'Test API' to make a request..."
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tinfoil API Test")
                .font(.title)
                .fontWeight(.bold)
            
            Button(action: {
                Task {
                    await testTinfoilAPI()
                }
            }) {
                Text(isLoading ? "Loading..." : "Test API")
                    .padding()
                    .background(isLoading ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !errorMessage.isEmpty {
                        Text("Error:")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text("Response:")
                        .font(.headline)
                    Text(responseText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .padding()
    }
    
    func testTinfoilAPI() async {
        isLoading = true
        errorMessage = ""
        responseText = "Making request..."
        
        do {
            // Create Tinfoil client
            let apiKey = ProcessInfo.processInfo.environment["TINFOIL_API_KEY"] ?? Secrets.tinfoilApiKey
            
            if apiKey.isEmpty || apiKey == "YOUR_API_KEY_HERE" {
                errorMessage = "Please set your Tinfoil API key in Privepal/Secrets.swift"
                responseText = "Configuration needed"
                isLoading = false
                return
            }
            
            let client = try await TinfoilAI.create(
                apiKey: apiKey,
                onVerification: { document in
                    guard let document = document else { return }
                    print("Security verified: \(document.securityVerified)")
                    
                    // Log verification steps
                    print("Fetch Digest: \(document.steps.fetchDigest.status)")
                    print("Verify Code: \(document.steps.verifyCode.status)")
                    print("Verify Enclave: \(document.steps.verifyEnclave.status)")
                    print("Compare Measurements: \(document.steps.compareMeasurements.status)")
                }
            )
            
            // Create a simple chat query
            // Trying "kimi-k2-thinking" as it is a primary example in Tinfoil docs
            let chatQuery = ChatQuery(
                messages: [
                    .user(.init(content: .string("Hello! Can you tell me a short joke?")))
                ],
                model: "kimi-k2-thinking" 
            )

            print("🚀 Sending request to Tinfoil with model: \(chatQuery.model ?? "default")...")
            
            // Make the request
            let response = try await client.chats(query: chatQuery)

            
            // Extract the response text
            if let choice = response.choices.first,
               let content = choice.message.content {
                responseText = content
                print("Response received: \(content)")
            } else {
                responseText = "No response content received"
            }
            
        } catch let decodingError as DecodingError {
            // This will help us see exactly what's missing in the JSON
            errorMessage = "Decoding Error: \(decodingError)"
            responseText = "The server response didn't match the expected format."
            print("Detailed Decoding Error: \(decodingError)")
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            responseText = "Request failed. See error above."
            print("Error making request: \(error)")
        }

        
        isLoading = false
    }
}

// Preview for SwiftUI Canvas
struct TinfoilAPITest_Previews: PreviewProvider {
    static var previews: some View {
        TinfoilAPITest()
    }
}
