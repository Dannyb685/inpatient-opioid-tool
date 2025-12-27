import SwiftUI
import UIKit // For Haptics

struct RiskAssessmentView: View {
    @EnvironmentObject var store: AssessmentStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showFullDetails = false
    @State private var showPatientView = false
    @State private var isQuickMode = true // Quick Mode Default: TRUE
    
    var accentColor: Color {
        return store.isPregnant ? ClinicalTheme.purple500 : ClinicalTheme.teal500
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                pinnedHeader
                
                // MARK: - SCROLLABLE INPUTS
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MODE TOGGLE
                        Picker("Assessment Mode", selection: Binding(
                            get: { self.isQuickMode },
                            set: { newValue in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    self.isQuickMode = newValue
                                }
                            }
                        )) {
                            Text("⚡️ Quick Mode").tag(true)
                            Text("Full Assessment").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        demographicsSection
                        clinicalInputsSection
                        additionalParametersSection
                        riskFactorsSection
                    }
                    .padding(.top)
                }
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Opioid Risk Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button("Reset") {
                            withAnimation { store.reset() }
                        }
                        .foregroundColor(.red)
                        
                        Button(action: { showPatientView = true }) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(accentColor)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            themeManager.isDarkMode.toggle()
                        }
                    }) {
                        Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.stars.fill")
                            .foregroundColor(accentColor)
                    }
                }
            }
            .sheet(isPresented: $showPatientView) {
                PatientSharedDecisionView()
            }
            .sheet(isPresented: $showFullDetails) {
                detailsSheet
            }
        }
    }
    
    // MARK: - SUBVIEWS
    
    var pinnedHeader: some View {
        VStack(spacing: 12) {
            // 1. Recommendations (FEATURED)
            if !store.recommendations.isEmpty {
                VStack(spacing: 8) {
                    ForEach(store.recommendations.prefix(2)) { rec in
                        HStack {
                            Circle()
                                .fill(rec.type == .safe ? accentColor : ClinicalTheme.amber500)
                                .frame(width: 8, height: 8)
                            Text(rec.name).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                            Spacer()
                            Text(rec.reason).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                }
                
                Divider().background(ClinicalTheme.divider)
                
                // 2. PRODIGY (Secondary/Compact)
                if !isQuickMode {
                    HStack(spacing: 8) {
                        Text("PRODIGY Risk Score")
                            .font(.caption).bold()
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Text("\(store.prodigyScore)")
                            .font(.body).fontWeight(.black)
                            .foregroundColor(ClinicalTheme.textPrimary)
                        
                        Text(store.prodigyRisk)
                            .font(.caption).fontWeight(.bold)
                            .foregroundColor(store.prodigyRisk == "High" ? ClinicalTheme.rose500 : (store.prodigyRisk == "Intermediate" ? ClinicalTheme.amber500 : ClinicalTheme.teal500))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((store.prodigyRisk == "High" ? ClinicalTheme.rose500 : (store.prodigyRisk == "Intermediate" ? ClinicalTheme.amber500 : ClinicalTheme.teal500)).opacity(0.1))
                            .cornerRadius(4)
                            
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textMuted)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

            } else {
                 // Empty State
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
    
    @ViewBuilder
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
        
        // Perinatal Toggle
        if store.shouldShowPregnancyToggle() {
            Toggle(isOn: $store.isPregnant) {
                 VStack(alignment: .leading, spacing: 2) {
                     Text("Pregnant / Breastfeeding").font(.subheadline).bold().foregroundColor(ClinicalTheme.purple500)
                     Text("Activates Perinatal Safety Mode").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                 }
            }
            .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.purple500))
            .padding()
            .background(ClinicalTheme.purple500.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }

    
    // clinicalInputsSection & additionalParametersSection use SelectionView which needs separate update if not using Theme in SelectionView.swift
    
    var clinicalInputsSection: some View {
        Group {
            // 1. Route (PROMOTED - FIRST QUESTION)
            SelectionView(
                title: "1. Route Preference",
                options: OpioidRoute.allCases,
                selection: $store.route
            )
            
            // 2. Hemodynamics (ALWAYS SHOW - ACUTE SAFETY)
            SelectionView(
                title: "2. Hemodynamics",
                options: Hemodynamics.allCases,
                selection: $store.hemo,
                colorMapper: { status in
                    switch status {
                    case .stable: return ClinicalTheme.teal500
                    case .unstable: return ClinicalTheme.rose500
                    }
                }
            )
            
            // 3. Renal Function (Toggle in Quick Mode)
            if isQuickMode {
                VStack(spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { store.renalFunction != .normal },
                        set: { 
                            UISelectionFeedbackGenerator().selectionChanged()
                            store.renalFunction = $0 ? .impaired : .normal 
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("3. Renal Impairment / CKD").font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                            Text("Maps to CrCl <60 (Standard Precautions)").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.amber500))
                    
                    if store.renalFunction != .normal {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(store.renalFunction == .dialysis ? ClinicalTheme.rose500 : ClinicalTheme.amber500)
                                Text("Status: \(store.renalFunction.rawValue)")
                                    .font(.caption).bold()
                                    .foregroundColor(ClinicalTheme.textPrimary)
                            }
                            Text("Is the patient on Dialysis? Strict avoidance of Morphine/Codeine required to prevent neurotoxicity.")
                                .font(.system(size: 10))
                                .foregroundColor(ClinicalTheme.textSecondary)
                            
                            Button(action: {
                                let isEscalating = (store.renalFunction != .dialysis)
                                if isEscalating { UINotificationFeedbackGenerator().notificationOccurred(.error) }
                                else { UISelectionFeedbackGenerator().selectionChanged() }
                                
                                withAnimation {
                                    store.renalFunction = (store.renalFunction == .dialysis) ? .impaired : .dialysis
                                }
                            }) {
                                Text(store.renalFunction == .dialysis ? "Revert to Standard CKD" : "Escalate to Dialysis")
                                    .font(.caption2).bold()
                                    .foregroundColor(store.renalFunction == .dialysis ? ClinicalTheme.teal500 : ClinicalTheme.rose500)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background((store.renalFunction == .dialysis ? ClinicalTheme.teal500 : ClinicalTheme.rose500).opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(8)
                        .background(ClinicalTheme.backgroundMain.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            } else {
                SelectionView(
                    title: "3. Renal Function (CrCl)",
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
            }
            
            // 4. Hepatic Function (Toggle in Quick Mode)
            if isQuickMode {
                VStack(spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { store.hepaticFunction != .normal },
                        set: { 
                            UISelectionFeedbackGenerator().selectionChanged()
                            store.hepaticFunction = $0 ? .impaired : .normal 
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("4. Liver Disease / Impairment").font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                            Text("Maps to Child-Pugh B (Standard Precautions)").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.amber500))
                    
                    if store.hepaticFunction != .normal {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(store.hepaticFunction == .failure ? ClinicalTheme.rose500 : ClinicalTheme.amber500)
                                Text("Status: \(store.hepaticFunction.rawValue)")
                                    .font(.caption).bold()
                                    .foregroundColor(ClinicalTheme.textPrimary)
                            }
                            Text("Does this patient have LIVER FAILURE (Child-Pugh C)? Hydromorphone bioavailability increases 4x vs baseline.")
                                .font(.system(size: 10))
                                .foregroundColor(ClinicalTheme.textSecondary)
                            
                            Button(action: {
                                let isEscalating = (store.hepaticFunction != .failure)
                                if isEscalating { UINotificationFeedbackGenerator().notificationOccurred(.error) }
                                else { UISelectionFeedbackGenerator().selectionChanged() }
                                
                                withAnimation {
                                    store.hepaticFunction = (store.hepaticFunction == .failure) ? .impaired : .failure
                                }
                            }) {
                                Text(store.hepaticFunction == .failure ? "Revert to Moderate Impairment" : "Escalate to Liver Failure (Child-Pugh C)")
                                    .font(.caption2).bold()
                                    .foregroundColor(store.hepaticFunction == .failure ? ClinicalTheme.teal500 : ClinicalTheme.rose500)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background((store.hepaticFunction == .failure ? ClinicalTheme.teal500 : ClinicalTheme.rose500).opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(8)
                        .background(ClinicalTheme.backgroundMain.opacity(0.3))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            } else {
                SelectionView(
                    title: "4. Hepatic Function",
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
            
            // 5. GI / Mental Status (HIDDEN IN QUICK MODE)
            if !isQuickMode {
                SelectionView(
                    title: "5. GI / Mental Status",
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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    var additionalParametersSection: some View {
        Group {
            if !isQuickMode {
                // 6. Clinical Indication
                SelectionView(
                    title: "6. Clinical Indication",
                    options: ClinicalIndication.allCases,
                    selection: $store.indication
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // 7. Pain Type (CRITICAL STEWARDSHIP GATE - ALWAYS SHOW)
            SelectionView(
                title: "7. Pain Type",
                options: PainType.allCases,
                selection: $store.painType
            )
        }
    }
    
    var riskFactorsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
             Text("Risk Factors (PRODIGY)").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
             Toggle("Opioid Naive", isOn: $store.naive)
             Toggle("Home Buprenorphine (MAT)", isOn: $store.mat)
             
             Toggle("Benzos / Sedatives", isOn: $store.benzos) // CRITICAL OVERDOSE GATE - ALWAYS SHOW
             Toggle("Sleep Apnea (OSA)", isOn: $store.sleepApnea) // CRITICAL RESPIRATORY GATE - ALWAYS SHOW
             
             if !isQuickMode {
                 Group {
                     Toggle("CHF", isOn: $store.chf)
                     // Benzos moved up for safety
                     Toggle("Hx Overdose / Subst. Use", isOn: $store.historyOverdose)
                     Toggle("Depression / Anxiety (Psych)", isOn: $store.psychHistory)
                 }
                 .transition(.opacity.combined(with: .move(edge: .top)))
             } else {
                 Button(action: {
                     withAnimation { isQuickMode = false }
                 }) {
                     HStack {
                         Text("Show full PRODIGY risk factors...")
                         Spacer()
                         Image(systemName: "chevron.down")
                     }
                     .font(.caption)
                     .foregroundColor(ClinicalTheme.teal500)
                 }
                 .padding(.top, 8)
                 .transition(.opacity.combined(with: .move(edge: .top)))
             }
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
                        
                        if store.recommendations.isEmpty {
                            // WATERMARK
                            VStack(spacing: 12) {
                                Image(systemName: "hand.tap")
                                    .font(.largeTitle)
                                    .foregroundColor(ClinicalTheme.textMuted.opacity(0.3))
                                Text("Complete inputs for options")
                                    .font(.caption)
                                    .foregroundColor(ClinicalTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(store.recommendations) { rec in
                                RecommendationCard(rec: rec)
                            }
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
