import AppKit
import Foundation

enum EngineBridge {
    private static let supportRoot = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/com.gamemac.www", isDirectory: true)

    private static var engineBundleURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/GameHub Engine Private.app", isDirectory: true)
    }

    static func launch(_ game: Game) async -> String {
        secureLocalAccountFiles()

        switch game.id {
        case "buckshot":
            return launchSteam(appID: "2835570")
                ? "Steam local lancé — Buckshot Roulette démarre."
                : "Le conteneur Steam local est indisponible."
        case "rocket":
            do {
                try await launchEpicRocketLeague()
                return "Epic local lancé — Rocket League démarre."
            } catch {
                return "Lancement Epic impossible : \(error.localizedDescription)"
            }
        default:
            if let launchURL = game.launchURL, NSWorkspace.shared.open(launchURL) {
                return "Lancement transmis au moteur GameHub local."
            }
            openEngine()
            return "Gestionnaire local ouvert pour installer ce jeu."
        }
    }

    static func openEngine() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = false
        NSWorkspace.shared.openApplication(at: engineBundleURL, configuration: configuration)
    }

    private static func launchSteam(appID: String) -> Bool {
        let executable = URL(fileURLWithPath: "/Volumes/ROG-ESD S1C/Jeux/GamehubLibrary/steamapps/common/Buckshot Roulette/Buckshot Roulette_windows/Buckshot Roulette.exe")
        guard FileManager.default.fileExists(atPath: executable.path) else { return false }

        return runWine(
            containerID: "1",
            nativeExecutable: executable,
            windowsExecutable: "Z:\\Volumes\\ROG-ESD S1C\\Jeux\\GamehubLibrary\\steamapps\\common\\Buckshot Roulette\\Buckshot Roulette_windows\\Buckshot Roulette.exe",
            arguments: [],
            graphicsComponent: "gptk-3.0-3",
            processEnvironmentDirectory: supportRoot.appendingPathComponent("gamehub/graphics_stack_exceptions/steam:\(appID)")
        )
    }

    private static func launchEpicRocketLeague() async throws {
        let session = try loadEpicSession()
        let exchangeCode = try await epicExchangeCode(accessToken: session.accessToken)
        let gameDirectory = URL(fileURLWithPath: "/Volumes/ROG-ESD S1C/Jeux/GamehubLibrary/rocketleague/Binaries/Win64", isDirectory: true)
        let launcher = gameDirectory.appendingPathComponent("Launcher.exe")

        guard FileManager.default.fileExists(atPath: launcher.path) else {
            throw LaunchError.missingGame
        }

        let started = runWine(
            containerID: "2",
            nativeExecutable: launcher,
            windowsExecutable: "Z:\\Volumes\\ROG-ESD S1C\\Jeux\\GamehubLibrary\\rocketleague\\Binaries\\Win64\\Launcher.exe",
            arguments: [
                "-AUTH_LOGIN=unused",
                "-AUTH_PASSWORD=\(exchangeCode)",
                "-AUTH_TYPE=exchangecode",
                "-epicapp=Sugar",
                "-epicenv=Prod",
                "-EpicPortal",
                "-epicuserid=\(session.accountID)",
                "-epicusername=\(session.displayName)",
                "-epiclocale=fr-FR",
                "-epicsandboxid=9773aa1aa54f4f7b80e44bef04986cea",
                "-noeac"
            ],
            graphicsComponent: "gptk-4.0-1",
            processEnvironmentDirectory: supportRoot.appendingPathComponent("gamehub/graphics_stack_exceptions/epic:Sugar")
        )

        if !started { throw LaunchError.wineUnavailable }
    }

    private static func runWine(
        containerID: String,
        nativeExecutable: URL,
        windowsExecutable: String,
        arguments: [String],
        graphicsComponent: String,
        processEnvironmentDirectory: URL
    ) -> Bool {
        let wineRoot = supportRoot.appendingPathComponent("wine-engine/containers/wine_installations/10000073", isDirectory: true)
        let wine = wineRoot.appendingPathComponent("bin/wine")
        let prefix = supportRoot.appendingPathComponent("wine-engine/containers/virtual_containers/\(containerID)", isDirectory: true)
        let basePrefix = supportRoot.appendingPathComponent("wine-engine/containers/base_containers/1", isDirectory: true)
        let graphicsRoot = supportRoot.appendingPathComponent("wine-engine/downloads/\(graphicsComponent)", isDirectory: true)

        guard FileManager.default.isExecutableFile(atPath: wine.path) else { return false }

        let nativeWorkingDirectory = nativeExecutable.deletingLastPathComponent()

        let process = Process()
        process.executableURL = wine
        process.currentDirectoryURL = nativeWorkingDirectory
        process.arguments = [windowsExecutable] + arguments

        var environment = ProcessInfo.processInfo.environment
        let existingPath = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        environment.merge([
            "PATH": "\(wineRoot.appendingPathComponent("bin").path):\(existingPath)",
            "LANG": "fr_FR.UTF-8",
            "LC_ALL": "fr_FR.UTF-8",
            "PROCESS_TAG": "gamehub_private_container:\(containerID)",
            "WINEARCH": "win64",
            "WINEDEBUG": "-all",
            "WINEMSYNC": "1",
            "WINEPREFIX": prefix.path,
            "WINEPREFIX_BASE": basePrefix.path,
            "WINE_INSTALLATION_PATH": wineRoot.path,
            "WINE_PATH": wineRoot.path,
            "WINE_APP_ICON_MASK": wineRoot.appendingPathComponent("share/mask/roundrect-mask.png").path,
            "WINEDLLPATH": graphicsRoot.appendingPathComponent("wine").path,
            "WINE_GPTK_LIBD3DSHARED_PATH": graphicsRoot.appendingPathComponent("external/libd3dshared.dylib").path,
            "WINE_PROCESS_ENV_DIR": processEnvironmentDirectory.path,
            "DYLD_FALLBACK_LIBRARY_PATH": "\(wineRoot.appendingPathComponent("lib").path):\(wineRoot.appendingPathComponent("lib/wine/x86_64-unix").path)",
            "GAMEHUB_DISABLE_ANALYTICS": "1",
            "FIREBASE_ANALYTICS_COLLECTION_ENABLED": "false"
        ]) { _, new in new }
        if containerID == "1" {
            environment["SteamAppId"] = "2835570"
            environment["SteamGameId"] = "2835570"
        }
        environment.removeValue(forKey: "DYLD_INSERT_LIBRARIES")
        process.environment = environment
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }

    private struct EpicSession {
        let accessToken: String
        let accountID: String
        let displayName: String
    }

    private static func loadEpicSession() throws -> EpicSession {
        let file = supportRoot.appendingPathComponent("epic-core/sessions.json")
        let data = try Data(contentsOf: file)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sessions = root["sessions"] as? [String: Any],
              let raw = sessions.values.first as? [String: Any],
              let token = raw["access_token"] as? String,
              let accountID = raw["account_id"] as? String else {
            throw LaunchError.missingEpicSession
        }
        return EpicSession(
            accessToken: token,
            accountID: accountID,
            displayName: raw["display_name"] as? String ?? "Epic Player"
        )
    }

    private static func epicExchangeCode(accessToken: String) async throws -> String {
        guard let url = URL(string: "https://account-public-service-prod.ol.epicgames.com/account/api/oauth/exchange") else {
            throw LaunchError.invalidEndpoint
        }
        var request = URLRequest(url: url)
        request.setValue("bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["code"] as? String else {
            throw LaunchError.epicAuthenticationFailed
        }
        return code
    }

    private static func secureLocalAccountFiles() {
        let manager = FileManager.default
        let files = [
            supportRoot.appendingPathComponent("steam-client/accounts.json"),
            supportRoot.appendingPathComponent("epic-core/sessions.json")
        ]
        let directories = [
            supportRoot.appendingPathComponent("steam-client", isDirectory: true),
            supportRoot.appendingPathComponent("epic-core", isDirectory: true)
        ]
        directories.forEach { try? manager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: $0.path) }
        files.forEach { try? manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: $0.path) }
    }

    private enum LaunchError: LocalizedError {
        case missingGame
        case missingEpicSession
        case invalidEndpoint
        case epicAuthenticationFailed
        case wineUnavailable

        var errorDescription: String? {
            switch self {
            case .missingGame: "installation du jeu introuvable"
            case .missingEpicSession: "session Epic locale introuvable"
            case .invalidEndpoint: "service Epic invalide"
            case .epicAuthenticationFailed: "la session Epic locale doit être renouvelée"
            case .wineUnavailable: "conteneur Wine indisponible"
            }
        }
    }
}
