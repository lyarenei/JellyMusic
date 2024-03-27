import Defaults
import MarqueeText
import OSLog
import SFSafeSymbols
import SwiftUI

enum AlbumDisplayMode: String, Defaults.Serializable {
    case asList
    case asPlainList
    case asTiles
}

struct AlbumCollection: View {
    @EnvironmentObject
    private var library: LibraryRepository

    @Default(.albumDisplayMode)
    private var displayMode: AlbumDisplayMode

    private let albums: [Album]
    private var forceDisplayMode: AlbumDisplayMode?
    private var showChevron = false
    private var rowHeight = 60.0

    init(albums: [Album]) {
        self.albums = albums
    }

    init(albums: ArraySlice<Album>) {
        self.albums = Array(albums)
    }

    var body: some View {
        switch forceDisplayMode ?? displayMode {
        case .asList:
            listContent()
        case .asPlainList:
            plainContent()
        case .asTiles:
            tileContent()
        }
    }

    @ViewBuilder
    private func listContent() -> some View {
        ForEach(albums, id: \.id) { album in
            NavigationLink {
                AlbumDetailScreen(album: album)
            } label: {
                albumListEntry(album: album)
            }
            .contextMenu { AlbumContextMenu(album: album) }
        }
    }

    @ViewBuilder
    private func plainContent() -> some View {
        ForEach(albums, id: \.id) { album in
            NavigationLink {
                AlbumDetailScreen(album: album)
            } label: {
                albumPlainEntry(album: album)
                    .padding(.vertical, 1)
                    .contentShape(Rectangle())
            }
            .contextMenu { AlbumContextMenu(album: album) }

            Divider()
        }
    }

    @ViewBuilder
    private func tileContent() -> some View {
        ForEach(albums, id: \.id) { album in
            NavigationLink {
                AlbumDetailScreen(album: album)
            } label: {
                AlbumTileComponent(album: album)
            }
            .buttonStyle(.plain)
            .contextMenu { AlbumContextMenu(album: album) }
            .frame(width: UIConstants.tileSize, height: UIConstants.tileSize)
        }
    }

    @ViewBuilder
    private func albumListEntry(album: Album) -> some View {
        HStack(spacing: 17) {
            ArtworkComponent(for: album)
                .frame(width: rowHeight, height: rowHeight)

            albumNameArtist(album: album)
        }
    }

    @ViewBuilder
    private func albumNameArtist(album: Album) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            MarqueeText(
                text: album.name,
                font: .preferredFont(forTextStyle: .title2),
                leftFade: UIConstants.marqueeFadeLen,
                rightFade: UIConstants.marqueeFadeLen,
                startDelay: UIConstants.marqueeDelay
            )

            MarqueeText(
                text: album.artistName,
                font: .preferredFont(forTextStyle: .body),
                leftFade: UIConstants.marqueeFadeLen,
                rightFade: UIConstants.marqueeFadeLen,
                startDelay: UIConstants.marqueeDelay
            )
            .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private func albumPlainEntry(album: Album) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 17) {
                ArtworkComponent(for: album)
                    .frame(width: rowHeight, height: rowHeight)

                albumNameArtist(album: album)
            }

            Spacer()

            if showChevron {
                Image(systemSymbol: .chevronRight)
                    .foregroundColor(.gray)
                    .padding(.trailing, 10)
            }
        }
    }
}

extension AlbumCollection {
    func forceMode(_ mode: AlbumDisplayMode) -> AlbumCollection {
        var view = self
        view.forceDisplayMode = mode
        return view
    }

    func rowHeight(_ height: CGFloat) -> AlbumCollection {
        var view = self
        view.rowHeight = height
        return view
    }

    func showNavChevron(_ value: Bool = false) -> AlbumCollection {
        var view = self
        view.showChevron = value
        return view
    }
}

#if DEBUG
struct AlbumList_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AlbumCollection(albums: PreviewData.albums)
                .forceMode(.asList)
        }
        .previewDisplayName("List")
        .environmentObject(PreviewUtils.libraryRepo)
        .environmentObject(ApiClient(previewEnabled: true))

        VStack {
            AlbumCollection(albums: PreviewData.albums)
                .forceMode(.asPlainList)
        }
        .previewDisplayName("Vstack")
        .padding(.horizontal)
        .environmentObject(PreviewUtils.libraryRepo)
        .environmentObject(ApiClient(previewEnabled: true))

        ScrollView(.horizontal) {
            HStack {
                AlbumCollection(albums: PreviewData.albums)
                    .forceMode(.asTiles)
            }
            .padding(.horizontal)
        }
        .previewDisplayName("Tiles")
        .environmentObject(PreviewUtils.libraryRepo)
        .environmentObject(ApiClient(previewEnabled: true))
    }
}
#endif
