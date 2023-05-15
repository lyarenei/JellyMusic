import SFSafeSymbols
import SwiftUI

struct FavoriteButton: View {
    @State
    private var isFavorite = false

    private let albumRepo: AlbumRepository
    private let songRepo: SongRepository
    private let item: any JellyfinItem
    private let textFavorite: String?
    private let textUnfavorite: String?
    private var layout: ButtonLayout = .horizontal

    init(
        item: any JellyfinItem,
        textFavorite: String? = nil,
        textUnfavorite: String? = nil,
        albumRepo: AlbumRepository = .shared,
        songRepo: SongRepository = .shared
    ) {
        self.item = item
        self.textFavorite = textFavorite
        self.textUnfavorite = textUnfavorite
        self.albumRepo = albumRepo
        self.songRepo = songRepo
    }

    var body: some View {
        Button {
            action()
        } label: {
            icon()
            buttonText(isFavorite ? textUnfavorite : textFavorite)
        }
        .onAppear { isFavorite = item.isFavorite }
    }

    @ViewBuilder
    private func buttonText(_ text: String?) -> some View {
        if let text {
            Text(text)
        }
    }

    private func icon() -> some View {
        Image(systemSymbol: isFavorite ? .heartFill : .heart)
            .resizable()
            .scaledToFit()
            .foregroundColor(.red)
    }

    private func action() {
        Task {
            do {
                switch item {
                case let album as Album:
                    try await albumRepo.setFavorite(albumId: album.uuid, isFavorite: !isFavorite)
                case let song as Song:
                    try await songRepo.setFavorite(songId: song.uuid, isFavorite: !isFavorite)
                default:
                    print("Unhandled item type: \(item)")
                    return
                }

                await MainActor.run { isFavorite.toggle() }
            } catch {
                print("Failed to update favorite status")
            }
        }
    }

    enum ButtonLayout {
        case horizontal
        case vertical
    }
}

extension FavoriteButton {
    func setLayout(_ layout: ButtonLayout) -> FavoriteButton {
        var view = self
        view.layout = layout
        return view
    }
}

#if DEBUG
// swiftlint:disable all
struct FavoriteButton_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteButton(
            item: PreviewData.albums.first!,
            albumRepo: .init(
                store: .previewStore(
                    items: PreviewData.albums,
                    cacheIdentifier: \.uuid
                )
            ),
            songRepo: .init(
                store: .previewStore(
                    items: PreviewData.songs,
                    cacheIdentifier: \.uuid
                )
            )
        )
    }
}
// swiftlint:enable all
#endif
