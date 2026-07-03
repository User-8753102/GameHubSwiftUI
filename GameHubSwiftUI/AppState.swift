import AppKit
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published var downloads: [DownloadItem] = []
    @Published var statusMessage: String?
    @Published var maxSimultaneousDownloads = 2
    @Published var closeToMenuBar = true
    @Published var localDiagnosticsLog = false
    @Published var showDemoCatalog = true

    private var simulationTask: Task<Void, Never>?

    init() {
        reloadLibrary()
    }

    var gameHubStoreFound: Bool {
        GameHubDataStore.isAvailable
    }

    var installedGames: [Game] {
        games.filter(\.installed)
    }

    var notInstalledGames: [Game] {
        games.filter { !$0.installed }
    }

    var browseGames: [Game] {
        games.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var trendingGames: [Game] {
        Array(games.sorted { $0.score > $1.score }.prefix(8))
    }

    var activeDownloadCount: Int {
        downloads.filter { $0.state.isActive || $0.state == .queued }.count
    }

    func game(for id: Game.ID) -> Game? {
        games.first { $0.id == id }
    }

    func reloadLibrary() {
        let bindings = GameHubDataStore.loadContainerBindings()
        let settingsByAppID = GameHubDataStore.loadSettingsByAppID()
        let steamState = SteamLibraryState()
        var catalogByAppID = Dictionary(uniqueKeysWithValues: Game.allCatalog.compactMap { game in
            game.platformAppID.map { ($0, game) }
        })
        var output: [Game] = []
        var usedIDs = Set<Game.ID>()

        for binding in bindings {
            guard let appID = binding.platformAppID else { continue }
            var game = catalogByAppID[appID] ?? Game(
                id: "\(binding.platform.rawValue)-\(appID)",
                name: binding.gameName,
                artwork: fallbackArtwork(for: appID),
                subtitle: "Configured locally in GameHub.",
                score: "8.0",
                genres: binding.platform.label,
                installed: true,
                platform: binding.platform,
                platformAppID: appID
            )
            game.name = binding.gameName
            game.platform = binding.platform
            game.platformAppID = appID
            game.gameID = binding.gameID
            game.installPath = binding.gamePath
            game.installed = true
            if let stored = settingsByAppID[appID] {
                game.stableKeyHash = stored.stableKeyHash
                game.settings = stored.settings
            }
            if let manifestName = steamState.name(forAppID: appID), game.name.hasPrefix("Steam ·") {
                game.name = manifestName
            }
            output.append(game)
            usedIDs.insert(game.id)
            catalogByAppID[appID] = game
        }

        for var game in Game.allCatalog where !usedIDs.contains(game.id) {
            if let stored = game.platformAppID.flatMap({ settingsByAppID[$0] }) {
                game.stableKeyHash = stored.stableKeyHash
                game.settings = stored.settings
            }
            switch steamState.state(forAppID: game.platformAppID) {
            case .installed:
                game.installed = true
                game.downloadProgress = nil
            case .downloading(let progress):
                game.installed = false
                game.downloadProgress = progress
            case .notInstalled:
                if game.platform.isReal {
                    game.installed = false
                }
            }
            if game.platform == .demo, !showDemoCatalog { continue }
            output.append(game)
        }

        games = output
        seedCompletedDownloadsIfNeeded()
    }

    func launchOrDownload(_ game: Game) async -> String {
        if game.installed {
            return await EngineBridge.launch(game)
        }
        startDownload(for: game)
        if game.platform == .steam, let appID = game.platformAppID {
            let opened = GameHubActionService.openSteamInstall(appID: appID)
            return opened
                ? "Steam opened to install \(game.name)."
                : "Unable to open Steam. The download was added to the local queue."
        }
        return "Download queued for \(game.name)."
    }

    func startDownload(for game: Game) {
        guard !downloads.contains(where: { $0.gameID == game.id && !$0.state.isFinal }) else {
            return
        }
        let total = max(game.installSizeBytes, 200_000_000)
        downloads.append(DownloadItem(
            gameID: game.id,
            title: game.name,
            artwork: game.artwork,
            state: game.platform == .steam ? .preparing : .queued,
            progress: game.downloadProgress ?? 0,
            totalBytes: total,
            external: game.platform == .steam
        ))
        ensureSimulationRunning()
    }

    func pauseDownload(_ item: DownloadItem) {
        setState(.paused, for: item.id)
    }

    func resumeDownload(_ item: DownloadItem) {
        setState(.queued, for: item.id)
        ensureSimulationRunning()
    }

    func cancelDownload(_ item: DownloadItem) {
        setState(.cancelled, for: item.id)
    }

    func clearFinishedDownloads() {
        downloads.removeAll { $0.state.isFinal }
    }

    func saveCompat(_ settings: GameSettings, for game: Game) {
        guard let index = games.firstIndex(where: { $0.id == game.id }) else { return }
        games[index].settings = settings
        statusMessage = "Compatibility profile saved locally for \(game.name)."
    }

    func createShortcut(for game: Game) {
        statusMessage = GameHubActionService.createShortcut(for: game)
            ? "Shortcut created on the Desktop."
            : "Shortcut unavailable for this game."
    }

    func openFolder(for game: Game) {
        statusMessage = GameHubActionService.openFolder(for: game)
            ? "Opened local game folder."
            : "No local folder is available."
    }

    func repair(_ game: Game) {
        EngineBridge.openEngine()
        statusMessage = "Opened the local GameHub engine for repair."
    }

    func manageDLC(_ game: Game) {
        if game.platform == .steam, let appID = game.platformAppID, GameHubActionService.openSteamStore(appID: appID) {
            statusMessage = "Opened Steam store/DLC page."
        } else {
            statusMessage = "DLC management is unavailable for this game."
        }
    }

    func uninstall(_ game: Game) {
        statusMessage = "Uninstall is intentionally delegated to the original GameHub engine."
        EngineBridge.openEngine()
    }

    private func setState(_ state: DownloadState, for id: DownloadItem.ID) {
        guard let index = downloads.firstIndex(where: { $0.id == id }) else { return }
        downloads[index].state = state
        if !state.isActive {
            downloads[index].speedBytesPerSecond = 0
        }
    }

    private func ensureSimulationRunning() {
        guard simulationTask == nil else { return }
        simulationTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(350))
                self.tickSimulation()
                if self.downloads.allSatisfy({ $0.state.isFinal || $0.state == .paused || $0.external }) {
                    self.simulationTask = nil
                    return
                }
            }
        }
    }

    private func tickSimulation() {
        var activeSlots = maxSimultaneousDownloads
        for index in downloads.indices {
            var item = downloads[index]
            if item.external {
                if item.state == .preparing { item.state = .downloading }
                downloads[index] = item
                continue
            }

            switch item.state {
            case .queued where activeSlots > 0:
                item.state = .preparing
                activeSlots -= 1
            case .preparing:
                item.state = .downloading
                activeSlots -= 1
            case .downloading:
                activeSlots -= 1
                let speed = Int64.random(in: 35_000_000...85_000_000)
                item.speedBytesPerSecond = speed
                item.progress = min(1, item.progress + Double(speed) * 0.35 / Double(item.totalBytes))
                if item.progress >= 1 {
                    item.state = .unpacking
                    item.speedBytesPerSecond = 0
                }
            case .unpacking:
                item.state = .verifying
            case .verifying:
                item.state = .completed
            default:
                break
            }
            downloads[index] = item
        }
    }

    private func seedCompletedDownloadsIfNeeded() {
        guard downloads.isEmpty else { return }
        if let rocket = games.first(where: { $0.id == Game.rocket.id && $0.installed }) {
            downloads.append(DownloadItem(
                gameID: rocket.id,
                title: rocket.name,
                artwork: rocket.artwork,
                state: .completed,
                progress: 1,
                totalBytes: rocket.installSizeBytes > 0 ? rocket.installSizeBytes : 36_420_000_000
            ))
        }
    }

    private func fallbackArtwork(for appID: String) -> String {
        let assets = ["hades", "slay2", "sultan", "cyberpunk", "assetto", "arcade", "bitray", "resist"]
        let seed = appID.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return assets[abs(seed) % assets.count]
    }
}
