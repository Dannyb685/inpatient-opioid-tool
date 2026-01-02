import SwiftUI

struct AdjuvantRow: View {
    let item: AdjuvantRecommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle().fill(ClinicalTheme.teal500.opacity(0.1)).frame(width: 32, height: 32)
                Image(systemName: item.category.contains("Neuropathic") ? "brain.head.profile" : "pills.fill")
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.teal500)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.drug).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                
                HStack(spacing: 6) {
                    Text(item.dose)
                        .font(.caption2).bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ClinicalTheme.teal500.opacity(0.1))
                        .foregroundColor(ClinicalTheme.teal500)
                        .cornerRadius(4)
                    
                    Text(item.rationale)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }

        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Removed card styling for cleaner list appearance
    }
}
