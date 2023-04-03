import SFSafeSymbols
import SwiftUI

/// Now playing component, somewhat similar what can be seen in Apple Music app.
///
/// Base implementation taken from: https://itnext.io/add-a-now-playing-bar-with-swiftui-to-your-app-d515b03f05e3
struct NowPlayingComponent<Content: View>: View {
    @Binding
    var isPresented: Bool

    var content: Content

    var body: some View {
        ZStack(alignment: .bottom) {
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

        NowPlayingBar(player: player())
            .previewDisplayName("Content")
    }
}
#endif

private struct NowPlayingBar: View {
    @ObservedObject
    private var player: MusicPlayer

    @State
    var isOpen: Bool = false

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

            SkipButton(player: player)
        }
        .padding(.trailing, 10)
        .frame(width: UIScreen.main.bounds.size.width, height: 65)
        .background(Blur())
        .sheet(isPresented: $isOpen) {
            MusicPlayerScreen(controller: .init())
        }
    }
}

private struct SongInfo: View {
    @Binding
    var song: Song?

    var body: some View {
        HStack {
            ArtworkComponent(itemId: song?.uuid ?? "")
                .frame(width: 50, height: 50)
                .shadow(radius: 6, x: 0, y: 3)
                .padding(.leading)

            Text(song?.name ?? "")
                .font(.title3)
                .padding(.leading, 10)

            Spacer()
        }
    }
}

private struct PlayPauseButton: View {
    @ObservedObject
    var player: MusicPlayer

    var body: some View {
        Button {
            player.isPlaying ? player.pause() : player.resume()
        } label: {
            Image(systemSymbol: player.isPlaying ? .pauseFill : .playFill)
                .font(.title2)
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct SkipButton: View {
    @ObservedObject
    var player: MusicPlayer

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: .forwardFill)
                .font(.title2)
                .frame(width: 60, height: 60)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func action() {
        Task(priority: .userInitiated) {
            do {
                try await player.skipForward()
            } catch {
                print("Failed to skip")
            }
        }
    }
}

/// Blur effect.
///
/// From: https://itnext.io/add-a-now-playing-bar-with-swiftui-to-your-app-d515b03f05e3
struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemChromeMaterial

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
