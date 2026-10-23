import SwiftUI

/// Vocabulary dictionary view presenting all saved words, flashcard study launcher, and quiz runner.
public struct SavedWordsListView: View {
    @StateObject private var vocabVM = VocabularyViewModel()
    @State private var searchWordText: String = ""
    @State private var showCreateDeckSheet: Bool = false
    @State private var newDeckTitle: String = ""
    
    public init() {}
    
    private var filteredWords: [SavedWord] {
        let q = searchWordText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return vocabVM.savedWords }
        return vocabVM.savedWords.filter {
            $0.word.lowercased().contains(q) ||
            ($0.translation ?? "").lowercased().contains(q) ||
            ($0.definition ?? "").lowercased().contains(q)
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Quick Action Bar: Flashcards + Quiz Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        vocabVM.startAllWordsFlashcards()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.stack.fill")
                            Text("Flashcards (\(vocabVM.savedWords.count))")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Constants.Colors.brandBurgundy)
                        .cornerRadius(8)
                    }
                    .disabled(vocabVM.savedWords.isEmpty)
                    
                    Button(action: {
                        vocabVM.generateQuiz()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile")
                            Text("Smart Quiz")
                        }
                        .font(.caption.bold())
                        .foregroundColor(Constants.Colors.brandBurgundy)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Constants.Colors.brandBurgundy.opacity(0.12))
                        .cornerRadius(8)
                    }
                    .disabled(vocabVM.savedWords.isEmpty)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search saved words or translations...", text: $searchWordText)
                        .font(.subheadline)
                    if !searchWordText.isEmpty {
                        Button(action: { searchWordText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                // Saved Words List
                if vocabVM.isLoading && vocabVM.savedWords.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Loading your vocabulary...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredWords.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "character.book.closed")
                            .font(.system(size: 45))
                            .foregroundColor(.secondary)
                        Text("No saved words yet")
                            .font(.headline)
                        Text("Tap any word while reading an article to analyze and save it automatically.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredWords) { item in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(item.word)
                                            .font(.headline)
                                        
                                        if let phonetic = item.phonetic, !phonetic.isEmpty {
                                            Text(phonetic)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        CEFRBadge(item.cefr ?? "B1")
                                    }
                                    
                                    if let translation = item.translation, !translation.isEmpty {
                                        Text(translation)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Constants.Colors.brandBurgundy)
                                    }
                                    
                                    if let def = item.definition, !def.isEmpty {
                                        Text(def)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                
                                Button(action: {
                                    SpeechSynthesisService.shared.speak(item.word)
                                }) {
                                    Image(systemName: "speaker.wave.2")
                                        .foregroundColor(Constants.Colors.brandBurgundy)
                                        .padding(8)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                let word = filteredWords[idx]
                                Task { await vocabVM.deleteWord(id: word.id) }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await vocabVM.fetchSavedWords()
                    }
                }
            }
            .navigationTitle("Vocabulary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showCreateDeckSheet = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(Constants.Colors.brandBurgundy)
                    }
                }
            }
            .sheet(isPresented: $vocabVM.isFlashcardsActive) {
                if let deck = vocabVM.activeDeckForStudy {
                    FlashcardViewerSheet(deck: deck)
                }
            }
            .sheet(isPresented: $vocabVM.isQuizActive) {
                QuizModalView(questions: vocabVM.activeQuizQuestions)
            }
            .alert("Create Custom Deck", isPresented: $showCreateDeckSheet) {
                TextField("Deck Title", text: $newDeckTitle)
                Button("Create", action: {
                    Task {
                        _ = await vocabVM.createCustomDeck(title: newDeckTitle)
                        newDeckTitle = ""
                    }
                })
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Create a review flashcard deck from your current vocabulary words.")
            }
        }
    }
}
