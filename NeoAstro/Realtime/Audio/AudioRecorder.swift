import Foundation
import AVFoundation
import Observation

/// Press-and-hold voice-note recorder. Wraps `AVAudioRecorder` and exposes
/// just enough state for the in-chat overlay UI.
@Observable
@MainActor
final class AudioRecorder {

    enum State { case idle, requestingPermission, recording, finishing }

    var state: State = .idle
    var elapsedSeconds: TimeInterval = 0
    var levelNormalized: Double = 0    // 0…1, drives the waveform pulse
    var lastError: String?

    private var recorder: AVAudioRecorder?
    private var startedAt: Date?
    private var meteringTask: Task<Void, Never>?

    /// Hard cap so we don't accidentally record long audio. RN side caps at
    /// ~60 s; mirror that.
    let maxDurationSeconds: TimeInterval = 60

    // MARK: - Public

    /// Start a recording. Resolves to `true` when capture began, `false` if
    /// permission was denied or session setup failed.
    @discardableResult
    func start() async -> Bool {
        guard state == .idle else { return false }
        state = .requestingPermission
        lastError = nil

        let granted = await requestMicPermission()
        guard granted else {
            state = .idle
            lastError = "Microphone permission required"
            return false
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let url = makeFileURL()
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 22_050.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.prepareToRecord()
            guard recorder.record() else {
                throw NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "AVAudioRecorder.record() returned false"])
            }
            self.recorder = recorder
            startedAt = .now
            state = .recording
            startMetering()
            AppLog.info(.chat, "voice recording started url=\(url.lastPathComponent)")
            return true
        } catch {
            state = .idle
            lastError = error.localizedDescription
            AppLog.error(.chat, "voice recording failed to start", error: error)
            return false
        }
    }

    /// Stop and return the captured audio.
    /// Returns `nil` if there was no active recording or it was too short.
    func stopAndCommit() async -> CapturedAudio? {
        guard state == .recording, let recorder, let startedAt else {
            cancel()
            return nil
        }
        state = .finishing
        recorder.stop()
        meteringTask?.cancel()
        meteringTask = nil

        let duration = Date().timeIntervalSince(startedAt)
        let url = recorder.url
        defer { resetSession() }

        // Discard accidental tap-and-release recordings shorter than ~0.6 s.
        guard duration >= 0.6 else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let captured = CapturedAudio(url: url, data: data, duration: duration)
            AppLog.info(.chat, "voice recording stopped duration=\(Int(duration))s bytes=\(data.count)")
            return captured
        } catch {
            AppLog.error(.chat, "voice recording read failed", error: error)
            return nil
        }
    }

    /// Cancel without committing — drops the temp file.
    func cancel() {
        meteringTask?.cancel()
        meteringTask = nil
        if let recorder {
            recorder.stop()
            try? FileManager.default.removeItem(at: recorder.url)
        }
        recorder = nil
        startedAt = nil
        elapsedSeconds = 0
        levelNormalized = 0
        state = .idle
        resetSession()
    }

    // MARK: - Internal

    private func requestMicPermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted: return true
        case .denied:  return false
        case .undetermined:
            return await withCheckedContinuation { cont in
                session.requestRecordPermission { granted in
                    cont.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }

    private func startMetering() {
        meteringTask?.cancel()
        meteringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.tickMetering()
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    private func tickMetering() {
        guard let recorder, let startedAt else { return }
        recorder.updateMeters()
        // -160..0 dB range → 0..1 normalised, with a soft floor so the bar
        // moves visibly even in quiet environments.
        let dB = recorder.averagePower(forChannel: 0)
        let clamped = max(-50, min(0, dB))
        levelNormalized = (Double(clamped) + 50.0) / 50.0

        let elapsed = Date().timeIntervalSince(startedAt)
        elapsedSeconds = elapsed
        if elapsed >= maxDurationSeconds {
            // Auto-stop at the hard cap. Caller observes `state` flip to
            // `.idle` if they were not the one who triggered stop.
            Task { _ = await self.stopAndCommit() }
        }
    }

    private func resetSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func makeFileURL() -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("voice-notes", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(UUID().uuidString).m4a")
    }
}

struct CapturedAudio {
    let url: URL
    let data: Data
    let duration: TimeInterval
}
