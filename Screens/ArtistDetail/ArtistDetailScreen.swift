import ButtonKit
import SFSafeSymbols
import SwiftUI

struct ArtistDetailScreen: View {
    @State
    private var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    init(artist: Artist, repo: LibraryRepository = .shared) {
        self.viewModel = ViewModel(artist: artist, repo: repo)
    }

    var body: some View {
        List {
            artistHeader
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            albumsSection
                .listSectionSeparatorTint(.systemGroupedBackground)

            Group {
                aboutSection
                genreSection
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.updateDetails() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { favoriteButton }
            ToolbarItem(placement: .navigationBarTrailing) { refreshButton }
        }
    }

    @ViewBuilder
    private var artistHeader: some View {
        HStack(spacing: 15) {
            ArtworkComponent(for: viewModel.artist)
                .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.artist.name)
                    .font(.title)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text("\(viewModel.albums.count) albums, \(viewModel.runtime.minutes) minutes")
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }
        }
    }

    @ViewBuilder
    private var albumsSection: some View {
        if viewModel.albums.isNotEmpty {
            Section("Albums (\(viewModel.albums.count))") {
                artistAlbums
            }
        } else {
            Text("No albums found")
                .font(.title2)
                .foregroundStyle(Color.gray)
        }
    }

    @ViewBuilder
    private var artistAlbums: some View {
        ForEach(viewModel.albums) { album in
            // TODO: value based navigation
            NavigationLink {
                AlbumDetailScreen(album: album)
            } label: {
                Label {
                    Text(album.name)
                        .font(.title3)
                } icon: {
                    ArtworkComponent(for: album)
                        .scaledToFit()
                }
                .labelStyle(.titleAndIcon)
            }
            .frame(height: 40)
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        if viewModel.artist.about.isNotEmpty {
            Section("About") {
                Text(viewModel.artist.about)
                    .font(.caption)
                    .lineLimit(viewModel.aboutLineLimit)
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            viewModel.toggleAboutLineLimit()
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private var genreSection: some View {
        Section("Genre") {
            Text("TBD")
        }
    }

    @ViewBuilder
    private var favoriteButton: some View {
        AsyncButton {
            await viewModel.onFavoriteButton()
        } label: {
            if viewModel.artist.isFavorite {
                Image(systemSymbol: .heartFill)
            } else {
                Image(systemSymbol: .heart)
            }
        }
    }

    @ViewBuilder
    private var refreshButton: some View {
        AsyncButton {
            await viewModel.onRefreshButton()
        } label: {
            Image(systemSymbol: .arrowClockwise)
        }
    }
}

#Preview {
    NavigationStack {
        ArtistDetailScreen(artist: PreviewData.artist, repo: PreviewUtils.libraryRepo)
            .environmentObject(ApiClient(previewEnabled: true))
    }
}
