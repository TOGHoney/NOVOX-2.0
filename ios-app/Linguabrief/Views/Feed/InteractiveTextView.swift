import SwiftUI
import UIKit
import NaturalLanguage

/// Custom interactive flowing text view that breaks sentences into tappable word tokens.
/// Tapping any word triggers native Word Intelligence analysis.
public struct InteractiveTextView: View {
    public let text: String
    public let languageCode: String
    public let onWordTapped: (String, String) -> Void
    public let onTextSelected: ((String) -> Void)?
    
    public init(
        text: String,
        languageCode: String = "auto",
        onWordTapped: @escaping (String, String) -> Void,
        onTextSelected: ((String) -> Void)? = nil
    ) {
        self.text = text
        self.languageCode = languageCode
        self.onWordTapped = onWordTapped
        self.onTextSelected = onTextSelected
    }
    
    public init(text: String, onWordTapped: @escaping (String, String) -> Void) {
        self.init(text: text, languageCode: "auto", onWordTapped: onWordTapped, onTextSelected: nil)
    }
    
    public var body: some View {
        let paragraphs = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        VStack(alignment: .leading, spacing: 16) {
            if paragraphs.isEmpty {
                TappableParagraphView(
                    text: text,
                    languageCode: languageCode,
                    onWordTapped: onWordTapped,
                    onTextSelected: onTextSelected
                )
            } else {
                ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    TappableParagraphView(
                        text: paragraph,
                        languageCode: languageCode,
                        onWordTapped: onWordTapped,
                        onTextSelected: onTextSelected
                    )
                }
            }
        }
    }
}

/// Native paragraph view wrapping a non-scrolling, high-performance UITextView
/// with language-aware word tokenization and non-interfering scroll gestures.
struct TappableParagraphView: UIViewRepresentable {
    let text: String
    let languageCode: String
    let onWordTapped: (String, String) -> Void
    let onTextSelected: ((String) -> Void)?
    
    func makeUIView(context: Context) -> TappableTextView {
        let view = TappableTextView()
        view.configure(text: text, languageCode: languageCode, onWordTapped: onWordTapped, onTextSelected: onTextSelected)
        return view
    }
    
    func updateUIView(_ uiView: TappableTextView, context: Context) {
        uiView.configure(text: text, languageCode: languageCode, onWordTapped: onWordTapped, onTextSelected: onTextSelected)
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: TappableTextView, context: Context) -> CGSize? {
        let targetWidth = proposal.width ?? (UIScreen.main.bounds.width - 32)
        let calcSize = uiView.sizeThatFits(CGSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: targetWidth, height: ceil(calcSize.height))
    }
}

final class TappableTextView: UITextView, UIGestureRecognizerDelegate, UITextViewDelegate {
    var onWordTapped: ((String, String) -> Void)?
    var onTextSelected: ((String) -> Void)?
    var languageCode: String = "auto"
    private var rawParagraph: String = ""
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isEditable = false
        isSelectable = true
        isScrollEnabled = false
        delegate = self
        backgroundColor = .clear
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delaysTouchesEnded = false
        tap.delegate = self
        addGestureRecognizer(tap)
    }
    
    func configure(
        text: String,
        languageCode: String,
        onWordTapped: @escaping (String, String) -> Void,
        onTextSelected: ((String) -> Void)? = nil
    ) {
        self.onWordTapped = onWordTapped
        self.onTextSelected = onTextSelected
        self.languageCode = languageCode
        
        if self.rawParagraph != text {
            self.rawParagraph = text
            applyAttributedText()
            invalidateIntrinsicContentSize()
        }
    }
    
    private func applyAttributedText() {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        style.paragraphSpacing = 0
        
        let font = UIFont(name: "Georgia", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: style
        ]
        self.attributedText = NSAttributedString(string: rawParagraph, attributes: attrs)
    }
    
    // MARK: - Native Edit Menu (Translate Selection)
    
    func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var actions = suggestedActions
        let ns = (rawParagraph as NSString)
        if range.location != NSNotFound && (range.location + range.length) <= ns.length {
            let selectedText = ns.substring(with: range).trimmingCharacters(in: .whitespacesAndNewlines)
            if !selectedText.isEmpty {
                let translateAction = UIAction(title: "Translate Selection", image: UIImage(systemName: "character.book.closed.fill")) { [weak self] _ in
                    self?.onTextSelected?(selectedText)
                }
                actions.insert(translateAction, at: 0)
            }
        }
        return UIMenu(children: actions)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        if self.selectedRange.length > 0 { return }
        let location = gesture.location(in: self)
        guard !rawParagraph.isEmpty else { return }
        
        let adjustedLocation = CGPoint(
            x: location.x - textContainerInset.left,
            y: location.y - textContainerInset.top
        )
        
        let charIndex = layoutManager.characterIndex(
            for: adjustedLocation,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )
        
        guard charIndex >= 0 && charIndex < (rawParagraph as NSString).length else { return }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: charIndex)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        guard adjustedLocation.x <= lineRect.maxX + 15 && adjustedLocation.y <= lineRect.maxY + 10 else {
            return
        }
        
        let stringIndex = rawParagraph.index(rawParagraph.startIndex, offsetBy: charIndex)
        
        // 1. Language-aware word tokenization via Apple NaturalLanguage
        let tokenizer = NLTokenizer(unit: .word)
        if languageCode != "auto" {
            tokenizer.setLanguage(NLLanguage(rawValue: languageCode))
        }
        tokenizer.string = rawParagraph
        
        let tokenRange = tokenizer.tokenRange(at: stringIndex)
        guard !tokenRange.isEmpty else { return }
        
        let rawWord = String(rawParagraph[tokenRange])
        let cleanWord = rawWord.trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanWord.isEmpty else { return }
        
        // 2. Language-aware sentence context
        let sentenceTokenizer = NLTokenizer(unit: .sentence)
        if languageCode != "auto" {
            sentenceTokenizer.setLanguage(NLLanguage(rawValue: languageCode))
        }
        sentenceTokenizer.string = rawParagraph
        let sentenceRange = sentenceTokenizer.tokenRange(at: stringIndex)
        let sentence = !sentenceRange.isEmpty ? String(rawParagraph[sentenceRange]) : rawParagraph
        
        // 3. Tactile visual highlight feedback
        highlightToken(range: tokenRange)
        
        // 4. Subtle haptic pulse
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        onWordTapped?(cleanWord, sentence)
    }
    
    private func highlightToken(range: Range<String.Index>) {
        let nsRange = NSRange(range, in: rawParagraph)
        guard let current = self.attributedText?.mutableCopy() as? NSMutableAttributedString else { return }
        
        let highlightColor = UIColor(red: 0.50, green: 0.00, blue: 0.13, alpha: 0.18)
        current.addAttribute(.backgroundColor, value: highlightColor, range: nsRange)
        self.attributedText = current
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }
            self.applyAttributedText()
        }
    }
}

/// Fast horizontal/vertical word list allowing exact word tapping (for fallback or quiz views)
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
