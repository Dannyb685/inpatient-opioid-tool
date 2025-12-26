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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
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
            VStack(alignment: .trailing, spacing: 4) {
               // Badge
                Text(badgeText)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.15))
                    .foregroundColor(badgeColor)
                    .cornerRadius(6)
                
                // Score Value
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.black)
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
        .clinicalCard()
    }
}
