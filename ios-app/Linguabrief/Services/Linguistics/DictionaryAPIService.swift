import Foundation

/// Service for fetching dictionary phonetics, definitions, and word translations.
public final class DictionaryAPIService: Sendable {
    
    public static let shared = DictionaryAPIService()
    
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Dictionary Definitions & Phonetics
    
    public struct DictionaryEntry: Codable, Sendable {
        public let word: String?
        public let phonetic: String?
        public let phonetics: [PhoneticItem]?
        public let meanings: [MeaningItem]?
        
        public struct PhoneticItem: Codable, Sendable {
            public let text: String?
            public let audio: String?
        }
        
        public struct MeaningItem: Codable, Sendable {
            public let partOfSpeech: String?
            public let definitions: [DefinitionItem]?
        }
        
        public struct DefinitionItem: Codable, Sendable {
            public let definition: String?
            public let example: String?
        }
    }
    
    public func fetchDictionaryData(for word: String) async -> (phonetic: String, audioUrl: String?, definitions: [String]) {
        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encoded)") else {
            return ("/\(word)/", nil, [])
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return ("/\(word)/", nil, [])
            }
            
            let entries = try JSONDecoder().decode([DictionaryEntry].self, from: data)
            guard let first = entries.first else {
                return ("/\(word)/", nil, [])
            }
            
            let phonetic = first.phonetic ?? first.phonetics?.first(where: { !($0.text ?? "").isEmpty })?.text ?? "/\(word)/"
            let audioUrl = first.phonetics?.first(where: { !($0.audio ?? "").isEmpty })?.audio
            
            var defs: [String] = []
            if let meanings = first.meanings {
                for m in meanings {
                    if let dList = m.definitions {
                        for d in dList {
                            if let defText = d.definition, !defText.isEmpty {
                                defs.append(defText)
                            }
                        }
                    }
                }
            }
            
            return (phonetic, audioUrl, Array(defs.prefix(3)))
        } catch {
            return ("/\(word)/", nil, [])
        }
    }
    
    // In-memory translation cache (Thread-safe NSCache)
    private let translationCache = NSCache<NSString, NSString>()
    
    // MARK: - Word Translation
    
    /// Translates a word from source language to target language, optionally extracting contextual meaning from sentence
    public func translateWord(
        _ word: String,
        fromSource source: String = "auto",
        toTarget target: String,
        inContext sentence: String? = nil
    ) async -> (wordTranslation: String, contextualMeaning: String?) {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanWord.isEmpty else { return ("", nil) }
        
        let cacheKey = "\(source):\(target):\(cleanWord.lowercased())" as NSString
        if let cached = translationCache.object(forKey: cacheKey) {
            let parts = (cached as String).components(separatedBy: "|||")
            return (parts.first ?? cleanWord, parts.count > 1 ? parts[1] : nil)
        }
        
        var wordTranslation = cleanWord
        var contextualMeaning: String? = nil
        
        // 1. Prepare batch items: Word + Context Sentence if present
        var textsToTranslate = [cleanWord]
        if let sentence = sentence, !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmedSentence = String(sentence.prefix(300))
            textsToTranslate.append(trimmedSentence)
        }
        
        // 2. Try backend /api/translate
        do {
            let requestPayload = TranslationRequest(texts: textsToTranslate, target: target, source: source)
            let response: TranslationResponse = try await APIClient.shared.request(
                .translate(),
                body: requestPayload,
                timeout: AppConfig.extendedTimeout
            )
            if let first = response.translations.first, !first.isEmpty {
                wordTranslation = first
            }
            if response.translations.count > 1 {
                contextualMeaning = response.translations[1]
            }
        } catch {
            // 3. Fallback to client-side Google GTX Web API
            if let encoded = cleanWord.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(source)&tl=\(target)&dt=t&q=\(encoded)") {
                do {
                    let (data, _) = try await session.data(from: url)
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
                       let firstArray = json.first as? [Any],
                       let subArray = firstArray.first as? [Any],
                       let translatedText = subArray.first as? String {
                        wordTranslation = translatedText
                    }
                } catch {}
            }
        }
        
        // Cache result
        let cacheValue = "\(wordTranslation)|||" + (contextualMeaning ?? "")
        translationCache.setObject(cacheValue as NSString, forKey: cacheKey)
        
        return (wordTranslation, contextualMeaning)
    }
    
    /// Translates arbitrary text (sentences, phrases, or words) contextually with caching
    public func translateText(
        _ text: String,
        fromSource source: String = "auto",
        toTarget target: String
    ) async -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        let cacheKey = "\(source):\(target):\(trimmed.lowercased())" as NSString
        if let cached = translationCache.object(forKey: cacheKey) {
            let parts = (cached as String).components(separatedBy: "|||")
            return parts.first ?? trimmed
        }
        
        var translated = trimmed
        
        do {
            let requestPayload = TranslationRequest(texts: [trimmed], target: target, source: source)
            let response: TranslationResponse = try await APIClient.shared.request(
                .translate(),
                body: requestPayload,
                timeout: AppConfig.extendedTimeout
            )
            if let first = response.translations.first, !first.isEmpty {
                translated = first
            }
        } catch {
            // Fallback to client-side Google GTX Web API
            if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(source)&tl=\(target)&dt=t&q=\(encoded)") {
                do {
                    let (data, _) = try await session.data(from: url)
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
                       let firstArray = json.first as? [Any] {
                        var combined = ""
                        for item in firstArray {
                            if let sub = item as? [Any], let piece = sub.first as? String {
                                combined += piece
                            }
                        }
                        if !combined.isEmpty {
                            translated = combined
                        }
                    }
                } catch {}
            }
        }
        
        translationCache.setObject(translated as NSString, forKey: cacheKey)
        return translated
    }

    /// Backward-compatible single-word translation method
    public func translateWord(_ word: String, toTargetLanguage target: String) async -> String {
        let (trans, _) = await translateWord(word, fromSource: "auto", toTarget: target, inContext: nil)
        return trans
    }
    
    // MARK: - Word Intelligence (Contextual Meaning & Pronunciation)
    
    public func fetchWordIntelligence(
        expression: String,
        sentence: String? = nil,
        baseLanguage: String,
        targetLanguage: String,
        cefrLevel: String
    ) async -> WordIntelligenceBackendResponse {
        let clean = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return WordIntelligenceBackendResponse(
                originalExpression: expression,
                translation: "",
                targetExpression: nil,
                pronunciationGuide: nil,
                contextualMeaning: nil,
                dictionaryDefinition: nil,
                partOfSpeech: nil,
                detectedCefr: cefrLevel,
                isSentence: false,
                targetLanguageCode: targetLanguage,
                baseLanguageCode: baseLanguage
            )
        }
        
        let req = WordIntelligenceRequest(
            expression: clean,
            sentence: sentence,
            baseLanguage: baseLanguage,
            targetLanguage: targetLanguage,
            cefrLevel: cefrLevel
        )
        
        do {
            let response: WordIntelligenceBackendResponse = try await APIClient.shared.request(
                .wordIntelligence(),
                body: req,
                timeout: AppConfig.extendedTimeout
            )
            return response
        } catch {
            let isBeginner = ["A1", "A2", "B1"].contains(cefrLevel.uppercased())
            let sourceLang = isBeginner ? baseLanguage : targetLanguage
            let destLang = isBeginner ? targetLanguage : baseLanguage
            let fallbackTrans = await translateText(clean, fromSource: sourceLang, toTarget: destLang)
            let targetExpr = isBeginner ? fallbackTrans : clean
            
            return WordIntelligenceBackendResponse(
                originalExpression: clean,
                translation: fallbackTrans,
                targetExpression: targetExpr,
                pronunciationGuide: nil,
                contextualMeaning: "In this sentence, '\(clean)' means '\(fallbackTrans)'.",
                dictionaryDefinition: nil,
                partOfSpeech: clean.contains(" ") ? "phrase" : "term",
                detectedCefr: cefrLevel,
                isSentence: clean.split(separator: " ").count > 3,
                targetLanguageCode: targetLanguage,
                baseLanguageCode: baseLanguage
            )
        }
    }
}

