import SFSafeSymbols
import SwiftUI

struct MusicPlayerScreen: View {
    @ObservedObject
    var player: MusicPlayer

    init(player: MusicPlayer = .shared) {
        _player = ObservedObject(wrappedValue: player)
    }

    var body: some View {
        VStack(spacing: 15) {
            ArtworkComponent(itemId: player.currentSong?.uuid ?? "")
                .frame(width: 270, height: 270)

            SongWithActions(song: $player.currentSong)

            SeekBar(song: $player.currentSong, currentTime: $player.currentTime)
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
}

#if DEBUG
struct MusicPlayerScreen_Previews: PreviewProvider {
    static var player = {
        var mp = MusicPlayer(preview: true)
        mp.currentSong = PreviewData.songs.first!
        return mp
    }

    static var previews: some View {
        MusicPlayerScreen(player: player())
    }
}
#endif

// MARK: - Song with actions

private struct SongWithActions: View {
    @Binding
    var song: Song?

    @State
    var isPopoverPresented: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(song?.name ?? "")
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
    @Binding
    var song: Song?

    @Binding
    var currentTime: TimeInterval

    @State
    private var remainingTime: TimeInterval

    init(
        song: Binding<Song?>,
        currentTime: Binding<TimeInterval>
    ) {
        _song = song
        _currentTime = currentTime
        remainingTime = song.wrappedValue?.runtime ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(
                value: currentTime,
                total: song?.runtime ?? 0
            )
            .progressViewStyle(.linear)
            .padding(.bottom, 10)
            .padding(.top, 15)
            .onChange(of: currentTime, perform: { newValue in
                remainingTime = song?.runtime ?? 0 - newValue
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
