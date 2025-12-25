import SwiftUI

struct RiskAssessmentView: View {
    @StateObject private var store = AssessmentStore()
    @State private var showFullDetails = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - PINNED HEADER (Score + Top Recs)
                VStack(spacing: 12) {
                    // 1. PRODIGY Score Row
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PRODIGY Score").font(.caption).foregroundColor(ClinicalTheme.slate400).textCase(.uppercase)
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(store.prodigyScore)")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(scoreColor)
                                
                                Text(store.prodigyRisk)
                                    .font(.headline)
                                    .foregroundColor(scoreColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(scoreColor.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                        Spacer()
                        
                        if !store.recommendations.isEmpty {
                            Button(action: { showFullDetails = true }) {
                                HStack(spacing: 4) {
                                    Text("Full Protocol")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.caption).bold()
                                .foregroundColor(ClinicalTheme.teal500)
                                .padding(8)
                                .background(ClinicalTheme.teal500.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                    }
                    
                    // 2. Recommendations Preview (Top 2)
                    if !store.recommendations.isEmpty {
                        Divider().background(ClinicalTheme.slate700)
                        
                        VStack(spacing: 8) {
                            ForEach(store.recommendations.prefix(2)) { rec in
                                HStack {
                                    Circle()
                                        .fill(rec.type == .safe ? ClinicalTheme.teal500 : ClinicalTheme.amber500)
                                        .frame(width: 8, height: 8)
                                    Text(rec.name).font(.subheadline).bold().foregroundColor(.white)
                                    Spacer()
                                    Text(rec.reason).font(.caption).foregroundColor(ClinicalTheme.slate400)
                                }
                            }
                        }
                    } else {
                        Text("Enter patient parameters below")
                            .font(.caption)
                            .italic()
                            .foregroundColor(ClinicalTheme.slate400)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .clinicalCard()
                .padding()
                .background(ClinicalTheme.slate900) // Ensure opaque background for pinning
                .zIndex(1)
                
                // MARK: - SCROLLABLE INPUTS
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Age & Sex
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Age").font(.caption).foregroundColor(ClinicalTheme.slate400).textCase(.uppercase)
                                TextField("Yrs", text: $store.age)
                                    .keyboardType(.numberPad)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(ClinicalTheme.slate800)
                                    .cornerRadius(8)
                            }
                            VStack(alignment: .leading) {
                                Text("Sex").font(.caption).foregroundColor(ClinicalTheme.slate400).textCase(.uppercase)
                                Picker("Sex", selection: $store.sex) {
                                    ForEach(Sex.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Basic Toggles
                        VStack(spacing: 16) {
                            Toggle("Opioid Naive", isOn: $store.naive)
                            Toggle("Home Buprenorphine (MAT)", isOn: $store.mat)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                        .padding()
                        .background(ClinicalTheme.slate800)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Inputs
                        Group {
                            InputSection(title: "1. Renal Function (CrCl)") {
                                Picker("Renal", selection: $store.renalFunction) {
                                    ForEach(RenalStatus.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                            
                            InputSection(title: "2. Hepatic Function") {
                                Picker("Hepatic", selection: $store.hepaticFunction) {
                                    ForEach(HepaticStatus.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                            
                            InputSection(title: "3. Hemodynamics") {
                                Picker("Hemo", selection: $store.hemo) {
                                    ForEach(Hemodynamics.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                            
                            InputSection(title: "4. GI / Mental Status") {
                                Picker("GI", selection: $store.gi) {
                                    ForEach(GIStatus.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                            
                            InputSection(title: "5. Route") {
                                Picker("Route", selection: $store.route) {
                                    ForEach(OpioidRoute.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                        }
                        
                        Group {
                            InputSection(title: "6. Pain Type") {
                                Picker("Pain", selection: $store.painType) {
                                    ForEach(PainType.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.menu)
                                .accentColor(ClinicalTheme.teal500)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            InputSection(title: "7. Clinical Indication") {
                                Picker("Indication", selection: $store.indication) {
                                    ForEach(ClinicalIndication.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                            }
                        }
                        
                        // Risk Factors (PRODIGY)
                        VStack(alignment: .leading, spacing: 10) {
                             Text("Risk Factors (PRODIGY)").font(.headline).foregroundColor(ClinicalTheme.slate400)
                             Toggle("Sleep Apnea (OSA)", isOn: $store.sleepApnea)
                             Toggle("CHF", isOn: $store.chf)
                             Toggle("Benzos / Sedatives", isOn: $store.benzos)
                             Toggle("COPD / Lung Disease", isOn: $store.copd)
                             Toggle("Psych History", isOn: $store.psychHistory)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                        .clinicalCard()
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding(.top)
                }
            }
            .background(ClinicalTheme.slate900.edgesIgnoringSafeArea(.all))
            .navigationTitle("Risk Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFullDetails) {
                // MARK: - FULL DETAILS SHEET
                NavigationView {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Monitoring Plan
                            if !store.monitoringPlan.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("MONITORING PLAN").font(.caption).fontWeight(.black).foregroundColor(ClinicalTheme.slate400)
                                    ForEach(store.monitoringPlan, id: \.self) { plan in
                                        HStack(alignment: .top) {
                                            Image(systemName: "lungs.fill").foregroundColor(ClinicalTheme.slate400).font(.caption)
                                            Text(plan).font(.subheadline).foregroundColor(.white)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                                .clinicalCard()
                                .padding(.horizontal)
                            }
                            
                            // Recommendations
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recommendations").font(.title3).bold().foregroundColor(.white).padding(.horizontal)
                                ForEach(store.recommendations) { rec in
                                    RecommendationCard(rec: rec)
                                }
                            }
                            
                            // Warnings
                            if !store.warnings.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("CONTRAINDICATIONS").font(.caption).fontWeight(.black).foregroundColor(ClinicalTheme.rose500)
                                    ForEach(store.warnings, id: \.self) { warn in
                                        HStack(alignment: .top) {
                                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(ClinicalTheme.rose500)
                                            Text(warn).font(.subheadline).foregroundColor(.white)
                                        }
                                    }
                                }
                                .padding()
                                .background(ClinicalTheme.rose500.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            
                            // Adjuvants
                            if !store.adjuvants.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ADJUVANTS").font(.caption).fontWeight(.black).foregroundColor(ClinicalTheme.teal500)
                                    ForEach(store.adjuvants, id: \.self) { adj in
                                        Text("• " + adj).font(.subheadline).foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(ClinicalTheme.teal500.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .background(ClinicalTheme.slate900.edgesIgnoringSafeArea(.all))
                    .navigationTitle("Assessment Details")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showFullDetails = false }
                        }
                    }
                }
            }
        }
    }
    
    var scoreColor: Color {
        switch store.prodigyRisk {
        case "High": return ClinicalTheme.rose500
        case "Intermediate": return ClinicalTheme.amber500
        default: return ClinicalTheme.teal500
        }
    }
}

// Helper Components
struct InputSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundColor(ClinicalTheme.teal500)
            content
        }
        .clinicalCard()
        .padding(.horizontal)
    }
}

struct RecommendationCard: View {
    let rec: DrugRecommendation
    var color: Color {
        switch rec.type {
        case .safe: return ClinicalTheme.teal500
        case .caution: return ClinicalTheme.amber500
        case .unsafe: return ClinicalTheme.rose500
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(rec.name).font(.title3).fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Text(rec.type == .safe ? "Preferred" : "Monitor")
                    .font(.caption).fontWeight(.bold).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(color.opacity(0.2)).foregroundColor(color).cornerRadius(6)
            }
            Text(rec.reason).font(.subheadline).fontWeight(.medium).foregroundColor(ClinicalTheme.slate400)
            Text(rec.detail).font(.caption).italic().foregroundColor(ClinicalTheme.slate700)
        }
        .padding().background(ClinicalTheme.slate800).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.5), lineWidth: 1))
        .padding(.horizontal)
    }
}
