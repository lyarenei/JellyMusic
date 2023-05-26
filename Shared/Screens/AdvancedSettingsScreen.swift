import Boutique
import Defaults
import Kingfisher
import SwiftUI
import SwiftUIBackports

struct AdvancedSettingsScreen: View {
    @EnvironmentObject
    private var fileRepo: FileRepository


    var body: some View {
        List {
            MaxCacheSize()
            ClearArtworkCache()
            RemoveDownloads()

            Section {
                PurgeOptions()
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .listStyle(.grouped)
        .navigationTitle("Advanced")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct AdvancedSettingsScreen_Previews: PreviewProvider {
    static var fileRepo: FileRepository = .init(
        downloadedSongsStore: .previewStore(items: PreviewData.songs, cacheIdentifier: \.uuid),
        downloadQueueStore: .previewStore(items: [], cacheIdentifier: \.uuid),
        apiClient: .init(previewEnabled: true)
    )

    static var albumRepo: AlbumRepository = .init(
        store: .previewStore(items: PreviewData.albums, cacheIdentifier: \.uuid),
        apiClient: .init(previewEnabled: true)
    )

    static var songRepo: SongRepository = .init(
        store: .previewStore(items: PreviewData.songs, cacheIdentifier: \.uuid),
        apiClient: .init(previewEnabled: true)
    )

    static var previews: some View {
        AdvancedSettingsScreen()
            .environmentObject(fileRepo)
            .environmentObject(albumRepo)
            .environmentObject(songRepo)
    }
}
#endif

private struct MaxCacheSize: View {
    @Default(.maxCacheSize)
    var maxCacheSize

    @ObservedObject
    var fileRepo: FileRepository

    init(fileRepo: FileRepository = .shared) {
        _fileRepo = ObservedObject(wrappedValue: fileRepo)
    }

    var body: some View {
        InlineNumberInputComponent(
            title: "Max cache size (MB)",
            inputNumber: $maxCacheSize,
            formatter: getFormatter()
        )
        .onChange(of: maxCacheSize, debounceTime: 5) { newValue in
            fileRepo.setCacheSizeLimit(newValue)
        }
    }

    private func getFormatter() -> NumberFormatter {
        let fmt = NumberFormatter()
        fmt.numberStyle = .none
        fmt.minimum = 50
        fmt.allowsFloats = false
        fmt.isLenient = false
        return fmt
    }
}

private struct PurgeOptions: View {
    @Stored(in: .albums)
    var albums: [Album]

    @Stored(in: .songs)
    var songs: [Song]

    @Stored(in: .downloadedSongs)
    var downloadedSongs: [Song]

    @State
    var showConfirm = false

    var body: some View {
        purgeLibraryDataButton()
        resetToDefaultButton()
    }

    @ViewBuilder
    private func purgeLibraryDataButton() -> some View {
        ConfirmButton(
            btnText: "Reset library",
            alertTitle: "Reset library",
            alertMessage: "This will clear all caches and local library data from the device",
            alertPrimaryBtnText: "Reset"
        ) {
            Task {
                do {
                    purgeImages()
                    try await purgeLibraryData()
                } catch {
                    print("Resetting library data failed: \(error.localizedDescription)")
                }
            }
        }
    }

    @ViewBuilder
    private func resetToDefaultButton() -> some View {
        ConfirmButton(
            btnText: "Reset JellyMusic",
            alertTitle: "Reset to defaults",
            alertMessage: "This will delete everything and reset all settings to their defaults",
            alertPrimaryBtnText: "Reset",
            alertPrimaryAction: resetToDefault
        )
    }

    private func resetToDefault() {
        Task {
            do {
                try await purgeAll()
            } catch {
                print("Reset failed: \(error.localizedDescription)")
            }

            Defaults.removeAll()
        }
    }

    private func purgeImages() {
        Kingfisher.ImageCache.default.clearMemoryCache()
        Kingfisher.ImageCache.default.clearDiskCache()
    }

    private func purgeLibraryData() async throws {
        try await $albums.removeAll()
        try await $songs.removeAll()
        try await $downloadedSongs.removeAll()
    }

    private func purgeDownloads() throws {
        try FileRepository.shared.removeAllFiles()
    }

    private func purgeAll() async throws {
        purgeImages()
        try await purgeLibraryData()
        try purgeDownloads()
    }
}

private struct ClearArtworkCache: View {
    @State
    private var sizeMB = 0.0

    var body: some View {
        Section {
            ConfirmButton(
                btnText: "Clear artwork cache",
                alertTitle: "Clear artwork cache",
                alertMessage: "",
                alertPrimaryBtnText: "Confirm",
                alertPrimaryAction: onConfirm
            )
            .foregroundColor(.red)
        } footer: {
            Text("Cache size: \(String(format: "%.1f", sizeMB)) MB")
        }
        .backport.task { await calculateSize() }
    }

    private func resetSize() {
        Task { await MainActor.run { sizeMB = 0 } }
    }

    @MainActor
    private func calculateSize() async {
        do {
            let sizeBytes = try await KingfisherManager.shared.cache.diskStorageSize
            sizeMB = Double(sizeBytes) / 1024 / 1024
        } catch {
            print("Failed to get image cache size: \(error.localizedDescription)")
        }
    }

    private func onConfirm() {
        Kingfisher.ImageCache.default.clearMemoryCache()
        Kingfisher.ImageCache.default.clearDiskCache()
        resetSize()
    }
}

private struct RemoveDownloads: View {
    @EnvironmentObject
    private var fileRepo: FileRepository

    @State
    private var sizeMB = 0.0

    var body: some View {
        Section {
            ConfirmButton(
                btnText: "Remove downloads",
                alertTitle: "Remove downloaded songs",
                alertMessage: "",
                alertPrimaryBtnText: "Confirm",
                alertPrimaryAction: onConfirm
            )
            .foregroundColor(.red)
        } footer: {
            Text("Current size: \(String(format: "%.1f", sizeMB)) MB")
        }
        .backport.task { await calculateSize() }
    }

    private func resetSize() {
        Task { await MainActor.run { sizeMB = 0 } }
    }

    private func onConfirm() {
        do {
            try fileRepo.removeAllFiles()
            resetSize()
        } catch {
            print("Failed to remove downloads: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func calculateSize() async {
        do {
            sizeMB = try fileRepo.downloadedFilesSizeInMB()
        } catch {
            print("Failed to get image cache size: \(error.localizedDescription)")
        }
    }
}
