import SwiftUI

/// Profile & Settings view displaying learning metrics, target language settings, and backend networking configuration.
public struct ProfileView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var customURLText: String = AppConfig.baseURLString
    @State private var showURLSavedAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                
                // User Header & Streak Metrics
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Constants.Colors.brandBurgundy)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(authVM.currentUser?.username.prefix(1) ?? "U").uppercased())
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authVM.currentUser?.username ?? "Language Learner")
                                .font(.title3.bold())
                            Text(authVM.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    
                    // Streak Metric Card
                    HStack {
                        Label("Daily Reading Streak", systemImage: "flame.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(authVM.currentUser?.streak ?? 1) days")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                // Language Preferences
                Section("Language Acquisition Settings") {
                    Picker("Target Language", selection: $authVM.targetLanguage) {
                        ForEach(Constants.targetLanguages) { lang in
                            Text("\(lang.flag) \(lang.name)").tag(lang.name)
                        }
                    }
                    .onChange(of: authVM.targetLanguage) { _, newValue in
                        Task {
                            _ = await authVM.updateLearningProfile(targetLanguage: newValue, cefrLevel: authVM.cefrLevel)
                        }
                    }
                    
                    Picker("CEFR Level", selection: $authVM.cefrLevel) {
                        ForEach(Constants.cefrLevels) { cefr in
                            Text("\(cefr.code) - \(cefr.title)").tag(cefr.code)
                        }
                    }
                    .onChange(of: authVM.cefrLevel) { _, newValue in
                        Task {
                            _ = await authVM.updateLearningProfile(targetLanguage: authVM.targetLanguage, cefrLevel: newValue)
                        }
                    }
                }
                
                // Reading List Navigation
                Section("Library") {
                    NavigationLink(destination: BookmarksListView()) {
                        Label("Saved Articles & Bookmarks", systemImage: "bookmark.fill")
                            .foregroundColor(.primary)
                    }
                }
                
                // Backend Server Configuration
                Section(header: Text("Backend Connection (Environment Config)"), footer: Text("Configure host address when running on a physical iPhone or custom network (e.g., http://192.168.1.100:5000). Simulator defaults to 127.0.0.1.")) {
                    HStack {
                        TextField("Backend Base URL", text: $customURLText)
                            .font(.subheadline)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Button("Apply URL") {
                            AppConfig.baseURLString = customURLText
                            showURLSavedAlert = true
                        }
                        .font(.caption.bold())
                        .foregroundColor(Constants.Colors.brandBurgundy)
                        
                        Spacer()
                        
                        Button("Reset to Default") {
                            AppConfig.resetToDefault()
                            customURLText = AppConfig.baseURLString
                            showURLSavedAlert = true
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                // Session Logout
                Section {
                    Button(role: .destructive, action: {
                        authVM.logout()
                    }) {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Profile & Settings")
            .alert("Server Config Updated", isPresented: $showURLSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Backend Base URL set to: \(AppConfig.baseURLString)")
            }
        }
    }
}
