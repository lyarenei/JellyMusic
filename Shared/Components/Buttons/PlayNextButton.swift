import SFSafeSymbols
import SwiftUI

struct PlayNextButton: View {
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
            Image(systemName: .forwardFill)
            if let text = text {
                Text(text)
            }
        }
    }

    func action() {
        Task(priority: .userInitiated) {
            do {
                try await player.skipForward()
            } catch {
                print("Skip to next track failed")
            }
        }
    }
}

#if DEBUG
struct PlayNextButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayNextButton(player: .init(preview: true))
    }
}
#endif
