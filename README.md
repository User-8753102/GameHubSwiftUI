# GameHub SwiftUI

Private macOS SwiftUI frontend for GameHub.

## What is included

- Native SwiftUI shell for explore, rankings, search, library, downloads, game detail, and per-game settings.
- Read-only import of the existing GameHub library bindings and per-game settings from local app support files.
- Local Steam and Epic launch paths for existing Wine containers, plus Steam install links for games that are not installed yet.
- Download queue controls, completed download history, shortcut/folder actions, compatibility panels, achievements, and discussions.
- Responsive layouts for compact and wide macOS windows.
- Optional Steam, Epic, and GOG account panels; no GameHub account is required to use the app.
- Local-only credential storage through the macOS Keychain.
- Privacy-preserving Firebase bridge stub for the preserved private engine copy.

## Build

```sh
xcodebuild -project GameHubSwiftUI.xcodeproj -scheme GameHubSwiftUI -configuration Release -derivedDataPath .release-build CODE_SIGNING_ALLOWED=NO build
```

The release app is produced at:

```text
.release-build/Build/Products/Release/GameHub.app
```

## Privacy

See `PRIVACY.md` for the local-only privacy model and telemetry notes.
