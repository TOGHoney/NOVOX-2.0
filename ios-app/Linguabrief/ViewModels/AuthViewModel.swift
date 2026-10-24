import Foundation
import SwiftUI

/// Authentication & session state view model.
/// Manages user credentials, Keychain persistence, onboarding completion, and profile settings.
@MainActor
public final class AuthViewModel: ObservableObject {
    
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User?
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // User preferences
    @AppStorage("selected_target_language") public var targetLanguage: String = "Spanish"
    @AppStorage("selected_cefr_level") public var cefrLevel: String = "B1"
    @AppStorage("selected_native_language") public var nativeLanguage: String = "English"
    
    // MARK: - Adaptive CEFR Learning Mode
    
    /// Returns true if user's proficiency level is Beginner or Intermediate (A1, A2, B1)
    public var isBeginnerOrIntermediate: Bool {
        let level = cefrLevel.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return level.hasPrefix("A1") || level.hasPrefix("A2") || level.hasPrefix("B1")
    }
    
    /// Reading Language:
    /// - Mode A (A1, A2, B1): News displayed in user's base/native language
    /// - Mode B (B2, C1, C2): News displayed in target/learning language
    public var readingLanguage: String {
        isBeginnerOrIntermediate ? nativeLanguage : targetLanguage
    }
    
    public var readingLanguageCode: String {
        Constants.languageCode(for: readingLanguage)
    }
    
    /// Translation Destination Language:
    /// - Mode A (A1, A2, B1): Tap/select translates into target/learning language
    /// - Mode B (B2, C1, C2): Tap/select translates into base/native language
    public var translationDestinationLanguage: String {
        isBeginnerOrIntermediate ? targetLanguage : nativeLanguage
    }
    
    public var translationDestinationLanguageCode: String {
        Constants.languageCode(for: translationDestinationLanguage)
    }
    
    public var adaptiveModeTitle: String {
        isBeginnerOrIntermediate ? "Mode A (A1–B1)" : "Mode B (B2–C2)"
    }
    
    public var adaptiveModeDescription: String {
        if isBeginnerOrIntermediate {
            return "Read in \(nativeLanguage) → Tap/Select for \(targetLanguage)"
        } else {
            return "Read in \(targetLanguage) → Tap/Select for \(nativeLanguage)"
        }
    }
    
    public init() {
        checkExistingSession()
    }
    
    // MARK: - Session Validation
    
    public func checkExistingSession() {
        guard let token = KeychainManager.shared.getToken(), !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.isAuthenticated = false
            self.currentUser = nil
            return
        }
        
        Task {
            do {
                let user: User = try await APIClient.shared.request(.getProfile())
                self.currentUser = user
                self.targetLanguage = user.targetLanguage ?? self.targetLanguage
                self.cefrLevel = user.cefrLevel ?? self.cefrLevel
                self.nativeLanguage = user.nativeLanguage ?? self.nativeLanguage
                self.errorMessage = nil
                self.isAuthenticated = true
            } catch {
                // Token invalid or expired
                KeychainManager.shared.clearAll()
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }
    
    // MARK: - Login
    
    public func login(email: String, password: String) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        struct LoginPayload: Codable {
            let email: String
            let password: String
        }
        
        do {
            let response: AuthResponse = try await APIClient.shared.request(
                .login(),
                body: LoginPayload(email: trimmedEmail, password: password)
            )
            
            // Save token synchronously before updating reactive state
            KeychainManager.shared.saveToken(response.token)
            KeychainManager.shared.saveUserId(response.id)
            
            let user = response.toUser()
            self.currentUser = user
            if let target = user.targetLanguage { self.targetLanguage = target }
            if let cefr = user.cefrLevel { self.cefrLevel = cefr }
            if let native = user.nativeLanguage { self.nativeLanguage = native }
            
            self.errorMessage = nil
            self.isAuthenticated = true
            self.isLoading = false
            return true
        } catch let err as NetworkError {
            self.errorMessage = err.localizedDescription
            self.isLoading = false
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return false
        }
    }
    
    // MARK: - Signup
    
    public func signup(username: String, email: String, password: String) async -> Bool {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedUser.count >= 3 else {
            self.errorMessage = "Username must be at least 3 characters."
            return false
        }
        guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
            self.errorMessage = "Please provide a valid email address."
            return false
        }
        guard password.count >= 6 else {
            self.errorMessage = "Password must be at least 6 characters."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        struct SignupPayload: Codable {
            let username: String
            let email: String
            let password: String
        }
        
        do {
            let response: AuthResponse = try await APIClient.shared.request(
                .signup(),
                body: SignupPayload(username: trimmedUser, email: trimmedEmail, password: password)
            )
            
            // Save token synchronously before updating reactive state
            KeychainManager.shared.saveToken(response.token)
            KeychainManager.shared.saveUserId(response.id)
            
            self.currentUser = response.toUser()
            self.errorMessage = nil
            self.isAuthenticated = true
            self.isLoading = false
            return true
        } catch let err as NetworkError {
            self.errorMessage = err.localizedDescription
            self.isLoading = false
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return false
        }
    }
    
    // MARK: - Profile & Onboarding Completion
    
    /// Updates user's learning profile. Native language is fixed to English.
    public func updateLearningProfile(targetLanguage: String, cefrLevel: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let payload = ProfileUpdateRequest(
            targetLanguage: targetLanguage,
            cefrLevel: cefrLevel,
            nativeLanguage: "English",
            profileCompleted: true
        )
        
        do {
            let updatedUser: User = try await APIClient.shared.request(.updateProfile(), body: payload)
            var finalUser = updatedUser
            if finalUser.profileCompleted == nil || finalUser.profileCompleted == false {
                finalUser.profileCompleted = true
            }
            self.currentUser = finalUser
            self.targetLanguage = targetLanguage
            self.cefrLevel = cefrLevel
            self.nativeLanguage = "English"
            self.isLoading = false
            return true
        } catch let err as NetworkError {
            self.errorMessage = err.localizedDescription
            self.isLoading = false
            return false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            return false
        }
    }
    
    // MARK: - Logout
    
    public func logout() {
        KeychainManager.shared.clearAll()
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
}
