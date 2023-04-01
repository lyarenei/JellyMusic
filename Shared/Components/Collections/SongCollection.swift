import SwiftUI
import SwiftUIBackports

struct SongCollection: View {
    private var songs: [Song]?

    private let showAlbumOrder: Bool
    private let showArtwork: Bool
    private let showAction: Bool
    private let showArtistName: Bool

    init(
        songs: [Song]? = nil,
        showAlbumOrder: Bool = false,
        showArtwork: Bool = true,
        showAction: Bool = true,
        showArtistName: Bool = false
    ) {
        self.songs = songs
        self.showAlbumOrder = showAlbumOrder
        self.showArtwork = showArtwork
        self.showAction = showAction
        self.showArtistName = showArtistName
    }

    var body: some View {
        if let gotSongs = songs, gotSongs.isEmpty {
            Text("No songs available")
                .font(.title3)
                .foregroundColor(.gray)
        } else if let gotSongs = songs {
            SongList(
                songs: gotSongs,
                showAlbumOrder: self.showAlbumOrder,
                showArtwork: self.showArtwork,
                showAction: self.showAction,
                showArtistName: self.showArtistName
            )
        } else {
            InProgressComponent("Refreshing songs ...")
        }
    }
}

#if DEBUG
struct SongCollection_Previews: PreviewProvider {
    static var previews: some View {
        SongCollection(songs: PreviewData.songs)
            .padding([.leading, .trailing])
            .previewDisplayName("Default")
        SongCollection(songs: [])
            .previewDisplayName("Empty")
        SongCollection(songs: nil)
            .previewDisplayName("Nil")

        SEC(
            song: PreviewData.songs[0],
            showAlbumOrder: true,
            showArtwork: false,
            showArtistName: true,
            showAction: true
        )
        .previewDisplayName("Song entry")
        .padding(.horizontal)
    }
}
#endif

private struct SongList: View {
    var songs: [Song]
    let showAlbumOrder: Bool
    let showArtwork: Bool
    let showAction: Bool
    let showArtistName: Bool

    var body: some View {
        let dividerPadding = showAlbumOrder ? 37.0 : 57.0
        LazyVStack(alignment: .leading) {
            Divider()

            ForEach(songs) { song in
                SEC(
                    song: song,
                    showAlbumOrder: self.showAlbumOrder,
                    showArtwork: self.showArtwork,
                    showArtistName: self.showArtistName,
                    showAction: self.showAction
                )
                .onTapGesture { Task(priority: .userInitiated) {
                    do {
                        try await MusicPlayer.shared.playNow(itemId: song.uuid)
                    } catch {
                        print("Failed to play item \(song.uuid)")
                    }
                }}
                .contentShape(Rectangle())
                .contextMenu { ContextOptions(song: song) }
                .padding(.horizontal)

                Divider()
                    .padding(.leading, dividerPadding)
            }
        }
    }
}

private struct SEC: View {
    @State
    private var artist = "song.artist"

    let song: Song

    let showAlbumOrder: Bool
    let showArtwork: Bool
    let showArtistName: Bool
    let showAction: Bool

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 17) {
                    if showAlbumOrder {
                        Text("\(song.index)")
                            .font(.title3)
                            .frame(minWidth: 20)
                    }

                    if showArtwork {
                        ArtworkComponent(itemId: song.uuid)
                            .frame(width: 40, height: 40)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.name)
                            .font(.title3)
                            .lineLimit(1)

                        // TODO: automatic - if artist differs from album artist
                        if showArtistName {
                            Text(artist)
                                .lineLimit(1)
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 4)

                Spacer()
            }
            .contentShape(Rectangle())

            if showAction {
                PrimaryActionButton(for: song.uuid)
                    .font(.title3)
                    .frame(width: 27, height: 27)
                    .padding(.trailing, 5)
            }
        }
        .frame(height: 45)
        .backport.task {
            guard showArtistName else { return }
            // TODO: fetch artist by song ID
            self.artist = "song.artist"
        }
    }
}

// TODO: extract to standalone buttons like download/favorite
private struct ContextOptions: View  {
    let song: Song

    var body: some View {
        Button { Task(priority: .userInitiated) {
            do {
                try await MusicPlayer.shared.playNow(itemId: song.uuid)
            } catch {
                print("Failed to play song \(song.uuid)")
            }
        }} label: {
            Image(systemSymbol: .playFill)
            Text("Play")
        }

        DownloadButton(for: song.uuid, showText: true)

        FavoriteButton(isFavorite: false)

        Button {
            Task(priority: .userInitiated) {
                do {
                    try await MusicPlayer.shared.enqueue(song.uuid, at: 0)
                } catch {
                    print("Failed to enqueue: \(song.uuid)")
                }
            }
        } label: {
            Image(systemSymbol: .textInsert)
            Text("Play Next")
        }

        Button {
            Task(priority: .userInitiated) {
                do {
                    try await MusicPlayer.shared.enqueue(song.uuid)
                } catch {
                    print("Failed to enqueue: \(song.uuid)")
                }
            }
        } label: {
            Image(systemSymbol: .textAppend)
            Text("Play Last")
        }
    }
}
