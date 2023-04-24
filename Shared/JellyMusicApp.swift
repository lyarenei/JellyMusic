import Defaults
import JellyfinAPI
import Kingfisher
import SFSafeSymbols
import SwiftUI

@main
struct JellyMusicApp: App {
    init() {
        // Memory image never expires.
        Kingfisher.ImageCache.default.memoryStorage.config.expiration = .never

        // Disk image expires in a week.
        Kingfisher.ImageCache.default.diskStorage.config.expiration = .days(7)

        // Limit disk cache size to 1 GB.
        Kingfisher.ImageCache.default.diskStorage.config.sizeLimit = 1000 * 1024 * 1024
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if os(iOS)
                HomeScreen()
                #endif

                #if os(macOS)
                MacHomeScreen()
                #endif
            }
            .onAppear { Task(priority: .medium) {
                // TODO: would be good to show error to user
                // NOTE: This overwrites local-only metadata (such as isDownloaded)
                do {
                    try await AlbumRepository.shared.refresh()
//                    try await SongRepository.shared.refresh()
                } catch {
                    print("Failed to refresh data: \(error)")
                }
            }}
        }

        #if os(macOS)
        Settings {
            MacSettingsView()
        }
        #endif
    }
}
