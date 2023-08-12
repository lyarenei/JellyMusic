import Boutique
import Foundation

final class LibraryRepository: ObservableObject {
    private let apiClient: ApiClient

    @Stored
    var artists: [Artist]

    @Stored
    var albums: [Album]

    init(
        artistStore: Store<Artist>,
        albumStore: Store<Album>,
        apiClient: ApiClient
    ) {
        self._artists = Stored(in: artistStore)
        self._albums = Stored(in: albumStore)
        self.apiClient = apiClient
    }

    enum LibraryError: Error {
        case notFound
    }

    func refreshAll() async throws {
        try await refreshArtists()
        try await refreshAlbums()
    }

    func refreshArtists() async throws {
        try await apiClient.performAuth()
        try await $artists.removeAll()
        let pageSize: Int32 = 50
        var offset: Int32 = 0
        while true {
            let artists = try await apiClient.services.artistService.getArtists(pageSize: pageSize, offset: offset)
            guard artists.isNotEmpty else { return }
            try await $artists.insert(artists)
            offset += pageSize
        }
    }

    func refreshAlbums() async throws {
        // TODO: pagination
        try await apiClient.performAuth()
        let remoteAlbums = try await apiClient.services.albumService.getAlbums()
        try await $albums.removeAll().insert(remoteAlbums).run()
    }

    func refresh(artist: Artist) async throws {
        // TODO: implementation
        try await apiClient.performAuth()
    }

    func refresh(album: Album) async throws {
        try await apiClient.performAuth()
        let remoteAlbum = try await apiClient.services.albumService.getAlbum(by: album.id)
        try await $albums.insert(remoteAlbum)
    }

    func setFavorite(artist: Artist, isFavorite: Bool) async throws {
        // TODO: implementation
    }

    func setFavorite(album: Album, isFavorite: Bool) async throws {
        guard var album = await $albums.items.by(id: album.id) else { throw LibraryError.notFound }
        try await apiClient.services.mediaService.setFavorite(itemId: album.id, isFavorite: isFavorite)
        album.isFavorite = isFavorite
        try await $albums.insert(album)
    }
}