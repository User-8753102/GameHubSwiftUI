import SwiftUI

private enum PageMetrics {
    static let maxContentWidth: CGFloat = 1320

    static func padding(for width: CGFloat) -> CGFloat {
        width < 980 ? 28 : 54
    }

    static func cardColumns(width: CGFloat, minimum: CGFloat = 210) -> [GridItem] {
        [GridItem(.adaptive(minimum: minimum, maximum: 320), spacing: 20)]
    }
}

struct HomeView: View {
    @ObservedObject var appState: AppState
    let navigate: (AppRoute) -> Void

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > 1040
            let padding = PageMetrics.padding(for: proxy.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    hero(isWide: isWide)
                        .frame(minHeight: isWide ? 500 : 640)

                    Text("Weekly Trending")
                        .font(.system(size: 23, weight: .bold))

                    LazyVGrid(columns: PageMetrics.cardColumns(width: proxy.size.width), spacing: 20) {
                        ForEach(appState.trendingGames) { game in
                            GameCard(game: game, compact: true) { navigate(.detail(game)) }
                        }
                    }
                }
                .padding(.horizontal, padding)
                .padding(.top, 44)
                .padding(.bottom, 50)
                .frame(maxWidth: PageMetrics.maxContentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    @ViewBuilder
    private func hero(isWide: Bool) -> some View {
        let featured = appState.trendingGames.first ?? .buckshot
        let secondary = Array(appState.trendingGames.dropFirst().prefix(3))
        if isWide {
            HStack(alignment: .center, spacing: 30) {
                heroArtwork(featured)
                heroCopy(featured, secondary: secondary)
                    .frame(width: 380, alignment: .leading)
                    .padding(.vertical, 25)
            }
        } else {
            VStack(alignment: .leading, spacing: 22) {
                heroArtwork(featured)
                    .frame(height: 360)
                heroCopy(featured, secondary: secondary)
            }
        }
    }

    private func heroArtwork(_ game: Game) -> some View {
        ZStack(alignment: .bottomLeading) {
            ArtworkImage(name: game.id == "buckshot" ? "buckshot_hero" : game.artwork)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .mask {
                    LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom)
                }
            HStack(spacing: 10) {
                Capsule().fill(.white).frame(width: 38, height: 6)
                ForEach(0..<6, id: \.self) { _ in
                    Circle().fill(.white.opacity(0.25)).frame(width: 6, height: 6)
                }
            }
            .padding(34)
        }
    }

    private func heroCopy(_ game: Game, secondary: [Game]) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                ForEach(secondary) { game in
                    ArtworkImage(name: game.artwork)
                        .frame(width: 92, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            Text(game.name)
                .font(.system(size: 27, weight: .bold))
                .foregroundStyle(GHTheme.text)
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("Excellent").font(.caption.bold())
                    Text(game.score)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(GHTheme.accent)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .glassPanel(radius: 14)
                FlowLayout(spacing: 7) {
                    ForEach(game.tags, id: \.self) { tag in
                        Text(tag)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .glassPanel(radius: 10)
                    }
                }
            }
            Text(game.subtitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
                .lineSpacing(6)
            Spacer(minLength: 0)
            HStack {
                Image(systemName: game.platform.symbol).font(.title2)
                Spacer()
                CapsuleButton(title: "Daily Picks", symbol: "sparkles", primary: true)
            }
        }
    }
}

struct RankingsView: View {
    let navigate: (AppRoute) -> Void

    private let columns: [(String, String, [String])] = [
        ("Popular Ranking", "slay2", ["Stardew Valley", "Hollow Knight", "Slay the Spire", "Red Dead Redemption 2", "Left 4 Dead 2", "Sultan's Game", "Hades II", "Monster Hunter: World"]),
        ("Hot-Play Ranking", "rank_hot", ["Slay the Spire 2", "CRIMSON DESERT", "Resident Evil 4", "Grand Theft Auto V Legacy", "Monster Hunter: World", "Borderlands 3", "Lies of P", "Assassin's Creed® Syndicate"]),
        ("Top-Selling Ranking", "rank_selling", ["Monster Hunter: World", "Resident Evil Village", "Monster Hunter Wilds", "Resident Evil 4", "DEATH STRANDING", "REMNANT II®", "Palworld", "Resident Evil 7 Biohazard"])
    ]

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > 1120
            let padding = PageMetrics.padding(for: proxy.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    PageTitle(title: "Rankings")
                    if isWide {
                        HStack(alignment: .top, spacing: 22) { rankingColumns }
                    } else {
                        VStack(alignment: .leading, spacing: 22) { rankingColumns }
                    }
                }
                .padding(padding)
                .frame(maxWidth: PageMetrics.maxContentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var rankingColumns: some View {
        ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
            RankingColumn(title: column.0, artwork: column.1, names: column.2) {
                navigate(.detail(index == 0 ? Game.buckshot : Game.rocket))
            }
        }
    }
}

private struct RankingColumn: View {
    let title: String
    let artwork: String
    let names: [String]
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            Text(title).font(.system(size: 22, weight: .bold))
            Button(action: action) {
                ArtworkImage(name: artwork)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.72, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 19))
            }
            .buttonStyle(.plain)
            ForEach(Array(names.enumerated()), id: \.offset) { offset, name in
                HStack(spacing: 12) {
                    Text("\(offset + 2)")
                        .font(.headline)
                        .foregroundStyle(offset == 0 ? .white : .secondary)
                        .frame(width: 20)
                    ArtworkImage(name: offset.isMultiple(of: 2) ? "slay2" : "buckshot")
                        .frame(width: 64, height: 35)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name).font(.system(size: 14, weight: .bold)).lineLimit(1)
                        Text("Explore a new world where excitement awaits.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 590, alignment: .top)
        .glassPanel(radius: 24)
    }
}

struct BrowseView: View {
    @ObservedObject var appState: AppState
    let navigate: (AppRoute) -> Void
    @State private var query = ""
    @State private var minimumScore = 0.0
    @State private var selectedTag: String?

    private var filteredGames: [Game] {
        appState.browseGames.filter { game in
            let queryMatches = query.isEmpty || game.name.localizedCaseInsensitiveContains(query)
            let scoreMatches = (Double(game.score) ?? 0) >= minimumScore
            let tagMatches = selectedTag == nil || game.tags.contains(selectedTag ?? "")
            return queryMatches && scoreMatches && tagMatches
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let padding = PageMetrics.padding(for: proxy.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    PageTitle(title: "Search")
                    BrowseToolbar(query: $query, minimumScore: $minimumScore, selectedTag: $selectedTag)
                    HStack {
                        Text("All games").font(.system(size: 23, weight: .bold))
                        Text("(\(filteredGames.count))").foregroundStyle(GHTheme.secondary)
                    }

                    LazyVGrid(columns: PageMetrics.cardColumns(width: proxy.size.width), spacing: 30) {
                        ForEach(filteredGames) { game in
                            GameCard(game: game) { navigate(.detail(game)) }
                        }
                    }
                }
                .padding(padding)
                .frame(maxWidth: PageMetrics.maxContentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

private struct BrowseToolbar: View {
    @Binding var query: String
    @Binding var minimumScore: Double
    @Binding var selectedTag: String?

    var body: some View {
        FlowLayout(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search games...", text: $query)
                    .textFieldStyle(.plain)
                    .frame(width: 210)
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
            Menu("Name (A-Z)", systemImage: "line.3.horizontal.decrease") { Button("A-Z") { } }
            Menu("Review Score", systemImage: "arrow.down") {
                Button("All") { minimumScore = 0 }
                Button("8.0+") { minimumScore = 8 }
                Button("9.0+") { minimumScore = 9 }
            }
            Menu("Filter", systemImage: "line.3.horizontal.decrease") {
                Button("All") { selectedTag = nil }
                ForEach(["Indie", "Action", "Adventure", "RPG", "Simulation", "Racing", "Sports"], id: \.self) { tag in
                    Button(tag) { selectedTag = tag }
                }
            }
        }
    }
}

struct LibraryView: View {
    @ObservedObject var appState: AppState
    let navigate: (AppRoute) -> Void
    @State private var query = ""

    private var installed: [Game] {
        filter(appState.installedGames)
    }

    private var notInstalled: [Game] {
        filter(appState.notInstalledGames)
    }

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > 1120
            let padding = PageMetrics.padding(for: proxy.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    PageTitle(title: "My Games")
                    libraryToolbar

                    if isWide {
                        HStack(alignment: .top, spacing: 28) {
                            librarySections(width: proxy.size.width)
                            AccountsPanel(appState: appState).frame(width: 330)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 28) {
                            AccountsPanel(appState: appState)
                            librarySections(width: proxy.size.width)
                        }
                    }
                }
                .padding(padding)
                .frame(maxWidth: PageMetrics.maxContentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var libraryToolbar: some View {
        FlowLayout(spacing: 12) {
            CapsuleButton(title: "All", symbol: "chevron.down")
            CapsuleButton(title: "Name (A-Z)", symbol: "chevron.down")
            CapsuleButton(title: "Add Game", symbol: "gamecontroller") {
                appState.statusMessage = "Add Game is delegated to the local GameHub engine."
                EngineBridge.openEngine()
            }
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search games...", text: $query)
                    .textFieldStyle(.plain)
                    .frame(width: 210)
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
            .background(Color.white.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func librarySections(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 25) {
            SectionHeader(title: "Installed", count: installed.count)
            LazyVGrid(columns: PageMetrics.cardColumns(width: width, minimum: 180), spacing: 22) {
                ForEach(installed) { game in
                    GameCard(game: game, compact: true) { navigate(.detail(game)) }
                }
            }
            SectionHeader(title: "Not Installed", count: notInstalled.count)
            LazyVGrid(columns: PageMetrics.cardColumns(width: width, minimum: 180), spacing: 26) {
                ForEach(notInstalled) { game in
                    GameCard(game: game, compact: true) { navigate(.detail(game)) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func filter(_ games: [Game]) -> [Game] {
        games.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
    }
}

private struct SectionHeader: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title).font(.system(size: 22, weight: .bold))
            Text("(\(count))").foregroundStyle(GHTheme.secondary)
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }
}

private struct AccountsPanel: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            account(
                title: "Steam",
                symbol: "circle.grid.cross",
                details: "Optional account · \(appState.installedGames.filter { $0.platform == .steam }.count) installed\nNo account required"
            )
            account(title: "Epic Games", symbol: "shield", details: "Optional account\n\(appState.installedGames.filter { $0.platform == .epic }.count) games")
            account(title: "GOG", symbol: "circle", details: "Login to GOG Now")
            if let status = appState.statusMessage {
                Label(status, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(GHTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .glassPanel(radius: 14)
            }
        }
    }

    private func account(title: String, symbol: String, details: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.headline)
            Divider().opacity(0.4)
            Text(details)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GHTheme.blue)
                .lineSpacing(7)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(radius: 17)
    }
}

struct GameDetailView: View {
    @ObservedObject var appState: AppState
    let game: Game
    let navigate: (AppRoute) -> Void
    @State private var showingMenu = false
    @State private var engineMessage: String?

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > 1120
            let padding = PageMetrics.padding(for: proxy.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(spacing: 15) {
                        Button { navigate(.page(.library)) } label: { Image(systemName: "chevron.left").font(.title2) }
                            .buttonStyle(.plain)
                        PageTitle(title: game.name)
                    }

                    if isWide {
                        HStack(alignment: .top, spacing: 34) {
                            mainDetail
                            GameInfoPanel(game: game).frame(width: 350)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 26) {
                            mainDetail
                            GameInfoPanel(game: game)
                        }
                    }
                }
                .padding(padding)
                .frame(maxWidth: PageMetrics.maxContentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var mainDetail: some View {
        VStack(spacing: 22) {
            ZStack(alignment: .bottom) {
                ArtworkImage(name: game.id == "buckshot" ? "buckshot_hero" : game.artwork)
                    .frame(maxWidth: .infinity)
                    .frame(height: 460)
                    .clipped()
                    .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))

                HStack(spacing: 10) {
                    CapsuleButton(
                        title: game.primaryActionTitle,
                        symbol: game.installed ? "play.fill" : "arrow.down.circle",
                        primary: true
                    ) {
                        engineMessage = game.installed ? "Preparing local container..." : "Queueing download..."
                        Task {
                            engineMessage = await appState.launchOrDownload(game)
                        }
                    }
                    Button { showingMenu.toggle() } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3.bold())
                            .frame(width: 44, height: 42)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingMenu, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 16) {
                            Button("Create Shortcut", systemImage: "arrow.up.forward.app") { appState.createShortcut(for: game); showingMenu = false }
                            Button("Game Settings", systemImage: "display") { showingMenu = false; navigate(.gameSettings(game)) }
                            Button("Open Folder", systemImage: "folder") { appState.openFolder(for: game); showingMenu = false }
                            Button("Repair Game", systemImage: "arrow.clockwise") { appState.repair(game); showingMenu = false }
                            Button("Manage DLC", systemImage: "shippingbox") { appState.manageDLC(game); showingMenu = false }
                            Button("Uninstall Game", systemImage: "trash", role: .destructive) { appState.uninstall(game); showingMenu = false }
                        }
                        .buttonStyle(.plain)
                        .padding(20)
                        .frame(width: 220, alignment: .leading)
                    }
                }
                .padding(18)
                .background(Color.black.opacity(0.50), in: Capsule())
            }

            if let engineMessage {
                Label(engineMessage, systemImage: "checkmark.circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GHTheme.accent)
            }

            CompatibilityPanel()
            AchievementPanel(game: game)
            DiscussionPanel(game: game)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct GameInfoPanel: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Reviews: Stellar", systemImage: "sparkles")
                    .foregroundStyle(GHTheme.accent)
                    .font(.headline)
                Spacer()
                Text(game.score).font(.title2.bold()).foregroundStyle(GHTheme.accent)
            }
            FlowLayout(spacing: 8) {
                ForEach(game.tags, id: \.self) {
                    Text($0).padding(.horizontal, 12).padding(.vertical, 6).glassPanel(radius: 10)
                }
            }
            infoRow("Developer", game.developer)
            infoRow("Publisher", game.publisher)
            infoRow("Release Date", game.releaseDate)
            infoRow("Estimated Download", game.installSizeText)
            infoRow("Platforms", game.platform.label)
            infoRow("Cloud Saves", (game.settings?.cloudSaves ?? false) ? "Enabled" : "Manual")
        }
        .padding(26)
        .glassPanel(radius: 22)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(title).foregroundStyle(GHTheme.secondary)
                Spacer()
                Text(value).foregroundStyle(GHTheme.blue).multilineTextAlignment(.trailing)
            }
            Divider().opacity(0.45)
        }
    }
}

private struct CompatibilityPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("Compatibility Reviews").font(.headline)
                Spacer()
                Text("View details  ›").foregroundStyle(.secondary)
            }
            HStack {
                Text("3.5").font(.title2.bold())
                Text("★★★★☆").foregroundStyle(.yellow)
            }
            Text("Well-adapted, experience is nearly perfectly smooth. · 6 reviews")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .glassPanel(radius: 18)
    }
}

private struct AchievementPanel: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements").font(.headline)
                Spacer()
                Text("View All  ›").foregroundStyle(.secondary)
            }
            ProgressView(value: Double(game.achievements.filter(\.unlocked).count), total: Double(max(game.achievements.count, 1)))
                .tint(.green)
            FlowLayout(spacing: 10) {
                ForEach(game.achievements) { achievement in
                    Label(achievement.title, systemImage: achievement.unlocked ? "checkmark.circle.fill" : "lock")
                        .font(.caption)
                        .foregroundStyle(achievement.unlocked ? GHTheme.accent : GHTheme.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassPanel(radius: 10)
                }
            }
        }
        .padding(24)
        .glassPanel(radius: 18)
    }
}

private struct DiscussionPanel: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Discussions").font(.headline)
                Spacer()
                Text("View all  ›").foregroundStyle(.secondary)
            }
            ForEach(game.discussions) { thread in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(thread.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                        Text("By \(thread.author)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(thread.replies) replies").font(.caption).foregroundStyle(GHTheme.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(24)
        .glassPanel(radius: 18)
    }
}

struct DownloadsView: View {
    @ObservedObject var appState: AppState
    let navigate: (AppRoute) -> Void

    private var queue: [DownloadItem] {
        appState.downloads.filter { !$0.state.isFinal }
    }

    private var completed: [DownloadItem] {
        appState.downloads.filter { $0.state.isFinal }
    }

    var body: some View {
        GeometryReader { proxy in
            let padding = PageMetrics.padding(for: proxy.size.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 35) {
                    PageTitle(title: "Downloads")
                    SectionHeader(title: "Queue", count: queue.count)
                    if queue.isEmpty {
                        Text("The queue is empty.").foregroundStyle(.secondary).padding(.leading, 16)
                    } else {
                        ForEach(queue) { item in downloadRow(item) }
                    }

                    SectionHeader(title: "Completed", count: completed.count)
                    ForEach(completed) { item in downloadRow(item) }
                    if !completed.isEmpty {
                        CapsuleButton(title: "Clear Finished", symbol: "trash") {
                            appState.clearFinishedDownloads()
                        }
                    }
                }
                .padding(padding)
                .frame(maxWidth: PageMetrics.maxContentWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private func downloadRow(_ item: DownloadItem) -> some View {
        HStack(spacing: 22) {
            ArtworkImage(name: item.artwork)
                .frame(width: 160, height: 94)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title).font(.system(size: 22, weight: .bold))
                Label(item.state.rawValue, systemImage: item.state.symbol)
                    .foregroundStyle(item.state == .failed ? .red : GHTheme.secondary)
                ProgressView(value: item.progress)
                    .tint(GHTheme.accent)
                HStack {
                    Text(item.progressText)
                    Text(item.speedText)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if item.state == .paused {
                CapsuleButton(title: "Resume", symbol: "play") { appState.resumeDownload(item) }
            } else if !item.state.isFinal {
                CapsuleButton(title: "Pause", symbol: "pause") { appState.pauseDownload(item) }
                CapsuleButton(title: "Cancel", symbol: "xmark") { appState.cancelDownload(item) }
            } else {
                CapsuleButton(title: "Remove") {
                    appState.downloads.removeAll { $0.id == item.id }
                }
            }
        }
        .padding(26)
        .glassPanel(radius: 24)
    }
}
