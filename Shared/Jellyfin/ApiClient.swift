import Defaults
import Foundation
import JellyfinAPI
import OSLog
import SimpleKeychain
import SwiftUI

final class ApiClient {
    private(set) var services: ApiServices = .preview

    init(previewEnabled: Bool = Defaults[.previewMode]) {
        setMode(previewEnabled)
    }

    private func setMode(_ isPreview: Bool) {
        if isPreview {
            usePreviewMode()
            return
        }

        useDefaultMode()
    }

    /// Use preview mode of the client with mocked data. Does not persist any changes.
    public func usePreviewMode() {
        services = .preview
        Logger.jellyfin.debug("Using preview mode for API client")
    }

    /// Use default mode of the client which connects to the configured server.
    public func useDefaultMode() {
        // swiftlint:disable:next force_unwrapping
        var serverUrl = URL(string: "http://localhost:8096")!
        if let configuredServerUrl = URL(string: Defaults[.serverUrl]) {
            serverUrl = configuredServerUrl
        }

        let jellyfinClient = JellyfinClient(configuration: .init(
            url: serverUrl,
            client: "JellyMusic",
            deviceName: UIDevice.current.model,
            deviceID: UIDevice.current.identifierForVendor?.uuidString ?? "missing_id",
            version: "0.0"
        ))

        services = ApiServices(
            albumService: DefaultAlbumService(client: jellyfinClient),
            songService: DefaultSongService(client: jellyfinClient),
            imageService: DefaultImageService(client: jellyfinClient),
            systemService: DefaultSystemService(client: jellyfinClient),
            mediaService: DefaultMediaService(client: jellyfinClient)
        )
        Logger.jellyfin.debug("Using default mode for API client")
    }

    /// Authorize against JellyfinServer with stored credentials.
    public func performAuth() async throws {
        Defaults[.userId] = ""
        let keychain = SimpleKeychain()
        let password = try? keychain.string(forKey: "password")
        guard let userPass = password else {
            throw ApiClientError.noPassword
        }

        let userId = try await services.systemService.logIn(
            username: Defaults[.username],
            password: userPass
        )

        if userId.isEmpty {
            throw ApiClientError.loginFailed
        }

        Defaults[.userId] = userId
    }
}

struct ApiServices {
    let albumService: any AlbumService
    let songService: any SongService
    let imageService: any ImageService
    let systemService: any SystemService
    let mediaService: any MediaService
}

extension ApiServices {
    static var preview: ApiServices {
        ApiServices(
            albumService: DummyAlbumService(albums: PreviewData.albums),
            songService: DummySongService(songs: PreviewData.songs),
            imageService: DummyImageService(),
            systemService: MockSystemService(),
            mediaService: MockMediaService()
        )
    }
}

private struct APIEnvironmentKey: EnvironmentKey {
    static let defaultValue: ApiClient = .init()
}

extension EnvironmentValues {
    var api: ApiClient {
        get { self[APIEnvironmentKey.self] }
        set { self[APIEnvironmentKey.self] = newValue }
    }
}

enum ApiClientError: Error {
    case noPassword
    case loginFailed
}

struct PreviewData {
    public static let albums = [
        Album(
            uuid: "1",
            name: "Nice album name",
            artistName: "Album artist",
            isFavorite: true
        ),
        Album(
            uuid: "2",
            name: "Album with very long name that one gets tired reading it",
            artistName: "Unamusing artist",
            isFavorite: false
        ),
        Album(
            uuid: "3",
            name: "Very long album name that can't possibly fit on one line on phone screen either in vertical or horizontal orientation",
            artistName: "Very long artist name that can't possibly fit on one line on phone screen either in vertical or horizontal orientation",
            isFavorite: true
        ),
    ]

    public static let songs = [
        // Songs for album 1
        Song(
            uuid: "1",
            index: 1,
            name: "Song name 1",
            parentId: "1",
            isFavorite: false,
            runtime: 123
        ),
        Song(
            uuid: "2",
            index: 2,
            name: "Song name 2 but this one has very long name",
            parentId: "1",
            isFavorite: false,
            runtime: 123
        ),
        // Songs for album 2
        Song(
            uuid: "3",
            index: 1,
            name: "Song name 3",
            parentId: "2",
            isFavorite: false,
            runtime: 123
        ),
        Song(
            uuid: "4",
            index: 2,
            name: "Song name 4 but this one has very long name",
            parentId: "2",
            isFavorite: false,
            runtime: 123
        ),
        Song(
            uuid: "5",
            index: 1,
            name: "Very long song name that can't possibly fit on one line on phone screen either in vertical or horizontal orientation",
            parentId: "3",
            isFavorite: false,
            runtime: 123
        ),
    ]
}
