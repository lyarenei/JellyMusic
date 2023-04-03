import SwiftUI

struct HomeScreen: View {
    @ObservedObject
    private var player: MusicPlayer = MusicPlayer.shared

    @State
    private var isPlayerPresented = false

    @State
    private var isPlayerOpen = false

    var body: some View {
        TabView {
            NowPlayingComponent(
                isPresented: $isPlayerPresented,
                content: LibraryScreen()
            )
            .tabItem {
                Image(systemSymbol: .musicQuarternote3)
                Text("Library")
            }
            .tag("library_tab")

            Text("Search")
                .tabItem {
                    Image(systemSymbol: .magnifyingglass)
                    Text("Search")
                }
                .tag("search_tab")

            SettingsScreen()
                .tabItem {
                    Image(systemSymbol: .gear)
                    Text("Settings")
                }
                .tag("settings_tab")
        }
        .onChange(of: player.currentSong) { curSong in
            withAnimation(.linear) {
                isPlayerPresented = curSong != nil
            }
        }
    }
}

#if DEBUG
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
#endif
