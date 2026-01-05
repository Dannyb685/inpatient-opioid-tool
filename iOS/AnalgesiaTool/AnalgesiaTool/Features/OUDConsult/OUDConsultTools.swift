import SwiftUI

// MARK: - Urine Toxicology View
struct UrineToxView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Urine Toxicology Window").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
            
            VStack(spacing: 0) {
                // Find "tox" category
                if let category = OUDStaticData.toolboxCategories.first(where: { $0.id == "tox" }) {
                    ForEach(Array(category.items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top) {
                            Text(item.title).bold().font(.caption).foregroundColor(ClinicalTheme.teal500).frame(width: 120, alignment: .leading)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(item.value).font(.caption).bold().foregroundColor(ClinicalTheme.textPrimary)
                                if let subtitle = item.subtitle {
                                    Text(subtitle).font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                                }
                            }
                        }
                        .padding()
                        
                        if index < category.items.count - 1 {
                            Divider().background(ClinicalTheme.divider)
                        }
                    }
                }
            }
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        }
        .clinicalCard()
    }
}

// MARK: - Symptom Management & Street Metrics
// SymptomMgmtView removed - moved to Protocols & VisualAidsView

// MARK: - Counseling & Intervention
struct CounselingView: View {
    var body: some View {
        VStack(spacing: 24) {
            
            // Unified Counseling Section (MI + FRAMES)
            if let category = OUDStaticData.toolboxCategories.first(where: { $0.id == "counseling" }) {
                // Section Header
                HStack {
                    Text(category.title)
                        .font(.headline)
                        .foregroundColor(ClinicalTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                ForEach(Array(category.items.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text(item.title)
                                .font(.headline)
                                .bold()
                                .foregroundColor(ClinicalTheme.teal500)
                            
                            Spacer()
                            
                            if !item.value.isEmpty {
                                Text(item.value)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ClinicalTheme.teal500.opacity(0.1))
                                    .foregroundColor(ClinicalTheme.teal500)
                                    .cornerRadius(4)
                            }
                        }
                        
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                }
            }
        }
    }
}


// MARK: - Ported Components from ScreeningView

struct VisualAidsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standard Drink Equivalents").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
            
            Image("alcohol_units")
                .resizable()
                .scaledToFit()
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(ToolkitData.drinkEquivalents.enumerated()), id: \.offset) { index, item in
                     HStack {
                        Text(item.0).bold().foregroundColor(ClinicalTheme.textPrimary)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(item.1).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                            Text(item.2).font(.caption2).bold().foregroundColor(ClinicalTheme.teal500)
                        }
                    }
                    .padding()
                    
                    if index < ToolkitData.drinkEquivalents.count - 1 {
                        Divider().background(ClinicalTheme.divider)
                    }
                }
            }
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        }
        .clinicalCard()
        
        // Street Pricing & Metrics (Moved from SymptomMgmtView)
        VStack(alignment: .leading, spacing: 12) {
            Text("Street Pricing & Metrics").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
            
            VStack(spacing: 0) {
            
                Image("street_drug_units")
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .padding(.bottom, 12)
                 if let category = OUDStaticData.toolboxCategories.first(where: { $0.id == "street" }) {
                    ForEach(Array(category.items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top) {
                            Text(item.title).bold().font(.caption).foregroundColor(ClinicalTheme.rose500).frame(width: 140, alignment: .leading)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(item.value).font(.caption).bold().foregroundColor(ClinicalTheme.textPrimary)
                                if let subtitle = item.subtitle {
                                    Text(subtitle).font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                                }
                            }
                        }
                        .padding()
                        
                        if index < category.items.count - 1 {
                            Divider().background(ClinicalTheme.divider)
                        }
                    }
                }
            }
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        }
        .clinicalCard()
        
        
        // Common Street Terms
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Street Terms").font(.headline).foregroundColor(ClinicalTheme.textPrimary).padding(.top, 8)
            
            VStack(spacing: 0) {
                ForEach(ToolkitData.streetOpioidTerms, id: \.0) { item in
                    HStack(alignment: .top) {
                        Text(item.0).bold().font(.caption).foregroundColor(ClinicalTheme.teal500).frame(width: 100, alignment: .leading)
                        Text(item.1).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        Spacer()
                    }
                    .padding()
                    
                    if item.0 != ToolkitData.streetOpioidTerms.last?.0 {
                        Divider().background(ClinicalTheme.divider)
                    }
                }
            }
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        }
        .clinicalCard()
    }
}


