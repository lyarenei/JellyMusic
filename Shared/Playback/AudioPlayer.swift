import AVFoundation
import Combine
import Foundation
import OSLog

enum PlayerState: String {
    case inactive, playing, paused
}

enum PlayerError: Error {
    case tempFileError, noData(itemId: String)
}

final class AudioPlayer: ObservableObject {
    @Published
    private(set) var playerState: PlayerState = .inactive

    @Published
    private(set) var currentTime: TimeInterval = 0

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var playbackTimer: Timer?
    private var trackStartTime: TimeInterval = 0

    init() {
        audioEngineSetup()
    }

    private func audioEngineSetup() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        audioEngine.prepare()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try session.setActive(true)
            Logger.player.debug("Audio engine has been initialized")
        } catch {
            Logger.player.debug("Failed to initialize audio engine: \(error.localizedDescription)")
        }
    }

    func play(song: Song) async throws {
        Logger.player.debug("Playing song \(song.uuid)")
        let audioFile = try getItemAudioFile(by: song.uuid)
        self.audioFile = audioFile
        await withCheckedContinuation { continuation in
            playerNode.scheduleFile(audioFile, at: nil) {
                continuation.resume()
            }
            resume()
        }
    }

    func pause() {
        playerNode.pause()
        audioEngine.pause()
        playerState = .paused
        stopPlaybackTimer()
        Logger.player.debug("Player is paused")
    }

    func resume() {
        try? audioEngine.start()
        playerNode.play()
        playerState = .playing
        Task { await startPlaybackTimer() }
        Logger.player.debug("Player is playing")
    }

    func stop() {
        playerNode.stop()
        playerNode.reset()
        audioEngine.stop()
        playerState = .inactive
        audioFile = nil
        stopPlaybackTimer()
        currentTime = 0
        trackStartTime = 0
        Logger.player.debug("Player is inactive")
    }

    private func getItemAudioFile(by itemID: String) throws -> AVAudioFile {
        guard let url = FileRepository.shared.fileURL(for: itemID) else {
            throw PlayerError.noData(itemId: itemID)
        }

        do {
            return try AVAudioFile(forReading: url)
        } catch {
            Logger.player.debug("Failed to create file for playback: \(error)")
            throw PlayerError.tempFileError
        }
    }

    private func startPlaybackTimer() async {
        Logger.player.debug("Starting playback timer")
        await MainActor.run {
            // Note: Not using CADisplayLink becasue:
            // 1) It would result in too smooth updates for the seek bar (every 1s is preferable)
            // 2) Is not available for macOS (there is CVDisplayLink, but the above point still stands)
            playbackTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                guard let self else { return }
                if let lastRenderTime = self.playerNode.lastRenderTime,
                   let playerTime = self.playerNode.playerTime(forNodeTime: lastRenderTime) {
                    let currentTime = Double(playerTime.sampleTime) / playerTime.sampleRate
                    self.currentTime = currentTime - self.trackStartTime
                }
            }

            RunLoop.current.add(playbackTimer!, forMode: .common)
        }
    }

    private func stopPlaybackTimer() {
        Logger.player.debug("Stopping playback timer")
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}
