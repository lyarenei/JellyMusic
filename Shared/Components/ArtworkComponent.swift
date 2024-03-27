import Kingfisher
import OSLog
import SFSafeSymbols
import SwiftUI

struct ArtworkComponent: View {
    private static let cornerRadius = 5.0
    private static let fadeDuration = 0.5
    private static let retryCount = 5
    private static let retryInterval = 10.0

    @EnvironmentObject
    private var apiClient: ApiClient

    private let itemId: String

    init(for item: any JellyfinItem) {
        self.itemId = item.id
    }

    init(for itemId: String) {
        self.itemId = itemId
    }

    var body: some View {
        GeometryReader { proxy in
            KFImage
                .dataProvider(jellyfinProvider)
                .cacheOriginalImage()
                .resizable()
                .placeholder {
                    Image(systemSymbol: .photoOnRectangleAngled)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .fill(alignment: .center)
                }
                .fade(duration: Self.fadeDuration)
                .retry(maxCount: Self.retryCount, interval: .seconds(Self.retryInterval))
                .appendProcessor(DownsamplingImageProcessor(size: doubleSize(proxy.size)))
                .onFailure { error in
                    Logger.artwork.debug("Failed to load image for item \(itemId): \(error.localizedDescription)")
                }
                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
                .border(.gray.opacity(0.5), cornerRadius: Self.cornerRadius)
                .aspectRatio(contentMode: .fit)
                .fill(alignment: .center)
        }
    }

    private var jellyfinProvider: JellyfinImageDataProvider {
        JellyfinImageDataProvider(
            itemId: itemId,
            imageService: apiClient.services.imageService
        )
    }

    private func doubleSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: size.width * 2,
            height: size.height * 2
        )
    }
}

#Preview {
    // swiftlint:disable:next force_unwrapping
    ArtworkComponent(for: PreviewData.albums.first!)
        .environmentObject(ApiClient(previewEnabled: true))
        .frame(width: 200, height: 200)
}
