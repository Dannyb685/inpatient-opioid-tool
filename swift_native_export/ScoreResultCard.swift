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
                
                // Score Value
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(badgeColor)
                    
                    if let label = valueLabel {
                        Text(label)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .clinicalCard()
    }
}
