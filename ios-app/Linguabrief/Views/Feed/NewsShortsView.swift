import SwiftUI

/// Dedicated full-screen immersive News Shorts experience.
/// Users swipe vertically to move through articles one by one.
/// Displays headlines and concise summaries in the user's adaptive reading language,
/// and allows tapping words or selecting sentences to translate into the learning language.
public struct NewsShortsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = NewsShortsViewModel()
    
    public init() {}
    
    public var body: some View {
        GeometryReader { outerGeo in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                
                // Content States
                if viewModel.isLoading && viewModel.articles.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.3)
                        Text("Curating News Shorts in \(authVM.readingLanguage)...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage, viewModel.articles.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.orange)
                        Text("Unable to load News Shorts")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Retry") {
                            Task { await viewModel.fetchShorts() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Constants.Colors.brandBurgundy)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.articles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "play.rectangle.on.rectangle")
                            .font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.6))
                        Text("No News Shorts Available")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Check back soon for fresh news briefs.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Vertical Snapping Shorts Feed
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.articles.enumerated()), id: \.element.id) { index, article in
                                NewsShortCardView(
                                    article: article,
                                    readingLanguageCode: viewModel.readingLanguageCode,
                                    destinationLanguageCode: viewModel.destinationLanguageCode,
                                    onWordTapped: { word, sentence in
                                        Task {
                                            await viewModel.translateWord(word, inSentence: sentence)
                                        }
                                    },
                                    onSentenceSelected: { selectedSentence in
                                        Task {
                                            await viewModel.translateSentence(selectedSentence)
                                        }
                                    },
                                    onOpenFullArticle: {
                                        viewModel.activeReaderArticle = article
                                    }
                                )
                                .frame(width: outerGeo.size.width, height: outerGeo.size.height)
                                .id(article.id)
                                .onAppear {
                                    viewModel.onArticleAppear(index: index)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $viewModel.currentArticleId)
                    .ignoresSafeArea(.all, edges: .top)
                }
                
                // Top Overlay Header Bar
                HStack(alignment: .center) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Adaptive Mode & Language Direction Pill
                    HStack(spacing: 6) {
                        Image(systemName: "play.rectangle.on.rectangle.fill")
                            .font(.caption2.bold())
                            .foregroundColor(Constants.Colors.brandBurgundy)
                        
                        Text(authVM.adaptiveModeTitle)
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                        
                        Text("·")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("\(authVM.readingLanguage) ➔ \(authVM.translationDestinationLanguage)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.65))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                    
                    Spacer()
                    
                    CEFRBadge(authVM.cefrLevel)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .task {
            await viewModel.configure(
                readingLanguageCode: authVM.readingLanguageCode,
                destinationLanguageCode: authVM.translationDestinationLanguageCode,
                baseLanguageCode: authVM.nativeLanguage,
                targetLanguageCode: authVM.targetLanguage,
                cefrLevel: authVM.cefrLevel
            )
        }
        .sheet(isPresented: $viewModel.showTranslationSheet) {
            ShortsTranslationSheet(viewModel: viewModel, authVM: authVM)
        }
        .sheet(item: $viewModel.activeReaderArticle) { article in
            NavigationStack {
                ArticleReaderView(
                    article: article,
                    targetLanguageCode: authVM.translationDestinationLanguageCode,
                    readingLanguageCode: authVM.readingLanguageCode,
                    destinationLanguageCode: authVM.translationDestinationLanguageCode
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") {
                            viewModel.activeReaderArticle = nil
                        }
                    }
                }
            }
        }
    }
}

/// Compact bottom sheet displaying the interactive word or sentence translation result,
/// pronunciation, contextual meaning in base language, and save-to-vocabulary state.
struct ShortsTranslationSheet: View {
    @ObservedObject var viewModel: NewsShortsViewModel
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isTranslating {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Analyzing linguistic context...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Type Badge & Language Direction
                    let isModeA = authVM.isBeginnerOrIntermediate
                    let destLabel = isModeA
                        ? "\(authVM.targetLanguage.capitalized) (TARGET)"
                        : "\(authVM.nativeLanguage.capitalized) (BASE)"
                    
                    HStack {
                        Text(viewModel.isSentenceTranslation ? "SENTENCE TRANSLATION" : "WORD INTELLIGENCE")
                            .font(.caption2.bold())
                            .foregroundColor(Constants.Colors.brandBurgundy)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Constants.Colors.brandBurgundy.opacity(0.12))
                            .cornerRadius(6)
                        
                        Spacer()
                        
                        Text("\(authVM.readingLanguage) ➔ \(authVM.translationDestinationLanguage)")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    // 1. Original Expression
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ORIGINAL")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.selectedText)
                            .font(.system(size: viewModel.isSentenceTranslation ? 17 : 22, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                    }
                    
                    Divider()
                    
                    // 2. Translation Result
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRANSLATION (\(destLabel.uppercased()))")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.translatedText)
                            .font(.system(size: viewModel.isSentenceTranslation ? 18 : 24, weight: .bold))
                            .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                    
                    // 3. Target Pronunciation Guide & Listen Button
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("PRONUNCIATION (\(authVM.targetLanguage.uppercased()))")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        HStack {
                            if let guide = viewModel.pronunciationGuide, !guide.isEmpty {
                                Text(guide)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(Constants.Colors.goldAccent)
                            } else {
                                Text(viewModel.targetExpression.isEmpty ? viewModel.translatedText : viewModel.targetExpression)
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: { viewModel.playPronunciation() }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "speaker.wave.2.fill")
                                    Text("Listen")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Constants.Colors.brandBurgundy)
                                .cornerRadius(6)
                            }
                        }
                    }
                    .padding(10)
                    .background(Constants.Colors.cardBackground)
                    .cornerRadius(8)
                    
                    // 4. Contextual Meaning in Base Language
                    if let ctx = viewModel.contextualMeaning, !ctx.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CONTEXTUAL MEANING (\(authVM.nativeLanguage.uppercased()))")
                                .font(.caption2.bold())
                                .foregroundColor(.purple)
                            
                            Text(ctx)
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(.primary)
                                .lineSpacing(2)
                        }
                        .padding(10)
                        .background(Color.purple.opacity(0.06))
                        .cornerRadius(8)
                    }
                    
                    if let err = viewModel.translationError {
                        Text(err)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    // Bottom Actions: Save to Vocabulary status
                    HStack {
                        if !viewModel.isSentenceTranslation {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Saved to Vocabulary")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Button("Done") {
                            viewModel.showTranslationSheet = false
                        }
                        .font(.body.bold())
                        .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                }
            }
            .padding(20)
            .navigationTitle("Word Intelligence")
            .navigationBarTitleDisplayMode(.inline)

        }
        .presentationDetents([.fraction(0.38), .medium])
        .presentationDragIndicator(.visible)
    }
}
