import SwiftUI

/// Bottom sheet displaying linguistic insights, dictionary definition, translation, and auto-save state.
public struct WordIntelligenceSheet: View {
    @ObservedObject public var viewModel: WordIntelligenceViewModel
    public let targetLanguageCode: String
    
    public init(viewModel: WordIntelligenceViewModel, targetLanguageCode: String) {
        self.viewModel = viewModel
        self.targetLanguageCode = targetLanguageCode
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                if viewModel.isAnalyzing {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Analyzing linguistic context...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let result = viewModel.selectedResult {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            
                            // Header: Word + CEFR Badge + Auto-Save Status
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.word)
                                        .font(.system(size: 28, weight: .bold, design: .serif))
                                        .foregroundColor(.primary)
                                    
                                    if !result.lemma.isEmpty && result.lemma.lowercased() != result.word.lowercased() {
                                        Text("Base lemma: \(result.lemma)")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    CEFRBadge(result.cefr)
                                    
                                    if viewModel.isSaved {
                                        Label("Saved", systemImage: "checkmark.circle.fill")
                                            .font(.caption2.bold())
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Color.green.opacity(0.12))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                            
                            // Phonetics & Native Audio Pronunciation Button
                            HStack(spacing: 12) {
                                if !result.phonetic.isEmpty {
                                    Text(result.phonetic)
                                        .font(.system(size: 15, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                
                                Button(action: {
                                    viewModel.playPronunciation()
                                }) {
                                    Label("Listen", systemImage: "speaker.wave.2.fill")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Constants.Colors.brandBurgundy)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Divider()
                            
                            // Contextual Translation Card
                            VStack(alignment: .leading, spacing: 6) {
                                Text("TRANSLATION")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                                
                                Text(result.translation.isEmpty ? result.word : result.translation)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Constants.Colors.brandBurgundy)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Constants.Colors.cardBackground)
                            .cornerRadius(12)
                            
                            // Part of Speech & Meaning
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("MEANING IN CONTEXT")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(result.partOfSpeech.uppercased())
                                        .font(.caption2.bold())
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                if result.definitions.isEmpty {
                                    Text("No definition available for this term.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(Array(result.definitions.enumerated()), id: \.offset) { idx, def in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(idx + 1).")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.secondary)
                                            Text(def)
                                                .font(.subheadline)
                                                .lineSpacing(4)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Constants.Colors.cardBackground)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                } else {
                    Text("Select a word in the article to view definitions.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Word Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.showSheet = false
                    }
                    .font(.body.bold())
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
