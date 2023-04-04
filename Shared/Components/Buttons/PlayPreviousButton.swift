import SFSafeSymbols
import SwiftUI

struct PlayPreviousButton: View {
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
            action()
        } label: {
            Image(systemName: .backwardFill)
            if let text = text {
                Text(text)
            }
        }
    }

    func action() {
        Task(priority: .userInitiated) {
            do {
                try await player.skipBackward()
            } catch {
                print("Skip to previous track failed")
            }
        }
    }
}

#if DEBUG
struct PlayPreviousButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayPreviousButton(player: .init(preview: true))
    }
}
#endif
