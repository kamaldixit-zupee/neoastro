import SwiftUI
import AVKit

/// Full-screen story viewer. Pages horizontally between stories; each story
/// shows its own progress bar at the top and auto-advances after a fixed
/// duration (5 s for images; tied to the video for videos). Tap-left /
/// tap-right to skip. Drag down to dismiss.
struct AstrologerStoriesView: View {
    let astrologerName: String
    let stories: [AstrologerStory]
    @Binding var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double = 0
    @State private var isPaused: Bool = false

    private let imageDuration: TimeInterval = 5.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if stories.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("No stories yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(stories.enumerated()), id: \.element.id) { idx, story in
                        StoryPage(story: story, isActive: idx == selectedIndex, isPaused: isPaused)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                tapZones
                progressOverlay
                topBar
            }
        }
        .task(id: selectedIndex) {
            await runStoryTimer()
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(astrologerName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.leading, 4)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 56)
            Spacer()
        }
    }

    private var progressOverlay: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(0..<stories.count, id: \.self) { idx in
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(height: 3)
                        .overlay(alignment: .leading) {
                            GeometryReader { geo in
                                Capsule()
                                    .fill(.white)
                                    .frame(
                                        width: geo.size.width * widthFraction(forIndex: idx),
                                        height: 3
                                    )
                            }
                            .frame(height: 3)
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 44)

            Spacer()
        }
    }

    /// Two invisible halves of the screen — tap left to go back, right to
    /// advance. Long-press anywhere pauses.
    private var tapZones: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { goBack() }
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { goForward() }
        }
        .ignoresSafeArea()
        .gesture(
            LongPressGesture(minimumDuration: 0.18)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onChanged { _ in isPaused = true }
                .onEnded { _ in isPaused = false }
        )
    }

    // MARK: - Logic

    private func widthFraction(forIndex idx: Int) -> CGFloat {
        if idx < selectedIndex { return 1 }
        if idx > selectedIndex { return 0 }
        return CGFloat(progress)
    }

    private func goForward() {
        guard !stories.isEmpty else { return }
        if selectedIndex < stories.count - 1 {
            withAnimation(.smooth(duration: 0.2)) {
                selectedIndex += 1
            }
        } else {
            dismiss()
        }
    }

    private func goBack() {
        guard !stories.isEmpty else { return }
        if selectedIndex > 0 {
            withAnimation(.smooth(duration: 0.2)) {
                selectedIndex -= 1
            }
        } else {
            // Restart current story.
            progress = 0
        }
    }

    private func runStoryTimer() async {
        progress = 0
        let frames = 60
        let step = imageDuration / Double(frames)
        for i in 1...frames {
            try? await Task.sleep(for: .seconds(step))
            if isPaused { return }
            progress = Double(i) / Double(frames)
        }
        if !isPaused {
            goForward()
        }
    }
}

// MARK: - Single page

private struct StoryPage: View {
    let story: AstrologerStory
    let isActive: Bool
    let isPaused: Bool

    var body: some View {
        ZStack {
            if story.isVideo, let url = story.mediaURL {
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            } else if let url = story.mediaURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit()
                    case .failure:
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundStyle(.orange)
                            Text("Couldn't load")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    case .empty:
                        ProgressView().tint(.white).controlSize(.large)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text("No media")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            if let caption = story.caption, !caption.isEmpty, isActive {
                VStack {
                    Spacer()
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.black.opacity(0.45), in: .rect(cornerRadius: 14))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 56)
                }
            }
        }
    }
}
