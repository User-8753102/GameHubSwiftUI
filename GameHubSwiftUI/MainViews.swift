import SwiftUI

private enum PageMetrics {
    static let contentMinWidth: CGFloat = 1080
}

struct HomeView: View {
    let navigate: (AppRoute) -> Void
    private let trending = [
        Game(id: "hades", name: "Hades II", artwork: "hades", subtitle: "Battle beyond the Underworld.", score: "9.3", genres: "Action · RPG", installed: false),
        Game(id: "slay2", name: "Slay the Spire 2", artwork: "slay2", subtitle: "Reunite with your deck.", score: "9.1", genres: "Strategy · RPG", installed: false),
        Game(id: "sultan", name: "Sultan's Game", artwork: "sultan", subtitle: "Survive the Sultan's weekly command.", score: "8.8", genres: "Strategy · Adventure", installed: false),
        Game(id: "cyberpunk", name: "Cyberpunk 2077", artwork: "cyberpunk", subtitle: "Wake up, Samurai.", score: "9.0", genres: "RPG · Open World", installed: false)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .center, spacing: 30) {
                    ZStack(alignment: .bottomLeading) {
                        ArtworkImage(name: "home_hero")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .mask {
                                LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom)
                            }
                        HStack(spacing: 10) {
                            Capsule().fill(.white).frame(width: 38, height: 6)
                            ForEach(0..<6, id: \.self) { _ in Circle().fill(.white.opacity(0.25)).frame(width: 6, height: 6) }
                        }
                        .padding(34)
                    }

                    VStack(alignment: .leading, spacing: 22) {
                        HStack(spacing: 14) {
                            ForEach(["cyberpunk", "assetto", "hades"], id: \.self) { art in
                                ArtworkImage(name: art)
                                    .frame(width: 92, height: 58)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        Text("Forza Horizon 6")
                            .font(.system(size: 27, weight: .bold))
                            .foregroundStyle(GHTheme.text)
                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text("Excellent").font(.caption.bold())
                                Text("8.6").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(GHTheme.accent)
                            }
                            .padding(.horizontal, 18).padding(.vertical, 11).glassPanel(radius: 14)
                            FlowLayout(spacing: 7) {
                                ForEach(["Simulation", "Sports", "Racing"], id: \.self) { tag in
                                    Text(tag).padding(.horizontal, 12).padding(.vertical, 7).glassPanel(radius: 10)
                                }
                            }
                        }
                        Text("Drive over 550 real cars and explore the breathtaking landscapes of Japan in the biggest Horizon adventure yet.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineSpacing(6)
                        Spacer()
                        HStack {
                            Image(systemName: "steeringwheel").font(.title2)
                            Spacer()
                            CapsuleButton(title: "Daily Picks", symbol: "sparkles", primary: true)
                        }
                    }
                    .frame(width: 380, alignment: .leading)
                    .padding(.vertical, 25)
                }
                .frame(height: 500)

                Text("Weekly Trending")
                    .font(.system(size: 23, weight: .bold))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                    ForEach(trending) { game in
                        GameCard(game: game, compact: true) { navigate(.detail(game)) }
                    }
                }
            }
            .padding(.horizontal, 54)
            .padding(.top, 44)
            .padding(.bottom, 50)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

struct RankingsView: View {
    let navigate: (AppRoute) -> Void

    private let columns: [(String, String, [String])] = [
        ("Popular Ranking", "rank_popular", ["Stardew Valley", "Hollow Knight", "Slay the Spire", "Red Dead Redemption 2", "Left 4 Dead 2", "Sultan's Game"]),
        ("Hot-Play Ranking", "rank_hot", ["Slay the Spire 2", "CRIMSON DESERT", "Resident Evil 4", "Grand Theft Auto V Legacy", "Monster Hunter: World", "Borderlands 3"]),
        ("Top-Selling Ranking", "rank_selling", ["Monster Hunter: World", "Resident Evil Village", "Monster Hunter Wilds", "Resident Evil 4", "DEATH STRANDING", "REMNANT II®"])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                PageTitle(title: "Rankings")
                HStack(alignment: .top, spacing: 22) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                        RankingColumn(title: column.0, artwork: column.1, names: column.2) {
                            navigate(.detail(index == 0 ? Game.buckshot : Game.rocket))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(54)
            .frame(minWidth: PageMetrics.contentMinWidth, maxWidth: .infinity, alignment: .topLeading)
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
                    Text("\(offset + 2)").font(.headline).foregroundStyle(offset == 0 ? .white : .secondary).frame(width: 20)
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.07)).frame(width: 64, height: 35)
                        .overlay(ArtworkImage(name: offset.isMultiple(of: 2) ? "slay2" : "buckshot").clipShape(RoundedRectangle(cornerRadius: 6)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name).font(.system(size: 14, weight: .bold)).lineLimit(1)
                        Text("Explore a new world where excitement awaits.").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 650, alignment: .top)
        .glassPanel(radius: 24)
    }
}

struct BrowseView: View {
    let navigate: (AppRoute) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                PageTitle(title: "Search")
                HStack {
                    Text("All games").font(.system(size: 23, weight: .bold))
                    Text("(2217)").foregroundStyle(GHTheme.secondary)
                    Spacer()
                    CapsuleButton(title: "Name (A-Z)", symbol: "line.3.horizontal.decrease")
                    CapsuleButton(title: "Release Date", symbol: "arrow.down")
                    CapsuleButton(title: "Review Score", symbol: "arrow.down")
                    CapsuleButton(title: "Filter", symbol: "line.3.horizontal.decrease")
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 30) {
                    ForEach(Game.browseGames) { game in
                        GameCard(game: game) { navigate(.detail(game)) }
                    }
                }
            }
            .padding(54)
            .frame(minWidth: PageMetrics.contentMinWidth, maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

struct LibraryView: View {
    let navigate: (AppRoute) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PageTitle(title: "My Games")
                HStack(spacing: 12) {
                    CapsuleButton(title: "All", symbol: "chevron.down")
                    CapsuleButton(title: "Name (A-Z)", symbol: "chevron.down")
                    Divider().frame(height: 36)
                    CapsuleButton(title: "Add Game", symbol: "gamecontroller")
                    Spacer()
                    CapsuleButton(title: "Search games...", symbol: "magnifyingglass")
                }

                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 25) {
                        SectionHeader(title: "Installed", count: 2)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 22) {
                            GameCard(game: .buckshot, compact: true) { navigate(.detail(.buckshot)) }
                            GameCard(game: .rocket, compact: true) { navigate(.detail(.rocket)) }
                        }
                        SectionHeader(title: "Not Installed", count: 150)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 26) {
                            ForEach(Game.browseGames) { game in
                                GameCard(game: game, compact: true) { navigate(.detail(game)) }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    AccountsPanel()
                        .frame(width: 330)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(54)
            .frame(minWidth: PageMetrics.contentMinWidth, maxWidth: .infinity, alignment: .topLeading)
        }
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
    var body: some View {
        VStack(spacing: 14) {
            account(title: "Steam", symbol: "circle.grid.cross", details: "AURA  •  Online\n121 games  ·  4997.5h")
            account(title: "Epic Games", symbol: "shield", details: "Call Me L.\n31 games")
            account(title: "GOG", symbol: "circle", details: "Login to GOG Now")
        }
    }

    private func account(title: String, symbol: String, details: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol).font(.headline)
            Divider().opacity(0.4)
            Text(details).font(.system(size: 13, weight: .semibold)).foregroundStyle(GHTheme.blue).lineSpacing(7)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(radius: 17)
    }
}

struct GameDetailView: View {
    let game: Game
    let navigate: (AppRoute) -> Void
    @State private var showingMenu = false
    @State private var engineMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(spacing: 15) {
                    Button { navigate(.page(.library)) } label: { Image(systemName: "chevron.left").font(.title2) }
                        .buttonStyle(.plain)
                    PageTitle(title: game.name)
                }

                HStack(alignment: .top, spacing: 34) {
                    VStack(spacing: 22) {
                        ZStack(alignment: .bottom) {
                            ArtworkImage(name: game.id == "buckshot" ? "buckshot_hero" : game.artwork)
                                .frame(maxWidth: .infinity)
                                .frame(height: 480)
                                .clipped()
                                .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom))

                            HStack(spacing: 10) {
                                CapsuleButton(
                                    title: game.installed ? "Play" : "Download 2.3 GB",
                                    symbol: "circle.grid.cross",
                                    primary: true
                                ) {
                                    engineMessage = "Préparation du conteneur local…"
                                    Task {
                                        engineMessage = await EngineBridge.launch(game)
                                    }
                                }
                                Button { showingMenu.toggle() } label: {
                                    Image(systemName: "ellipsis").font(.title3.bold()).frame(width: 44, height: 42)
                                        .background(Color.white.opacity(0.08), in: Circle())
                                }
                                .buttonStyle(.plain)
                                .popover(isPresented: $showingMenu, arrowEdge: .bottom) {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Button("Create Shortcut", systemImage: "arrow.up.forward.app") { showingMenu = false }
                                        Button("Game Settings", systemImage: "display") { showingMenu = false; navigate(.gameSettings) }
                                        Button("Open Folder", systemImage: "folder") { showingMenu = false }
                                        Button("Repair Game", systemImage: "arrow.clockwise") { showingMenu = false }
                                        Button("Uninstall Game", systemImage: "trash", role: .destructive) { showingMenu = false }
                                    }
                                    .buttonStyle(.plain).padding(20).frame(width: 210, alignment: .leading)
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

                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                Text("Compatibility Reviews").font(.headline)
                                Spacer()
                                Text("View details  ›").foregroundStyle(.secondary)
                            }
                            HStack { Text("3.5").font(.title2.bold()); Text("★★★★☆").foregroundStyle(.yellow) }
                            Text("Well-adapted, experience is nearly perfectly smooth. · 6 reviews").foregroundStyle(.secondary)
                        }
                        .padding(24).glassPanel(radius: 18)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)

                    GameInfoPanel(game: game).frame(width: 350)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(54)
            .frame(minWidth: PageMetrics.contentMinWidth, maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct GameInfoPanel: View {
    let game: Game
    private let rows = [("Developer", "Mike Klubnika"), ("Publisher", "Unknown publisher"), ("Release Date", "2024-04-04"), ("Estimated Download", "858.6 MB"), ("Platforms", "◉"), ("Cloud Saves", "Manual")]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Reviews:  Stellar", systemImage: "sparkles").foregroundStyle(GHTheme.accent).font(.headline)
                Spacer()
                Text(game.score).font(.title2.bold()).foregroundStyle(GHTheme.accent)
            }
            FlowLayout(spacing: 8) {
                ForEach(game.genres.components(separatedBy: " · "), id: \.self) { Text($0).padding(.horizontal, 12).padding(.vertical, 6).glassPanel(radius: 10) }
            }
            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0).foregroundStyle(GHTheme.secondary)
                    Spacer()
                    Text(row.1).foregroundStyle(GHTheme.blue)
                }
                Divider().opacity(0.45)
            }
        }
        .padding(26)
        .glassPanel(radius: 22)
    }
}

struct DownloadsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 35) {
                PageTitle(title: "Downloads")
                SectionHeader(title: "Queue", count: 0)
                Text("The queue is empty.").foregroundStyle(.secondary).padding(.leading, 16)
                SectionHeader(title: "Completed", count: 1)
                HStack(spacing: 22) {
                    ArtworkImage(name: "rocket").frame(width: 160, height: 94).clipShape(RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rocket League®").font(.system(size: 24, weight: .bold))
                        Text("36.42 GB / 36.42 GB").foregroundStyle(.secondary)
                    }
                    Spacer()
                    CapsuleButton(title: "Remove")
                }
                .padding(34)
                .glassPanel(radius: 28)
            }
            .padding(54)
            .frame(minWidth: PageMetrics.contentMinWidth, maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
