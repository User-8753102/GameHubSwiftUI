# GameHub SwiftUI

Private macOS SwiftUI frontend for GameHub.

## What is included

- Native SwiftUI shell for browsing, library, downloads, rankings, and settings.
- Local Steam and Epic launch paths for existing Wine containers.
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
