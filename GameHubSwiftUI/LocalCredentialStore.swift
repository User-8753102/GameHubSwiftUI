import Combine
import Foundation
import Security

enum GamingService: String, Codable, CaseIterable, Identifiable {
    case steam
    case gog
    case epic

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .steam: "Steam"
        case .gog: "GOG"
        case .epic: "Epic Games"
        }
    }
}

struct LocalCredential: Codable, Equatable {
    var accountIdentifier: String
    var secret: String
    var updatedAt: Date
}

@MainActor
final class LocalCredentialStore: ObservableObject {
    @Published private(set) var accounts: [GamingService: LocalCredential] = [:]
    @Published private(set) var lastError: String?

    private let keychainService = "com.louisgilles.GameHub.local-accounts"

    init() {
        reload()
    }

    func reload() {
        var loaded: [GamingService: LocalCredential] = [:]
        for service in GamingService.allCases {
            if let credential = read(service) {
                loaded[service] = credential
            }
        }
        accounts = loaded
    }

    @discardableResult
    func save(service: GamingService, accountIdentifier: String, secret: String) -> Bool {
        let credential = LocalCredential(
            accountIdentifier: accountIdentifier.trimmingCharacters(in: .whitespacesAndNewlines),
            secret: secret,
            updatedAt: Date()
        )
        guard !credential.accountIdentifier.isEmpty else {
            lastError = "The account identifier cannot be empty."
            return false
        }
        guard let data = try? JSONEncoder().encode(credential) else {
            lastError = "Unable to encode the local credential."
            return false
        }

        SecItemDelete(baseQuery(for: service) as CFDictionary)
        var query = baseQuery(for: service)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            lastError = SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)"
            return false
        }

        lastError = nil
        accounts[service] = credential
        return true
    }

    func remove(_ service: GamingService) {
        let status = SecItemDelete(baseQuery(for: service) as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            accounts.removeValue(forKey: service)
            lastError = nil
        } else {
            lastError = SecCopyErrorMessageString(status, nil) as String?
        }
    }

    private func read(_ service: GamingService) -> LocalCredential? {
        var query = baseQuery(for: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(LocalCredential.self, from: data)
    }

    private func baseQuery(for service: GamingService) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: service.rawValue,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
    }
}
