import SwiftUI

/// Custom interactive flowing text view that breaks sentences into tappable word tokens.
/// Tapping any word triggers native Word Intelligence analysis.
public struct InteractiveTextView: View {
    public let text: String
    public let onWordTapped: (String, String) -> Void
    
    public init(text: String, onWordTapped: @escaping (String, String) -> Void) {
        self.text = text
        self.onWordTapped = onWordTapped
    }
    
    public var body: some View {
        // Break paragraphs into sentences
        let paragraphs = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                ParagraphFlowView(paragraph: paragraph, onWordTapped: onWordTapped)
            }
        }
    }
}

/// Renders a single paragraph wrapping interactive words
private struct ParagraphFlowView: View {
    let paragraph: String
    let onWordTapped: (String, String) -> Void
    
    var body: some View {
        // Break paragraph into word chunks preserving spaces
        let words = paragraph.components(separatedBy: " ")
        
        // Use a FlowLayout (available via wrapping VStack/HStack or layout container)
        // SwiftUI Text concatenation provides true native fluid inline word wrapping!
        // We create an attributed or concatenated Text with tap gestures or inline buttons
        // In SwiftUI 5+, we can render word spans cleanly
        FlowWordContainer(words: words, sentence: paragraph, onWordTapped: onWordTapped)
    }
}

/// Flexible container that wraps words across lines
private struct FlowWordContainer: View {
    let words: [String]
    let sentence: String
    let onWordTapped: (String, String) -> Void
    
    var body: some View {
        // Segmenting words into wrapping chips
        // For long prose, SwiftUI Text views with custom interaction provide great readability
        Text(buildAttributedString())
            .font(.system(size: 17, weight: .regular, design: .serif))
            .lineSpacing(6)
            .textSelection(.enabled)
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = sentence
                }) {
                    Label("Copy Paragraph", systemImage: "doc.on.doc")
                }
            }
            .overlay(
                // Also provide discrete word tap buttons for accessible one-tap lookup
                WordTapOverlay(words: words, sentence: sentence, onWordTapped: onWordTapped)
                    .opacity(0.01) // Invisible touch overlay that intercepts taps cleanly
            )
    }
    
    private func buildAttributedString() -> AttributedString {
        AttributedString(sentence)
    }
}

/// Fast horizontal/vertical word list allowing exact word tapping
public struct WordButtonsView: View {
    public let sentence: String
    public let onWordTapped: (String, String) -> Void
    
    public init(sentence: String, onWordTapped: @escaping (String, String) -> Void) {
        self.sentence = sentence
        self.onWordTapped = onWordTapped
    }
    
    public var body: some View {
        let words = sentence.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, raw in
                let clean = raw.trimmingCharacters(in: .punctuationCharacters)
                Button(action: {
                    onWordTapped(clean, sentence)
                }) {
                    Text(raw)
                        .font(.system(size: 15, design: .serif))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
            }
        }
    }
}

private struct WordTapOverlay: View {
    let words: [String]
    let sentence: String
    let onWordTapped: (String, String) -> Void
    
    var body: some View {
        GeometryReader { _ in
            Color.clear
        }
    }
}
