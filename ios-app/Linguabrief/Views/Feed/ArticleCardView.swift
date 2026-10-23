import SwiftUI

/// Compact news feed card displaying article metadata, thumbnail, AI summary, and action buttons.
public struct ArticleCardView: View {
    public let article: Article
    public let isSummaryLoading: Bool
    public let onSummarizeTapped: () -> Void
    
    @State private var isSummaryExpanded: Bool = false
    
    public init(
        article: Article,
        isSummaryLoading: Bool = false,
        onSummarizeTapped: @escaping () -> Void
    ) {
        self.article = article
        self.isSummaryLoading = isSummaryLoading
        self.onSummarizeTapped = onSummarizeTapped
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Meta Row: Topic chip + Source + Date
            HStack(spacing: 8) {
                if let topic = article.topic {
                    Text(topic.uppercased())
                        .font(.caption2.bold())
                        .foregroundColor(Constants.Colors.brandBurgundy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Constants.Colors.brandBurgundy.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Text(article.source ?? "Global News")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let pub = article.publishedAt {
                    Text(formatDate(pub))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Image & Title
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                    
                    if let desc = article.description, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                if let img = article.imageUrl, let url = URL(string: img), !img.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 75)
                                .cornerRadius(8)
                                .clipped()
                        default:
                            Color(.systemGray5)
                                .frame(width: 80, height: 75)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // AI Summary Expansion Block
            if let summary = article.aiSummary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSummaryExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.caption.bold())
                                .foregroundColor(Constants.Colors.goldAccent)
                            Text("AI SUMMARY (60–80 WORDS)")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: isSummaryExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if isSummaryExpanded {
                        Text(summary)
                            .font(.system(size: 14, design: .serif))
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                Button(action: onSummarizeTapped) {
                    HStack(spacing: 6) {
                        if isSummaryLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.caption)
                        }
                        Text(isSummaryLoading ? "Generating AI Summary..." : "Read AI Summary")
                            .font(.caption.bold())
                    }
                    .foregroundColor(Constants.Colors.brandBurgundy)
                    .padding(.vertical, 4)
                }
                .disabled(isSummaryLoading)
            }
        }
        .padding(14)
        .cardStyle()
    }
    
    private func formatDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let d = formatter.date(from: dateStr) {
            let out = DateFormatter()
            out.dateStyle = .short
            return out.string(from: d)
        }
        return dateStr
    }
}
