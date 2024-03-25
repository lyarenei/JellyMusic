import SwiftUI
import SwiftUIX

struct SearchScreen: View {
    @EnvironmentObject
    private var library: LibraryRepository

    @State
    private var query: String = .empty

    @State
    private var searchQuery: String = .empty

    var body: some View {
        NavigationStack {
            VStack {
                searchBar

                let filteredArtists = library.artists.filter { $0.name.containsIgnoreCase(searchQuery) }
                let filteredAlbums = library.albums.filter { $0.name.containsIgnoreCase(searchQuery) }
                let filteredSongs = library.songs.filter { $0.name.containsIgnoreCase(searchQuery) }

                List {
                    artistResults(filteredArtists)
                    albumResults(filteredAlbums)
                    songResults(filteredSongs)
                }
                .listStyle(.grouped)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var searchBar: some View {
        SearchBar(text: $query)
            .placeholder("Search")
            .isInitialFirstResponder(true)
            .showsCancelButton(true)
            .autocorrectionDisabled()
            .autocapitalization(.none)
            .onChange(of: query, debounceTime: 0.5) { newValue in
                searchQuery = newValue
            }
    }

    @ViewBuilder
    private func artistResults(_ artists: [Artist]) -> some View {
        if artists.isNotEmpty {
            Section("Artists") {
                ForEach(artists, id: \.id) { artist in
                    NavigationLink {
                        ArtistDetailScreen(artist: artist)
                    } label: {
                        Label(artist.name) {
                            ArtworkComponent(for: artist)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func albumResults(_ albums: [Album]) -> some View {
        if albums.isNotEmpty {
            Section("Albums") {
                AlbumCollection(albums: albums)
                    .forceMode(.asList)
            }
        }
    }

    @ViewBuilder
    private func songResults(_ songs: [Song]) -> some View {
        if songs.isNotEmpty {
            Section("Songs") {
                SongCollection(songs: songs)
                    .collectionType(.list)
                    .showAlbumName()
                    .showArtwork()
            }
        }
    }
}

#if DEBUG
struct SearchScreen_Previews: PreviewProvider {
    static var previews: some View {
        SearchScreen()
            .environmentObject(PreviewUtils.libraryRepo)
            .environmentObject(ApiClient(previewEnabled: true))
    }
}
#endif
