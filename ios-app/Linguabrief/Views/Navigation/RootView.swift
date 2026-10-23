import SwiftUI

/// Root navigation router directing users to Auth, Onboarding, or Main Tabs.
public struct RootView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    
    public init() {}
    
    public var body: some View {
        Group {
            if !authVM.isAuthenticated {
                LoginView()
            } else if authVM.currentUser?.profileCompleted != true {
                LearningProfileSetupView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authVM.currentUser?.profileCompleted)
    }
}
