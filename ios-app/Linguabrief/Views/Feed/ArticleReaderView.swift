import SwiftUI

/// Full distraction-free article reader view with web scraping, interactive word analysis, translation, and comments.
public struct ArticleReaderView: View {
    public let article: Article
    public let targetLanguageCode: String
    
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var detailVM: ArticleDetailViewModel
    @StateObject private var wordIntelVM = WordIntelligenceViewModel()
    @State private var showCommentsSheet: Bool = false
    
    public init(article: Article, targetLanguageCode: String = "es") {
        self.article = article
        self.targetLanguageCode = targetLanguageCode
        _detailVM = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }
    
    private var learningLanguageName: String {
        let code = Constants.languageCode(for: targetLanguageCode)
        return Constants.targetLanguages.first(where: { $0.code == code })?.name ?? "Learning Language"
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Article Title (Original or Translated)
                Text(detailVM.showTranslation ? (detailVM.translatedTitle ?? article.title) : (article.originalTitle ?? article.title))
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                
                // Translation Badge if active
                if detailVM.showTranslation {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.caption.bold())
                        Text("Translated into \(learningLanguageName)")
                            .font(.caption.bold())
                        Spacer()
                        Button("View Original (EN)") {
                            detailVM.showTranslation = false
                        }
                        .font(.caption.bold())
                        .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Constants.Colors.brandBurgundy.opacity(0.08))
                    .foregroundColor(Constants.Colors.brandBurgundy)
                    .cornerRadius(8)
                } else if article.originalTitle != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "character.book.closed")
                            .font(.caption.bold())
                        Text("Showing Original English")
                            .font(.caption.bold())
                        Spacer()
                        Button("Translate to \(learningLanguageName)") {
                            let langCode = Constants.languageCode(for: targetLanguageCode)
                            Task { await detailVM.translateArticle(to: langCode, force: true) }
                        }
                        .font(.caption.bold())
                        .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .foregroundColor(.secondary)
                    .cornerRadius(8)
                }
                
                if let err = detailVM.translationError {
                    Text("Translation note: \(err)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Metadata Row
                HStack {
                    Text("\(article.source ?? "News") · \(article.topic?.capitalized ?? "General")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        Task { await detailVM.toggleBookmark() }
                    }) {
                        Image(systemName: detailVM.isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.title3)
                            .foregroundColor(detailVM.isBookmarked ? Constants.Colors.brandBurgundy : .secondary)
                    }
                }
                
                // Thumbnail Banner
                if let img = article.imageUrl, let url = URL(string: img), !img.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .clipped()
                        default:
                            EmptyView()
                        }
                    }
                }
                
                // AI Summary Card
                if let summary = article.aiSummary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.goldAccent)
                            Text("AI SUMMARY")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                        
                        Text(summary)
                            .font(.system(size: 15, design: .serif))
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Constants.Colors.cardBackground)
                    .cornerRadius(12)
                }
                
                Divider()
                
                // Body Content & Interactive Word Selection
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("TAP ANY WORD FOR INTELLIGENCE & DEFINITION:")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    if detailVM.showTranslation, let translated = detailVM.translatedContent {
                        // Render translated text
                        InteractiveTextView(text: translated) { word, sentence in
                            Task {
                                await wordIntelVM.analyzeWord(word, inSentence: sentence, targetLanguageCode: targetLanguageCode)
                            }
                        }
                        
                        // If Japanese romaji is available, render romaji pronunciation section
                        if let romaji = detailVM.romajiContent {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Image(systemName: "textformat")
                                        .font(.caption.bold())
                                    Text("ROMAJI TRANSLITERATION")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(Constants.Colors.goldAccent)
                                
                                Text(romaji)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    } else if detailVM.isExtracting || detailVM.isTranslating {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(detailVM.isExtracting ? "Retrieving full article..." : "Translating into \(learningLanguageName)...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    } else if let extracted = detailVM.extractedArticle {
                        // Render full extracted text
                        InteractiveTextView(text: extracted.content) { word, sentence in
                            Task {
                                await wordIntelVM.analyzeWord(word, inSentence: sentence, targetLanguageCode: targetLanguageCode)
                            }
                        }
                        
                        // Also render discrete tap chips for convenience
                        Divider().padding(.vertical, 10)
                        Text("Word Tokens:")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        WordButtonsView(sentence: extracted.content.prefix(1000).description) { word, sentence in
                            Task {
                                await wordIntelVM.analyzeWord(word, inSentence: sentence, targetLanguageCode: targetLanguageCode)
                            }
                        }
                    } else {
                        // Render available snippet content
                        let bodyText = (article.content?.isEmpty == false ? article.content : article.description) ?? article.title
                        
                        InteractiveTextView(text: bodyText) { word, sentence in
                            Task {
                                await wordIntelVM.analyzeWord(word, inSentence: sentence, targetLanguageCode: targetLanguageCode)
                            }
                        }
                        
                        Divider().padding(.vertical, 10)
                        Text("Word Tokens:")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        WordButtonsView(sentence: bodyText) { word, sentence in
                            Task {
                                await wordIntelVM.analyzeWord(word, inSentence: sentence, targetLanguageCode: targetLanguageCode)
                            }
                        }
                    }
                }
                
                // Link to Open Original Source in Safari
                if let url = URL(string: article.url) {
                    Link(destination: url) {
                        Label("Open Original Web Source", systemImage: "arrow.up.right.square")
                            .font(.subheadline.bold())
                            .foregroundColor(Constants.Colors.brandBurgundy)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button(action: {
                        let targetCode = Constants.languageCode(for: targetLanguageCode)
                        Task { await detailVM.translateArticle(to: targetCode) }
                    }) {
                        HStack(spacing: 4) {
                            if detailVM.isTranslating {
                                ProgressView().tint(Constants.Colors.brandBurgundy)
                            } else {
                                Image(systemName: detailVM.showTranslation ? "doc.plaintext" : "translate")
                                Text(detailVM.showTranslation ? "Original" : "Translate")
                                    .font(.caption.bold())
                            }
                        }
                        .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                    .disabled(detailVM.isTranslating)
                    
                    Button(action: {
                        showCommentsSheet = true
                    }) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.body)
                            .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                }
            }
        }
        .sheet(isPresented: $wordIntelVM.showSheet) {
            WordIntelligenceSheet(viewModel: wordIntelVM, targetLanguageCode: targetLanguageCode)
        }
        .sheet(isPresented: $showCommentsSheet) {
            CommentsSheetView(detailVM: detailVM)
        }
        .task {
            await detailVM.checkBookmarkStatus()
            let langCode = Constants.languageCode(for: targetLanguageCode)
            await detailVM.loadFullText(andTranslateTo: langCode)
        }
    }
}
