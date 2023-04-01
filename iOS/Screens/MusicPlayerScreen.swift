import SFSafeSymbols
import SwiftUI

struct MusicPlayerScreen: View {
    @StateObject
    private var controller: MusicPlayerController

    @ObservedObject
    private var player: MusicPlayer

    init(
        controller: MusicPlayerController,
        player: MusicPlayer = .shared
    ) {
        _controller = StateObject(wrappedValue: controller)
        _player = ObservedObject(wrappedValue: player)
    }

    var body: some View {
        if let song = player.currentSong {
            Group {
                VStack(spacing: 15) {
                    ArtworkComponent(itemId: song.uuid)
                        .frame(width: 270, height: 270)

                    SongWithActions(song: song)

                    SeekBar(song: song, controller: controller)
                        .disabled(true)

                    PlaybackControl()
                        .font(.largeTitle)
                        .buttonStyle(.plain)
                        .padding(.horizontal, 50)

                    VolumeBar()
                        .font(.footnote)
                        .padding(.bottom, 20)
                        .disabled(true)
                        .foregroundColor(.init(UIColor.secondaryLabel))

                    BottomPlaceholder()
                        .padding(.horizontal, 50)
                        .font(.title3)
                        .foregroundColor(.init(UIColor.secondaryLabel))
                        .frame(height: 40)
                }
                .padding([.top, .horizontal], 30)
            }
            .popupTitle(song.name)
            .popupImage(Image(systemSymbol: .square))
            .popupBarMarqueeScrollEnabled(true)
            .popupBarItems({
                HStack(spacing: 20) {
                    Button {
                        controller.onPlayPauseButton()
                    } label: {
                        Image(systemSymbol: controller.playIcon)
                    }
                    .buttonStyle(.plain)

                    Button {
                        controller.onSkipForward()
                    } label: {
                        Image(systemSymbol: .forwardFill)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
            })
        } else {
            EmptyView()
        }
    }
}

#if DEBUG
struct MusicPlayerScreen_Previews: PreviewProvider {
    static var player = {
        var mp = MusicPlayer(preview: true)
        mp.currentSong = PreviewData.songs[0]
        return mp
    }

    static var previews: some View {
        MusicPlayerScreen(controller: MusicPlayerController(preview: true), player: player())
    }
}
#endif

// MARK: - Song with actions

private struct SongWithActions: View {
    var song: Song

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(song.name)
                    .bold()
                    .lineLimit(1)
                    .font(.title2)

                Text("song.artistName")
                    .lineLimit(1)
                    .font(.body)
            }

            Spacer()

            Button {
                // Options button
            } label: {
                Image(systemSymbol: .ellipsisCircle)
            }
            .font(.title2)
            .disabled(true)
        }
    }
}

// MARK: - Playback bar

private struct SeekBar: View {
    @ObservedObject private var controller: MusicPlayerController

    @State private var progress: TimeInterval = 0
    @State private var currentTime: TimeInterval = 0
    @State private var remainingTime: TimeInterval

    private let song: Song

    init(
        song: Song,
        controller: MusicPlayerController
    ) {
        self.song = song
        _controller = ObservedObject(wrappedValue: controller)
        remainingTime = song.runtime
    }

    var body: some View {
        VStack(spacing: 0) {
            Slider(
                value: $progress,
                in: 0 ... song.runtime
            )
            .onChange(of: progress, perform: { newValue in
                currentTime = progress
                remainingTime = song.runtime - progress
            })

            HStack {
                Text(currentTime.timeString)
                    .font(.caption)

                Spacer()

                Text(remainingTime.timeString)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Playback control

private struct PlaybackControl: View {
    @ObservedObject
    private var player: MusicPlayer = .shared

    var body: some View {
        HStack {
            Button {
                // Previous song
            } label: {
                Image(systemSymbol: .backwardFill)
            }
            .font(.title2)
            .disabled(true)

            Spacer()

            Button {
                player.isPlaying ? player.pause() : player.resume()
            } label: {
                if self.player.isPlaying {
                    Image(systemSymbol: .pauseFill)
                } else {
                    Image(systemSymbol: .playFill)
                }
            }

            Spacer()

            Button { Task(priority: .userInitiated) {
                do {
                    try await player.skipForward()
                } catch {
                    print("Skip to next track failed: \(error)")
                }
            }} label: {
                Image(systemSymbol: .forwardFill)
            }
            .font(.title2)
        }
        .frame(height: 40)
    }
}

// MARK: - Volume bar

private struct VolumeBar: View {
    @State
    private var volumePercent: Double = 0.35

    var body: some View {
        HStack {
            Image(systemSymbol: .speakerFill)

            Slider(
                value: $volumePercent,
                in: 0 ... 1
            )

            Image(systemSymbol: .speakerWave3Fill)
        }
    }
}

private struct BottomPlaceholder: View {
    @State var airplayPresented: Bool = false

    var body: some View {
        HStack {
            Image(systemSymbol: .quoteBubble)
            Spacer()
            AirPlayComponent()
            Spacer()
            Image(systemSymbol: .listBullet)
        }
    }
}
