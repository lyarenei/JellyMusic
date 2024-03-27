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

            Divider()
                .padding(.leading)

            songs(albumSongs)
                .padding(.bottom, 15)

            AlbumPreviewCollection(
                for: previewAlbums,
                titleText: "More by \(album.artistName)",
                emptyText: "No albums"
            )
            .stackType(.horizontal)
        }
    }

    @ViewBuilder
    private var artworkWithName: some View {
        VStack(spacing: 20) {
            ArtworkComponent(for: album)
                .frame(width: 270, height: 270)

            VStack(spacing: 5) {
                Text(album.name)
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.center)

                Text(album.artistName)
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
    private func songs(_ songs: [Song]) -> some View {
        VStack {
            if songs.isEmpty {
                Text("No songs")
                    .foregroundColor(.gray)
                    .font(.title3)
            } else {
                songList(of: songs)
            }
        }
    }

    @ViewBuilder
    private func songList(of songs: [Song]) -> some View {
        let discCount = library.getDiscCount(for: album)
        if discCount > 1 {
            ForEach(enumerating: 1...discCount) { discNum in
                let discSongs = songs.filtered(by: .albumDisc(num: discNum))
                Section {
                    songCollection(
                        songs: discSongs.sorted(by: .index),
                        showLastDivider: discNum == discCount
                    )
                } header: {
                    discGroupHeader(text: "Disc \(discNum)")
                }
            }
        } else {
            songCollection(
                songs: songs.sorted(by: .index),
                showLastDivider: true
            )
        }
    }

    @ViewBuilder
    private func songCollection(songs: [Song], showLastDivider: Bool) -> some View {
        ForEach(songs, id: \.id) { song in
            HStack(spacing: 10) {
                songCell(allSongs: albumSongs, song)
                PrimaryActionButton(item: song)
                    .padding(.trailing)
            }
            .frame(height: 35)
            .padding(.leading)

            divider(songs: songs, song: song, showLastDivider: showLastDivider)
        }
    }

    @ViewBuilder
    private func songCell(allSongs: [Song], _ song: Song) -> some View {
        SongListRowComponent(song: song)
            .showAlbumOrder()
            .showArtistName()
            .height(35)
            .contentShape(Rectangle())
            .contextMenu { SongContextOptions(song: song) }
            .onTapGesture { Task { await onSongTap(song) } }
    }

    private func onSongTap(_ song: Song) async {
        let queue = {
            var songsToPlay: [Song] = []
            let currentDiscSongs = albumSongs
                .filtered(by: .albumDisc(num: song.albumDisc))
                .sorted(by: .index)

            let albumDiscCount = library.getDiscCount(for: album)
            var restOfSongs: [Song] = []
            for discNum in song.albumDisc...albumDiscCount {
                guard discNum != song.albumDisc else { continue }
                let discSongs = albumSongs.filtered(by: .albumDisc(num: discNum))
                restOfSongs.append(contentsOf: discSongs.sorted(by: .index))
            }

            songsToPlay.append(contentsOf: currentDiscSongs.dropFirst(song.index))
            songsToPlay.append(contentsOf: restOfSongs)
            return songsToPlay
        }()

        await MusicPlayer.shared.play(song: song)
        MusicPlayer.shared.enqueue(songs: queue, position: .last)
    }

    @ViewBuilder
    private func divider(songs: [Song], song: Song, showLastDivider: Bool) -> some View {
        if let lastSong = songs.last {
            if song != lastSong || showLastDivider {
                Divider()
                    .padding(.leading)
            }
        }
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

    private var albumSongs: [Song] {
        library.songs.filtered(by: .albumId(album.id))
    }

    private var previewAlbums: [Album] {
        library.albums.filter { $0.id != album.id && $0.artistId == album.artistId }
    }
}

// MARK: - Context options

private struct SongContextOptions: View {
    let song: Song

    var body: some View {
        PlayButton(text: "Play", item: song)
        DownloadButton(item: song, textDownload: "Download", textRemove: "Remove")
        FavoriteButton(item: song, textFavorite: "Favorite", textUnfavorite: "Unfavorite")
        EnqueueButton(text: "Play Next", item: song, position: .next)
        EnqueueButton(text: "Play Last", item: song, position: .last)
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
        .environmentObject(ApiClient(previewEnabled: true))

        AlbumDetailScreen(album: PreviewData.albums.first!)
            .previewDisplayName("Empty")
            .environmentObject(PreviewUtils.libraryRepoEmpty)
            .environmentObject(ApiClient(previewEnabled: true))
    }
}
// swiftlint:enable all
#endif
