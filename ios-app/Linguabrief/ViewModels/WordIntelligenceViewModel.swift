import Foundation
import SwiftUI

/// View model for on-demand word intelligence, linguistic analysis, dictionary definition, and auto-save.
@MainActor
public final class WordIntelligenceViewModel: ObservableObject {
    
    @Published public var selectedResult: WordIntelligenceResult?
    @Published public var isAnalyzing: Bool = false
    @Published public var isSaved: Bool = false
    @Published public var showSheet: Bool = false
    
    // Cached set of words saved in current session
    private var sessionSavedWords = Set<String>()
    
    public init() {}
    
    // MARK: - Analyze & Lookup
    
    public func analyzeWord(
        _ rawWord: String,
        inSentence sentence: String? = nil,
        targetLanguageCode: String = "es"
    ) async {
        let clean = rawWord.trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count > 1 else { return }
        
        isAnalyzing = true
        showSheet = true
        isSaved = false
        
        // 1. Native on-device linguistic analysis via Apple NaturalLanguage
        let (lemma, pos, cefr) = NativeLinguisticService.shared.analyzeWord(word: clean, inSentence: sentence)
        
        var result = WordIntelligenceResult(
            word: clean,
            lemma: lemma,
            partOfSpeech: pos,
            cefr: cefr
        )
        
        // 2. Fetch definition, phonetics, and translation in parallel
        async let dictTask = DictionaryAPIService.shared.fetchDictionaryData(for: lemma)
        async let transTask = DictionaryAPIService.shared.translateWord(lemma, toTargetLanguage: targetLanguageCode)
        
        let (dictData, translation) = await (dictTask, transTask)
        
        result.phonetic = dictData.phonetic
        result.audioUrl = dictData.audioUrl
        result.definitions = dictData.definitions
        result.translation = translation
        
        self.selectedResult = result
        self.isAnalyzing = false
        
        // 3. Auto-save to backend /api/saved-words
        await autoSaveWord(result, sentence: sentence)
    }
    
    // MARK: - Auto-Save to Backend
    
    private func autoSaveWord(_ result: WordIntelligenceResult, sentence: String?) async {
        let saveKey = "\(result.word.lowercased())_\(result.translation.lowercased())"
        guard !sessionSavedWords.contains(saveKey) else {
            self.isSaved = true
            return
        }
        
        let payload = SavedWordCreateRequest(
            word: result.word,
            translation: result.translation,
            contextSentence: sentence ?? "",
            definition: result.definitions.first ?? "",
            phonetic: result.phonetic,
            cefr: result.cefr
        )
        
        do {
            let _: SingleSavedWordResponse = try await APIClient.shared.request(.saveWord(), body: payload)
            sessionSavedWords.insert(saveKey)
            self.isSaved = true
        } catch {
            // Already saved or connection issue
            self.isSaved = true
        }
    }
    
    // MARK: - Pronunciation
    
    public func playPronunciation() {
        guard let result = selectedResult else { return }
        SpeechSynthesisService.shared.speak(result.word, languageCode: "en-US")
    }
}
