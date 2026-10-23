import SwiftUI

/// Immersive full-screen card for a single news short article,
/// displaying headline, concise summary in the user's adaptive reading language,
/// source, image, and interactive word tap & sentence selection.
public struct NewsShortCardView: View {
    public let article: Article
    public let readingLanguageCode: String
    public let destinationLanguageCode: String
    public let onWordTapped: (String, String) -> Void
    public let onSentenceSelected: (String) -> Void
    public let onOpenFullArticle: () -> Void
    
    public init(
        article: Article,
        readingLanguageCode: String,
        destinationLanguageCode: String,
        onWordTapped: @escaping (String, String) -> Void,
        onSentenceSelected: @escaping (String) -> Void,
        onOpenFullArticle: @escaping () -> Void
    ) {
        self.article = article
        self.readingLanguageCode = readingLanguageCode
        self.destinationLanguageCode = destinationLanguageCode
        self.onWordTapped = onWordTapped
        self.onSentenceSelected = onSentenceSelected
        self.onOpenFullArticle = onOpenFullArticle
    }
    
    private var conciseSummaryText: String {
        if let ai = article.aiSummary, !ai.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ai
        }
        if let desc = article.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return desc
        }
        return article.title
    }
    
    private var destinationLanguageName: String {
        Constants.targetLanguages.first(where: { $0.code == destinationLanguageCode })?.name
            ?? Constants.nativeLanguages.first(where: { $0.code == destinationLanguageCode })?.name
            ?? "Target Language"
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                
                // Background Layer (Article Image or Deep Ambient Gradient)
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    if let img = article.imageUrl, let url = URL(string: img), !img.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            default:
                                EmptyView()
                            }
                        }
                    }
                    
                    // Dark Cinematic Gradient Overlay for high legibility
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.65),
                            Color.black.opacity(0.35),
                            Color.black.opacity(0.85),
                            Color.black.opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
                
                // Card Content Overlay
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Top Metadata Row
                    HStack(spacing: 8) {
                        if let src = article.source, !src.isEmpty {
                            Text(src.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Constants.Colors.brandBurgundy)
                                .cornerRadius(6)
                        }
                        
                        if let topic = article.topic, !topic.isEmpty {
                            Text(topic.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.18))
                                .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        if let dateStr = article.publishedAt {
                            Text(formatDate(dateStr))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.top, 60) // Clears top bar
                    
                    Spacer()
                    
                    // Article Headline
                    VStack(alignment: .leading, spacing: 8) {
                        InteractiveTextView(
                            text: article.title,
                            languageCode: readingLanguageCode,
                            onWordTapped: onWordTapped,
                            onTextSelected: onSentenceSelected
                        )
                        .colorScheme(.dark)
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(12)
                    
                    // Concise News Summary
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.goldAccent)
                            Text("NEWS SUMMARY")
                                .font(.caption2.bold())
                                .foregroundColor(Constants.Colors.goldAccent)
                        }
                        
                        InteractiveTextView(
                            text: conciseSummaryText,
                            languageCode: readingLanguageCode,
                            onWordTapped: onWordTapped,
                            onTextSelected: onSentenceSelected
                        )
                        .colorScheme(.dark)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    
                    // Interactive Guidance Hint & Full Article Button
                    VStack(spacing: 10) {
                        HStack {
                            Text("💡 Tap any word or select a sentence to translate into \(destinationLanguageName)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.75))
                            Spacer()
                        }
                        
                        Button(action: onOpenFullArticle) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("Read Full Article")
                                    .font(.subheadline.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Constants.Colors.brandBurgundy)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
            }
        }
    }
    
    private func formatDate(_ raw: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: raw) {
            let relative = RelativeDateTimeFormatter()
            relative.unitsStyle = .short
            return relative.localizedString(for: date, relativeTo: Date())
        }
        return "Recent"
    }
}
