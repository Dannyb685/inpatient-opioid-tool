import SwiftUI
struct ConditionGuidesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("General Reference (Safety Logic Not Applied)")
                .font(.caption)
                .bold()
                .foregroundColor(.orange)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ClinicalTheme.backgroundCard)
            
            Divider().background(ClinicalTheme.divider)
            
            ForEach(Array(ProtocolData.conditionGuides.enumerated()), id: \.element.id) { index, guide in
                DisclosureGroup(
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(guide.recommendations, id: \.self) { rec in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(ClinicalTheme.teal500).frame(width: 6, height: 6).padding(.top, 6)
                                    Text(rec)
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    },
                    label: {
                        Text(guide.title)
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.textPrimary)
                    }
                )
                .padding()
                
                if index < ProtocolData.conditionGuides.count - 1 {
                    Divider().background(ClinicalTheme.divider)
                }
            }
        }
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        .padding(.horizontal, 24)
    }
}
