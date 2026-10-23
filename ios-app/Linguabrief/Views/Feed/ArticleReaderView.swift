import SwiftUI

/// Full distraction-free article reader view with web scraping, interactive word analysis, translation, and comments.
public struct ArticleReaderView: View {
    public let article: Article
    public let targetLanguageCode: String
    public let readingLanguageCode: String?
    public let destinationLanguageCode: String?
    
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var detailVM: ArticleDetailViewModel
    @StateObject private var wordIntelVM = WordIntelligenceViewModel()
    @State private var showCommentsSheet: Bool = false
    
    public init(
        article: Article,
        targetLanguageCode: String = "es",
        readingLanguageCode: String? = nil,
        destinationLanguageCode: String? = nil
    ) {
        self.article = article
        self.targetLanguageCode = targetLanguageCode
        self.readingLanguageCode = readingLanguageCode
        self.destinationLanguageCode = destinationLanguageCode
        _detailVM = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }
    
    private var effectiveReadingLangCode: String {
        readingLanguageCode ?? authVM.readingLanguageCode
    }
    
    private var effectiveDestLangCode: String {
        destinationLanguageCode ?? authVM.translationDestinationLanguageCode
    }
    
    private var destinationLanguageName: String {
        Constants.targetLanguages.first(where: { $0.code == effectiveDestLangCode })?.name
            ?? Constants.nativeLanguages.first(where: { $0.code == effectiveDestLangCode })?.name
            ?? "Learning Language"
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Adaptive Mode Indicator Banner
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption.bold())
                        .foregroundColor(Constants.Colors.brandBurgundy)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authVM.adaptiveModeTitle)
                            .font(.caption2.bold())
                            .foregroundColor(Constants.Colors.brandBurgundy)
                        Text(authVM.adaptiveModeDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    CEFRBadge(authVM.cefrLevel)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Constants.Colors.brandBurgundy.opacity(0.08))
                .cornerRadius(10)
                
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
                        Text("Translated into \(destinationLanguageName)")
                            .font(.caption.bold())
                        Spacer()
                        Button("View Original") {
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
                            Text("AI SUMMARY (\(authVM.readingLanguage.uppercased()))")
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
                        Text("TAP ANY WORD OR SELECT A SENTENCE TO TRANSLATE:")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    if detailVM.showTranslation, let translated = detailVM.translatedContent {
                        InteractiveTextView(
                            text: translated,
                            languageCode: effectiveDestLangCode,
                            onWordTapped: { word, sentence in
                                Task {
                                    await wordIntelVM.analyzeWord(
                                        word,
                                        inSentence: sentence,
                                        baseLanguageCode: authVM.nativeLanguage,
                                        targetLanguageCode: authVM.targetLanguage,
                                        cefrLevel: authVM.cefrLevel
                                    )
                                }
                            },
                            onTextSelected: { selectedSentence in
                                Task {
                                    await wordIntelVM.analyzeSentence(
                                        selectedSentence,
                                        baseLanguageCode: authVM.nativeLanguage,
                                        targetLanguageCode: authVM.targetLanguage,
                                        cefrLevel: authVM.cefrLevel
                                    )
                                }
                            }
                        )
                    } else if detailVM.isExtracting || detailVM.isTranslating {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(detailVM.isExtracting ? "Retrieving full article..." : "Translating into \(destinationLanguageName)...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    } else if let extracted = detailVM.extractedArticle {
                        InteractiveTextView(
                            text: extracted.content,
                            languageCode: effectiveReadingLangCode,
                            onWordTapped: { word, sentence in
                                Task {
                                    await wordIntelVM.analyzeWord(
                                        word,
                                        inSentence: sentence,
                                        baseLanguageCode: authVM.nativeLanguage,
                                        targetLanguageCode: authVM.targetLanguage,
                                        cefrLevel: authVM.cefrLevel
                                    )
                                }
                            },
                            onTextSelected: { selectedSentence in
                                Task {
                                    await wordIntelVM.analyzeSentence(
                                        selectedSentence,
                                        baseLanguageCode: authVM.nativeLanguage,
                                        targetLanguageCode: authVM.targetLanguage,
                                        cefrLevel: authVM.cefrLevel
                                    )
                                }
                            }
                        )
                    } else {
                        let bodyText = (article.content?.isEmpty == false ? article.content : article.description) ?? article.title
                        InteractiveTextView(
                            text: bodyText,
                            languageCode: effectiveReadingLangCode,
                            onWordTapped: { word, sentence in
                                Task {
                                    await wordIntelVM.analyzeWord(
                                        word,
                                        inSentence: sentence,
                                        baseLanguageCode: authVM.nativeLanguage,
                                        targetLanguageCode: authVM.targetLanguage,
                                        cefrLevel: authVM.cefrLevel
                                    )
                                }
                            },
                            onTextSelected: { selectedSentence in
                                Task {
                                    await wordIntelVM.analyzeSentence(
                                        selectedSentence,
                                        baseLanguageCode: authVM.nativeLanguage,
                                        targetLanguageCode: authVM.targetLanguage,
                                        cefrLevel: authVM.cefrLevel
                                    )
                                }
                            }
                        )
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
                        Task { await detailVM.translateArticle(to: effectiveDestLangCode) }
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
            WordIntelligenceSheet(
                viewModel: wordIntelVM,
                targetLanguageCode: authVM.targetLanguage,
                baseLanguageCode: authVM.nativeLanguage
            )
        }

        .sheet(isPresented: $showCommentsSheet) {
            CommentsSheetView(detailVM: detailVM)
        }
        .task {
            await detailVM.checkBookmarkStatus()
            if effectiveReadingLangCode != "en" {
                await detailVM.loadFullText(andTranslateTo: effectiveReadingLangCode)
            } else {
                await detailVM.loadFullText()
            }
        }
    }
}

