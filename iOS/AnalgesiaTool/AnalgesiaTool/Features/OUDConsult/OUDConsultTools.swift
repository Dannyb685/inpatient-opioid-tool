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
            // Counseling Tips
            VStack(alignment: .leading, spacing: 12) {
                Text("Motivational Interviewing Tips").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                
                VStack(spacing: 0) {
                     if let category = OUDStaticData.toolboxCategories.first(where: { $0.id == "counseling" }) {
                        ForEach(Array(category.items.enumerated()), id: \.offset) { index, item in
                            HStack(alignment: .top) {
                                Text(item.title).bold().font(.caption).foregroundColor(ClinicalTheme.teal500).frame(width: 80, alignment: .leading)
                                VStack(alignment: .leading) {
                                    Text(item.value).font(.caption).bold().foregroundColor(ClinicalTheme.textPrimary)
                                    if let subtitle = item.subtitle {
                                        Text(subtitle).font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                                    }
                                }
                                Spacer()
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
            
            // FRAMES Model (Ported from ScreeningView)
            InterventionView()
        }
    }
}


// MARK: - Ported Components from ScreeningView

struct VisualAidsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Standard Drink Equivalents").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 20) {
                    // Beer
                    VStack {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 2).stroke(ClinicalTheme.textSecondary, lineWidth: 1).frame(width: 30, height: 60)
                            RoundedRectangle(cornerRadius: 2).fill(ClinicalTheme.amber500.opacity(0.8)).frame(width: 30, height: 55)
                        }
                        Text("Beer").font(.caption2).bold()
                        Text("12oz").font(.caption2).foregroundColor(.secondary)
                    }
                    // Malt
                    VStack {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 2).stroke(ClinicalTheme.textSecondary, lineWidth: 1).frame(width: 25, height: 50)
                            RoundedRectangle(cornerRadius: 2).fill(ClinicalTheme.amber500.opacity(0.6)).frame(width: 25, height: 40)
                        }
                        Text("Malt").font(.caption2).bold()
                        Text("8oz").font(.caption2).foregroundColor(.secondary)
                    }
                    // Wine
                    VStack {
                        ZStack(alignment: .bottom) {
                            Image(systemName: "wineglass")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 30)
                                .foregroundColor(ClinicalTheme.textSecondary)
                            
                            Image(systemName: "wineglass.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 30)
                                .foregroundColor(ClinicalTheme.rose500.opacity(0.8))
                                .mask(
                                    VStack {
                                        Spacer()
                                        Rectangle().frame(height: 15)
                                    }
                                    .frame(width: 20, height: 30)
                                )
                        }
                        Text("Wine").font(.caption2).bold()
                        Text("5oz").font(.caption2).foregroundColor(.secondary)
                    }
                    // Spirits (Shot)
                    VStack {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 1).stroke(ClinicalTheme.textSecondary, lineWidth: 1).frame(width: 20, height: 25)
                            RoundedRectangle(cornerRadius: 1).fill(ClinicalTheme.textPrimary.opacity(0.8)).frame(width: 20, height: 15)
                        }
                        Text("Shot").font(.caption2).bold()
                        Text("1.5oz").font(.caption2).foregroundColor(.secondary)
                    }
                    
                    Divider().frame(height: 40)
                    
                    // Pint
                    VStack {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4).stroke(ClinicalTheme.textSecondary, lineWidth: 1).frame(width: 35, height: 50)
                            RoundedRectangle(cornerRadius: 4).fill(ClinicalTheme.textPrimary.opacity(0.8)).frame(width: 35, height: 45)
                            Text("375").font(.system(size: 8)).foregroundColor(ClinicalTheme.backgroundMain).offset(y: -20)
                        }
                        Text("Pint").font(.caption2).bold()
                        Text("8.5x").font(.caption2).foregroundColor(ClinicalTheme.rose500)
                    }
                    
                    // Handle
                    VStack {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6).stroke(ClinicalTheme.textSecondary, lineWidth: 1).frame(width: 45, height: 70)
                            RoundedRectangle(cornerRadius: 6).fill(ClinicalTheme.textPrimary.opacity(0.8)).frame(width: 45, height: 65)
                            Text("1.75").font(.system(size: 10)).foregroundColor(ClinicalTheme.backgroundMain).offset(y: -30)
                        }
                        Text("Handle").font(.caption2).bold()
                        Text("39x").font(.caption2).foregroundColor(ClinicalTheme.rose500)
                    }
                }
                .padding()
            }
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            
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

struct InterventionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FRAMES Model").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
            ForEach(ToolkitData.framesData, id: \.0) { item in
                HStack(alignment: .top, spacing: 12) {
                    Text(item.0)
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(ClinicalTheme.teal500)
                        .frame(width: 30)
                    VStack(alignment: .leading) {
                        Text(item.1).bold().foregroundColor(ClinicalTheme.textPrimary)
                        Text(item.2).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            }
        }
        .clinicalCard()
    }
}
