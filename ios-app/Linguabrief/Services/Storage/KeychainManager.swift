import Foundation
import Security

/// Secure iOS Keychain manager for persisting JWT session tokens and user identifiers.
/// Implements triple-layer persistence:
/// 1. Synchronous thread-safe in-memory cache for immediate, zero-latency access across views.
/// 2. Primary hardware-backed Keychain storage with proper `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` accessibility.
/// 3. Persistent fallback backing store to guarantee session retention across simulator restarts and sandbox resets.
public final class KeychainManager: @unchecked Sendable {
    
    public static let shared = KeychainManager()
    
    private let tokenService = "com.novox.linguabrief.auth-token"
    private let userIdService = "com.novox.linguabrief.user-id"
    private let account = "currentUser"
    
    private let tokenFallbackKey = "com.novox.linguabrief.session.token"
    private let userIdFallbackKey = "com.novox.linguabrief.session.userId"
    
    private let lock = NSLock()
    private var memoryCache: [String: String] = [:]
    
    private init() {
        // Hydrate in-memory cache on initialization
        if let token = readDirect(service: tokenService, fallbackKey: tokenFallbackKey), !token.isEmpty {
            memoryCache[tokenService] = token
        }
        if let uid = readDirect(service: userIdService, fallbackKey: userIdFallbackKey), !uid.isEmpty {
            memoryCache[userIdService] = uid
        }
    }
    
    // MARK: - Auth Token API
    
    public func saveToken(_ token: String) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        lock.lock()
        memoryCache[tokenService] = trimmed
        lock.unlock()
        
        writeDirect(service: tokenService, fallbackKey: tokenFallbackKey, value: trimmed)
    }
    
    public func getToken() -> String? {
        lock.lock()
        if let cached = memoryCache[tokenService], !cached.isEmpty {
            lock.unlock()
            return cached
        }
        lock.unlock()
        
        if let loaded = readDirect(service: tokenService, fallbackKey: tokenFallbackKey), !loaded.isEmpty {
            lock.lock()
            memoryCache[tokenService] = loaded
            lock.unlock()
            return loaded
        }
        return nil
    }
    
    public func deleteToken() {
        lock.lock()
        memoryCache.removeValue(forKey: tokenService)
        lock.unlock()
        
        eraseDirect(service: tokenService, fallbackKey: tokenFallbackKey)
    }
    
    // MARK: - User ID API
    
    public func saveUserId(_ userId: String) {
        let trimmed = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        lock.lock()
        memoryCache[userIdService] = trimmed
        lock.unlock()
        
        writeDirect(service: userIdService, fallbackKey: userIdFallbackKey, value: trimmed)
    }
    
    public func getUserId() -> String? {
        lock.lock()
        if let cached = memoryCache[userIdService], !cached.isEmpty {
            lock.unlock()
            return cached
        }
        lock.unlock()
        
        if let loaded = readDirect(service: userIdService, fallbackKey: userIdFallbackKey), !loaded.isEmpty {
            lock.lock()
            memoryCache[userIdService] = loaded
            lock.unlock()
            return loaded
        }
        return nil
    }
    
    public func clearAll() {
        deleteToken()
        lock.lock()
        memoryCache.removeValue(forKey: userIdService)
        lock.unlock()
        eraseDirect(service: userIdService, fallbackKey: userIdFallbackKey)
    }
    
    // MARK: - Internal Storage Machinery
    
    private func writeDirect(service: String, fallbackKey: String, value: String) {
        // 1. Persist to standard defaults fallback immediately
        UserDefaults.standard.set(value, forKey: fallbackKey)
        UserDefaults.standard.synchronize()
        
        // 2. Persist to iOS Keychain
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            _ = SecItemAdd(newItem as CFDictionary, nil)
        }
    }
    
    private func readDirect(service: String, fallbackKey: String) -> String? {
        // 1. Try iOS Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data, let str = String(data: data, encoding: .utf8), !str.isEmpty {
            return str
        }
        
        // 2. Fallback to UserDefaults
        if let fallback = UserDefaults.standard.string(forKey: fallbackKey), !fallback.isEmpty {
            // Re-sync into Keychain if possible
            let syncData = Data(fallback.utf8)
            var newItem: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: syncData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            _ = SecItemAdd(newItem as CFDictionary, nil)
            return fallback
        }
        
        return nil
    }
    
    private func eraseDirect(service: String, fallbackKey: String) {
        // 1. Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: fallbackKey)
        UserDefaults.standard.synchronize()
        
        // 2. Clear Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        _ = SecItemDelete(query as CFDictionary)
    }
}

