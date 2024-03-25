import SwiftUI

struct AlbumListRowComponent: View {
    let album: Album

    var body: some View {
        HStack(spacing: 17) {
            ArtworkComponent(for: album)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 3) {
                Text(album.name)
                    .font(.title2)
                    .lineLimit(1)

                Text(album.artistName)
                    .lineLimit(1)
                    .font(.body)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}

#if DEBUG
// swiftlint:disable all
struct AlbumListRowComponent_Previews: PreviewProvider {
    static var previews: some View {
        AlbumListRowComponent(album: PreviewData.albums.first!)
            .padding(.horizontal)
            .environmentObject(ApiClient(previewEnabled: true))
    }
}
// swiftlint:enable all
#endif
