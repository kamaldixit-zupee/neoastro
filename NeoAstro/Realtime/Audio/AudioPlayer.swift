import Foundation
import AVFoundation
import Observation

/// Single global audio-message player. Only one bubble plays at a time —
/// tapping a second bubble stops the first. Lives at app scope so playback
/// survives view rebuilds inside the chat.
@Observable
@MainActor
final class AudioPlayer {
    static let shared = AudioPlayer()

    /// Identifier of the currently-playing message (chat message id), or
    /// `nil` when nothing is playing.
    var playingId: String?

    /// Progress 0…1 for the currently-playing message.
    var progress: Double = 0

    /// Total duration of the currently-playing message in seconds.
    var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var delegate: PlayerDelegate?
    private var tickTask: Task<Void, Never>?

    private init() {}

    func play(messageId: String, url: URL) {
        if playingId == messageId, player?.isPlaying == true {
            stop()
            return
        }
        stop()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            let delegate = PlayerDelegate { [weak self] in
                Task { @MainActor in self?.stop() }
            }
            player.delegate = delegate
            player.prepareToPlay()
            guard player.play() else {
                AppLog.warn(.chat, "AVAudioPlayer.play() returned false")
                return
            }
            self.player = player
            self.delegate = delegate
            self.playingId = messageId
            self.duration = player.duration
            self.progress = 0
            startTicking()
            AppLog.info(.chat, "audio playback start id=\(messageId) duration=\(Int(player.duration))s")
        } catch {
            AppLog.error(.chat, "audio playback failed to start", error: error)
        }
    }

    func stop() {
        tickTask?.cancel()
        tickTask = nil
        player?.stop()
        player = nil
        delegate = nil
        playingId = nil
        progress = 0
        duration = 0
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, let player = self.player else { return }
                if player.duration > 0 {
                    self.progress = player.currentTime / player.duration
                }
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    private final class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            onFinish()
        }
    }
}
