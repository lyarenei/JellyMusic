import Kingfisher
import MarqueeText
import SwiftUI

struct TileComponent: View {
    @EnvironmentObject
    private var library: LibraryRepository

    private let item: any JellyfinItem
    private var titleText: String?
    private var subtitleText: String?

    init(item: any JellyfinItem) {
        self.item = item
    }

    var body: some View {
        GeometryReader { proxy in
            let widthScale = subtitleText != nil ? 0.82 : 0.88
            VStack(alignment: .leading) {
                ArtworkComponent(for: item)

                VStack(alignment: .leading, spacing: 2) {
                    title(proxy.size.width)

                    if let subtitleText {
                        subtitle(subtitleText, width: proxy.size.width)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.width / widthScale)
        }
    }

    @ViewBuilder
    private func title(_ width: CGFloat) -> some View {
        let textSize = width / 11.176
        MarqueeText(
            text: titleText ?? item.name,
            font: .systemFont(ofSize: textSize, weight: .medium),
            leftFade: UIConstants.marqueeFadeLen,
            rightFade: UIConstants.marqueeFadeLen,
            startDelay: UIConstants.marqueeDelay
        )
    }

    @ViewBuilder
    private func subtitle(_ text: String, width: CGFloat) -> some View {
        let textSize = width / 15.83
        MarqueeText(
            text: text,
            font: .systemFont(ofSize: textSize),
            leftFade: UIConstants.marqueeFadeLen,
            rightFade: UIConstants.marqueeFadeLen,
            startDelay: UIConstants.marqueeDelay
        )
        .foregroundColor(.gray)
    }
}

extension TileComponent {
    func tileTitle(_ text: String) -> TileComponent {
        var view = self
        view.titleText = text
        return view
    }

    func tileSubTitle(_ text: String) -> TileComponent {
        var view = self
        view.subtitleText = text
        return view
    }
}

#Preview {
    // swiftlint:disable:next force_unwrapping
    TileComponent(item: PreviewData.albums.first!)
        .environmentObject(PreviewUtils.libraryRepo)
        .environmentObject(ApiClient(previewEnabled: true))
        .frame(width: UIConstants.tileSize + 110)
}
