import SwiftUI

/// Main news feed screen displaying interleaved topic news, category filtering, search, and reader navigation.
public struct FeedView: View {
    @StateObject private var feedVM = FeedViewModel()
    @EnvironmentObject private var authVM: AuthViewModel
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Top Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search news, topic, or keyword", text: $feedVM.searchQuery)
                        .font(.subheadline)
                    
                    if !feedVM.searchQuery.isEmpty {
                        Button(action: { feedVM.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Topic Selector Chips (Horizontal Scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Constants.topics) { topic in
                            let isSelected = feedVM.selectedTopic == topic.value
                            Button(action: {
                                Task { await feedVM.selectTopic(topic.value) }
                            }) {
                                Text(topic.label)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(isSelected ? Constants.Colors.brandBurgundy : Color(.systemGray6))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                
                // Feed Content
                if feedVM.isLoading && feedVM.articles.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Curating your language news feed...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = feedVM.errorMessage, feedVM.articles.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Unable to load feed")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Retry") {
                            Task { await feedVM.fetchFeed() }
                        }
                        .burgundyButtonStyle()
                        .frame(width: 140)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if feedVM.filteredArticles.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "newspaper")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No articles found")
                            .font(.headline)
                        Text("Try selecting another category or refreshing.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(feedVM.filteredArticles) { article in
                                NavigationLink(destination: ArticleReaderView(article: article, targetLanguageCode: Constants.languageCode(for: authVM.targetLanguage))) {
                                    ArticleCardView(
                                        article: article,
                                        isSummaryLoading: feedVM.summaryLoadingMap[article.id] ?? false,
                                        onSummarizeTapped: {
                                            Task { await feedVM.generateSummary(for: article.id) }
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onAppear {
                                    Task { await feedVM.loadMoreIfNeeded(currentArticle: article) }
                                }
                            }
                            
                            if feedVM.isLoadingMore {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Loading more articles...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await feedVM.fetchFeed(targetLanguage: authVM.targetLanguage)
                    }
                }
            }
            .navigationTitle("Global News")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        CEFRBadge(authVM.cefrLevel)
                        
                        if let lang = Constants.targetLanguages.first(where: { $0.name == authVM.targetLanguage || $0.code == authVM.targetLanguage }) {
                            Text(lang.flag)
                                .font(.title3)
                        }
                    }
                }
            }
            .task {
                await feedVM.updateLanguageIfNeeded(authVM.targetLanguage)
            }
            .onChange(of: authVM.targetLanguage) { newLang in
                Task {
                    await feedVM.updateLanguageIfNeeded(newLang)
                }
            }
        }
    }
}
