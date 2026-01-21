import SwiftUI

struct ScoreResultCard: View {
    let title: String
    let subtitle: String?
    let value: String
    let valueLabel: String? // e.g. "mg/day"
    let badgeText: String
    let badgeColor: Color
    @EnvironmentObject var themeManager: ThemeManager
    
    init(title: String, 
         subtitle: String? = nil, 
         value: String, 
         valueLabel: String? = nil, 
         badgeText: String, 
         badgeColor: Color) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.valueLabel = valueLabel
        self.badgeText = badgeText
        self.badgeColor = badgeColor
    }
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.textPrimary)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Score & Badge Column
            VStack(alignment: .trailing, spacing: 6) {
               // Badge
                Text(badgeText)
                    .font(.caption2)
                    .fontWeight(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(badgeColor.opacity(0.15))
                    .foregroundColor(badgeColor)
                    .cornerRadius(8)
                    .padding(.bottom, 4) // Vertical Rhythm: 4px gap
                
                // Score Value
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(badgeColor)
                        .fixedSize() // Prevent Wrapping
                    
                    if let label = valueLabel {
                        Text(label)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
            }
        }
        .padding(20) // Even 20px padding
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
