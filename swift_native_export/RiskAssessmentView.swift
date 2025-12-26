import SwiftUI

struct RiskAssessmentView: View {
    @StateObject private var store = AssessmentStore()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showFullDetails = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                pinnedHeader
                
                // MARK: - SCROLLABLE INPUTS
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        demographicsSection
                        clinicalInputsSection
                        additionalParametersSection
                        riskFactorsSection
                    }
                    .padding(.top)
                }
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Risk Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFullDetails) {
                detailsSheet
            }
        }
    }
    
    // MARK: - SUBVIEWS
    
    var pinnedHeader: some View {
        VStack(spacing: 12) {
            // 1. PRODIGY Score Row
            ScoreResultCard(
                title: "PRODIGY Score",
                subtitle: "Respiratory Depression Risk",
                value: "\(store.prodigyScore)",
                badgeText: store.prodigyRisk,
                badgeColor: store.prodigyRisk == "High" ? ClinicalTheme.rose500 : (store.prodigyRisk == "Intermediate" ? ClinicalTheme.amber500 : ClinicalTheme.teal500)
            )
            
            // 2. Recommendations Preview (Top 2)
            if !store.recommendations.isEmpty {
                Divider().background(ClinicalTheme.divider)
                
                VStack(spacing: 8) {
                    ForEach(store.recommendations.prefix(2)) { rec in
                        HStack {
                            Circle()
                                .fill(rec.type == .safe ? ClinicalTheme.teal500 : ClinicalTheme.amber500)
                                .frame(width: 8, height: 8)
                            Text(rec.name).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                            Spacer()
                            Text(rec.reason).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                }
            } else {
                Text("Enter patient parameters below")
                    .font(.caption)
                    .italic()
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onTapGesture {
            showFullDetails = true
        }
        .clinicalCard()
        .padding()
        .background(ClinicalTheme.backgroundMain) // Ensure opaque background for pinning
        .zIndex(1)
    }
    
    var demographicsSection: some View {
        VStack(spacing: 16) {
            // Age & Sex
            HStack {
                VStack(alignment: .leading) {
                    Text("Age").font(.caption).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase)
                    TextField("Yrs", text: $store.age)
                        .keyboardType(.numberPad)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .padding()
                        .background(ClinicalTheme.backgroundInput)
                        .cornerRadius(8)
                        .addKeyboardDoneButton()
                }
                VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sex").font(.caption).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase)
                    Picker("Sex", selection: $store.sex) {
                        ForEach(Sex.allCases, id: \.self) { sex in
                            Text(sex == .male ? "Male" : "Female").tag(sex)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorMultiply(ClinicalTheme.teal500) // Tint for segmented picker
                }
                }
            }
            .padding(.horizontal)
            
        }
    }

    
    // clinicalInputsSection & additionalParametersSection use SelectionView which needs separate update if not using Theme in SelectionView.swift
    
    var clinicalInputsSection: some View {
        Group {
            // 1. Hemodynamics
             SelectionView(
                title: "1. Hemodynamics",
                options: Hemodynamics.allCases,
                selection: $store.hemo,
                colorMapper: { status in
                    switch status {
                    case .stable: return ClinicalTheme.teal500
                    case .unstable: return ClinicalTheme.rose500
                    }
                }
            )
            
            // 2. Renal Function
             SelectionView(
                title: "2. Renal Function (CrCl)",
                options: RenalStatus.allCases,
                selection: $store.renalFunction,
                colorMapper: { status in
                    switch status {
                    case .normal: return ClinicalTheme.teal500
                    case .impaired: return ClinicalTheme.amber500
                    case .dialysis: return ClinicalTheme.rose500
                    }
                }
            )
            
            // 3. GI / Mental Status
            SelectionView(
                title: "3. GI / Mental Status",
                options: GIStatus.allCases,
                selection: $store.gi,
                colorMapper: { status in
                    switch status {
                    case .intact: return ClinicalTheme.teal500
                    case .tube: return ClinicalTheme.amber500
                    case .npo: return ClinicalTheme.rose500
                    }
                }
            )
            
            // 4. Route
            SelectionView(
                title: "4. Route",
                options: OpioidRoute.allCases,
                selection: $store.route
            )
            
            // 5. Hepatic Function
            SelectionView(
                title: "5. Hepatic Function",
                options: HepaticStatus.allCases,
                selection: $store.hepaticFunction,
                colorMapper: { status in
                    switch status {
                    case .normal: return ClinicalTheme.teal500
                    case .impaired: return ClinicalTheme.amber500
                    case .failure: return ClinicalTheme.rose500
                    }
                }
            )
        }
    }
    
    var additionalParametersSection: some View {
        Group {
            // 6. Clinical Indication
            SelectionView(
                title: "6. Clinical Indication",
                options: ClinicalIndication.allCases,
                selection: $store.indication
            )
            
            // 7. Pain Type
            VStack(alignment: .leading, spacing: 10) {
                Text("7. Pain Type").font(.headline).foregroundColor(ClinicalTheme.teal500)
                Picker("Pain", selection: $store.painType) {
                    ForEach(PainType.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu)
                .accentColor(ClinicalTheme.teal500)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            }
            .clinicalCard()
            .padding(.horizontal)
        }
    }
    
    var riskFactorsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
             Text("Risk Factors (PRODIGY)").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
             Toggle("Opioid Naive", isOn: $store.naive)
             Toggle("Home Buprenorphine (MAT)", isOn: $store.mat)
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
    
    var detailsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Monitoring Plan (High Priority)
                    if !store.monitoringPlan.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MONITORING PLAN").font(.caption).fontWeight(.black).foregroundColor(ClinicalTheme.textSecondary)
                            ForEach(store.monitoringPlan, id: \.self) { plan in
                                HStack(alignment: .top) {
                                    Image(systemName: "lungs.fill").foregroundColor(ClinicalTheme.textSecondary).font(.caption)
                                    Text(plan).font(.subheadline).foregroundColor(ClinicalTheme.textPrimary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .clinicalCard()
                        .padding(.horizontal)
                    }
                    
                    // 2. CONTRAINDICATIONS
                    if !store.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CONTRAINDICATIONS").font(.caption).fontWeight(.black).foregroundColor(ClinicalTheme.rose500)
                            ForEach(store.warnings, id: \.self) { warn in
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(ClinicalTheme.rose500)
                                    Text(warn).font(.subheadline).foregroundColor(ClinicalTheme.textPrimary)
                                }
                            }
                        }
                        .padding()
                        .background(ClinicalTheme.rose500.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // 3. ADJUVANTS
                    if !store.adjuvants.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ADJUVANTS").font(.caption).fontWeight(.black).foregroundColor(ClinicalTheme.teal500)
                            ForEach(store.adjuvants, id: \.self) { adj in
                                Text("• " + adj).font(.subheadline).foregroundColor(ClinicalTheme.textPrimary)
                            }
                        }
                        .padding()
                        .background(ClinicalTheme.teal500.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // 4. Recommendations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommendations").font(.title3).bold().foregroundColor(ClinicalTheme.textPrimary).padding(.horizontal)
                        ForEach(store.recommendations) { rec in
                            RecommendationCard(rec: rec)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Assessment Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showFullDetails = false }
                }
            }
        }
        // Removed .colorScheme(.dark)
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
// RiskAssessmentView.swift - Removing InputSection as it is replaced by SelectionView
struct RecommendationCard: View {
    let rec: DrugRecommendation
    var color: Color {
        switch rec.type {
        case .safe: return ClinicalTheme.teal500
        case .caution: return ClinicalTheme.amber500
        case .unsafe: return ClinicalTheme.rose500
        }
    }
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(rec.name).font(.title3).fontWeight(.bold).foregroundColor(ClinicalTheme.textPrimary)
                Spacer()
                Text(rec.type == .safe ? "Preferred" : "Monitor")
                    .font(.caption).fontWeight(.bold).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(color.opacity(0.2)).foregroundColor(color).cornerRadius(6)
            }
            // Improved legibility: slate300 instead of slate400
            Text(rec.reason).font(.subheadline).fontWeight(.medium).foregroundColor(ClinicalTheme.textSecondary)
            Text(rec.detail).font(.caption).italic().foregroundColor(ClinicalTheme.textMuted)
        }
        .padding().background(ClinicalTheme.backgroundCard).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.5), lineWidth: 1))
        .padding(.horizontal)
    }
}
