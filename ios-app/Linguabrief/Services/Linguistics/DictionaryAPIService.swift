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
    
    // MARK: - Word Translation
    
    /// Translates a word into the target language using backend `/api/translate` or web fallback
    public func translateWord(_ word: String, toTargetLanguage target: String) async -> String {
        // 1. Try backend LibreTranslate API first
        do {
            let requestPayload = TranslationRequest(texts: [word], target: target, source: "auto")
            let response: TranslationResponse = try await APIClient.shared.request(.translate(), body: requestPayload)
            if let first = response.translations.first, !first.isEmpty {
                return first
            }
        } catch {
            // Backend LibreTranslate is optional/local; fallback to web translator
        }
        
        // 2. Fallback to client-side Google GTX Web API (same fallback as React Articles.jsx)
        guard let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=\(target)&dt=t&q=\(encoded)") else {
            return word
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
               let firstArray = json.first as? [Any],
               let subArray = firstArray.first as? [Any],
               let translatedText = subArray.first as? String {
                return translatedText
            }
        } catch {}
        
        return word
    }
}
