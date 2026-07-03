import SwiftUI

private struct SettingsNavItem: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
}

private let globalItems = [
    SettingsNavItem(id: "general", title: "General", symbol: "gearshape"),
    SettingsNavItem(id: "my", title: "My", symbol: "person"),
    SettingsNavItem(id: "steam", title: "Steam", symbol: "circle.grid.cross"),
    SettingsNavItem(id: "epic", title: "Epic", symbol: "shield"),
    SettingsNavItem(id: "gog", title: "GOG", symbol: "circle"),
    SettingsNavItem(id: "storage", title: "Storage", symbol: "externaldrive"),
    SettingsNavItem(id: "feedback", title: "Feedback", symbol: "bubble.left"),
    SettingsNavItem(id: "about", title: "About", symbol: "info.circle")
]

private let gameItems = [
    SettingsNavItem(id: "steam", title: "Steam", symbol: "circle.grid.cross"),
    SettingsNavItem(id: "general", title: "General", symbol: "gearshape"),
    SettingsNavItem(id: "container", title: "Container", symbol: "cube"),
    SettingsNavItem(id: "compat", title: "Compat", symbol: "shield"),
    SettingsNavItem(id: "graphics", title: "Graphics", symbol: "display"),
    SettingsNavItem(id: "frame", title: "Frame Gen", symbol: "bolt"),
    SettingsNavItem(id: "deps", title: "Deps", symbol: "shippingbox")
]

private struct SettingsSidebar: View {
    let items: [SettingsNavItem]
    @Binding var selected: String
    let back: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let back {
                Button(action: back) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            } else {
                Spacer().frame(height: 58)
            }

            ForEach(items) { item in
                Button { selected = item.id } label: {
                    Label(item.title, systemImage: item.symbol)
                        .font(.system(size: 14, weight: selected == item.id ? .bold : .medium))
                        .foregroundStyle(selected == item.id ? .white : .white.opacity(0.65))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .background(selected == item.id ? Color.white.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Divider().opacity(0.4)
            Label("Search", systemImage: "magnifyingglass")
            Label("Downloads", systemImage: "arrow.down.to.line")
            Label("Profile", systemImage: "person.crop.circle")
        }
        .padding(16)
        .frame(width: 220)
        .background(Color.black.opacity(0.12))
        .overlay(alignment: .trailing) { Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1) }
    }
}

struct GlobalSettingsView: View {
    let back: () -> Void
    @State private var selected = "general"

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(items: globalItems, selected: $selected, back: back)
            Group {
                switch selected {
                case "steam": GlobalSteamSettings()
                case "epic": EpicSettings()
                case "storage": StorageSettings()
                case "my", "gog": LocalAccountsSettings(initialService: selected == "gog" ? .gog : .steam)
                default: GeneralAppSettings()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct LocalAccountsSettings: View {
    @StateObject private var store = LocalCredentialStore()
    @State private var service: GamingService
    @State private var accountIdentifier = ""
    @State private var secret = ""
    @State private var status = "Stored only on this Mac · iCloud sync disabled"

    init(initialService: GamingService) {
        _service = State(initialValue: initialService)
    }

    var body: some View {
        SettingsPage(title: "Local Accounts") {
            HStack(spacing: 12) {
                ForEach(GamingService.allCases) { item in
                    Button {
                        service = item
                        loadCurrent()
                    } label: {
                        Text(item.displayName)
                            .font(.headline)
                            .padding(.horizontal, 22)
                            .frame(height: 44)
                            .background(service == item ? Color.white.opacity(0.14) : Color.white.opacity(0.05), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 18) {
                Label("Private local vault", systemImage: "lock.shield")
                    .font(.title2.bold())
                    .foregroundStyle(GHTheme.accent)
                Text("Credentials are encrypted by the macOS Keychain, marked This Device Only, and never synchronized through iCloud.")
                    .foregroundStyle(GHTheme.secondary)

                Text("Account identifier").font(.headline)
                TextField("Username, email or account ID", text: $accountIdentifier)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 12))

                Text("Local token or password").font(.headline)
                SecureField("Stored encrypted", text: $secret)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 12))

                HStack {
                    CapsuleButton(title: "Save locally", symbol: "lock.fill", primary: true) {
                        if store.save(service: service, accountIdentifier: accountIdentifier, secret: secret) {
                            secret = ""
                            status = "Saved securely on this Mac"
                        } else {
                            status = store.lastError ?? "Unable to save"
                        }
                    }
                    if store.accounts[service] != nil {
                        CapsuleButton(title: "Remove", symbol: "trash") {
                            store.remove(service)
                            accountIdentifier = ""
                            secret = ""
                            status = "Local credential removed"
                        }
                    }
                    Spacer()
                    Label(status, systemImage: "externaldrive.badge.checkmark")
                        .font(.caption)
                        .foregroundStyle(GHTheme.secondary)
                }

                Divider().opacity(0.4)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Store authentication").font(.headline)
                        Text("Use the isolated local engine for Steam, GOG, or Epic OAuth.")
                            .font(.caption).foregroundStyle(GHTheme.secondary)
                    }
                    Spacer()
                    CapsuleButton(title: "Open account manager", symbol: "person.badge.key") {
                        EngineBridge.openEngine()
                    }
                }
            }
            .padding(28)
            .glassPanel(radius: 20)
            .onAppear { loadCurrent() }

            SettingsCard {
                ForEach(GamingService.allCases) { item in
                    HStack {
                        Image(systemName: store.accounts[item] == nil ? "circle.dashed" : "checkmark.circle.fill")
                            .foregroundStyle(store.accounts[item] == nil ? .secondary : GHTheme.accent)
                        Text(item.displayName).font(.headline)
                        Spacer()
                        Text(store.accounts[item]?.accountIdentifier ?? "Not configured")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .frame(height: 64)
                }
            }
        }
    }

    private func loadCurrent() {
        accountIdentifier = store.accounts[service]?.accountIdentifier ?? ""
        secret = ""
        status = "Stored only on this Mac · iCloud sync disabled"
    }
}

struct GameSettingsView: View {
    let navigate: (AppRoute) -> Void
    @State private var selected = "steam"

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(items: gameItems, selected: $selected, back: { navigate(.detail(.buckshot)) })
            Group {
                switch selected {
                case "general": GameGeneralSettings()
                case "container": ContainerSettings()
                case "compat": CompatibilitySettings()
                case "graphics": GraphicsSettings()
                case "deps": DependenciesSettings()
                default: SteamGameSettings()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct SettingsPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PageTitle(title: title)
                content
            }
            .frame(maxWidth: 1080, alignment: .leading)
            .padding(.horizontal, 58)
            .padding(.vertical, 70)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct SettingRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    var trailing: String? = nil
    var button: String? = nil
    var toggle: Binding<Bool>? = nil
    var destructive = false

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 21))
                .foregroundStyle(destructive ? .red : GHTheme.blue)
                .frame(width: 38)
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.system(size: 18, weight: .medium)).foregroundStyle(destructive ? .red.opacity(0.85) : GHTheme.blue)
                if !subtitle.isEmpty { Text(subtitle).font(.system(size: 15)).foregroundStyle(destructive ? .red.opacity(0.65) : GHTheme.secondary) }
            }
            Spacer()
            if let trailing { Text(trailing).font(.system(size: 16)).foregroundStyle(.secondary); Image(systemName: "chevron.down").foregroundStyle(GHTheme.blue) }
            if let button { CapsuleButton(title: button) }
            if let toggle { Toggle("", isOn: toggle).labelsHidden().toggleStyle(.switch) }
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 92)
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View { VStack(spacing: 0) { content }.glassPanel(radius: 20) }
}

private struct GeneralAppSettings: View {
    var body: some View {
        SettingsPage(title: "General") {
            SettingsCard {
                SettingRow(symbol: "globe", title: "App language", subtitle: "Switch the display language of the app", trailing: "Follow System")
                SettingRow(symbol: "macwindow", title: "Create desktop shortcut", subtitle: "Generate a quick-launch icon on your desktop", button: "Generate")
                SettingRow(symbol: "trash", title: "Reset all game data", subtitle: "Clear all game containers and related data, the app will restart automatically", button: "Reset")
                SettingRow(symbol: "folder", title: "Wine Log Directory", subtitle: "Customize log output directory for debugging and troubleshooting", button: "Select Folder")
                SettingRow(symbol: "arrow.counterclockwise", title: "Reset App", subtitle: "Clear all app data and restart to restore initial state", button: "Reset", destructive: true)
            }
            Text("Privacy").font(.title2.bold())
            SettingsCard {
                SettingRow(symbol: "hand.raised.fill", title: "Telemetry disabled", subtitle: "No analytics, usage events, advertising identifiers, or browsing activity are collected")
                Divider().opacity(0.4)
                SettingRow(symbol: "doc.text.magnifyingglass", title: "Log uploads disabled", subtitle: "Diagnostic logs remain on this Mac and are never uploaded automatically")
                Divider().opacity(0.4)
                SettingRow(symbol: "icloud.slash", title: "Cloud identity disabled", subtitle: "GameHub does not require an Apple account and does not use iCloud")
            }
        }
    }
}

private struct GlobalSteamSettings: View {
    @State private var cloud = true
    var body: some View {
        SettingsPage(title: "Steam") {
            SettingsCard {
                SettingRow(symbol: "person.crop.circle", title: "AURA   Primary", subtitle: "Connected Steam account", button: "×")
                SettingRow(symbol: "plus", title: "Add Steam account", subtitle: "")
            }
            SettingsCard { SettingRow(symbol: "key", title: "Steam Product Key", subtitle: "Redeem a product key and sync it to the current Steam library", button: "Activate") }
            SettingsCard { SettingRow(symbol: "arrow.clockwise", title: "Steam App Cache", subtitle: "Clear the local appcache and force a full background Steam product metadata rebuild", button: "Rebuild Now") }
            SettingsCard { SettingRow(symbol: "character.book.closed", title: "Steam Client Language", subtitle: "Set the display language of the Steam client", trailing: "Follow System") }
            SettingsCard { SettingRow(symbol: "mappin", title: "Download Region", subtitle: "Choose the server region for Steam content downloads", trailing: "Auto (Current Network)") }
            SettingsCard { SettingRow(symbol: "icloud.and.arrow.up", title: "Cloud Saves", subtitle: "Automatically sync game saves to the cloud", toggle: $cloud) }
        }
    }
}

private struct EpicSettings: View {
    var body: some View {
        SettingsPage(title: "Epic") {
            SettingsCard {
                SettingRow(symbol: "person.crop.circle", title: "Call Me L.", subtitle: "Epic Games account", button: "Log out")
            }
        }
    }
}

private struct StorageSettings: View {
    var body: some View {
        SettingsPage(title: "Storage") {
            VStack(alignment: .leading, spacing: 22) {
                HStack { Text("Total Storage Usage").foregroundStyle(.secondary); Spacer(); Text("43.3 GB").font(.title.bold()) }
                GeometryReader { proxy in
                    HStack(spacing: 4) {
                        Capsule().fill(Color.blue).frame(width: proxy.size.width * 0.86)
                        Capsule().fill(Color.green).frame(width: 5)
                        Capsule().fill(Color.purple).frame(width: proxy.size.width * 0.05)
                    }
                }.frame(height: 8)
                Text("●  Game Files   40.8 GB     ●  Game Data   228 MB     ●  Installed Wine Containers   2.13 GB")
                    .foregroundStyle(.secondary)
            }
            .padding(28).glassPanel(radius: 20)
            HStack(spacing: 22) {
                storageGame("rocket", "Rocket League®", "39.6 GB", "105 MB")
                storageGame("buckshot", "Buckshot Roulette", "1.24 GB", "123 MB")
                Spacer()
            }
        }
    }

    private func storageGame(_ image: String, _ title: String, _ files: String, _ data: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ArtworkImage(name: image).frame(width: 255, height: 150).clipShape(RoundedRectangle(cornerRadius: 18))
            Text(title).font(.headline)
            HStack { Label("Files", systemImage: "folder"); Spacer(); Text(files) }
            HStack { Label("Data", systemImage: "cylinder"); Spacer(); Text(data) }
        }.frame(width: 255)
    }
}

private struct SteamGameSettings: View {
    @State private var offline = false
    @State private var cloud = false
    @State private var input = false
    var body: some View {
        SettingsPage(title: "Steam") {
            SettingsCard {
                SettingRow(symbol: "wifi.slash", title: "Offline Mode", subtitle: "Allow running verified Steam games without network", toggle: $offline)
                SettingRow(symbol: "icloud", title: "Cloud Saves", subtitle: "Allow syncing saves with other devices", toggle: $cloud)
                SettingRow(symbol: "gamecontroller", title: "Steam Input (Experimental)", subtitle: "Run games through Steam's official universal controller compatibility layer", toggle: $input)
                SettingRow(symbol: "play", title: "Launch Options", subtitle: "Can affect the game's operation, performance, and features.", trailing: "default")
            }
        }
    }
}

private struct GameGeneralSettings: View {
    @State private var retina = false
    var body: some View {
        SettingsPage(title: "General") {
            SettingsCard {
                SettingRow(symbol: "character.book.closed", title: "Language", subtitle: "Set Wine container system language", trailing: "Follow System")
                SettingRow(symbol: "display", title: "Retina Mode", subtitle: "Enable Wine Mac Driver high-resolution rendering when launching the game", toggle: $retina)
                SettingRow(symbol: "curlybraces", title: "Environment variables", subtitle: "Configure environment variables for special app requirements", button: "+")
                SettingRow(symbol: "terminal", title: "Launch options", subtitle: "Add launch parameters to enable features or fix compatibility issues")
            }
        }
    }
}

private struct ContainerSettings: View {
    private let rows = [("square.and.arrow.down", "Install App", "Install an exe or msi program"), ("externaldrive", "Open C Drive", "Open the virtual C drive in Finder"), ("gearshape", "Wine Settings", "Adjust Wine compatibility and runtime options"), ("folder", "Resource Manager", "Browse and manage game files"), ("waveform.path.ecg", "Task Manager", "View and stop running processes"), ("globe", "Internet Settings", "Configure network and proxy options"), ("gamecontroller", "Game Controllers", "Set up controllers and gamepads"), ("display", "Display Settings", "Adjust resolution and desktop display"), ("play", "Run...", "Open the Windows Run dialog to execute commands or programs")]
    var body: some View {
        SettingsPage(title: "Container") {
            SettingsCard {
                ForEach(rows, id: \.1) { SettingRow(symbol: $0.0, title: $0.1, subtitle: $0.2, trailing: "") }
                SettingRow(symbol: "arrow.counterclockwise", title: "Reset Data", subtitle: "Clear this game's runtime data and reinitialize", trailing: "", destructive: true)
            }
        }
    }
}

private struct CompatibilitySettings: View {
    @State private var decode = false
    @State private var gamepad = false
    @State private var avx = false
    var body: some View {
        SettingsPage(title: "Compat") {
            SettingsCard {
                SettingRow(symbol: "slider.horizontal.3", title: "Compatibility scheme", subtitle: "Use the recommended scheme or customize it yourself", button: "Sync latest cloud config")
                SettingRow(symbol: "square.3.layers.3d", title: "Compatibility layer", subtitle: "Choose a Wine version. Different versions provide different compatibility.", trailing: "wine-proton_11.0")
                SettingRow(symbol: "arrow.triangle.2.circlepath", title: "Sync mode", subtitle: "Choose Wine sync mechanism. Different modes affect performance and compatibility.", trailing: "MSync")
                SettingRow(symbol: "movieclapper", title: "Skip audio/video decode", subtitle: "Use a black screen for CG cutscenes to mitigate compatibility issues.", toggle: $decode)
                SettingRow(symbol: "gamecontroller", title: "Gamepad compatibility mode", subtitle: "Enable a dedicated gamepad service process to improve controller compatibility.", toggle: $gamepad)
                SettingRow(symbol: "cpu", title: "AVX Instructions", subtitle: "Enable Rosetta AVX instruction set emulation, required by some games", toggle: $avx)
            }
        }
    }
}

private struct GraphicsSettings: View {
    @State private var hud = false
    @State private var dlss = false
    var body: some View {
        SettingsPage(title: "Graphics") {
            SettingsCard {
                SettingRow(symbol: "gauge", title: "MetalHUD", subtitle: "Show the Metal performance HUD overlay in-game", toggle: $hud)
                SettingRow(symbol: "display", title: "Switch Graphics Stack", subtitle: "Choose the DirectX to Metal conversion method, or use Wine D3D native rendering", trailing: "gptk-3.0-3")
                SettingRow(symbol: "sparkles", title: "DLSS Support", subtitle: "Only applies to GPTK and DXMT graphics stacks and enables DLSS-related support", toggle: $dlss)
                SettingRow(symbol: "bolt", title: "Ray Tracing", subtitle: "Control DirectX Raytracing (DXR) support", trailing: "Auto")
                SettingRow(symbol: "flask", title: "Switch MoltenVK", subtitle: "Choose MoltenVK version for Vulkan to Metal conversion", trailing: "builtin")
                SettingRow(symbol: "folder", title: "Open Shader Cache", subtitle: "Manage your shader compilation cache", trailing: "")
            }
            SettingsCard { SettingRow(symbol: "doc.badge.gearshape", title: "Graphics Stack Exceptions", subtitle: "Override graphics stack for specific exe files", button: "Add exception") }
        }
    }
}

private struct DependenciesSettings: View {
    private let names = ["base", "cjkfonts", "physx", "oalinst", "VulkanRT", "vcredist2022", "atiadlxx", "FAudio", "xaudio", "mfc140"]
    var body: some View {
        SettingsPage(title: "Deps") {
            Text("Installed  (1)").font(.title2.bold())
            SettingsCard { SettingRow(symbol: "point.3.connected.trianglepath.dotted", title: "base", subtitle: "v1.0.0 · 638.0 B") }
            Text("Not installed  (9)").font(.title2.bold())
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(names.dropFirst(), id: \.self) { name in
                    SettingRow(symbol: "point.3.connected.trianglepath.dotted", title: name, subtitle: "v1.0.2 · 629.0 B", button: "↓")
                        .glassPanel(radius: 18)
                }
            }
        }
    }
}
