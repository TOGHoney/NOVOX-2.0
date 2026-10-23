import SwiftUI

public extension View {
    
    /// Styles a container as a card with subtle shadow and border
    func cardStyle(backgroundColor: Color = Color(.secondarySystemBackground)) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator).opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    /// Brand burgundy primary button style
    func burgundyButtonStyle() -> some View {
        self
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Constants.Colors.brandBurgundy)
            .cornerRadius(10)
    }
}
