import SwiftUI

struct ContentView: View {
    @State private var viewModel = ChatViewModel()
    @FocusState private var isFocused: Bool
    @State private var showShield = false
    @State private var showChats = false

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button {
                    showChats = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }

                Spacer()

                // Model toggle
                HStack(spacing: 2) {
                    ForEach(AIModel.allCases) { m in
                        Button {
                            viewModel.model = m
                        } label: {
                            Text(m.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(
                                    viewModel.model == m ? .black : .white
                                )
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    Capsule().fill(
                                        viewModel.model == m ? .white : .clear
                                    )
                                )
                        }
                    }
                }
                .padding(3)
                .glassEffect(.regular, in: .capsule)

                Spacer()

                Button {
                    showShield = true
                } label: {
                    Image(systemName: "shield")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            viewModel.ready ? .green : .white
                        )
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 12)

            // Content
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            if let chat = viewModel.activeChat,
                               !chat.messages.isEmpty
                            {
                                LazyVStack(spacing: 12) {
                                    ForEach(chat.messages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                    if viewModel.isThinking {
                                        HStack {
                                            Text("thinking...")
                                                .font(
                                                    .system(
                                                        size: 13,
                                                        design: .monospaced
                                                    )
                                                )
                                                .foregroundStyle(
                                                    Color(white: 0.4)
                                                )
                                            Spacer()
                                        }
                                    }
                                    Color.clear.frame(height: 1).id("bottom")
                                }
                                .padding(.horizontal)
                            } else {
                                VStack(spacing: 20) {
                                    Image("Logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 72, height: 72)
                                        .opacity(
                                            viewModel.verifyStep < 3 ? 0.6 : 1
                                        )
                                    VStack(spacing: 6) {
                                        Text("Fast. Private. Yours.")
                                            .font(
                                                .system(
                                                    size: 22, weight: .medium
                                                )
                                            )
                                            .foregroundStyle(.white)
                                        Text(
                                            "Ask anything. Nobody can read it, not even us."
                                        )
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(white: 0.45))
                                    }
                                    VerifyRingView(
                                        step: viewModel.verifyStep,
                                        channelOk: viewModel.channelOk
                                    )
                                    .padding(.top, 4)
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: geometry.size.height - 140
                                )
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture { isFocused = false }
                    .onChange(of: viewModel.activeChat?.messages.last?.text) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
                .contentMargins(.bottom, 90, for: .scrollContent)
            }
        }
        .overlay(alignment: .bottom) {
            inputBar
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShield) {
            ShieldView(
                channelOk: viewModel.channelOk,
                chatCount: viewModel.store.chats.count,
                messageCount: viewModel.store.chats.reduce(0) {
                    $0 + $1.messages.count
                }
            )
        }
        .sheet(isPresented: $showChats) {
            ChatListView(viewModel: viewModel)
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ZStack(alignment: .topLeading) {
                if viewModel.messageText.isEmpty {
                    Text(
                        viewModel.ready
                            ? "Message Privepal"
                            : viewModel.verifyStep == 3
                                ? "Encrypted channel down"
                                : "Verifying private channel..."
                    )
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(Color(white: 0.3))
                    .padding(.top, 10)
                    .padding(.leading, 12)
                    .onTapGesture { isFocused = true }
                }
                TextField("", text: $viewModel.messageText, axis: .vertical)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .padding(.top, 10)
                    .padding(.leading, 12)
                    .padding(.bottom, 10)
                    .focused($isFocused)
            }
            .frame(minHeight: 44)

            if !viewModel.messageText.isEmpty || viewModel.isLoading {
                Button {
                    viewModel.isLoading
                        ? viewModel.stop() : viewModel.sendMessage()
                } label: {
                    ZStack {
                        if viewModel.isLoading {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.black)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.white))
                    .opacity(viewModel.ready ? 1 : 0.4)
                }
                .disabled(!viewModel.ready)
                .transition(.scale.combined(with: .opacity))
                .padding(.bottom, 4)
            }
        }
        .padding(6)
        .animation(.bouncy, value: viewModel.messageText.isEmpty)
        .animation(.bouncy, value: viewModel.isLoading)
        .glassEffect(
            .regular.tint(.black.opacity(0.6)), in: .rect(cornerRadius: 38)
        )
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
        .padding(.bottom, 8)
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        if message.isUser {
            HStack {
                Spacer()
                Text(message.text)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .padding(.leading, 60)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(
                    (try? AttributedString(
                        markdown: message.text,
                        options: .init(
                            interpretedSyntax:
                                .inlineOnlyPreservingWhitespace
                        )
                    )) ?? AttributedString(message.text)
                )
                .font(.system(size: 15))
                .foregroundStyle(Color(white: 0.9))
                .textSelection(.enabled)

                if let ttft = message.ttftMs {
                    Text("first token \(ttft)ms")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color(white: 0.35))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 20)
        }
    }
}

struct ChatListView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmWipe = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.store.chats) { chat in
                    Button {
                        viewModel.activeChatId = chat.id
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(chat.title)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(
                                chat.updatedAt.formatted(
                                    date: .abbreviated, time: .shortened
                                )
                            )
                            .font(.caption2)
                            .foregroundStyle(Color(white: 0.4))
                        }
                    }
                    .listRowBackground(Color(white: 0.08))
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        viewModel.deleteChat(viewModel.store.chats[i])
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmWipe = true
                    } label: {
                        Text("Wipe all chats from this device")
                    }
                    .listRowBackground(Color(white: 0.08))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.newChat()
                        dismiss()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .confirmationDialog(
                "Delete all chats from this device? This cannot be undone.",
                isPresented: $confirmWipe,
                titleVisibility: .visible
            ) {
                Button("Wipe everything", role: .destructive) {
                    viewModel.wipeAll()
                    dismiss()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
