import Kingfisher
import MarqueeText
import SwiftUI

struct AlbumTileComponent: View {
    @EnvironmentObject
    private var library: LibraryRepository

    let album: Album

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 6) {
                ArtworkComponent(itemId: album.id)

                tileNames
                    .padding(.horizontal, 2)
            }
            .frame(width: proxy.size.width, height: proxy.size.width + 40)
        }
    }

    @ViewBuilder
    private var tileNames: some View {
        VStack(alignment: .leading, spacing: 2) {
            MarqueeText(
                text: album.name,
                font: .systemFont(ofSize: 17, weight: .medium),
                leftFade: UIConstants.marqueeFadeLen,
                rightFade: UIConstants.marqueeFadeLen,
                startDelay: UIConstants.marqueeDelay
            )

            MarqueeText(
                text: album.artistName,
                font: .systemFont(ofSize: 12),
                leftFade: UIConstants.marqueeFadeLen,
                rightFade: UIConstants.marqueeFadeLen,
                startDelay: UIConstants.marqueeDelay
            )
            .foregroundColor(.gray)
        }
    }
}

#if DEBUG
struct AlbumTile_Previews: PreviewProvider {
    static var previews: some View {
        // swiftlint:disable:next force_unwrapping
        AlbumTileComponent(album: PreviewData.albums.first!)
            .environmentObject(PreviewUtils.libraryRepo)
            .frame(width: 160)
    }
}
#endif
