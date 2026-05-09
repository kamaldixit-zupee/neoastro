import SwiftUI

struct ConsultChatView: View {
    let astrologer: AstrologerAPI

    private var astroPrice: Int { Int(astrologer.price ?? 0) }
    private var astroIsOnline: Bool {
        if let state = astrologer.status?.state { return state == "ONLINE" }
        return astrologer.isActive ?? false
    }
    private var astroGradient: [String] {
        let palettes = [
            ["#7B2CBF", "#FF8FAB"],
            ["#3A86FF", "#8338EC"],
            ["#F72585", "#B5179E"],
            ["#06A77D", "#3A86FF"],
            ["#FFB703", "#FB8500"],
            ["#7209B7", "#F72585"]
        ]
        let i = abs(astrologer._id.hashValue) % palettes.count
        return palettes[i]
    }

    @Environment(\.dismiss) private var dismiss
    @State private var messages: [Message] = ConsultChatView.seedMessages
    @State private var draft: String = ""
    @State private var elapsed: Int = 0
    @State private var timer: Timer?
    @FocusState private var inputFocused: Bool

    struct Message: Identifiable, Hashable {
        let id = UUID()
        let text: String
        let isMe: Bool
        let date: Date
    }

    private static let seedMessages: [Message] = [
        .init(text: "Namaste 🙏 Welcome to NeoAstro.", isMe: false, date: .now.addingTimeInterval(-60)),
        .init(text: "Please share your name, date and time of birth to begin.", isMe: false, date: .now.addingTimeInterval(-55))
    ]

    var body: some View {
        ZStack {
            CosmicBackground()

            VStack(spacing: 0) {
                chatHeader
                messagesList
                composer
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(10)
            }
            .buttonStyle(.glass)
            .clipShape(Circle())

            AvatarView(name: astrologer.name, imageURL: astrologer.imageURL, gradient: astroGradient, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(astrologer.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    Circle()
                        .fill(astroIsOnline ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(timerText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            Button {} label: {
                Image(systemName: "phone.fill")
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(10)
            }
            .buttonStyle(.glass)
            .clipShape(Circle())

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(10)
            }
            .buttonStyle(.glass)
            .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.clear)
    }

    private var timerText: String {
        let m = elapsed / 60
        let s = elapsed % 60
        return String(format: "%02d:%02d • ₹%d/min", m, s, astroPrice)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg, gradient: astroGradient)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation(.smooth) { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("", text: $draft, prompt: Text("Type a message…").foregroundColor(.white.opacity(0.5)), axis: .vertical)
                .lineLimit(1...4)
                .font(.body)
                .foregroundStyle(.white)
                .tint(AppTheme.pinkAccent)
                .focused($inputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)

            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(14)
            }
            .buttonStyle(.glass)
            .clipShape(Circle())
            .tint(AppTheme.pinkAccent)
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .padding(.top, 6)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messages.append(.init(text: text, isMe: true, date: .now))
        draft = ""

        Task {
            try? await Task.sleep(for: .seconds(1.0))
            let reply = autoReply(for: text)
            messages.append(.init(text: reply, isMe: false, date: .now))
        }
    }

    private func autoReply(for input: String) -> String {
        let lower = input.lowercased()
        if lower.contains("name") { return "Thanks! And your date of birth please?" }
        if lower.contains("birth") || lower.contains("dob") { return "Got it. Your time of birth, as accurate as possible?" }
        if lower.contains("career") { return "Saturn's transit favours steady work. Avoid hasty decisions till next month." }
        if lower.contains("love") || lower.contains("relationship") { return "Venus is well-placed for you. Honest conversations will heal most things." }
        return "Tell me one specific area — career, relationships, finance, health — and I'll go deeper."
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

private struct MessageBubble: View {
    let message: ConsultChatView.Message
    let gradient: [String]

    var body: some View {
        HStack {
            if message.isMe { Spacer(minLength: 40) }

            bubbleContent
                .frame(maxWidth: 280, alignment: message.isMe ? .trailing : .leading)

            if !message.isMe { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        let base = Text(message.text)
            .font(.body)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

        if message.isMe {
            base
                .background(
                    LinearGradient(
                        colors: [AppTheme.pinkAccent, Color(hex: "#7209B7")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: .rect(cornerRadius: 18)
                )
        } else {
            base
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
        }
    }
}
