import MarqueeText
import SwiftUI

struct SongListRowComponent: View {
    @EnvironmentObject
    private var library: LibraryRepository

    let song: Song

    private var showAlbumOrder = false
    private var showArtwork = false
    private var showArtistName = false
    private var showAlbumName = false
    private var height = 40.0

    init(song: Song) {
        self.song = song
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 17) {
                orderOrArtwork
                songBody
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var orderOrArtwork: some View {
        if showAlbumOrder {
            Text("\(song.index)")
                .frame(minWidth: 20)
        } else if showArtwork {
            let square = CGSize(width: height, height: height)
            ArtworkComponent(for: song.albumId)
                .frame(width: square.width, height: square.height)
        }
    }

    @ViewBuilder
    private var songBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song.name)
                .lineLimit(1)

            artistOrAlbumName
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private var artistOrAlbumName: some View {
        // TODO: automatic - if artist differs from album artist
        if showArtistName {
            MarqueeText(
                text: song.artistCreditName,
                font: .systemFont(ofSize: 12),
                leftFade: UIConstants.marqueeFadeLen,
                rightFade: UIConstants.marqueeFadeLen,
                startDelay: UIConstants.marqueeDelay
            )
        } else if showAlbumName, let albumName = library.albums.by(id: song.albumId)?.name {
            MarqueeText(
                text: albumName,
                font: .systemFont(ofSize: 12),
                leftFade: UIConstants.marqueeFadeLen,
                rightFade: UIConstants.marqueeFadeLen,
                startDelay: UIConstants.marqueeDelay
            )
        }
    }
}

extension SongListRowComponent {
    func showAlbumOrder(_ value: Bool = true) -> SongListRowComponent {
        var view = self
        view.showAlbumOrder = value
        return view
    }

    func showArtwork(_ value: Bool = true) -> SongListRowComponent {
        var view = self
        view.showArtwork = value
        return view
    }

    func showArtistName(_ value: Bool = true) -> SongListRowComponent {
        var view = self
        view.showArtistName = value
        return view
    }

    func height(_ height: CGFloat) -> SongListRowComponent {
        var view = self
        view.height = height
        return view
    }

    func showAlbumName(_ value: Bool = true) -> SongListRowComponent {
        var view = self
        view.showAlbumName = value
        return view
    }
}

#if DEBUG
// swiftlint:disable all
struct SongListRowComponent_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SongListRowComponent(song: PreviewData.songs.first!)
                .showArtwork()
                .showArtistName()
                .padding(.horizontal)

            SongListRowComponent(song: PreviewData.songs.first!)
                .showAlbumOrder()
                .showArtistName()
                .padding(.horizontal)
        }
        .environmentObject(PreviewUtils.libraryRepo)
        .environmentObject(ApiClient(previewEnabled: true))
        .listStyle(.plain)
    }
}
// swiftlint:enable all
#endif
