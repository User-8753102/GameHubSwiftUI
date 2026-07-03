import SwiftUI

struct RootView: View {
    @State private var route: AppRoute = .page(.home)
    @State private var showSearch = false

    private var selectedPage: AppPage? {
        if case let .page(page) = route { return page }
        return nil
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            HStack(spacing: 0) {
                if route != .page(.settings), route != .gameSettings {
                    Sidebar(selected: selectedPage, navigate: navigate, showSearch: { showSearch = true })
                }

                Group {
                    switch route {
                    case .page(.home):
                        HomeView(navigate: navigate)
                    case .page(.rankings):
                        RankingsView(navigate: navigate)
                    case .page(.browse):
                        BrowseView(navigate: navigate)
                    case .page(.library):
                        LibraryView(navigate: navigate)
                    case .page(.downloads):
                        DownloadsView()
                    case .page(.settings):
                        GlobalSettingsView()
                    case .detail(let game):
                        GameDetailView(game: game, navigate: navigate)
                    case .gameSettings:
                        GameSettingsView(navigate: navigate)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .clipped()

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

        route = destination
    }
}
