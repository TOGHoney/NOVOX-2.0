import Foundation
import SwiftUI

/// View model for Vocabulary management, Custom Decks, Flashcard study, and Distractor Quiz generation.
@MainActor
public final class VocabularyViewModel: ObservableObject {
    
    @Published public var savedWords: [SavedWord] = []
    @Published public var customDecks: [FlashcardDeck] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // Study tools state
    @Published public var activeQuizQuestions: [QuizQuestion] = []
    @Published public var isQuizActive: Bool = false
    @Published public var activeDeckForStudy: FlashcardDeck?
    @Published public var isFlashcardsActive: Bool = false
    
    public init() {
        Task {
            await fetchSavedWords()
            await fetchCustomDecks()
        }
    }
    
    // MARK: - Saved Words Operations
    
    public func fetchSavedWords() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Backend returns { success: true, data: [...] } or array directly
            if let response: SavedWordDataResponse = try? await APIClient.shared.request(.savedWords()),
               let list = response.data {
                self.savedWords = list
            } else if let array: [SavedWord] = try? await APIClient.shared.request(.savedWords()) {
                self.savedWords = array
            }
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    public func deleteWord(id: String) async {
        do {
            try await APIClient.shared.requestVoid(.deleteWord(id: id))
            self.savedWords.removeAll(where: { $0.id == id })
        } catch {}
    }
    
    // MARK: - Custom Decks Operations
    
    public func fetchCustomDecks() async {
        do {
            let decks: [FlashcardDeck] = try await APIClient.shared.request(.flashcardDecks())
            self.customDecks = decks
        } catch {}
    }
    
    public func createCustomDeck(title: String, startDate: Date? = nil, endDate: Date? = nil) async -> Bool {
        var filtered = savedWords
        
        if let start = startDate, let end = endDate {
            let formatter = ISO8601DateFormatter()
            filtered = savedWords.filter { word in
                guard let createdStr = word.createdAt, let date = formatter.date(from: createdStr) else { return true }
                return date >= start && date <= end
            }
        }
        
        let deckTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Deck (\(filtered.count) words)"
            : title
        
        let payload = FlashcardDeckCreateRequest(title: deckTitle, deck: filtered)
        
        do {
            let created: FlashcardDeck = try await APIClient.shared.request(.createFlashcardDeck(), body: payload)
            self.customDecks.insert(created, at: 0)
            return true
        } catch {
            return false
        }
    }
    
    public func deleteDeck(id: String) async {
        do {
            try await APIClient.shared.requestVoid(.deleteFlashcardDeck(id: id))
            self.customDecks.removeAll(where: { $0.id == id })
        } catch {}
    }
    
    // MARK: - Quiz Generation with Smart Distractors
    
    /// Replicates `generateQuizQuestions` from web `src/utils/quizUtils.js`
    public func generateQuiz(from words: [SavedWord]? = nil) {
        let pool = (words != nil && !words!.isEmpty) ? words! : savedWords
        guard !pool.isEmpty else { return }
        
        var questions: [QuizQuestion] = []
        
        for item in pool {
            let correctAnswer = (item.translation?.isEmpty == false ? item.translation : item.definition) ?? "N/A"
            
            // Collect distractors from other saved words
            let potentialDistractors = Set(
                pool.filter { $0.word != item.word }
                    .compactMap { ($0.translation?.isEmpty == false ? $0.translation : $0.definition) }
                    .filter { !$0.isEmpty && $0 != correctAnswer }
            )
            
            let selectedDistractors = Array(potentialDistractors.shuffled().prefix(3))
            var allOptions = selectedDistractors
            allOptions.append(correctAnswer)
            allOptions.shuffle()
            
            let q = QuizQuestion(
                word: item.word,
                correctAnswer: correctAnswer,
                contextSentence: item.contextSentence ?? item.definition ?? "",
                options: allOptions
            )
            questions.append(q)
        }
        
        self.activeQuizQuestions = questions.shuffled()
        self.isQuizActive = true
    }
    
    public func startFlashcardDeck(_ deck: FlashcardDeck) {
        self.activeDeckForStudy = deck
        self.isFlashcardsActive = true
    }
    
    public func startAllWordsFlashcards() {
        let deck = FlashcardDeck(title: "All Saved Words", deck: savedWords, wordCount: savedWords.count)
        self.activeDeckForStudy = deck
        self.isFlashcardsActive = true
    }
}
