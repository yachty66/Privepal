//
//  ContentView.swift
//  Privepal
//
//  Created by Max Hager on 12/29/25.
//

import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let thoughtDuration: Int? // nil for user
}

struct ContentView: View {
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20)) // Slightly smaller icon
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("Anthropic: Claude 3...")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // Disclaimer Text (Pinned, always visible only in empty state)
            if messages.isEmpty {
                Text("AI models can make mistakes. Always check\nimportant info.")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            }
            
            // Scrollable Content Area (Enables swipe dismissal)
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if messages.isEmpty {
                            Spacer()
                                
                            // Center glowing orb/dots
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.white.opacity(0.2), .clear],
                                            center: .center,
                                            startRadius: 5,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 160, height: 160)
                                    
                                Image(systemName: "circle.dotted") // Approximating the dot pattern
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundStyle(.white.opacity(0.1))
                            }
                            
                            Spacer()
                        } else {
                            // Chat Messages
                            LazyVStack(spacing: 24) {
                                ForEach(messages) { message in
                                    if message.isUser {
                                        // User Message
                                        HStack {
                                            Spacer()
                                            Text(message.text)
                                                .font(.system(size: 17))
                                                .foregroundStyle(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color(white: 0.15))
                                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                        .stroke(.white.opacity(0.1), lineWidth: 0.5)
                                                )
                                        }
                                        .padding(.leading, 60)
                                    } else {
                                        // AI Response
                                        VStack(alignment: .leading, spacing: 8) {
                                            if let duration = message.thoughtDuration {
                                                HStack(spacing: 4) {
                                                    Text("Thought for \(duration) seconds")
                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 10, weight: .bold))
                                                }
                                                .font(.caption)
                                                .foregroundStyle(.gray)
                                            }
                                            
                                            Text(message.text)
                                                .font(.system(size: 17))
                                                .foregroundStyle(.white)
                                                .lineSpacing(4)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.trailing, 20)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 100)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: messages.isEmpty ? geometry.size.height : nil)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    isFocused = false
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Bottom Input Bar
            VStack(alignment: .leading, spacing: 10) {
                // Text Input Area
                ZStack(alignment: .topLeading) {
                    if messageText.isEmpty {
                        Text("Message")
                            .font(.system(size: 19))
                            .foregroundStyle(Color(white: 0.25))
                            .padding(.top, 4)
                            .padding(.leading, 4)
                            .onTapGesture {
                                isFocused = true
                            }
                    }
                    TextField("", text: $messageText, axis: .vertical)
                        .font(.system(size: 19))
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                        .padding(.leading, 4)
                        .focused($isFocused)
                }
                .frame(minHeight: 36)
                
                // Tools Row
                HStack(spacing: 12) {
                    // Plus Button
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                    }
                    
                    // Search Pill
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.system(size: 17))
                            Text("Search")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .capsule)
                    }
                    
                    Spacer()
                    
                    // Mic Button or Send Button
                    if messageText.isEmpty {
                        Button(action: {}) {
                            Image(systemName: "mic")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.tint(.white.opacity(0.1)).interactive(), in: .circle)
                        }
                    } else {
                        Button(action: {
                            let userMsg = Message(text: messageText, isUser: true, thoughtDuration: nil)
                            messages.append(userMsg)
                            let responseText = "Are you tying a knot, shoelaces, or\nsomething else? I'm happy to help if you\nneed instructions on how to tie something\nspecific!"
                            messageText = ""
                            
                            // Delayed response simulation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let aiMsg = Message(text: responseText, isUser: false, thoughtDuration: 3)
                                withAnimation {
                                    messages.append(aiMsg)
                                }
                            }
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(.white))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(12)
            .animation(.bouncy, value: messageText.isEmpty) // Animate the transition
            .glassEffect(.regular.tint(.black.opacity(0.6)), in: .rect(cornerRadius: 38))
            .overlay(
                RoundedRectangle(cornerRadius: 38)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8) // Small bottom padding relative to safe area
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
