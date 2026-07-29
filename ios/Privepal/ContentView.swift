import SwiftUI

struct ContentView: View {
    @State private var viewModel = ChatViewModel()
    @FocusState private var isFocused: Bool
    // launch-arg overrides support App Store screenshot automation
    @State private var showShield = CommandLine.arguments.contains("-shield")
    @State private var showChats = CommandLine.arguments.contains("-chats")

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
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color(white: 0.09)))
                }

                Spacer()

                // Model toggle
                HStack(spacing: 4) {
                    ForEach(AIModel.allCases) { m in
                        Button {
                            viewModel.model = m
                        } label: {
                            Text(m.label)
                                .font(.system(size: 14))
                                .foregroundStyle(
                                    viewModel.model == m
                                        ? .white : Color(white: 0.6)
                                )
                                .padding(.vertical, 6)
                                .padding(.horizontal, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewModel.model == m
                                            ? Color(white: 0.28) : .clear)
                                )
                        }
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(white: 0.09))
                )

                Spacer()

                Button {
                    showShield = true
                } label: {
                    Image(systemName: "shield")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            viewModel.ready ? .green : .white
                        )
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color(white: 0.09)))
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
                                                .font(.system(size: 14))
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
                                    // web-style bordered verification card
                                    VStack(spacing: 14) {
                                        VerifyRingView(
                                            step: viewModel.verifyStep,
                                            channelOk: viewModel.channelOk
                                        )
                                        if viewModel.verifyStep == 3 {
                                            HStack(spacing: 4) {
                                                Text("See what is proven vs. what you take on trust")
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color(white: 0.45))
                                        }
                                    }
                                    .padding(20)
                                    .frame(maxWidth: 360)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color(white: 0.04))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color(white: 0.16), lineWidth: 1)
                                    )
                                    .onTapGesture { showShield = true }
                                    .padding(.top, 4)

                                    if viewModel.verifyStep == 3 {
                                        HStack(spacing: 5) {
                                            Text("Open source. Don't trust us? Audit the code with")
                                                .foregroundStyle(Color(white: 0.45))
                                            ForEach(
                                                Array(AuditLinks.links.enumerated()),
                                                id: \.offset
                                            ) { i, link in
                                                Link(link.name, destination: link.url)
                                                    .foregroundStyle(Color(white: 0.65))
                                                    .underline()
                                                if i < AuditLinks.links.count - 1 {
                                                    Text("·").foregroundStyle(Color(white: 0.4))
                                                }
                                            }
                                        }
                                        .font(.system(size: 11.5))
                                    }
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
                    .font(.system(size: 15))
                    .foregroundStyle(Color(white: 0.38))
                    .padding(.top, 10)
                    .padding(.leading, 12)
                    .onTapGesture { isFocused = true }
                }
                TextField("", text: $viewModel.messageText, axis: .vertical)
                    .font(.system(size: 15))
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
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.white)
                    )
                    .opacity(viewModel.ready ? 1 : 0.4)
                }
                .disabled(!viewModel.ready)
                .transition(.scale.combined(with: .opacity))
                .padding(.bottom, 3)
                .padding(.trailing, 3)
            }
        }
        .padding(6)
        .animation(.bouncy, value: viewModel.messageText.isEmpty)
        .animation(.bouncy, value: viewModel.isLoading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(white: 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(white: 0.18), lineWidth: 1)
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
                    .font(.system(size: 15))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .padding(.leading, 60)
            .contextMenu {
                Button {
                    UIPasteboard.general.string = message.text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    MarkdownText(text: message.text)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(white: 0.11))
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                Spacer(minLength: 30)
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = message.text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        }
    }
}

struct ChatListView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmWipe = false
    @State private var chatToDelete: Chat?
    @State private var search = ""

    // client-side search across titles and full message content;
    // nothing ever leaves the device
    private var visibleChats: [Chat] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return viewModel.store.chats }
        return viewModel.store.chats.filter { c in
            c.title.lowercased().contains(q)
                || c.messages.contains { $0.text.lowercased().contains(q) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(visibleChats) { chat in
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
                    if let i = indexSet.first {
                        chatToDelete = visibleChats[i]
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
            .searchable(text: $search, prompt: "Search chats")
            .confirmationDialog(
                "Delete \"\(chatToDelete?.title ?? "this chat")\"? This cannot be undone.",
                isPresented: Binding(
                    get: { chatToDelete != nil },
                    set: { if !$0 { chatToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete chat", role: .destructive) {
                    if let c = chatToDelete { viewModel.deleteChat(c) }
                    chatToDelete = nil
                }
            }
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
