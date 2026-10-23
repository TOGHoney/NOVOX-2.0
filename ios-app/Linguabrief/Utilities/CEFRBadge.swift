import SwiftUI

/// Compact chip component displaying a color-coded CEFR level badge (A1 through C2).
public struct CEFRBadge: View {
    public let level: String
    
    public init(_ level: String) {
        self.level = level.uppercased()
    }
    
    private var badgeColor: Color {
        switch level {
        case "A1": return .green
        case "A2": return .mint
        case "B1": return .blue
        case "B2": return .indigo
        case "C1": return .purple
        case "C2": return .orange
        default: return .gray
        }
    }
    
    public var body: some View {
        Text(level)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeColor)
            .cornerRadius(6)
    }
}
