import SwiftUI

public enum Constants {
    
    // MARK: - App Branding & Theme Colors
    public enum Colors {
        public static let brandBurgundy = Color(red: 0.50, green: 0.00, blue: 0.13) // #800020
        public static let brandDeepWine = Color(red: 0.35, green: 0.09, blue: 0.09) // #5A1818
        public static let backgroundDark = Color(red: 0.06, green: 0.09, blue: 0.16) // #0F172A
        public static let cardBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
        public static let borderSubtle = Color(red: 0.88, green: 0.90, blue: 0.94)
        public static let goldAccent = Color(red: 0.85, green: 0.47, blue: 0.02)
    }
    
    // MARK: - Supported Target Languages
    public struct LanguageOption: Identifiable, Hashable, Sendable {
        public var id: String { code }
        public let name: String
        public let flag: String
        public let code: String
        public let bcp47: String
    }
    
    public static let targetLanguages: [LanguageOption] = [
        LanguageOption(name: "Spanish", flag: "🇪🇸", code: "es", bcp47: "es-ES"),
        LanguageOption(name: "French", flag: "🇫🇷", code: "fr", bcp47: "fr-FR"),
        LanguageOption(name: "German", flag: "🇩🇪", code: "de", bcp47: "de-DE"),
        LanguageOption(name: "Japanese", flag: "🇯🇵", code: "ja", bcp47: "ja-JP"),
        LanguageOption(name: "Thai", flag: "🇹🇭", code: "th", bcp47: "th-TH")
    ]
    
    public static let nativeLanguages: [LanguageOption] = [
        LanguageOption(name: "English", flag: "🇺🇸", code: "en", bcp47: "en-US"),
        LanguageOption(name: "Spanish", flag: "🇪🇸", code: "es", bcp47: "es-ES"),
        LanguageOption(name: "French", flag: "🇫🇷", code: "fr", bcp47: "fr-FR"),
        LanguageOption(name: "German", flag: "🇩🇪", code: "de", bcp47: "de-DE"),
        LanguageOption(name: "Japanese", flag: "🇯🇵", code: "ja", bcp47: "ja-JP"),
        LanguageOption(name: "Hindi", flag: "🇮🇳", code: "hi", bcp47: "hi-IN")
    ]
    
    public static func languageCode(for nameOrCode: String) -> String {
        let cleaned = nameOrCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let match = targetLanguages.first(where: { $0.code.lowercased() == cleaned || $0.name.lowercased() == cleaned }) {
            return match.code
        }
        if let match = nativeLanguages.first(where: { $0.code.lowercased() == cleaned || $0.name.lowercased() == cleaned }) {
            return match.code
        }
        return cleaned.isEmpty ? "es" : cleaned
    }
    
    // MARK: - CEFR Proficiency Levels
    public struct CEFRLevel: Identifiable, Hashable, Sendable {
        public var id: String { code }
        public let code: String
        public let title: String
        public let description: String
        public let badgeColor: Color
    }
    
    public static let cefrLevels: [CEFRLevel] = [
        CEFRLevel(code: "A1", title: "Beginner", description: "Familiar everyday expressions & very basic phrases.", badgeColor: .green),
        CEFRLevel(code: "A2", title: "Elementary", description: "Communicate in routine, simple daily tasks.", badgeColor: .mint),
        CEFRLevel(code: "B1", title: "Intermediate", description: "Deal with travel situations & conversational topics.", badgeColor: .blue),
        CEFRLevel(code: "B2", title: "Upper Intermediate", description: "Interact fluently with native speakers on complex news.", badgeColor: .indigo),
        CEFRLevel(code: "C1", title: "Advanced", description: "Express ideas fluently and spontaneously with nuance.", badgeColor: .purple),
        CEFRLevel(code: "C2", title: "Proficient", description: "Summarize and debate advanced cultural & political topics.", badgeColor: .orange)
    ]
    
    // MARK: - Topics (11 Feeds from articleFetcher.js)
    public struct TopicOption: Identifiable, Hashable, Sendable {
        public var id: String { value }
        public let label: String
        public let value: String
    }
    
    public static let topics: [TopicOption] = [
        TopicOption(label: "All", value: "all"),
        TopicOption(label: "Technology", value: "technology"),
        TopicOption(label: "Movies", value: "movies"),
        TopicOption(label: "USA", value: "usa"),
        TopicOption(label: "India", value: "india"),
        TopicOption(label: "Japan", value: "japan"),
        TopicOption(label: "China", value: "china"),
        TopicOption(label: "Russia", value: "russia"),
        TopicOption(label: "Sports", value: "sports"),
        TopicOption(label: "Education", value: "education"),
        TopicOption(label: "Politics", value: "politics"),
        TopicOption(label: "Foreign Relations", value: "foreign-relations")
    ]
}
