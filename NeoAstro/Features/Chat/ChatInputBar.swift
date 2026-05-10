import SwiftUI
import PhotosUI

struct ChatInputBar: View {
    @Binding var text: String
    @FocusState.Binding var focused: Bool
    @Bindable var recorder: AudioRecorder
    let onSend: () -> Void
    let onTypingTouch: () -> Void
    let onVoiceCommit: (CapturedAudio) -> Void
    let onImage: (Data) -> Void

    @State private var photoPick: PhotosPickerItem?
    @State private var isLoadingPhoto: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var willCancel: Bool = false

    private let cancelThreshold: CGFloat = -80

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 6) {
            if recorder.state == .recording || recorder.state == .finishing {
                VoiceRecorderOverlay(
                    recorder: recorder,
                    dragOffset: dragOffset,
                    willCancel: willCancel
                )
            }

            HStack(alignment: .bottom, spacing: 10) {
                photoPickerButton

                TextField(
                    "",
                    text: $text,
                    prompt: Text("Type a message…").foregroundColor(.white.opacity(0.45)),
                    axis: .vertical
                )
                .focused($focused)
                .lineLimit(1...4)
                .font(.subheadline)
                .foregroundStyle(.white)
                .tint(AppTheme.pinkAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)
                .onChange(of: text) { _, _ in onTypingTouch() }
                .disabled(recorder.state == .recording)

                trailingButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Photo picker

    private var photoPickerButton: some View {
        PhotosPicker(selection: $photoPick, matching: .images) {
            Group {
                if isLoadingPhoto {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 38, height: 38)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .tint(.white.opacity(0.18))
        .disabled(recorder.state == .recording || isLoadingPhoto)
        .onChange(of: photoPick) { _, newValue in
            guard let newValue else { return }
            Task { await loadPhoto(newValue) }
        }
    }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem) async {
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                onImage(data)
            }
        } catch {
            AppLog.error(.chat, "photo load failed", error: error)
        }
        photoPick = nil
    }

    // MARK: - Trailing send / mic

    @ViewBuilder
    private var trailingButton: some View {
        if canSend {
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(AppTheme.pinkAccent)
        } else {
            micButton
        }
    }

    private var micButton: some View {
        Image(systemName: recorder.state == .recording ? "waveform" : "mic.fill")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 38, height: 38)
            .glassEffect(
                .regular.tint(recorder.state == .recording ? .red.opacity(0.7) : AppTheme.pinkAccent.opacity(0.5)),
                in: .circle
            )
            .scaleEffect(recorder.state == .recording ? 1.08 : 1.0)
            .animation(.smooth, value: recorder.state)
            .gesture(holdToRecordGesture)
    }

    private var holdToRecordGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.15)
            .onEnded { _ in
                Task { await recorder.start() }
            }
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .second(_, let drag?):
                    dragOffset = drag.translation.width
                    willCancel = drag.translation.width < cancelThreshold
                default:
                    break
                }
            }
            .onEnded { _ in
                let cancelled = willCancel
                dragOffset = 0
                willCancel = false
                Task {
                    if cancelled {
                        recorder.cancel()
                    } else if let captured = await recorder.stopAndCommit() {
                        onVoiceCommit(captured)
                    } else {
                        recorder.cancel()
                    }
                }
            }
    }
}
