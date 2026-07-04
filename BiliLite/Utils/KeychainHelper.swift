import Foundation

/// Simple helper for saving/reading/deleting sensitive strings from the iOS Keychain.
/// Uses `kSecClassGenericPassword` so tokens are encrypted at rest and excluded
/// from unencrypted iTunes/Finder backups (unlike UserDefaults plists).
struct KeychainHelper {

    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete any existing item first to avoid duplicate
        delete(key: key)

        let query: [String: Any] = [
            kSecClass            as String: kSecClassGenericPassword,
            kSecAttrAccount      as String: key,
            kSecAttrAccessible   as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData        as String: data,
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass        as String: kSecClassGenericPassword,
            kSecAttrAccount  as String: key,
            kSecReturnData   as String: true,
            kSecMatchLimit   as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
