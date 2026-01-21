import SwiftUI

struct ClinicalCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.textPrimary)
                Spacer()
            }
            .padding(12)
            .background(color.opacity(0.1))
            
            Divider()
            
            // Content
            content
                .padding(16)
        }
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ClinicalTheme.cardBorder, lineWidth: 1)
        )
    }
}
