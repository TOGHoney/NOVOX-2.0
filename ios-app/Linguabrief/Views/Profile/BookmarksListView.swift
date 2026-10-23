import SwiftUI

/// Reading list view presenting all bookmarked articles.
public struct BookmarksListView: View {
    @State private var bookmarks: [Bookmark] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    public init() {}
    
    public var body: some View {
        VStack {
            if isLoading && bookmarks.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading saved articles...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if bookmarks.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 45))
                        .foregroundColor(.secondary)
                    Text("No bookmarks yet")
                        .font(.headline)
                    Text("Save articles while browsing the feed to build your personal reading list.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(bookmarks) { b in
                        let snap = b.article
                        NavigationLink(destination: ArticleReaderView(
                            article: Article(
                                id: b.id,
                                title: snap?.title ?? "Saved Article",
                                description: snap?.description,
                                content: snap?.content,
                                source: snap?.source,
                                url: b.articleUrl,
                                imageUrl: snap?.imageUrl,
                                publishedAt: snap?.publishedAt,
                                topic: snap?.category,
                                aiSummary: snap?.aiSummary
                            )
                        )) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(snap?.title ?? "Saved Article")
                                    .font(.headline)
                                    .lineLimit(2)
                                
                                HStack {
                                    Text(snap?.source ?? "News")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if let cat = snap?.category, !cat.isEmpty {
                                        Text(cat.capitalized)
                                            .font(.caption2.bold())
                                            .foregroundColor(Constants.Colors.brandBurgundy)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            let item = bookmarks[idx]
                            Task {
                                try? await APIClient.shared.requestVoid(.removeBookmark(articleUrl: item.articleUrl))
                                bookmarks.remove(at: idx)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Bookmarks")
        .task {
            await fetchBookmarks()
        }
        .refreshable {
            await fetchBookmarks()
        }
    }
    
    private func fetchBookmarks() async {
        isLoading = true
        do {
            let list: [Bookmark] = try await APIClient.shared.request(.bookmarks())
            self.bookmarks = list
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
}
