import Foundation
import SFSafeSymbols
import SwiftUI

@MainActor
final class MusicPlayerController: ObservableObject {
    @ObservedObject
    var player: MusicPlayer

    @Published
    var playIcon: SFSymbol = .playFill

    private var cancellables: Cancellables = []

    init(
        player: MusicPlayer = .shared,
        preview: Bool = false
    ) {
        self._player = ObservedObject(wrappedValue: player)
        guard !preview else { return }
        subscribeToIsPlaying()
    }

    func onPlayPauseButton() {
        player.isPlaying ? player.pause() : player.resume()
    }

    func onSkipForward() {
        Task(priority: .userInitiated) {
            do {
                try await player.skipForward()
            } catch {
                print("Skip forward failed")
            }
        }
    }

    func onSkipBackward() {

    }

    private func subscribeToIsPlaying() {
        player.$isPlaying.sink { [weak self] isPlaying in
            guard let self = self else { return }
            self.playIcon = isPlaying ? .pauseFill : .playFill
        }
        .store(in: &cancellables)
    }
}
