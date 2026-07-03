import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    @State private var route: AppRoute = .page(.home)
    @State private var settingsReturnRoute: AppRoute = .page(.home)
    @State private var showSearch = false

    private var selectedPage: AppPage? {
        if case let .page(page) = route { return page }
        return nil
    }

    private var showsSidebar: Bool {
        if route == .page(.settings) { return false }
        if case .gameSettings = route { return false }
        return true
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                AmbientBackground()
                    .zIndex(-10)

                Group {
                    switch route {
                    case .page(.home):
                        HomeView(appState: appState, navigate: navigate)
                    case .page(.rankings):
                        RankingsView(navigate: navigate)
                    case .page(.browse):
                        BrowseView(appState: appState, navigate: navigate)
                    case .page(.library):
                        LibraryView(appState: appState, navigate: navigate)
                    case .page(.downloads):
                        DownloadsView(appState: appState, navigate: navigate)
                    case .page(.settings):
                        GlobalSettingsView(back: { navigate(settingsReturnRoute) })
                    case .detail(let game):
                        GameDetailView(appState: appState, game: appState.game(for: game.id) ?? game, navigate: navigate)
                    case .gameSettings(let game):
                        GameSettingsView(appState: appState, game: appState.game(for: game.id) ?? game, navigate: navigate)
                    }
                }
                .padding(.leading, showsSidebar ? Sidebar.width : 0)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .clipped()
                .environmentObject(appState)
                .zIndex(1)

                if showsSidebar {
                    Sidebar(selected: selectedPage, navigate: navigate, showSearch: { showSearch = true })
                        .frame(width: Sidebar.width)
                        .layoutPriority(1000)
                        .zIndex(2)
                }

            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
        .overlay {
            if showSearch {
                SearchOverlay(isPresented: $showSearch)
                    .zIndex(10)
            }
        }
        .animation(.easeOut(duration: 0.18), value: showSearch)
    }

    private func navigate(_ destination: AppRoute) {
        guard route != destination else {
            return
        }

        if destination == .page(.settings) {
            settingsReturnRoute = route
        }

        route = destination
    }
}
