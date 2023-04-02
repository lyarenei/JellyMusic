import AVFoundation
import Combine
import Foundation
import OSLog

enum PlayerState: String {
    case inactive, playing, paused
}

enum PlayerError: Error {
    case emptyQueue, tempFileError, noData(itemId: String)
}

class AudioPlayer: ObservableObject {
    @Published
    var playerState: PlayerState = .inactive

    @Published
    var queue: [String] = []

    @Published
    var currentItemId: String?

    @Published
    var currentTime: TimeInterval = 0

    private let audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var playbackTimer: Timer?
    private var skipRequested = false

    init() {
        audioEngineSetup()

        // Set interruption handler
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
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

    func play() async throws {
        if currentItemId == nil {
            try await prepareNextItem()
        }

        scheduleAudio()
        resume()
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
        queue.removeAll()
        currentItemId = nil
        audioFile = nil
        stopPlaybackTimer()
        Logger.player.debug("Player is inactive")
    }

    func skipToNext() async throws {
        Logger.player.debug("Requested skip to next item")
        skipRequested = true
        playerNode.stop()
        playerNode.reset()
        try await playNextItem()
    }

    func insertItem(_ itemID: String, at index: Int) {
        Logger.player.debug("Adding item to queue: \(itemID)")
        queue.insert(itemID, at: index)
    }

    func insertItems(_ itemIds: [String], at index: Int) {
        queue.insert(contentsOf: itemIds, at: index)
    }

    func removeItem(at index: Int) {
        if index >= 0 && index < queue.count {
            queue.remove(at: index)
        }
    }

    func append(itemId: String) {
        Logger.player.debug("Adding item to queue: \(itemId)")
        queue.append(itemId)
    }

    func append(itemIds: [String]) {
        queue.append(contentsOf: itemIds)
    }

    private func prepareNextItem() async throws {
        guard queue.isNotEmpty else {
            stop()
            throw PlayerError.emptyQueue
        }

        currentItemId = queue.removeFirst()
        Logger.player.debug("Next item will be played: \(self.currentItemId ?? "no-id")")
        audioFile = try await getItemAudioFile(by: currentItemId!)
    }

    private func playNextItem() async throws {
        try await prepareNextItem()
        stopPlaybackTimer()
        try await play()
    }

    private func scheduleAudio() {
        Logger.player.debug("Scheduling audio file to play")
        // Xcode suggestion is for iOS 15
        playerNode.scheduleFile(audioFile!, at: nil) {
            Task(priority: .background) {
                if self.skipRequested {
                    self.skipRequested = false
                } else {
                    try await self.playNextItem()
                }
            }
        }
    }

    /// Handles interruption from a call or Siri
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) { resume() }
        default:
            break
        }
    }

    private func getItemAudioFile(by itemID: String) async throws -> AVAudioFile? {
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
                    self.currentTime = Double(playerTime.sampleTime) / playerTime.sampleRate
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
