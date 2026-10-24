import SwiftUI

/// Bottom sheet displaying linguistic insights, dictionary definition, translation, and auto-save state.
/// Respects the user's learning mode:
/// - Mode A (A1-B1): News in base language -> Prominent target-language translation & target pronunciation
/// - Mode B (B2-C2): News in target language -> Prominent base-language translation & target pronunciation
/// - Contextual explanation is ALWAYS displayed in the user's base language.
public struct WordIntelligenceSheet: View {
    @ObservedObject public var viewModel: WordIntelligenceViewModel
    @ObservedObject private var speechService = SpeechSynthesisService.shared
    public let targetLanguageCode: String
    public let baseLanguageCode: String
    
    public init(viewModel: WordIntelligenceViewModel, targetLanguageCode: String, baseLanguageCode: String = "en") {
        self.viewModel = viewModel
        self.targetLanguageCode = targetLanguageCode
        self.baseLanguageCode = baseLanguageCode
    }
    
    private var baseLangName: String {
        let code = viewModel.selectedResult?.baseLanguageCode ?? baseLanguageCode
        return Constants.nativeLanguages.first(where: { $0.code == code })?.name
            ?? Constants.targetLanguages.first(where: { $0.code == code })?.name
            ?? "Base Language"
    }
    
    private var targetLangName: String {
        let code = viewModel.selectedResult?.targetLanguageCode ?? targetLanguageCode
        return Constants.targetLanguages.first(where: { $0.code == code })?.name
            ?? Constants.nativeLanguages.first(where: { $0.code == code })?.name
            ?? "Target Language"
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
                            
                            // 1. ORIGINAL EXPRESSION
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.isSentence ? "ORIGINAL EXPRESSION" : "ORIGINAL WORD")
                                            .font(.caption2.bold())
                                            .foregroundColor(.secondary)
                                        
                                        Text(result.word)
                                            .font(.system(size: result.isSentence ? 19 : 28, weight: .bold, design: .serif))
                                            .foregroundColor(.primary)
                                            .lineSpacing(4)
                                        
                                        if !result.isSentence && !result.lemma.isEmpty && result.lemma.lowercased() != result.word.lowercased() {
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
                            }
                            
                            // Error & Retry Banner if translation had issues
                            if let error = viewModel.errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.footnote)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Button("Retry") {
                                        Task { await viewModel.retry() }
                                    }
                                    .font(.footnote.bold())
                                    .foregroundColor(Constants.Colors.brandBurgundy)
                                }
                                .padding(10)
                                .background(Color.orange.opacity(0.12))
                                .cornerRadius(8)
                            }
                            
                            // 2. TRANSLATION CARD (Adaptive Direction)
                            // Mode A (A1-B1): Prominent Target Language Translation
                            // Mode B (B2-C2): Prominent Base Language Translation
                            let isModeA = result.isBeginnerOrIntermediate
                            let translationCardHeader = isModeA
                                ? "TARGET TRANSLATION (\(targetLangName.uppercased()))"
                                : "BASE TRANSLATION (\(baseLangName.uppercased()))"
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(translationCardHeader)
                                        .font(.caption2.bold())
                                        .foregroundColor(Constants.Colors.brandBurgundy)
                                    Spacer()
                                    if isModeA {
                                        Text("\(baseLangName) ➔ \(targetLangName)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("\(targetLangName) ➔ \(baseLangName)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text(result.translation.isEmpty ? result.word : result.translation)
                                    .font(.system(size: result.isSentence ? 19 : 24, weight: .bold, design: result.isSentence ? .serif : .default))
                                    .foregroundColor(Constants.Colors.brandBurgundy)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Constants.Colors.brandBurgundy.opacity(0.06))
                            .cornerRadius(12)
                            
                            // 3. TARGET PRONUNCIATION & LISTEN CONTROL
                            // Always teaches how to pronounce the target-language expression
                            let targetExpr = result.targetExpression?.isEmpty == false
                                ? result.targetExpression!
                                : (isModeA ? result.translation : result.word)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("PRONUNCIATION (\(targetLangName.uppercased()))")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                HStack(alignment: .center, spacing: 14) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(targetExpr)
                                            .font(.system(size: result.isSentence ? 16 : 20, weight: .semibold, design: .serif))
                                            .foregroundColor(.primary)
                                        
                                        if let guide = result.pronunciationGuide, !guide.isEmpty {
                                            Text(guide)
                                                .font(.system(size: 15, weight: .medium, design: .monospaced))
                                                .foregroundColor(Constants.Colors.goldAccent)
                                        } else if !result.phonetic.isEmpty {
                                            Text(result.phonetic)
                                                .font(.system(size: 15, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if speechService.isSpeaking {
                                            speechService.stop()
                                        } else {
                                            viewModel.playPronunciation()
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                            Text(speechService.isSpeaking ? "Playing" : "Listen")
                                                .font(.caption.bold())
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(speechService.isSpeaking ? Constants.Colors.goldAccent : Constants.Colors.brandBurgundy)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Constants.Colors.cardBackground)
                            .cornerRadius(12)
                            
                            // 4. CONTEXTUAL MEANING (ALWAYS IN BASE LANGUAGE)
                            if let ctx = result.contextualMeaning, !ctx.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Label("CONTEXTUAL MEANING (\(baseLangName.uppercased()))", systemImage: "text.quote")
                                            .font(.caption2.bold())
                                            .foregroundColor(.purple)
                                        Spacer()
                                    }
                                    
                                    Text(ctx)
                                        .font(.system(size: 15, weight: .medium, design: .serif))
                                        .foregroundColor(.primary)
                                        .lineSpacing(4)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.purple.opacity(0.06))
                                .cornerRadius(12)
                            }
                            
                            // 5. DICTIONARY DEFINITION
                            if !result.isSentence {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("DICTIONARY DEFINITION (\(baseLangName.uppercased()))")
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
                                        Text("No verified dictionary entry available for this term; contextual meaning provided above.")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                            .italic()
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
                        }
                        .padding()
                    }
                } else {
                    Text("Select a word or sentence in the article to view translations.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle(viewModel.selectedResult?.isSentence == true ? "Sentence Translation" : "Word Intelligence")
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
        .presentationDetents([.fraction(0.48), .medium, .large])
        .presentationDragIndicator(.visible)
    }
}

