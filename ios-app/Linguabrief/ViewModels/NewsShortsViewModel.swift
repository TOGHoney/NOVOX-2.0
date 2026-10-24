import Foundation
import SwiftUI

/// View model managing the immersive News Shorts vertical infinite stream,
/// adaptive CEFR level-based language loading, deduplication, and word/sentence contextual translation.
@MainActor
public final class NewsShortsViewModel: ObservableObject {
    
    @Published public var articles: [Article] = []
    @Published public var currentArticleId: String?
    @Published public var isLoading: Bool = false
    @Published public var isLoadingMore: Bool = false
    @Published public var hasMore: Bool = true
    @Published public var errorMessage: String?
    
    // Translation Bottom Sheet State
    @Published public var selectedText: String = ""
    @Published public var translatedText: String = ""
    @Published public var targetExpression: String = ""
    @Published public var pronunciationGuide: String?
    @Published public var contextualMeaning: String?
    @Published public var isSentenceTranslation: Bool = false
    @Published public var isTranslating: Bool = false
    @Published public var translationError: String?
    @Published public var lastError: String?
    @Published public var showTranslationSheet: Bool = false
    @Published public var isSavedToVocabulary: Bool = false
    
    // Reader Sheet State
    @Published public var activeReaderArticle: Article?
    
    private var offset: Int = 0
    private let pageSize: Int = 15
    private var isFetching: Bool = false
    private var loadedIds = Set<String>()
    private var loadedUrls = Set<String>()
    
    public private(set) var readingLanguageCode: String = "en"
    public private(set) var destinationLanguageCode: String = "es"
    public private(set) var baseLanguageCode: String = "en"
    public private(set) var targetLanguageCode: String = "es"
    public private(set) var cefrLevel: String = "B1"
    
    public init() {}
    
    // MARK: - Configuration & Initial Load
    
    public func configure(
        readingLanguageCode: String,
        destinationLanguageCode: String,
        baseLanguageCode: String = "en",
        targetLanguageCode: String = "es",
        cefrLevel: String = "B1"
    ) async {
        self.baseLanguageCode = baseLanguageCode
        self.targetLanguageCode = targetLanguageCode
        self.cefrLevel = cefrLevel
        guard self.readingLanguageCode != readingLanguageCode || articles.isEmpty else { return }
        self.readingLanguageCode = readingLanguageCode
        self.destinationLanguageCode = destinationLanguageCode
        await fetchShorts()
    }
    
    public func fetchShorts() async {
        guard !isFetching else { return }
        isFetching = true
        isLoading = true
        errorMessage = nil
        offset = 0
        loadedIds.removeAll()
        loadedUrls.removeAll()
        
        do {
            let response: FeedResponse = try await APIClient.shared.request(
                .feed(offset: 0, limit: pageSize, topic: "all", targetLang: readingLanguageCode)
            )
            
            var unique: [Article] = []
            for art in response.articles {
                if !loadedUrls.contains(art.url) && !loadedIds.contains(art.id) {
                    loadedUrls.insert(art.url)
                    loadedIds.insert(art.id)
                    unique.append(art)
                }
            }
            
            self.articles = unique
            self.hasMore = response.hasMore
            self.offset = response.articles.count
            if currentArticleId == nil || !unique.contains(where: { $0.id == currentArticleId }) {
                self.currentArticleId = unique.first?.id
            }
            self.isLoading = false
            self.isFetching = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            self.isFetching = false
        }
    }
    
    // MARK: - Incremental Paging
    
    public func onArticleAppear(index: Int) {
        guard !isLoadingMore, hasMore, !isFetching else { return }
        if index >= articles.count - 3 {
            Task {
                await loadMoreShorts()
            }
        }
    }
    
    public func loadMoreShorts() async {
        guard !isLoadingMore, hasMore, !isFetching else { return }
        isFetching = true
        isLoadingMore = true
        
        do {
            let response: FeedResponse = try await APIClient.shared.request(
                .feed(offset: offset, limit: pageSize, topic: "all", targetLang: readingLanguageCode)
            )
            
            var newUnique: [Article] = []
            for art in response.articles {
                if !loadedUrls.contains(art.url) && !loadedIds.contains(art.id) {
                    loadedUrls.insert(art.url)
                    loadedIds.insert(art.id)
                    newUnique.append(art)
                }
            }
            
            self.articles.append(contentsOf: newUnique)
            self.hasMore = response.hasMore
            self.offset += response.articles.count
            self.isLoadingMore = false
            self.isFetching = false
        } catch {
            self.isLoadingMore = false
            self.isFetching = false
        }
    }
    
    // MARK: - Word & Sentence Interactive Translation
    
    public func translateWord(_ rawWord: String, inSentence sentence: String? = nil) async {
        let cleanWord = rawWord.trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanWord.isEmpty else { return }
        
        self.selectedText = cleanWord
        self.isSentenceTranslation = false
        self.isTranslating = true
        self.translationError = nil
        self.isSavedToVocabulary = false
        self.showTranslationSheet = true
        
        let isModeA = ["A1", "A2", "B1"].contains(cefrLevel.uppercased())
        
        let aiResp = await DictionaryAPIService.shared.fetchWordIntelligence(
            expression: cleanWord,
            sentence: sentence,
            baseLanguage: baseLanguageCode,
            targetLanguage: targetLanguageCode,
            cefrLevel: cefrLevel
        )
        
        if aiResp.translation.isEmpty {
            self.translationError = "Unable to translate '\(cleanWord)'. Tap to retry."
            self.translatedText = cleanWord
            self.targetExpression = cleanWord
            self.pronunciationGuide = nil
            self.contextualMeaning = nil
        } else {
            self.translatedText = aiResp.translation
            self.targetExpression = aiResp.targetExpression ?? (isModeA ? aiResp.translation : cleanWord)
            self.pronunciationGuide = aiResp.pronunciationGuide
            self.contextualMeaning = aiResp.contextualMeaning
        }
        
        self.isTranslating = false
        
        // Auto-save word to backend
        await autoSaveWord(word: cleanWord, translation: self.translatedText, contextSentence: sentence)
    }
    
    public func translateSentence(_ rawSentence: String) async {
        let cleanSentence = rawSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanSentence.isEmpty else { return }
        
        self.selectedText = cleanSentence
        self.isSentenceTranslation = true
        self.isTranslating = true
        self.translationError = nil
        self.isSavedToVocabulary = false
        self.showTranslationSheet = true
        
        let isModeA = ["A1", "A2", "B1"].contains(cefrLevel.uppercased())
        
        let aiResp = await DictionaryAPIService.shared.fetchWordIntelligence(
            expression: cleanSentence,
            sentence: cleanSentence,
            baseLanguage: baseLanguageCode,
            targetLanguage: targetLanguageCode,
            cefrLevel: cefrLevel
        )
        
        if aiResp.translation.isEmpty {
            self.translationError = "Unable to translate this sentence. Tap to retry."
            self.translatedText = cleanSentence
            self.targetExpression = cleanSentence
            self.pronunciationGuide = nil
            self.contextualMeaning = nil
        } else {
            self.translatedText = aiResp.translation
            self.targetExpression = aiResp.targetExpression ?? (isModeA ? aiResp.translation : cleanSentence)
            self.pronunciationGuide = aiResp.pronunciationGuide
            self.contextualMeaning = aiResp.contextualMeaning
        }
        
        self.isTranslating = false
    }
    
    public func playPronunciation() {
        // Speaks the target-language expression using the target-language locale
        let textToSpeak = targetExpression.isEmpty ? translatedText : targetExpression
        guard !textToSpeak.isEmpty else {
            lastError = "No text available for pronunciation"
            return
        }
        let voiceCode = Constants.bcp47(for: targetLanguageCode)
        SpeechSynthesisService.shared.speak(textToSpeak, languageCode: voiceCode)
        if let error = SpeechSynthesisService.shared.lastError {
            lastError = error
        }
    }
    
    public func playOriginalPronunciation() {
        guard !selectedText.isEmpty else { return }
        let voiceCode = Constants.bcp47(for: readingLanguageCode)
        SpeechSynthesisService.shared.speak(selectedText, languageCode: voiceCode)
    }
    
    private func autoSaveWord(word: String, translation: String, contextSentence: String?) async {
        let payload = SavedWordCreateRequest(
            word: word,
            translation: translation,
            contextSentence: contextSentence ?? "",
            definition: contextualMeaning ?? translation,
            phonetic: pronunciationGuide ?? "",
            cefr: cefrLevel
        )
        
        do {
            let _: SingleSavedWordResponse = try await APIClient.shared.request(.saveWord(), body: payload)
            self.isSavedToVocabulary = true
        } catch {
            self.isSavedToVocabulary = true
        }
    }
}

