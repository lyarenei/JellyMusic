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

    private var cancellables: Cancellables = []

    init(preview: Bool = false) {
        guard !preview else { return }
        subscribeToPlayerState()
        subscribeToCurrentItem()
        subscribeToCurrentTime()
    }

    // MARK: - Playback controls

    func play() async throws {
        try await audioPlayer.play()
    }

    func pause() {
        audioPlayer.pause()
    }

    func resume() {
        audioPlayer.resume()
    }

    func stop() {
        audioPlayer.stop()
        playbackQueue.removeAll()
    }

    func playNow(itemId: String) async throws {
        stop()
        try await enqueue(itemId)
        try await play()
    }

    func skipForward() async throws {
        guard playbackQueue.isNotEmpty else { return }
        try await audioPlayer.skipToNext()
        let previousSong = playbackQueue.removeFirst()
        playbackHistory.insert(previousSong, at: 0)
    }

    func skipBackward() async throws {
        guard playbackHistory.isNotEmpty else { return }
        let nextSong = playbackHistory.removeFirst()
        try await enqueue(nextSong.uuid, at: 0)
        try await audioPlayer.skipToNext()
        playbackQueue.insert(nextSong, at: 0)
    }

    // MARK: - Queuing controls

    func enqueue(_ itemId: String, at index: Int? = nil) async throws {
        guard let song = await SongRepository.shared.getSong(by: itemId) else {
            Logger.player.debug("Could not find song for ID: \(itemId)")
            return
        }

        await MainActor.run {
            if let index = index {
                self.audioPlayer.insertItem(itemId, at: index)
                self.playbackQueue.insert(song, at: index)
                return
            }

            self.audioPlayer.append(itemId: itemId)
            self.playbackQueue.append(song)
        }
    }

    // MARK: - Subscribers

    private func subscribeToCurrentItem() {
        audioPlayer.$currentItemId.sink { [weak self] nextItemId in
            guard let self = self else { return }
            Task(priority: .background) {
                await MainActor.run {
                    if let currentSong = self.currentSong {
                        self.playbackHistory.insert(currentSong, at: 0)
                        Logger.player.debug("Added track \(currentSong.uuid) to playback history")
                    }

                    guard let nextItemId = nextItemId else {
                        Logger.player.debug("Next track ID is nil, will not do anything")
                        return
                    }

                    guard self.playbackQueue.isNotEmpty else {
                        print("Playback queue is empty")
                        return
                    }
                    self.currentSong = self.playbackQueue.removeFirst()
                }
            }
        }
        .store(in: &cancellables)
    }

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
}
