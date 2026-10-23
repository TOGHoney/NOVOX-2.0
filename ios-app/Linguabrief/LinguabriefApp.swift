import SwiftUI

@main
public struct LinguabriefApp: App {
    @StateObject private var authVM = AuthViewModel()
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authVM)
        }
    }
}
