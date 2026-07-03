# GameHub SwiftUI privacy design

- No Firebase, Google Tag Manager, Sentry, analytics SDK, tracking identifier, advertising SDK, or telemetry endpoint is included.
- No Apple account, Sign in with Apple entitlement, or iCloud entitlement is used.
- Credentials entered in the SwiftUI account screen are stored as generic-password items in the macOS Keychain.
- Keychain items explicitly set `kSecAttrSynchronizable` to `false` and use `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- Existing Steam and Epic engine sessions stay in their local cache files with permissions `0600`; their parent directories use `0700`.
- The app contains no code that uploads logs. Network access during launch is limited to the selected store/game services; Epic launch requests a short-lived exchange code from Epic's account service.
- Installed games are started directly in their existing local Wine containers, without GameHub's remote `e1003` launch-authorization step.

The original GameHub 0.8.360 bundle was found to include a Firebase analytics bridge. The preserved private engine copy replaces that bridge with a local no-op implementation, while the SwiftUI frontend contains no analytics SDK. The original unmodified application remains available only as a backup.
