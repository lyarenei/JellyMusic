import SFSafeSymbols
import SwiftUI
import SwiftUIX

/// Now playing component, somewhat similar what can be seen in Apple Music app.
///
/// Base implementation taken from: https://itnext.io/add-a-now-playing-bar-with-swiftui-to-your-app-d515b03f05e3
struct NowPlayingComponent<Content: View>: View {
    @Binding
    var isPresented: Bool

    var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content

            if isPresented {
                NowPlayingBar()
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom),
                        removal: .identity
                    ))
            }
        }
    }
}

#if DEBUG
// swiftlint:disable all
struct NowPlayingComponent_Previews: PreviewProvider {
    @State
    static var isPresented = true

    static var player = {
        var mp = MusicPlayer(preview: true)
        mp.currentSong = PreviewData.songs.first!
        return mp
    }

    static var previews: some View {
        NowPlayingComponent(isPresented: $isPresented, content: LibraryScreen())
            .previewDisplayName("BG + buttons")
            .environmentObject(ApiClient(previewEnabled: true))

        NowPlayingBar(player: player())
            .previewDisplayName("Content")
            .environmentObject(ApiClient(previewEnabled: true))
    }
}
// swiftlint:enable all
#endif

private struct NowPlayingBar: View {
    @ObservedObject
    private var player: MusicPlayer

    @State
    var isOpen = false

    init(player: MusicPlayer = .shared) {
        _player = ObservedObject(wrappedValue: player)
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                isOpen = true
            } label: {
                SongInfo(song: $player.currentSong)
                    .frame(height: 60)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            PlayPauseButton(player: player)
                .frame(width: 60, height: 60)
                .font(.title2)
                .buttonStyle(.plain)
                // Increase the tap area
                .padding(.leading)
                .contentShape(Rectangle())

            PlayNextButton(player: player)
                .font(.title2)
                .frame(width: 60, height: 60)
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(player.upNext.isEmpty)
        }
        .padding(.trailing, 10)
        .frame(width: Screen.size.width, height: 65)
        .background(Blur())
        .sheet(isPresented: $isOpen) {
            SheetCloseButton(isPresented: $isOpen)
            MusicPlayerScreen()
        }
    }
}

private struct SongInfo: View {
    @Binding
    var song: Song?

    var body: some View {
        HStack {
            ArtworkComponent(for: song?.albumId ?? .empty)
                .frame(width: 50, height: 50)
                .shadow(radius: 6, x: 0, y: 3)
                .padding(.leading)

            Text(song?.name ?? .empty)
                .font(.system(size: 16))
                .padding(.leading, 10)
                .lineLimit(1)

            Spacer()
        }
    }
}

/// Blur effect.
///
/// From: https://itnext.io/add-a-now-playing-bar-with-swiftui-to-your-app-d515b03f05e3
struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemChromeMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
