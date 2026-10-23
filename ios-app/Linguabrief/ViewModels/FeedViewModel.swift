import Foundation
import SwiftUI

/// Feed view model managing the infinite, interleaved topic news stream and AI summaries.
@MainActor
public final class FeedViewModel: ObservableObject {
    
    @Published public var articles: [Article] = []
    @Published public var isLoading: Bool = false
    @Published public var isLoadingMore: Bool = false
    @Published public var hasMore: Bool = true
    @Published public var errorMessage: String?
    @Published public var selectedTopic: String = "all"
    @Published public var searchQuery: String = ""
    @Published public var summaryLoadingMap: [String: Bool] = [:]
    
    private var offset: Int = 0
    private let pageSize: Int = 20
    public private(set) var currentLanguageCode: String = "es"
    
    public init() {
        let cefr = UserDefaults.standard.string(forKey: "selected_cefr_level") ?? "B1"
        let isBeginner = cefr.hasPrefix("A1") || cefr.hasPrefix("A2") || cefr.hasPrefix("B1")
        let native = UserDefaults.standard.string(forKey: "selected_native_language") ?? "English"
        let target = UserDefaults.standard.string(forKey: "selected_target_language") ?? "Spanish"
        let readingLang = isBeginner ? native : target
        self.currentLanguageCode = Constants.languageCode(for: readingLang)
        Task {
            await fetchFeed()
        }
    }
    
    // MARK: - Filtered Articles
    
    public var filteredArticles: [Article] {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return articles }
        return articles.filter {
            $0.title.lowercased().contains(q) ||
            ($0.description ?? "").lowercased().contains(q) ||
            ($0.source ?? "").lowercased().contains(q)
        }
    }
    
    // MARK: - Feed Fetching
    
    public func fetchFeed(readingLanguageCode: String? = nil) async {
        if let code = readingLanguageCode {
            self.currentLanguageCode = code
        }
        
        isLoading = true
        errorMessage = nil
        offset = 0
        
        do {
            let response: FeedResponse = try await APIClient.shared.request(
                .feed(offset: 0, limit: pageSize, topic: selectedTopic, targetLang: currentLanguageCode)
            )
            self.articles = response.articles
            self.hasMore = response.hasMore
            self.offset = response.articles.count
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    public func updateAdaptiveReadingLanguageIfNeeded(_ code: String) async {
        if code != currentLanguageCode {
            await fetchFeed(readingLanguageCode: code)
        }
    }
    
    public func updateLanguageIfNeeded(_ language: String) async {
        let code = Constants.languageCode(for: language)
        await updateAdaptiveReadingLanguageIfNeeded(code)
    }
    
    public func loadMoreIfNeeded(currentArticle: Article) async {
        guard !isLoadingMore, hasMore else { return }
        guard let index = articles.firstIndex(where: { $0.id == currentArticle.id }),
              index >= articles.count - 4 else { return }
        
        isLoadingMore = true
        
        do {
            let response: FeedResponse = try await APIClient.shared.request(
                .feed(offset: offset, limit: pageSize, topic: selectedTopic, targetLang: currentLanguageCode)
            )
            
            // Deduplicate incoming articles by URL
            let existingUrls = Set(articles.map { $0.url })
            let newUnique = response.articles.filter { !existingUrls.contains($0.url) }
            
            self.articles.append(contentsOf: newUnique)
            self.hasMore = response.hasMore
            self.offset += response.articles.count
            self.isLoadingMore = false
        } catch {
            self.isLoadingMore = false
        }
    }
    
    public func selectTopic(_ topic: String) async {
        guard selectedTopic != topic else { return }
        selectedTopic = topic
        await fetchFeed()
    }
    
    // MARK: - On-Demand AI Summary
    
    public func generateSummary(for articleId: String) async {
        guard summaryLoadingMap[articleId] != true else { return }
        summaryLoadingMap[articleId] = true
        
        do {
            let response: BatchSummaryResponse = try await APIClient.shared.request(
                .batchSummary(),
                body: BatchSummaryRequest(articleIds: [articleId]),
                timeout: AppConfig.extendedTimeout
            )
            
            if let updated = response.articles.first(where: { $0.id == articleId }) {
                if let idx = articles.firstIndex(where: { $0.id == articleId }) {
                    articles[idx].aiSummary = updated.aiSummary
                }
            }
            summaryLoadingMap[articleId] = false
        } catch {
            summaryLoadingMap[articleId] = false
        }
    }
}
