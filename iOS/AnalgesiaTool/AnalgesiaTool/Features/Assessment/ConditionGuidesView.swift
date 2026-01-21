import SwiftUI
struct ConditionGuidesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. General Principles
            Text("General Principles")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(ClinicalTheme.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            ForEach(Array(ProtocolData.generalPrinciples.enumerated()), id: \.element.id) { index, guide in
                DisclosureGroup(
                    content: {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(guide.recommendations, id: \.self) { rec in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: guide.title.contains("Non-Opioids") ? "cross.case.fill" : "pills.fill")
                                        .foregroundColor(guide.title.contains("Non-Opioids") ? ClinicalTheme.teal500 : ClinicalTheme.rose500)
                                        .font(.caption2)
                                        .padding(.top, 2)
                                    Text(rec)
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    },
                    label: {
                        HStack {
                            Text(guide.title)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(ClinicalTheme.textPrimary)
                            Spacer()
                        }
                    }
                )
                .padding()
                Divider().background(ClinicalTheme.divider)
            }
            
            // 2. Condition Specific
            Text("Condition Specific")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(ClinicalTheme.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(Array(ProtocolData.conditionGuides.enumerated()), id: \.element.id) { index, guide in
                DisclosureGroup(
                    content: {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(guide.recommendations, id: \.self) { rec in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(ClinicalTheme.teal500).frame(width: 6, height: 6).padding(.top, 6)
                                    Text(rec)
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, 12)
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
    }
}
