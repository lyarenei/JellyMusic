import SFSafeSymbols
import SwiftUI

struct AlbumDetailScreen: View {
    @EnvironmentObject
    private var library: LibraryRepository

    let album: Album

    var body: some View {
        ScrollView {
            content
                .padding(.top, 15)
                .padding(.bottom, 25)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                albumToolbarMenu
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                RefreshButton(mode: .album(id: album.id))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack {
            artworkWithName
                .padding(.bottom, 10)

            actions
                .padding(.bottom, 10)

            runtime

            if library.getDiscCount(for: album) <= 1 {
                Divider()
                    .padding(.leading)
            }

            songs
                .padding(.bottom, 15)

            AlbumPreviewCollection(
                for: previewAlbums,
                titleText: "More by \(library.getArtistName(for: album))",
                emptyText: "No albums"
            )
            .stackType(.horizontal)
        }
    }

    @ViewBuilder
    private var artworkWithName: some View {
        VStack(spacing: 20) {
            ArtworkComponent(itemId: album.id)
                .frame(width: 270, height: 270)

            VStack(spacing: 5) {
                Text(album.name)
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.center)

                Text(library.getArtistName(for: album))
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var actions: some View {
        HStack {
            PlayButton(text: "Play", item: album)
                .frame(width: 120, height: 45)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(style: StrokeStyle(lineWidth: 1.0))
                        .foregroundColor(.accentColor)
                )

            Button {
                // Album shuffle play action
            } label: {
                Image(systemSymbol: .shuffle)
                Text("Shuffle")
            }
            .frame(width: 120, height: 45)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1.0))
                    .foregroundColor(.lightGray)
            )
            .disabled(true)
        }
    }

    @ViewBuilder
    private var runtime: some View {
        let songCount = library.getSongs(for: album).count
        let runtime = library.getRuntime(for: album)
        Text("\(songCount) songs, \(runtime.minutes) minutes")
            .foregroundColor(.gray)
            .font(.system(size: 16))
    }

    @ViewBuilder
    private var songs: some View {
        if library.getSongs(for: album).isEmpty {
            Text("No songs")
                .foregroundColor(.gray)
                .font(.title3)
        } else {
            songList
        }
    }

    @ViewBuilder
    private var songList: some View {
        let discCount = library.getDiscCount(for: album)
        if discCount > 1 {
            ForEach(enumerating: 1...discCount) { idx in
                let songs = library.getSongs(for: album).filtered(by: .albumDisc(num: idx))
                Section {
                    songCollection(
                        songs: songs.sorted(by: .index),
                        showLastDivider: idx == discCount
                    )
                } header: {
                    discGroupHeader(text: "Disc \(idx)")
                }
            }
        } else {
            songCollection(
                songs: library.getSongs(for: album),
                showLastDivider: true
            )
        }
    }

    @ViewBuilder
    private func songCollection(songs: [Song], showLastDivider: Bool) -> some View {
        SongCollection(songs: songs)
            .showAlbumOrder()
            .showArtistName()
            .collectionType(.plain)
            .rowHeight(30)
            .showLastDivider(showLastDivider)
            .font(.system(size: 16))
    }

    @ViewBuilder
    private func discGroupHeader(text: String) -> some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)

            HStack {
                Text(text)
                    .foregroundColor(.gray)
                    .font(.system(size: 16))

                Spacer()
            }
            .padding(.leading)
            .padding(.top)
            .padding(.bottom, 5)
        }
    }

    @ViewBuilder
    private var albumToolbarMenu: some View {
        Menu {
            AlbumContextMenu(album: album)
        } label: {
            Image(systemSymbol: .ellipsisCircle)
                .imageScale(.large)
        }
    }

    private var previewAlbums: [Album] {
        library.albums.filter { $0.id != album.id && $0.artistId == album.artistId }
    }
}

#if DEBUG
// swiftlint:disable all
struct AlbumDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AlbumDetailScreen(album: PreviewData.albums.first!)
        }
        .previewDisplayName("Default")
        .environmentObject(PreviewUtils.libraryRepo)

        AlbumDetailScreen(album: PreviewData.albums.first!)
            .previewDisplayName("Empty")
            .environmentObject(PreviewUtils.libraryRepoEmpty)
    }
}
// swiftlint:enable all
#endif
