import AppKit
import Foundation

enum GameHubDataStore {
    struct ContainerBinding: Decodable, Hashable {
        let gameID: String?
        let gameName: String
        let platform: GamePlatform
        let platformAppID: String?
        let gamePath: String?
        let virtualContainerID: String?

        enum CodingKeys: String, CodingKey {
            case gameID = "game_id"
            case gameName = "game_name"
            case platform
            case platformAppID = "platform_app_id"
            case gamePath = "game_path"
            case virtualContainerID = "virtual_container_id"
        }
    }

    struct StoredSettings: Hashable {
        let appID: String
        let stableKeyHash: String?
        let settings: GameSettings
    }

    static var supportRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.gamemac.www", isDirectory: true)
    }

    static var gameHubRoot: URL {
        supportRoot.appendingPathComponent("gamehub", isDirectory: true)
    }

    static var isAvailable: Bool {
        FileManager.default.fileExists(atPath: gameHubRoot.path)
    }

    static func loadContainerBindings() -> [ContainerBinding] {
        let url = gameHubRoot.appendingPathComponent("game_container_store.json")
        guard let data = try? Data(contentsOf: url),
              let store = try? JSONDecoder().decode(ContainerStore.self, from: data) else {
            return []
        }
        return store.bindings
    }

    static func loadSettingsByAppID() -> [String: StoredSettings] {
        let settingsDir = gameHubRoot.appendingPathComponent("game-settings", isDirectory: true)
        guard let files = try? FileManager.default.contentsOfDirectory(at: settingsDir, includingPropertiesForKeys: nil) else {
            return [:]
        }

        var settings: [String: StoredSettings] = [:]
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let raw = try? JSONDecoder().decode(RawGameSettingsFile.self, from: data),
                  let appID = raw.key.platformAppId else {
                continue
            }
            settings[appID] = StoredSettings(
                appID: appID,
                stableKeyHash: raw.stableGameKeyHash,
                settings: raw.settings.map(GameSettings.init(raw:)) ?? .placeholder
            )
        }
        return settings
    }

    private struct ContainerStore: Decodable {
        let bindings: [ContainerBinding]
    }

    private struct RawGameSettingsFile: Decodable {
        let key: RawKey
        let stableGameKeyHash: String?
        let settings: RawSettings?

        enum CodingKeys: String, CodingKey {
            case key
            case stableGameKeyHash = "stable_game_key_hash"
            case settings
        }
    }

    private struct RawKey: Decodable {
        let platform: String?
        let platformAppId: String?
        let gameId: String?

        enum CodingKeys: String, CodingKey {
            case platform
            case platformAppId = "platform_app_id"
            case gameId = "game_id"
        }
    }

    struct RawSettings: Decodable {
        let language: String?
        let startParameters: String?
        let compatibilityLayer: String?
        let compatibilityLayerConfig: RawLayerConfig?
        let syncMode: String?
        let moltenVK: String?
        let dlssMode: String?
        let rayTracingMode: String?
        let retinaMode: Bool?
        let metalHudEnabled: Bool?
        let metal4Enabled: Bool?
        let gamepadCompatMode: Bool?
        let avxEnabled: Bool?
        let bypassAvDecode: Bool?
        let dxmtExperimentalDx12Support: Bool?
        let graphicsStack: RawGraphicsStack?
        let steam: RawSteamSettings?

        enum CodingKeys: String, CodingKey {
            case language
            case startParameters = "start_parameters"
            case compatibilityLayer = "compatibility_layer"
            case compatibilityLayerConfig = "compatibility_layer_config"
            case syncMode = "sync_mode"
            case moltenVK = "molten_vk"
            case dlssMode = "dlss_mode"
            case rayTracingMode = "ray_tracing_mode"
            case retinaMode = "retina_mode"
            case metalHudEnabled = "metal_hud_enabled"
            case metal4Enabled = "metal4_enabled"
            case gamepadCompatMode = "gamepad_compat_mode"
            case avxEnabled = "avx_enabled"
            case bypassAvDecode = "bypass_av_decode"
            case dxmtExperimentalDx12Support = "dxmt_experimental_dx12_support"
            case graphicsStack = "graphics_stack"
            case steam
        }
    }

    struct RawLayerConfig: Decodable {
        let displayName: String?
        let frameworkType: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
            case frameworkType = "framework_type"
        }
    }

    struct RawGraphicsStack: Decodable {
        let componentConfig: RawComponentConfig?

        enum CodingKeys: String, CodingKey {
            case componentConfig = "component_config"
        }
    }

    struct RawComponentConfig: Decodable {
        let displayName: String?

        enum CodingKeys: String, CodingKey {
            case displayName = "display_name"
        }
    }

    struct RawSteamSettings: Decodable {
        let offlineMode: Bool?
        let autoSyncCloudArchive: Bool?
        let steamInput: Bool?

        enum CodingKeys: String, CodingKey {
            case offlineMode = "offline_mode"
            case autoSyncCloudArchive = "auto_sync_cloud_archive"
            case steamInput = "steam_input"
        }
    }
}

extension GameSettings {
    init(raw: GameHubDataStore.RawSettings) {
        self.init(
            language: raw.language ?? "system",
            startParameters: raw.startParameters ?? "",
            compatibilityLayer: raw.compatibilityLayerConfig?.displayName
                ?? raw.compatibilityLayer ?? GameSettings.placeholder.compatibilityLayer,
            compatibilityFramework: raw.compatibilityLayerConfig?.frameworkType ?? "proton",
            graphicsStack: raw.graphicsStack?.componentConfig?.displayName ?? GameSettings.placeholder.graphicsStack,
            syncMode: raw.syncMode ?? GameSettings.placeholder.syncMode,
            moltenVK: raw.moltenVK ?? GameSettings.placeholder.moltenVK,
            dlssMode: raw.dlssMode ?? GameSettings.placeholder.dlssMode,
            rayTracingMode: raw.rayTracingMode ?? GameSettings.placeholder.rayTracingMode,
            retinaMode: raw.retinaMode ?? false,
            metalHUDEnabled: raw.metalHudEnabled ?? false,
            metal4Enabled: raw.metal4Enabled ?? false,
            gamepadCompatMode: raw.gamepadCompatMode ?? false,
            avxEnabled: raw.avxEnabled ?? false,
            bypassAVDecode: raw.bypassAvDecode ?? false,
            dxmtExperimentalDX12: raw.dxmtExperimentalDx12Support ?? false,
            offlineMode: raw.steam?.offlineMode ?? false,
            cloudSaves: raw.steam?.autoSyncCloudArchive ?? false,
            steamInput: raw.steam?.steamInput ?? false
        )
    }
}

struct SteamLibraryState {
    enum InstallState: Equatable {
        case notInstalled
        case downloading(progress: Double)
        case installed
    }

    struct Entry {
        let appID: String
        let name: String
        let state: InstallState
        let bytesDownloaded: Int64
        let bytesToDownload: Int64
        let libraryPath: String
    }

    private(set) var byAppID: [String: Entry] = [:]

    init(libraries: [URL] = Self.discoverLibraries()) {
        for lib in libraries {
            let steamapps = lib.appendingPathComponent("steamapps", isDirectory: true)
            guard let files = try? FileManager.default.contentsOfDirectory(at: steamapps, includingPropertiesForKeys: nil) else {
                continue
            }
            for file in files where file.lastPathComponent.hasPrefix("appmanifest_") && file.pathExtension == "acf" {
                guard let entry = Self.parse(file, libraryPath: lib.path) else { continue }
                if let existing = byAppID[entry.appID], existing.state == .installed { continue }
                byAppID[entry.appID] = entry
            }
        }
    }

    static func discoverLibraries() -> [URL] {
        let steamRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Steam", isDirectory: true)
        var libraries: [URL] = [steamRoot]
        let libraryFile = steamRoot.appendingPathComponent("steamapps/libraryfolders.vdf")
        if let text = try? String(contentsOf: libraryFile, encoding: .utf8) {
            for path in values("path", in: text) {
                let url = URL(fileURLWithPath: path, isDirectory: true)
                if !libraries.contains(url) { libraries.append(url) }
            }
        }
        for binding in GameHubDataStore.loadContainerBindings() {
            guard let path = binding.gamePath else { continue }
            let url = URL(fileURLWithPath: path, isDirectory: true)
            if !libraries.contains(url) { libraries.append(url) }
        }
        return libraries
    }

    func state(forAppID appID: String?) -> InstallState {
        guard let appID, let entry = byAppID[appID] else { return .notInstalled }
        return entry.state
    }

    func name(forAppID appID: String?) -> String? {
        guard let appID else { return nil }
        return byAppID[appID]?.name
    }

    private static func parse(_ url: URL, libraryPath: String) -> Entry? {
        guard let text = try? String(contentsOf: url, encoding: .utf8),
              let appID = value("appid", in: text) else {
            return nil
        }
        let name = value("name", in: text) ?? "Steam \(appID)"
        let flags = value("StateFlags", in: text).flatMap { Int($0) } ?? 0
        let downloaded = value("BytesDownloaded", in: text).flatMap { Int64($0) } ?? 0
        let total = value("BytesToDownload", in: text).flatMap { Int64($0) } ?? 0

        let state: InstallState
        if flags == 4 || (total > 0 && downloaded >= total) {
            state = .installed
        } else if total > 0 && downloaded < total {
            state = .downloading(progress: max(0, min(1, Double(downloaded) / Double(total))))
        } else {
            state = .notInstalled
        }

        return Entry(
            appID: appID,
            name: name,
            state: state,
            bytesDownloaded: downloaded,
            bytesToDownload: total,
            libraryPath: libraryPath
        )
    }

    private static func value(_ key: String, in text: String) -> String? {
        values(key, in: text).first
    }

    private static func values(_ key: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "\"\(key)\"\\s+\"([^\"]*)\"") else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1, let valueRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[valueRange])
        }
    }
}

enum GameHubActionService {
    @discardableResult
    static func openSteamInstall(appID: String) -> Bool {
        guard let url = URL(string: "steam://install/\(appID)") else { return false }
        return NSWorkspace.shared.open(url)
    }

    @discardableResult
    static func openSteamStore(appID: String) -> Bool {
        guard let url = URL(string: "steam://store/\(appID)") else { return false }
        return NSWorkspace.shared.open(url)
    }

    @discardableResult
    static func openFolder(for game: Game) -> Bool {
        guard let path = game.installPath else { return false }
        return NSWorkspace.shared.open(URL(fileURLWithPath: path, isDirectory: true))
    }

    @discardableResult
    static func createShortcut(for game: Game) -> Bool {
        guard let url = game.launchURL else { return false }
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        guard let destination = desktop?.appendingPathComponent("\(game.name).webloc") else { return false }
        let payload = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict><key>URL</key><string>\(url.absoluteString)</string></dict></plist>
        """
        do {
            try payload.write(to: destination, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
}
