import Foundation
import SwiftUI

/// Global runtime configuration for Linguabrief iOS client.
/// Allows dynamic configuration of backend address to support:
/// - iOS Simulator: http://127.0.0.1:5000
/// - Physical iPhone: http://<Mac-LAN-IP>:5000
/// - Remote Staging/Production: https://api.linguabrief.com
public enum AppConfig {
    
    public static let defaultSimulatorURL = "http://127.0.0.1:5000"
    
    private static let backendURLKey = "linguabrief_backend_base_url"
    
    /// The active backend base URL
    public static var baseURLString: String {
        get {
            if let custom = UserDefaults.standard.string(forKey: backendURLKey), !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return custom.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return defaultSimulatorURL
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: backendURLKey)
            } else {
                UserDefaults.standard.set(trimmed, forKey: backendURLKey)
            }
        }
    }
    
    public static var baseURL: URL {
        URL(string: baseURLString) ?? URL(string: defaultSimulatorURL)!
    }
    
    public static let defaultTimeout: TimeInterval = 15.0
    public static let extendedTimeout: TimeInterval = 60.0
    
    /// Reset backend URL back to default simulator URL
    public static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: backendURLKey)
    }
}
