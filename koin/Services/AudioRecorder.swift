
import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioRecorder: NSObject, ObservableObject {

    @Published private(set) var isRecording = false
    @Published private(set) var selectedURL: URL?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0

    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?

    // MARK: - Recording

    func startRecording(to url: URL) async -> Bool {
        guard !isRecording else { return false }

        let permission = await AVAudioApplication
            .requestRecordPermission()

        guard permission else {
            errorMessage = "Accesso al microfono negato."
            return false
        }

        do {
            stopPlayback()

            let session = AVAudioSession.sharedInstance()

            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker]
            )

            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey:
                    AVAudioQuality.high.rawValue
            ]

            let newRecorder = try AVAudioRecorder(
                url: url,
                settings: settings
            )

            guard newRecorder.record() else {
                errorMessage = "Impossibile avviare la registrazione."
                return false
            }

            recorder = newRecorder
            isRecording = true

            return true

        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        recorder?.stop()
        recorder = nil
        isRecording = false

        try? AVAudioSession.sharedInstance()
            .setActive(false)
    }

    // MARK: - Playback

    func togglePlayback(for recording: Recording) {
        guard !isRecording else { return }

        if selectedURL == recording.url {
            if isPlaying {
                pausePlayback()
            } else {
                resumePlayback()
            }

            return
        }

        stopPlayback()

        do {
            let session = AVAudioSession.sharedInstance()

            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(
                contentsOf: recording.url
            )

            newPlayer.delegate = self
            newPlayer.prepareToPlay()

            guard newPlayer.play() else {
                errorMessage = "Impossibile riprodurre l'audio."
                return
            }

            player = newPlayer
            selectedURL = recording.url
            duration = newPlayer.duration
            currentTime = 0
            isPlaying = true

            startProgressTimer()

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func pausePlayback() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
    }

    private func resumePlayback() {
        guard let player else { return }

        guard player.play() else {
            errorMessage = "Impossibile riprendere l'audio."
            return
        }

        isPlaying = true
        startProgressTimer()
    }

    func stopPlayback() {
        stopProgressTimer()

        player?.delegate = nil
        player?.stop()
        player = nil

        selectedURL = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }

    // MARK: - Progress

    private func startProgressTimer() {
        stopProgressTimer()

        progressTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let player = self.player else {
                    return
                }

                self.currentTime = player.currentTime
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }

        let safeTime = min(
            max(time, 0),
            player.duration
        )

        player.currentTime = safeTime
        currentTime = safeTime
    }
}

// MARK: - Player Delegate

extension AudioRecorder: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor [weak self] in
            self?.stopPlayback()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        let message = error?.localizedDescription
            ?? "Errore durante la riproduzione."

        Task { @MainActor [weak self] in
            self?.stopPlayback()
            self?.errorMessage = message
        }
    }
}
