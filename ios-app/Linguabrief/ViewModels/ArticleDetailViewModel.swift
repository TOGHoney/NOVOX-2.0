import Foundation
import SwiftUI

/// View model for the full article reader, web extraction, bookmarks, and comments.
@MainActor
public final class ArticleDetailViewModel: ObservableObject {
    
    public let article: Article
    
    @Published public var extractedArticle: ExtractedArticle?
    @Published public var isExtracting: Bool = false
    @Published public var extractionError: String?
    
    // Bookmarking state
    @Published public var isBookmarked: Bool = false
    @Published public var isTogglingBookmark: Bool = false
    
    // Comments state
    @Published public var comments: [Comment] = []
    @Published public var isCommentsLoading: Bool = false
    @Published public var isPostingComment: Bool = false
    
    // Translation state
    @Published public var translatedTitle: String?
    @Published public var translatedContent: String?
    @Published public var romajiContent: String?
    @Published public var isTranslating: Bool = false
    @Published public var showTranslation: Bool = false
    @Published public var translationError: String?
    
    public init(article: Article) {
        self.article = article
    }
    
    // MARK: - Article Translation & Romaji
    
    public func translateArticle(to targetLangCode: String, force: Bool = false) async {
        if !force && showTranslation {
            showTranslation = false
            return
        }
        
        if !force && translatedTitle != nil && translatedContent != nil {
            showTranslation = true
            return
        }
        
        isTranslating = true
        translationError = nil
        
        let textToTranslate = extractedArticle?.content ?? article.content ?? article.description ?? article.title
        let snippet = String(textToTranslate.prefix(2500))
        let titleToTranslate = article.originalTitle ?? article.title
        
        do {
            let req = TranslationRequest(texts: [titleToTranslate, snippet], target: targetLangCode)
            let res: TranslationResponse = try await APIClient.shared.request(
                .translate(),
                body: req,
                timeout: AppConfig.extendedTimeout
            )
            if res.translations.count >= 2 {
                self.translatedTitle = res.translations[0]
                self.translatedContent = res.translations[1]
            } else if let first = res.translations.first {
                self.translatedTitle = first
                self.translatedContent = snippet
            }
            
            // If Japanese, compute romaji transliteration on-device
            if targetLangCode.lowercased() == "ja" {
                if let trans = self.translatedContent {
                    self.romajiContent = trans.applyingTransform(.toLatin, reverse: false)
                }
            }
            
            self.showTranslation = true
            self.isTranslating = false
        } catch {
            self.translationError = error.localizedDescription
            self.isTranslating = false
        }
    }
    
    // MARK: - Full Text Extraction
    
    public func loadFullText(andTranslateTo targetLangCode: String? = nil) async {
        guard extractedArticle == nil, !isExtracting else { return }
        isExtracting = true
        extractionError = nil
        
        do {
            let extracted: ExtractedArticle = try await APIClient.shared.request(
                .extractArticle(url: article.url),
                timeout: AppConfig.extendedTimeout
            )
            self.extractedArticle = extracted
            self.isExtracting = false
            
            // Automatically translate while loading
            if let targetLang = targetLangCode, !targetLang.isEmpty && targetLang.lowercased() != "en" {
                await translateArticle(to: targetLang, force: true)
            }
        } catch {
            self.extractionError = error.localizedDescription
            self.isExtracting = false
            
            // If extraction fails, still translate snippet while loading
            if let targetLang = targetLangCode, !targetLang.isEmpty && targetLang.lowercased() != "en" {
                await translateArticle(to: targetLang, force: true)
            }
        }
    }
    
    // MARK: - Bookmark Handling
    
    public func checkBookmarkStatus() async {
        do {
            let bookmarks: [Bookmark] = try await APIClient.shared.request(.bookmarks())
            self.isBookmarked = bookmarks.contains(where: { $0.articleUrl == article.url })
        } catch {}
    }
    
    public func toggleBookmark() async {
        guard !isTogglingBookmark else { return }
        isTogglingBookmark = true
        
        do {
            if isBookmarked {
                try await APIClient.shared.requestVoid(.removeBookmark(articleUrl: article.url))
                self.isBookmarked = false
            } else {
                let snapshot = BookmarkArticleSnapshot(
                    title: article.title,
                    description: article.description,
                    content: article.content,
                    imageUrl: article.imageUrl,
                    url: article.url,
                    source: article.source,
                    publishedAt: article.publishedAt,
                    category: article.topic,
                    aiSummary: article.aiSummary
                )
                let payload = BookmarkCreateRequest(articleUrl: article.url, article: snapshot)
                let _: Bookmark = try await APIClient.shared.request(.addBookmark(), body: payload)
                self.isBookmarked = true
            }
            self.isTogglingBookmark = false
        } catch {
            self.isTogglingBookmark = false
        }
    }
    
    // MARK: - Comments Handling
    
    public func loadComments() async {
        isCommentsLoading = true
        do {
            let list: [Comment] = try await APIClient.shared.request(.comments(articleUrl: article.url))
            self.comments = list
            self.isCommentsLoading = false
        } catch {
            self.isCommentsLoading = false
        }
    }
    
    public func postComment(text: String, parentId: String? = nil) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        isPostingComment = true
        let payload = CommentCreateRequest(articleUrl: article.url, text: trimmed, parentId: parentId)
        
        do {
            let newComment: Comment = try await APIClient.shared.request(.postComment(), body: payload)
            self.comments.append(newComment)
            self.isPostingComment = false
            return true
        } catch {
            self.isPostingComment = false
            return false
        }
    }
    
    public func deleteComment(id: String) async {
        do {
            try await APIClient.shared.requestVoid(.deleteComment(id: id))
            self.comments.removeAll(where: { $0.id == id })
        } catch {}
    }
}
