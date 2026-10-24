import Foundation
import SwiftUI

/// View model for on-demand word intelligence, linguistic analysis, dictionary definition, and auto-save.
@MainActor
public final class WordIntelligenceViewModel: ObservableObject {
    
    @Published public var selectedResult: WordIntelligenceResult?
    @Published public var isAnalyzing: Bool = false
    @Published public var isSaved: Bool = false
    @Published public var showSheet: Bool = false
    @Published public var errorMessage: String?
    @Published public var lastError: String? = nil
    
    // Last request context for retry
    private var lastRawExpression: String = ""
    private var lastSentence: String? = nil
    private var lastBaseLang: String = "en"
    private var lastTargetLang: String = "es"
    private var lastCefrLevel: String = "B1"
    private var lastIsSentence: Bool = false
    
    // Cached set of words saved in current session
    private var sessionSavedWords = Set<String>()
    
    public init() {}
    
    // MARK: - Analyze & Lookup
    
    /// Primary Word Intelligence analysis method respecting learning mode:
    /// - Mode A (A1-B1): Base language expression -> Target language translation & target pronunciation
    /// - Mode B (B2-C2): Target language expression -> Base language translation & target pronunciation
    /// - Contextual meaning is ALWAYS in the learner's base language.
    public func analyzeWord(
        _ rawWord: String,
        inSentence sentence: String? = nil,
        baseLanguageCode: String = "en",
        targetLanguageCode: String = "es",
        cefrLevel: String = "B1"
    ) async {
        let clean = rawWord.trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        self.lastRawExpression = clean
        self.lastSentence = sentence
        self.lastBaseLang = baseLanguageCode
        self.lastTargetLang = targetLanguageCode
        self.lastCefrLevel = cefrLevel
        self.lastIsSentence = false
        
        isAnalyzing = true
        showSheet = true
        errorMessage = nil
        isSaved = false
        
        let isBeginnerOrIntermediate = ["A1", "A2", "B1"].contains(cefrLevel.uppercased())
        
        // 1. Native on-device linguistic analysis via Apple NaturalLanguage
        let (lemma, pos, nativeCefr) = NativeLinguisticService.shared.analyzeWord(word: clean, inSentence: sentence)
        
        // 2. Fetch backend word intelligence and dictionary data in parallel
        async let aiTask = DictionaryAPIService.shared.fetchWordIntelligence(
            expression: clean,
            sentence: sentence,
            baseLanguage: baseLanguageCode,
            targetLanguage: targetLanguageCode,
            cefrLevel: cefrLevel
        )
        async let dictTask = DictionaryAPIService.shared.fetchDictionaryData(for: lemma.isEmpty ? clean : lemma)
        
        let (aiResp, dictData) = await (aiTask, dictTask)
        
        let targetExpr = aiResp.targetExpression?.isEmpty == false
            ? aiResp.targetExpression!
            : (isBeginnerOrIntermediate ? aiResp.translation : clean)
        
        let pronunciation = aiResp.pronunciationGuide?.isEmpty == false
            ? aiResp.pronunciationGuide!
            : (!dictData.phonetic.isEmpty && dictData.phonetic != "/\(clean)/" ? dictData.phonetic : "")
        
        var definitions = dictData.definitions
        if definitions.isEmpty, let aiDef = aiResp.dictionaryDefinition, !aiDef.isEmpty {
            definitions = [aiDef]
        }
        
        let result = WordIntelligenceResult(
            word: clean,
            lemma: lemma,
            partOfSpeech: aiResp.partOfSpeech ?? pos,
            cefr: aiResp.detectedCefr ?? nativeCefr,
            phonetic: pronunciation,
            pronunciationGuide: aiResp.pronunciationGuide,
            audioUrl: dictData.audioUrl,
            translation: aiResp.translation,
            contextualMeaning: aiResp.contextualMeaning,
            targetExpression: targetExpr,
            sourceLanguage: isBeginnerOrIntermediate ? baseLanguageCode : targetLanguageCode,
            destinationLanguage: isBeginnerOrIntermediate ? targetLanguageCode : baseLanguageCode,
            targetLanguageCode: targetLanguageCode,
            baseLanguageCode: baseLanguageCode,
            contextSentence: sentence,
            definitions: definitions,
            confidenceScore: 92,
            isSentence: aiResp.isSentence ?? false,
            isBeginnerOrIntermediate: isBeginnerOrIntermediate
        )
        
        if result.translation.isEmpty {
            self.errorMessage = "Could not retrieve translation for '\(clean)'. Tap retry."
        }
        
        self.selectedResult = result
        self.isAnalyzing = false
        
        // 3. Auto-save word to backend
        await autoSaveWord(result, sentence: sentence)
    }
    
    /// Backward-compatible overload
    public func analyzeWord(
        _ rawWord: String,
        inSentence sentence: String? = nil,
        sourceLanguageCode: String = "auto",
        nativeLanguageCode: String = "en"
    ) async {
        // Map source/destination back to base/target if caller used old signature
        let isSourceEnglish = sourceLanguageCode == "en"
        let baseLang = isSourceEnglish ? "en" : nativeLanguageCode
        let targetLang = isSourceEnglish ? nativeLanguageCode : (sourceLanguageCode == "auto" ? "es" : sourceLanguageCode)
        let cefr = isSourceEnglish ? "A2" : "B2"
        await analyzeWord(
            rawWord,
            inSentence: sentence,
            baseLanguageCode: baseLang,
            targetLanguageCode: targetLang,
            cefrLevel: cefr
        )
    }
    
    // MARK: - Sentence Translation
    
    public func analyzeSentence(
        _ rawSentence: String,
        baseLanguageCode: String = "en",
        targetLanguageCode: String = "es",
        cefrLevel: String = "B1"
    ) async {
        let clean = rawSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        self.lastRawExpression = clean
        self.lastSentence = nil
        self.lastBaseLang = baseLanguageCode
        self.lastTargetLang = targetLanguageCode
        self.lastCefrLevel = cefrLevel
        self.lastIsSentence = true
        
        isAnalyzing = true
        showSheet = true
        errorMessage = nil
        isSaved = false
        
        let isBeginnerOrIntermediate = ["A1", "A2", "B1"].contains(cefrLevel.uppercased())
        
        // Fetch contextual intelligence for sentence
        let aiResp = await DictionaryAPIService.shared.fetchWordIntelligence(
            expression: clean,
            sentence: clean,
            baseLanguage: baseLanguageCode,
            targetLanguage: targetLanguageCode,
            cefrLevel: cefrLevel
        )
        
        let targetExpr = aiResp.targetExpression?.isEmpty == false
            ? aiResp.targetExpression!
            : (isBeginnerOrIntermediate ? aiResp.translation : clean)
        
        var defs: [String] = []
        if let aiDef = aiResp.dictionaryDefinition, !aiDef.isEmpty {
            defs.append(aiDef)
        }
        
        let result = WordIntelligenceResult(
            word: clean,
            lemma: "",
            partOfSpeech: aiResp.partOfSpeech ?? "Sentence Context",
            cefr: aiResp.detectedCefr ?? cefrLevel,
            phonetic: aiResp.pronunciationGuide ?? "",
            pronunciationGuide: aiResp.pronunciationGuide,
            translation: aiResp.translation,
            contextualMeaning: aiResp.contextualMeaning,
            targetExpression: targetExpr,
            sourceLanguage: isBeginnerOrIntermediate ? baseLanguageCode : targetLanguageCode,
            destinationLanguage: isBeginnerOrIntermediate ? targetLanguageCode : baseLanguageCode,
            targetLanguageCode: targetLanguageCode,
            baseLanguageCode: baseLanguageCode,
            contextSentence: clean,
            definitions: defs,
            confidenceScore: 90,
            isSentence: true,
            isBeginnerOrIntermediate: isBeginnerOrIntermediate
        )
        
        if result.translation.isEmpty {
            self.errorMessage = "Could not retrieve translation for this selection. Tap retry."
        }
        
        self.selectedResult = result
        self.isAnalyzing = false
    }
    
    /// Backward-compatible overload
    public func analyzeSentence(
        _ rawSentence: String,
        sourceLanguageCode: String = "auto",
        destinationLanguageCode: String = "en"
    ) async {
        let isSourceEnglish = sourceLanguageCode == "en"
        let baseLang = isSourceEnglish ? "en" : destinationLanguageCode
        let targetLang = isSourceEnglish ? destinationLanguageCode : (sourceLanguageCode == "auto" ? "es" : sourceLanguageCode)
        let cefr = isSourceEnglish ? "A2" : "B2"
        await analyzeSentence(
            rawSentence,
            baseLanguageCode: baseLang,
            targetLanguageCode: targetLang,
            cefrLevel: cefr
        )
    }

    public func retry() async {
        guard !lastRawExpression.isEmpty else { return }
        if lastIsSentence {
            await analyzeSentence(
                lastRawExpression,
                baseLanguageCode: lastBaseLang,
                targetLanguageCode: lastTargetLang,
                cefrLevel: lastCefrLevel
            )
        } else {
            await analyzeWord(
                lastRawExpression,
                inSentence: lastSentence,
                baseLanguageCode: lastBaseLang,
                targetLanguageCode: lastTargetLang,
                cefrLevel: lastCefrLevel
            )
        }
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
            definition: result.contextualMeaning ?? result.definitions.first ?? "",
            phonetic: result.pronunciationGuide ?? result.phonetic,
            cefr: result.cefr
        )
        
        do {
            let _: SingleSavedWordResponse = try await APIClient.shared.request(.saveWord(), body: payload)
            sessionSavedWords.insert(saveKey)
            self.isSaved = true
        } catch {
            self.isSaved = true
        }
    }
    
    // MARK: - Pronunciation Audio Control
    
    /// Plays the TARGET-LANGUAGE expression using the target language's correct BCP-47 locale.
    /// In Mode A: target expression is the translation.
    /// In Mode B: target expression is the original expression.
    public func playPronunciation() {
        guard let result = selectedResult else { return }
        
        let targetText = result.targetExpression?.isEmpty == false
            ? result.targetExpression!
            : (result.isBeginnerOrIntermediate ? result.translation : result.word)
        
        guard !targetText.isEmpty else {
            lastError = "No text available for pronunciation"
            return
        }
        
        let targetLocale = Constants.bcp47(for: result.targetLanguageCode ?? "es")
        SpeechSynthesisService.shared.speak(targetText, languageCode: targetLocale)
        if let error = SpeechSynthesisService.shared.lastError {
            lastError = error
        }
    }
    
    /// Optional: Plays the ORIGINAL expression in its natural language
    public func playOriginalPronunciation() {
        guard let result = selectedResult else { return }
        let origLocale = Constants.bcp47(for: result.sourceLanguage ?? (result.isBeginnerOrIntermediate ? "en" : "es"))
        SpeechSynthesisService.shared.speak(result.word, languageCode: origLocale)
    }
}

