import SwiftUI

// MARK: - MERGED TRANSPARENCY ACCORDION (Logix + Visuals)
struct MergedAlgorithmTransparencyAccordion: View {
    @Binding var expandedItem: String?
    let title = "Algorithm Transparency"
    let icon = "function"
    
    var isExpanded: Bool { expandedItem == title }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    if isExpanded { expandedItem = nil } else { expandedItem = title }
                }
            }) {
                HStack {
                    Image(systemName: icon).foregroundColor(ClinicalTheme.teal500)
                    Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(ClinicalTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
            }
            
            if isExpanded {
                Divider()
                VStack(alignment: .leading, spacing: 16) {
                    // Logic Text
                    Text(InfoContent.algorithm)
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider().background(ClinicalTheme.divider)
                    
                    // Visual Potency Bars (Embedded)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Visual Potency Guide")
                            .font(.caption).bold()
                            .foregroundColor(ClinicalTheme.textPrimary)
                        
                        PotencyBar(label: "Morphine", factor: 1.0, color: ClinicalTheme.teal500)
                        PotencyBar(label: "Oxycodone", factor: 1.5, color: ClinicalTheme.amber500)
                        PotencyBar(label: "Hydromorphone", factor: 4.0, color: ClinicalTheme.rose500)
                        
                        Text("Equianalgesic factors based on CDC 2022 Guidelines.")
                            .font(.caption2)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .padding(.top, 4)
                    }
                    .padding(12)
                    .background(ClinicalTheme.backgroundMain.opacity(0.5))
                    .cornerRadius(8)
                    
                    Divider().background(ClinicalTheme.divider)
                    
                    // Evidence Section (Moved from separate accordion)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clinical Evidence")
                            .font(.caption).bold()
                            .foregroundColor(ClinicalTheme.textPrimary)
                        Text(InfoContent.evidence)
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ClinicalTheme.backgroundMain)
            }
            
            Divider()
        }
    }
}
