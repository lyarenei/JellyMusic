import SFSafeSymbols
import SwiftUI

struct PlayButton: View {
    @ObservedObject
    var player: MusicPlayer

    let text: String?
    let itemId: String

    init(
        _ text: String? = nil,
        for itemId: String,
        player: MusicPlayer = .shared
    ) {
        self.text = text
        self.itemId = itemId
        _player = ObservedObject(wrappedValue: player)
    }

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemSymbol: .playFill)
            if let text = text {
                Text(text)
            }
        }
    }

    func action() {
        Task(priority: .userInitiated) {
            do {
                try await player.playNow(itemId: itemId)
            } catch {
                print("Failed to start playback")
            }
        }
    }
}

struct PlayPauseButton: View {
    @ObservedObject
    var player: MusicPlayer

    let text: String?

    init(
        _ text: String? = nil,
        player: MusicPlayer = .shared
    ) {
        self.text = text
        _player = ObservedObject(wrappedValue: player)
    }

    var body: some View {
        Button {
            player.isPlaying ? player.pause() : player.resume()
        } label: {
            Image(systemSymbol: player.isPlaying ? .pauseFill : .playFill)
            if let text = text {
                Text(text)
            }
        }
    }
}

#if DEBUG
struct PlayButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayButton(for: PreviewData.songs.first!.uuid, player: .init(preview: true))
        PlayPauseButton(player: .init(preview: true))
            .previewDisplayName("Play/Pause button")
    }
}
#endif
