import Foundation
import SwiftUI

enum AppPage: String, CaseIterable, Identifiable {
    case home, rankings, browse, library, downloads, settings

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .home: "house"
        case .rankings: "chart.bar"
        case .browse: "gamecontroller"
        case .library: "square.grid.2x2"
        case .downloads: "arrow.down.to.line"
        case .settings: "person.crop.circle"
        }
    }
}

enum AppRoute: Equatable {
    case page(AppPage)
    case detail(Game)
    case gameSettings(Game)
}

enum GamePlatform: String, Codable, CaseIterable, Hashable {
    case steam
    case epic
    case gog
    case local
    case demo

    var label: String {
        switch self {
        case .steam: "Steam"
        case .epic: "Epic"
        case .gog: "GOG"
        case .local: "Local"
        case .demo: "Demo"
        }
    }

    var symbol: String {
        switch self {
        case .steam: "circle.grid.cross"
        case .epic: "shield"
        case .gog: "circle"
        case .local: "folder"
        case .demo: "sparkles"
        }
    }

    var isReal: Bool { self != .demo }
}

struct GameSettings: Codable, Hashable {
    var language: String
    var startParameters: String
    var compatibilityLayer: String
    var compatibilityFramework: String
    var graphicsStack: String
    var syncMode: String
    var moltenVK: String
    var dlssMode: String
    var rayTracingMode: String
    var retinaMode: Bool
    var metalHUDEnabled: Bool
    var metal4Enabled: Bool
    var gamepadCompatMode: Bool
    var avxEnabled: Bool
    var bypassAVDecode: Bool
    var dxmtExperimentalDX12: Bool
    var offlineMode: Bool
    var cloudSaves: Bool
    var steamInput: Bool

    static let placeholder = GameSettings(
        language: "system",
        startParameters: "",
        compatibilityLayer: "wine-proton_11.0",
        compatibilityFramework: "proton",
        graphicsStack: "gptk-3.0-3",
        syncMode: "msync",
        moltenVK: "builtin-moltenvk-1.4.2",
        dlssMode: "disabled",
        rayTracingMode: "auto",
        retinaMode: false,
        metalHUDEnabled: false,
        metal4Enabled: false,
        gamepadCompatMode: false,
        avxEnabled: false,
        bypassAVDecode: false,
        dxmtExperimentalDX12: false,
        offlineMode: false,
        cloudSaves: false,
        steamInput: false
    )
}

enum CompatOptions {
    static let languages = ["system", "en", "fr", "zh"]
    static let compatibilityLayers = ["wine-proton_11.0", "wine-proton_10.0", "wine-proton_9.0", "crossover-24"]
    static let graphicsStacks = ["gptk-3.0-3", "gptk-2.1", "dxmt", "dxvk", "d3dmetal"]
    static let syncModes = ["msync", "esync", "none"]
    static let dlssModes = ["disabled", "auto", "quality", "performance"]
    static let rayTracingModes = ["auto", "on", "off"]
}

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let unlocked: Bool
}

struct DiscussionThread: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let replies: Int
}

struct Game: Identifiable, Hashable {
    var id: String
    var name: String
    var artwork: String
    var subtitle: String
    var score: String
    var genres: String
    var installed: Bool
    var developer: String
    var publisher: String
    var releaseDate: String
    var estimatedDownload: String
    var platform: GamePlatform
    var platformAppID: String?
    var gameID: String?
    var stableKeyHash: String?
    var installPath: String?
    var installSizeBytes: Int64
    var hasUpdate: Bool
    var downloadProgress: Double?
    var settings: GameSettings?
    var achievements: [Achievement]
    var discussions: [DiscussionThread]

    init(
        id: String,
        name: String,
        artwork: String,
        subtitle: String,
        score: String,
        genres: String,
        installed: Bool,
        developer: String = "Unknown developer",
        publisher: String = "Unknown publisher",
        releaseDate: String = "2024-04-04",
        estimatedDownload: String = "2.3 GB",
        platform: GamePlatform = .demo,
        platformAppID: String? = nil,
        gameID: String? = nil,
        stableKeyHash: String? = nil,
        installPath: String? = nil,
        installSizeBytes: Int64 = 0,
        hasUpdate: Bool = false,
        downloadProgress: Double? = nil,
        settings: GameSettings? = nil,
        achievements: [Achievement] = Game.defaultAchievements,
        discussions: [DiscussionThread] = Game.defaultDiscussions
    ) {
        self.id = id
        self.name = name
        self.artwork = artwork
        self.subtitle = subtitle
        self.score = score
        self.genres = genres
        self.installed = installed
        self.developer = developer
        self.publisher = publisher
        self.releaseDate = releaseDate
        self.estimatedDownload = estimatedDownload
        self.platform = platform
        self.platformAppID = platformAppID
        self.gameID = gameID
        self.stableKeyHash = stableKeyHash
        self.installPath = installPath
        self.installSizeBytes = installSizeBytes
        self.hasUpdate = hasUpdate
        self.downloadProgress = downloadProgress
        self.settings = settings
        self.achievements = achievements
        self.discussions = discussions
    }

    var isReal: Bool { platform.isReal }

    var launchURL: URL? {
        guard isReal, let platformAppID else { return nil }
        return URL(string: "gamehub://launch/\(platform.rawValue)/\(platformAppID)")
    }

    var installSizeText: String {
        if installSizeBytes > 0 {
            return ByteCountFormatter.string(fromByteCount: installSizeBytes, countStyle: .file)
        }
        return estimatedDownload
    }

    var tags: [String] {
        genres.components(separatedBy: " · ").filter { !$0.isEmpty }
    }

    var primaryActionTitle: String {
        if installed { return hasUpdate ? "Update" : "Play" }
        if let downloadProgress { return "\(Int(downloadProgress * 100))%" }
        return "Download \(installSizeText)"
    }

    static let buckshot = Game(
        id: "buckshot",
        name: "Buckshot Roulette",
        artwork: "buckshot",
        subtitle: "A deadly game of chance at a grimy underground table.",
        score: "9.5",
        genres: "Indie · Action · Simulation",
        installed: true,
        developer: "Mike Klubnika",
        estimatedDownload: "858.6 MB",
        platform: .steam,
        platformAppID: "2835570",
        gameID: "96772",
        installSizeBytes: 858_600_000
    )

    static let rocket = Game(
        id: "rocket",
        name: "Rocket League®",
        artwork: "rocket",
        subtitle: "Soccer meets driving in the ultimate competitive arena.",
        score: "8.7",
        genres: "Sports · Racing",
        installed: true,
        developer: "Psyonix LLC",
        publisher: "Epic Games",
        releaseDate: "2015-07-07",
        estimatedDownload: "36.42 GB",
        platform: .epic,
        platformAppID: "Sugar",
        gameID: "162941",
        installSizeBytes: 36_420_000_000
    )

    static let undertale = Game(
        id: "undertale",
        name: "UNDERTALE",
        artwork: "tenmillion",
        subtitle: "The friendly RPG where nobody has to get hurt.",
        score: "9.7",
        genres: "RPG · Indie",
        installed: false,
        developer: "tobyfox",
        publisher: "tobyfox",
        releaseDate: "2015-09-15",
        estimatedDownload: "200 MB",
        platform: .steam,
        platformAppID: "391540",
        installSizeBytes: 200_000_000
    )

    static let browseGames: [Game] = [
        Game(id: "orbitalis", name: "ORBITALIS", artwork: "orbitalis", subtitle: "A meditative orbital puzzle.", score: "7.1", genres: "Indie · Simulation", installed: false),
        Game(id: "10m", name: "10,000,000", artwork: "tenmillion", subtitle: "Match, build and escape.", score: "8.9", genres: "Indie · RPG · Casual", installed: false),
        Game(id: "amps", name: "1000 Amps", artwork: "amps", subtitle: "Restore light to a vast world.", score: "8.0", genres: "Adventure · Indie", installed: false),
        Game(id: "resist", name: "1000xRESIST", artwork: "resist", subtitle: "A thrilling sci-fi adventure.", score: "9.5", genres: "Adventure · Indie", installed: false),
        Game(id: "arcade", name: "Arcade Paradise", artwork: "arcade", subtitle: "Build the arcade of your dreams.", score: "8.1", genres: "Simulation · Casual", installed: false),
        Game(id: "army", name: "Army Craft", artwork: "army", subtitle: "Command your colorful army.", score: "7.8", genres: "Action · Indie", installed: false),
        Game(id: "assetto", name: "Assetto Corsa", artwork: "assetto", subtitle: "The definitive racing simulation.", score: "9.0", genres: "Racing · Sports", installed: false),
        Game(id: "bitray", name: "BitRay", artwork: "bitray", subtitle: "A geometric puzzle adventure.", score: "7.4", genres: "Indie · Puzzle", installed: false)
    ]

    static let allCatalog: [Game] = [.buckshot, .rocket, .undertale] + browseGames

    static let defaultAchievements: [Achievement] = [
        Achievement(id: "70k", title: "70K", unlocked: true),
        Achievement(id: "bronze", title: "Bronze Gates", unlocked: true),
        Achievement(id: "losses", title: "Chasing Losses", unlocked: true),
        Achievement(id: "overdose", title: "Overdose", unlocked: false),
        Achievement(id: "coin", title: "Coin Flip", unlocked: false),
        Achievement(id: "style", title: "Going Out With Style!", unlocked: false)
    ]

    static let defaultDiscussions: [DiscussionThread] = [
        DiscussionThread(id: "save", title: "PINNED: Save file location", author: "Kris Deltarune", replies: 26),
        DiscussionThread(id: "bugs", title: "PINNED: Bug Reports", author: "Neon Freak", replies: 1257),
        DiscussionThread(id: "vulkan", title: "PINNED: Known Issues / Vulkan Error", author: "Mistalleks", replies: 269)
    ]
}

enum DownloadState: String, CaseIterable, Hashable {
    case queued = "Queued"
    case preparing = "Preparing"
    case downloading = "Downloading"
    case unpacking = "Unpacking"
    case verifying = "Verifying"
    case paused = "Paused"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case failed = "Failed"

    var isActive: Bool {
        switch self {
        case .preparing, .downloading, .unpacking, .verifying: true
        default: false
        }
    }

    var isFinal: Bool {
        switch self {
        case .completed, .cancelled, .failed: true
        default: false
        }
    }

    var symbol: String {
        switch self {
        case .queued: "clock"
        case .preparing: "gearshape"
        case .downloading: "arrow.down.circle"
        case .unpacking: "shippingbox"
        case .verifying: "checkmark.shield"
        case .paused: "pause.circle"
        case .completed: "checkmark.circle.fill"
        case .cancelled: "xmark.circle"
        case .failed: "exclamationmark.triangle.fill"
        }
    }
}

struct DownloadItem: Identifiable, Hashable {
    let id = UUID()
    let gameID: Game.ID
    var title: String
    var artwork: String
    var state: DownloadState = .queued
    var progress: Double = 0
    var speedBytesPerSecond: Int64 = 0
    var totalBytes: Int64
    var external: Bool = false

    var progressText: String {
        let done = Int64(progress * Double(totalBytes))
        let doneText = ByteCountFormatter.string(fromByteCount: done, countStyle: .file)
        let totalText = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return "\(doneText) / \(totalText)"
    }

    var speedText: String {
        guard state == .downloading, speedBytesPerSecond > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: speedBytesPerSecond, countStyle: .file) + "/s"
    }
}
