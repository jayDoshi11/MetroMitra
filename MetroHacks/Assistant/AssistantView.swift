import SwiftUI

/// Chat with the on-device assistant: type or tap, and it does the task for you.
struct AssistantView: View {
    @State private var model: AssistantViewModel
    @FocusState private var inputFocused: Bool

    init(listViewModel: IncidentListViewModel) {
        _model = State(initialValue: AssistantViewModel(listViewModel: listViewModel))
    }

    private var canSend: Bool {
        !model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !model.isBusy
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            VStack(spacing: 0) {
                conversation
                if let last = model.messages.last, !last.isUser, !last.chips.isEmpty, !model.isBusy {
                    chipRow(last.chips)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                inputBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(tr("Assistant"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { model.reset() } label: { Image(systemName: "arrow.counterclockwise") }
                }
                ToolbarItem(placement: .topBarTrailing) { LanguageMenu() }
            }
        }
    }

    // MARK: - Conversation

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    header
                    ForEach(model.messages) { message in
                        bubble(message)
                            .id(message.id)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    if model.isBusy {
                        HStack(alignment: .bottom, spacing: 8) {
                            avatar
                            TypingIndicator()
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemGroupedBackground), in: bubbleShape(isUser: false))
                            Spacer(minLength: 40)
                        }
                        .id("typing")
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: model.messages.count)
            .onChange(of: model.messages.count) { _, _ in scrollToEnd(proxy) }
            .onChange(of: model.isBusy) { _, _ in scrollToEnd(proxy) }
            .onChange(of: inputFocused) { _, _ in scrollToEnd(proxy) }
        }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.25)) {
            if model.isBusy {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = model.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Image("LogoMark")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text("Metro Mitra").font(.headline)
            Text(tr("Report problems, check stations, find your nearest one — even offline."))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("English · ગુજરાતી · हिन्दी")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
        }
        .padding(.vertical, 8)
    }

    private var avatar: some View {
        Image("LogoMark")
            .resizable()
            .scaledToFill()
            .frame(width: 30, height: 30)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 0.5))
    }

    private func bubbleShape(isUser: Bool) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 18,
            bottomLeadingRadius: isUser ? 18 : 4,
            bottomTrailingRadius: isUser ? 4 : 18,
            topTrailingRadius: 18,
            style: .continuous
        )
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 48)
            } else {
                avatar
            }
            Text(message.text)
                .font(.body)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(message.isUser ? Color.white : Color.primary)
                .background(
                    message.isUser
                        ? AnyShapeStyle(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.8)],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                    in: bubbleShape(isUser: message.isUser)
                )
            if !message.isUser { Spacer(minLength: 48) }
        }
    }

    // MARK: - Chips + input

    private func chipRow(_ chips: [ChatChip]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips) { chip in
                    Button { model.tap(chip) } label: {
                        Text(chip.title)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(Color.accentColor.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        @Bindable var model = model

        return HStack(alignment: .bottom, spacing: 10) {
            TextField(tr("Type a message…"), text: $model.input, axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit { model.send() }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(inputFocused ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.2), lineWidth: 1)
                )

            Button { model.send() } label: {
                Image(systemName: "arrow.up")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(canSend ? Color.accentColor : Color.secondary.opacity(0.35), in: Circle())
            }
            .disabled(!canSend)
            .animation(.snappy, value: canSend)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.bar)
    }
}

/// Three bouncing dots shown while the assistant is "typing".
private struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 7, height: 7)
                    .offset(y: animate ? -3 : 3)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.15), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}
