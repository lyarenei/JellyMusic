import SFSafeSymbols
import SwiftUI

struct EnqueueButton: View {
    @ObservedObject
    var player: MusicPlayer

    let text: String?
    let itemId: String
    let mode: EnqueueMode

    init(
        _ text: String? = nil,
        for itemId: String,
        mode: EnqueueMode = .playLast,
        player: MusicPlayer = .shared
    ) {
        self.text = text
        self.itemId = itemId
        self.mode = mode
        _player = ObservedObject(wrappedValue: player)
    }

    var body: some View {
        Button {
            action()
        } label: {
            switch mode {
            case .playNext:
                Image(systemSymbol: .textInsert)
            case .playLast:
                Image(systemSymbol: .textAppend)
            }

            if let text = text {
                Text(text)
            }
        }
    }

    func action() {
        Task(priority: .userInitiated) {
            do {
                switch mode {
                case .playNext:
                    try await player.enqueue(itemId, at: 0)
                case .playLast:
                    try await player.enqueue(itemId)
                }
            } catch {
                print("Failed to enqueue \(itemId)")
            }
        }
    }

    enum EnqueueMode {
        case playNext, playLast
    }
}

#if DEBUG
struct EnqueueButton_Previews: PreviewProvider {
    static var previews: some View {
        EnqueueButton(for: PreviewData.songs.first!.uuid, player: .init(preview: true))
    }
}
#endif
