import SwiftUI

/// Interactive 3D flip flashcard viewer replicating StudyTools.jsx.
public struct FlashcardViewerSheet: View {
    public let deck: FlashcardDeck
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    
    public init(deck: FlashcardDeck) {
        self.deck = deck
    }
    
    private var currentCard: SavedWord? {
        guard !deck.deck.isEmpty, currentIndex < deck.deck.count else { return nil }
        return deck.deck[currentIndex]
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let card = currentCard {
                    
                    // Card Progress Indicator
                    Text("\(currentIndex + 1) of \(deck.deck.count)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    // 3D Flip Card Container
                    ZStack {
                        // Card Front (Word + Phonetic)
                        VStack(spacing: 16) {
                            Text("WORD")
                                .font(.caption2.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                            
                            Text(card.word)
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .multilineTextAlignment(.center)
                            
                            if let phonetic = card.phonetic, !phonetic.isEmpty {
                                Text(phonetic)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                SpeechSynthesisService.shared.speak(card.word)
                            }) {
                                Label("Listen", systemImage: "speaker.wave.2.fill")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Constants.Colors.brandBurgundy)
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                            Text("Tap to reveal meaning ↻")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .background(Color(.systemBackground))
                        .cornerRadius(18)
                        .cardStyle()
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                        
                        // Card Back (Translation + Definition)
                        VStack(spacing: 16) {
                            Text("TRANSLATION")
                                .font(.caption2.bold())
                                .foregroundColor(Constants.Colors.brandBurgundy)
                            
                            Text(card.translation ?? "N/A")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Constants.Colors.brandBurgundy)
                                .multilineTextAlignment(.center)
                            
                            if let def = card.definition, !def.isEmpty {
                                Text(def)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(4)
                                    .multilineTextAlignment(.center)
                            }
                            
                            if let sentence = card.contextSentence, !sentence.isEmpty {
                                Text("\"\(sentence)\"")
                                    .font(.caption.italic())
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                            
                            Text("Tap to flip back ↻")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(18)
                        .cardStyle()
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isFlipped.toggle()
                        }
                    }
                    .padding(.horizontal)
                    
                    // Previous / Next Navigation Controls
                    HStack(spacing: 40) {
                        Button(action: {
                            if currentIndex > 0 {
                                isFlipped = false
                                currentIndex -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(currentIndex > 0 ? Constants.Colors.brandBurgundy : .secondary.opacity(0.3))
                        }
                        .disabled(currentIndex == 0)
                        
                        Button(action: {
                            if currentIndex < deck.deck.count - 1 {
                                isFlipped = false
                                currentIndex += 1
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(currentIndex < deck.deck.count - 1 ? Constants.Colors.brandBurgundy : .secondary.opacity(0.3))
                        }
                        .disabled(currentIndex >= deck.deck.count - 1)
                    }
                    .padding(.top, 16)
                    
                } else {
                    Text("No cards in this deck.")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle(deck.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
