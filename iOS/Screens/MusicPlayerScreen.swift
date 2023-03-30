import SFSafeSymbols
import SwiftUI

struct MusicPlayerScreen: View {
    @ObservedObject
    private var player: MusicPlayer

    init(player: MusicPlayer = .shared) {
        self._player = ObservedObject(wrappedValue: player)
    }

    var body: some View {
        if let song = player.currentSong {
            Group {
                VStack(spacing: 15) {
                    ArtworkComponent(itemId: song.uuid)
                        .frame(width: 270, height: 270)

                    SongWithActions(song: song)

                    SeekBar()
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
                        .padding([.leading, .trailing], 50)
                        .font(.title3)
                        .foregroundColor(.init(UIColor.secondaryLabel))
                }
                .padding([.top, .horizontal], 30)
            }
            .popupTitle(song.name)
            .popupImage(Image(systemSymbol: .square))
            .popupBarMarqueeScrollEnabled(true)
            .popupBarItems({
                HStack(spacing: 20) {
                    Button(action: {
                        player.isPlaying ? player.pause() : player.resume()
                    }) {
                        if player.isPlaying {
                            Image(systemSymbol: .pauseFill)
                        } else {
                            Image(systemSymbol: .playFill)
                        }
                    }
                    .buttonStyle(.plain)

                    Button { Task(priority: .userInitiated) {
                        do {
                            try await player.skipForward()
                        } catch {
                            print("Skip to next track failed: \(error)")
                        }
                    }} label: {
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
        MusicPlayerScreen(player: player())
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
    @ObservedObject private var player: MusicPlayer = .shared

    @State private var progress: TimeInterval = 0
    @State private var currentTime: TimeInterval = 0
    @State private var remainingTime: TimeInterval = 1

    private var fallbackValue: TimeInterval = 1

    var body: some View {
        VStack(spacing: 0) {
            Slider(
                value: $progress,
                in: 0...(player.currentSong?.runtime ?? fallbackValue)
            )
            .onChange(of: progress, perform: { newValue in
                currentTime = progress
                remainingTime = player.currentSong?.runtime ?? fallbackValue - progress
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
    var body: some View {
        HStack {
            Image(systemSymbol: .quoteBubble)
            Spacer()
            Image(systemSymbol: .airplayaudio)
            Spacer()
            Image(systemSymbol: .listBullet)
        }
    }
}
