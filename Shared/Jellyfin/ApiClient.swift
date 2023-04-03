import Defaults
import Foundation
import JellyfinAPI
import SimpleKeychain
import SwiftUI

final class ApiClient {
    private(set) var services: ApiServices = .preview

    init() {
        Defaults[.previewMode] ? usePreviewMode() : useDefaultMode()
    }

    init(previewEnabled: Bool = true) {
        previewEnabled ? usePreviewMode() : useDefaultMode()
    }

    /// Use preview mode of the client with mocked data. Does not persist any changes.
    public func usePreviewMode() {
        services = .preview
    }

    public func useDefaultMode() {
        var connectUrl = URL(string: "http://localhost:8096")!
        if let validServerUrl = URL(string: Defaults[.serverUrl]) {
            connectUrl = validServerUrl
        }

        let jellyfinClient = JellyfinClient(configuration: .init(
            url: connectUrl,
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
    }

    public func performAuth() async throws -> Bool {
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

        if !userId.isEmpty {
            Defaults[.userId] = userId
            return true
        }

        return false
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
            artistName: "Unamusing artist"
        ),
        Album(
            uuid: "3",
            name: "Very long album name that can't possibly fit on one line on phone screen either in vertical or horizontal orientation",
            artistName: "Very long artist name that can't possibly fit on one line on phone screen either in vertical or horizontal orientation",
            isFavorite: true
        )
    ]

    public static let songs = [
        // Songs for album 1
        Song(
            uuid: "1",
            index: 1,
            name: "Song name 1",
            parentId: "1",
            runtime: 123
        ),
        Song(
            uuid: "2",
            index: 2,
            name: "Song name 2 but this one has very long name",
            parentId: "1",
            runtime: 123
        ),
        // Songs for album 2
        Song(
            uuid: "3",
            index: 1,
            name: "Song name 3",
            parentId: "2",
            runtime: 123
        ),
        Song(
            uuid: "4",
            index: 2,
            name: "Song name 4 but this one has very long name",
            parentId: "2",
            runtime: 123
        ),
        Song(
            uuid: "5",
            index: 1,
            name: "Very long song name that can't possibly fit on one line on phone screen either in vertical or horizontal orientation",
            parentId: "3",
            runtime: 123
        )
    ]
}
