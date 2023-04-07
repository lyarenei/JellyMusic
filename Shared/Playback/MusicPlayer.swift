import AVFoundation
import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
final class MusicPlayer: ObservableObject {
    public static let shared = MusicPlayer()

    @ObservedObject
    private var audioPlayer: AudioPlayer = .init()

    @Published
    var currentSong: Song? = nil

    @Published
    var playbackQueue: [Song] = []

    @Published
    var playbackHistory: [Song] = []

    @Published
    var isPlaying: Bool = false

    @Published
    var currentTime: TimeInterval = 0

    private var playTask: Task<Void, Never>?

    private var cancellables: Cancellables = []

    init(preview: Bool = false) {
        guard !preview else { return }

        subscribeToPlayerState()
//        subscribeToCurrentItem()
        subscribeToCurrentTime()

        // Set interruption handler
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    // MARK: - Playback controls
    func pause() {
        audioPlayer.pause()
    }

    func resume() {
        switch audioPlayer.playerState {
        case .inactive:
            guard let currentSong = currentSong else { return }
            Task(priority: .userInitiated) {
//                try await enqueue(currentSong.uuid, at: 0)
                try await audioPlayer.play(song: currentSong)
            }
        case .paused:
            audioPlayer.resume()
        case .playing:
            return
        }
    }

    private func stop() {
        audioPlayer.stop()
        playbackQueue.removeAll()
    }

    func play(itemId: String) async throws {
        guard let song = await SongRepository.shared.getSong(by: itemId) else {
            Logger.player.debug("Could not find song for ID: \(itemId)")
            return
        }
        try await play(song: song)
    }

    func play(song: Song) async throws {
        try await play(songs: [song])
    }

    func play(songs: [Song]) async throws {
        playbackQueue = songs
        try await playNextSong()
    }

    func skipForward() async throws {
        guard playbackQueue.isNotEmpty else { return }
        let nextSong = playbackQueue.removeFirst()
        playbackHistory.insert(nextSong, at: 0)
        try await playNextSong()
    }

    func skipBackward() async throws {
        guard playbackHistory.isNotEmpty else { return }
        let previousSong = playbackHistory.removeFirst()
        playbackQueue.insert(previousSong, at: 0)
        try await playNextSong()
    }

    private func playNextSong() async throws {
        guard playbackQueue.isNotEmpty else { return }
        let nextSong = playbackQueue.removeFirst()
        playTask?.cancel()
        playTask = Task {
            do {
                audioPlayer.stop()
                try await audioPlayer.play(song: nextSong)
                try await skipForward()
            } catch {
                Logger.player.error("Failed to play song: \(nextSong.uuid)")
            }
        }
    }

    // MARK: - Queuing controls
    func enqueue(itemId: String, position: EnqueuePosition) async throws {
        guard let song = await SongRepository.shared.getSong(by: itemId) else {
            Logger.player.debug("Could not find song for ID: \(itemId)")
            return
        }

        await MainActor.run {
            switch position {
            case .next:
                playbackQueue.insert(song, at: 0)
            case .last:
                playbackQueue.append(song)
            }
        }
    }

    // MARK: - Subscribers
    private func subscribeToPlayerState() {
        audioPlayer.$playerState.sink { [weak self] curState in
            guard let self = self else { return }
            Task(priority: .background) {
                await MainActor.run {
                    switch curState {
                    case .playing:
                        self.isPlaying = true
                    default:
                        self.isPlaying = false
                    }
                }
            }
        }
        .store(in: &cancellables)
    }

    private func subscribeToCurrentTime() {
        audioPlayer.$currentTime.sink { [weak self] curTime in
            guard let self = self else { return }
            Task(priority: .background) {
                await MainActor.run { self.currentTime = curTime.rounded(.toNearestOrAwayFromZero) }
            }
        }
        .store(in: &cancellables)
    }

    /// Handles interruption from a call or Siri
    @objc
    private func handleInterruption(notification: Notification) {
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

    enum EnqueuePosition {
        case next
        case last
    }
}
