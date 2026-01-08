//
//  ContentView.swift
//  Privepal
//
//  Created by Max Hager on 12/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = ChatViewModel()
    @FocusState private var isFocused: Bool
    @State private var showSettings: Bool = false
    @State private var showInfo: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: {
                    showInfo = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20)) // Slightly smaller icon
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("Tinfoil: GPT OSS 120B") //other models: "gpt-oss-120b", "kimi-k2-thinking"
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
                
                Button(action: {
                    viewModel.clearChat()
                }) {
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
            if viewModel.messages.isEmpty {
                Text("AI models can make mistakes. Always check\nimportant info.")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
            }
            
            // Scrollable Content Area (Enables swipe dismissal)
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            if viewModel.messages.isEmpty {
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
                                    ForEach(viewModel.messages) { message in
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
                                            .id(message.id)
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
                                                
                                                Text(LocalizedStringKey(message.text))
                                                    .font(.system(size: 17))
                                                    .foregroundStyle(.white)
                                                    .lineSpacing(4)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.trailing, 20)
                                            .id(message.id)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, geometry.size.height) // Allow scrolling items to top
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: viewModel.messages.isEmpty ? geometry.size.height : nil)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture {
                        isFocused = false
                    }
                    .onChange(of: viewModel.messages.count) {
                        guard !viewModel.messages.isEmpty else { return }
                        let lastMessage = viewModel.messages.last!
                        
                        withAnimation {
                            if lastMessage.isUser {
                                // User sent message: snap it to top
                                proxy.scrollTo(lastMessage.id, anchor: .top)
                            } else {
                                // AI replied: keep the User's message (context) at the top
                                if viewModel.messages.count >= 2 {
                                    let contextId = viewModel.messages[viewModel.messages.count - 2].id
                                    proxy.scrollTo(contextId, anchor: .top)
                                } else {
                                    proxy.scrollTo(lastMessage.id, anchor: .top)
                                }
                            }
                        }
                    }
                    .onChange(of: viewModel.messages.last?.text) {
                        guard !viewModel.messages.isEmpty else { return }
                        let lastMessage = viewModel.messages.last!
                        if !lastMessage.isUser {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isFocused) {
                        if isFocused, let lastId = viewModel.messages.last?.id {
                            // When keyboard opens, ensure we see the context
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    if let lastMsg = viewModel.messages.last, !lastMsg.isUser, viewModel.messages.count >= 2 {
                                         proxy.scrollTo(viewModel.messages[viewModel.messages.count - 2].id, anchor: .top)
                                    } else {
                                         proxy.scrollTo(lastId, anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Bottom Input Bar
            HStack(alignment: .bottom, spacing: 12) {
                // Text Input Area
                ZStack(alignment: .topLeading) {
                    if viewModel.messageText.isEmpty {
                        Text("Message")
                            .font(.system(size: 19))
                            .foregroundStyle(Color(white: 0.25))
                            .padding(.top, 10)
                            .padding(.leading, 12)
                            .onTapGesture {
                                isFocused = true
                            }
                    }
                    TextField("", text: $viewModel.messageText, axis: .vertical)
                        .font(.system(size: 19))
                        .foregroundStyle(.white)
                        .padding(.top, 10)
                        .padding(.leading, 12)
                        .padding(.bottom, 10)
                        .focused($isFocused)
                }
                .frame(minHeight: 44)
                
                // Send Button (Only visible when typing or loading)
                if !viewModel.messageText.isEmpty || viewModel.isLoading {
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.black)
                            }
                        }
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white))
                    }
                    .disabled(viewModel.isLoading)
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 4) // Align with bottom of text field
                }
            }
            .padding(6)
            .animation(.bouncy, value: viewModel.messageText.isEmpty) // Animate the transition
            .animation(.bouncy, value: viewModel.isLoading)
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
        // .sheet(isPresented: $showSettings) {
        //     SettingsView()
        // }
        .alert("Privacy by design", isPresented: $showInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your messages are processed using encrypted computing in the cloud, so the chat content stays encrypted while an answer is generated. We don’t store your conversations, and no one can read them.")
        }
    }
}

#Preview {
    ContentView()
}