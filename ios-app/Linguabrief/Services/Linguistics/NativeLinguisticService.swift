import Foundation
import NaturalLanguage

/// Native on-device linguistic analysis powered by Apple NaturalLanguage.framework.
/// Replaces the web app's browser-only `wink-nlp` and `wink-eng-lite-web-model` JavaScript libraries.
public final class NativeLinguisticService: Sendable {
    
    public static let shared = NativeLinguisticService()
    
    private init() {}
    
    // MARK: - Linguistic Analysis
    
    /// Analyzes an English word in context, extracting its base lemma, part of speech, and CEFR rating
    public func analyzeWord(word: String, inSentence sentence: String? = nil) -> (lemma: String, partOfSpeech: String, cefr: String) {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        guard !cleanWord.isEmpty else {
            return (word, "noun", "A1")
        }
        
        let textToAnalyze = sentence ?? cleanWord
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        tagger.string = textToAnalyze
        
        var detectedPOS = "noun"
        var detectedLemma = cleanWord
        
        // Find the range of the target word within the text
        if let wordRange = textToAnalyze.range(of: cleanWord, options: .caseInsensitive) {
            let (lexicalTag, _) = tagger.tag(at: wordRange.lowerBound, unit: .word, scheme: .lexicalClass)
            let (lemmaTag, _) = tagger.tag(at: wordRange.lowerBound, unit: .word, scheme: .lemma)
            
            if let pos = lexicalTag {
                detectedPOS = mapNLTagToStandard(pos)
            }
            if let lemma = lemmaTag?.rawValue, !lemma.isEmpty {
                detectedLemma = lemma.lowercased()
            }
        } else {
            // Analyze the isolated word directly
            let isolatedTagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
            isolatedTagger.string = cleanWord
            let (lexicalTag, _) = isolatedTagger.tag(at: cleanWord.startIndex, unit: .word, scheme: .lexicalClass)
            let (lemmaTag, _) = isolatedTagger.tag(at: cleanWord.startIndex, unit: .word, scheme: .lemma)
            
            if let pos = lexicalTag {
                detectedPOS = mapNLTagToStandard(pos)
            }
            if let lemma = lemmaTag?.rawValue, !lemma.isEmpty {
                detectedLemma = lemma.lowercased()
            }
        }
        
        let cefr = estimateCEFR(detectedLemma)
        return (detectedLemma, detectedPOS, cefr)
    }
    
    // MARK: - CEFR Level Estimation Heuristic
    
    /// Replicates the web app's `estimateCEFR` heuristic from `src/utils/articleUtils.js`
    public func estimateCEFR(_ word: String) -> String {
        let w = word.lowercased()
        let commonA1 = Set(["a", "an", "the", "in", "on", "at", "go", "see", "their", "they", "them", "he", "she", "it", "my", "his", "her", "we", "you", "be", "do", "have", "can", "will"])
        
        if commonA1.contains(w) { return "A1" }
        let len = w.count
        if len <= 4 { return "A2" }
        if len <= 6 { return "B1" }
        if len <= 8 { return "B2" }
        if len <= 11 { return "C1" }
        return "C2"
    }
    
    // MARK: - Private Helpers
    
    private func mapNLTagToStandard(_ tag: NLTag) -> String {
        switch tag {
        case .noun:
            return "noun"
        case .verb:
            return "verb"
        case .adjective:
            return "adjective"
        case .adverb:
            return "adverb"
        default:
            return "noun"
        }
    }
}
