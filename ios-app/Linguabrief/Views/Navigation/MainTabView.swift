import SwiftUI

/// Main 5-tab navigation hub of Linguabrief.
public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("News Feed", systemImage: "newspaper.fill")
                }
                .tag(0)
            
            SavedWordsListView()
                .tabItem {
                    Label("Vocabulary", systemImage: "character.book.closed.fill")
                }
                .tag(1)
            
            ContestListView()
                .tabItem {
                    Label("Contests", systemImage: "trophy.fill")
                }
                .tag(2)
            
            DebateRoomsListView()
                .tabItem {
                    Label("Debates", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(4)
        }
        .accentColor(Constants.Colors.brandBurgundy)
    }
}
