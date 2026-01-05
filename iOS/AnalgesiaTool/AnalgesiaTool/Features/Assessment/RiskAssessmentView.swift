import SwiftUI
import UIKit // For Haptics

struct RiskAssessmentView: View {
    @EnvironmentObject var store: AssessmentStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showFullDetails = false

    @State private var isQuickMode = true // Quick Mode Default: TRUE
    
    var accentColor: Color {
        return store.isPregnant ? ClinicalTheme.purple500 : ClinicalTheme.teal500
    }

    var profileColor: Color {
        switch store.analgesicProfile {
        case .naive: return ClinicalTheme.teal500      // Safe / Standard
        case .chronicRx: return ClinicalTheme.amber500 // Moderate Tolerance
        case .highPotency: return ClinicalTheme.rose500 // Danger / Unknown
        case .buprenorphine: return ClinicalTheme.purple500 // Blockade / High Affinity
        case .methadone: return Color.indigo // QTc / Variable Half-life
        case .naltrexone: return Color.gray            // Blocked
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                pinnedHeader
                
                // MARK: - SCROLLABLE INPUTS
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
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
                        medicationHistorySection
                        riskFactorsSection
                        
                        AssessmentContextFlowCard()
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    .padding(.bottom, 100)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                }
            }
            .addKeyboardDoneButton()
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Opioid Risk Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        withAnimation { store.reset() }
                    }
                    .foregroundColor(.red)
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

            .sheet(isPresented: $showFullDetails) {
                detailsSheet
            }
        }
    }
    
    // MARK: - SUBVIEWS
    
    var pinnedHeader: some View {
        VStack(spacing: 4) {
             // Header Title
            HStack {
                Text("RECOMMENDATIONS")
                    .font(.caption2)
                    .fontWeight(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accentColor.opacity(0.15))
                    .foregroundColor(accentColor)
                    .cornerRadius(8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.textMuted)
            }
            .padding(.bottom, 4)
            
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
                
                Divider().background(ClinicalTheme.divider).padding(.vertical, 4)
                
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
                }
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
            
            // 3. Renal Function (CrCl)
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
            
            // 4. Hepatic Function
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
            
            // 6. History of GI Bleed (Independent Question)
            if !isQuickMode {
                Toggle(isOn: $store.historyGIBleed) {
                     VStack(alignment: .leading, spacing: 2) {
                         Text("6. History of GI Bleed?").font(.subheadline).bold().foregroundColor(ClinicalTheme.rose500)
                         Text("Prevents systemic NSAID recommendations").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                     }
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                .padding()
                .background(ClinicalTheme.rose500.opacity(0.05))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.rose500.opacity(0.3), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    var additionalParametersSection: some View {
        Group {
            if !isQuickMode {
                // 7. Clinical Indication
                SelectionView(
                    title: "7. Clinical Indication",
                    options: ClinicalIndication.allCases,
                    selection: $store.indication
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // 8. Pain Type (CRITICAL STEWARDSHIP GATE - ALWAYS SHOW)
            SelectionView(
                title: "8. Pain Type",
                options: PainType.allCases,
                selection: $store.painType
            )
        }
    }
    
    var medicationHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(ClinicalTheme.teal500)
                Text("Substance Profile")
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.textSecondary)
            }
            


            // 1. ANALGESIC PROFILE PICKER
            VStack(alignment: .leading, spacing: 6) {
                Text("Patient Baseline")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .textCase(.uppercase)
                
                Menu {
                    Picker("Profile", selection: $store.analgesicProfile) {
                        ForEach(AnalgesicProfile.allCases) { profile in
                            Text(profile.rawValue).tag(profile)
                        }
                    }
                } label: {
                    HStack {
                        Text(store.analgesicProfile.rawValue)
                            .font(.body).bold()
                            .foregroundColor(ClinicalTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundInput)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(profileColor.opacity(0.5), lineWidth: 1.5)
                    )
                }
            }
            
            // 2. DYNAMIC PAIN MODIFIERS
            Group {
                // METHADONE CONTEXT
                if store.analgesicProfile == .methadone {
                    Divider()
                    Toggle(isOn: $store.qtcProlonged) {
                        VStack(alignment: .leading) {
                            Text("QTc Prolongation (>450ms)")
                                .font(.subheadline).bold()
                            Text("Warning: Limit QT-prolonging adjuvants")
                                .font(.caption).foregroundColor(ClinicalTheme.rose500)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                    
                    Toggle(isOn: $store.splitDosing) {
                        VStack(alignment: .leading) {
                            Text("Already on Split Dosing?")
                                .font(.subheadline).bold()
                            Text(store.splitDosing ? "Good for analgesia" : "Recommendation: Split dose q8h")
                                .font(.caption).foregroundColor(store.splitDosing ? ClinicalTheme.teal500 : ClinicalTheme.amber500)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                }
                
                // BUPRENORPHINE CONTEXT
                if store.analgesicProfile == .buprenorphine {
                    Divider()
                    Toggle("Currently Split Dosing (q6-8h)?", isOn: $store.splitDosing)
                        .font(.subheadline)
                        .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                }
                
                // HIGH POTENCY / FENTANYL
                if store.analgesicProfile == .highPotency {
                    Divider()
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(ClinicalTheme.rose500)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Note: Tolerance Unpredictable")
                                .font(.subheadline).bold()
                            Text("Lipophilic storage prevents accurate MME calculation. Titrate by effect.")
                                .font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // NALTREXONE
                if store.analgesicProfile == .naltrexone {
                    Divider()
                    HStack(alignment: .top) {
                        Image(systemName: "nosign")
                            .foregroundColor(ClinicalTheme.rose500)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Receptor Blockade Active")
                                .font(.subheadline).bold()
                            Text("Opioids ineffective. Prioritize Ketamine/Regional.")
                                .font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.easeInOut, value: store.analgesicProfile)
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        .padding(.horizontal)
    }

    var riskFactorsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
             Text("Risk Factors (PRODIGY)").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
             
             if !isQuickMode {
                 Group {
                     Toggle("Benzos / Sedatives", isOn: $store.benzos)
                     Toggle("Sleep Apnea (OSA)", isOn: $store.sleepApnea)
                     Toggle("CHF", isOn: $store.chf)
                     Toggle("Hx Overdose / Subst. Use", isOn: $store.historyOverdose)
                     Toggle("Depression / Anxiety", isOn: $store.psychHistory)
                 }
                 .transition(.opacity.combined(with: .move(edge: .top)))
             } else {
                 Button(action: {
                     withAnimation { isQuickMode = false }
                 }) {
                     HStack {
                         Text("Show PRODIGY risk factors...")
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
                    
                    // 0. PATIENT CONTEXT (Reverted to Styled One-Liner)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PATIENT CONTEXT")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(ClinicalTheme.textSecondary)
                        
                        Text(LocalizedStringKey(store.generatedSummary))
                            .font(.body) // System font (no serif)
                            .foregroundColor(ClinicalTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClinicalTheme.backgroundCard) // White card
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    .padding(.horizontal)

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
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clinicalCard()
                        .padding(.horizontal)
                    }
                    
                    // 3. ADJUVANTS
                    if !store.adjuvants.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Adjuvant Options").font(.title3).bold().foregroundColor(ClinicalTheme.textPrimary).padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 4) { // Reduced spacing for list feel
                                ForEach(store.adjuvants) { adj in
                                    AdjuvantRow(item: adj)
                                    Divider().padding(.leading) // Added divider for list feel
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .clinicalCard()
                            .padding(.horizontal)
                        }
                    }
                    
                    // 4. Opioid Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Opioid Options").font(.title3).bold().foregroundColor(ClinicalTheme.textPrimary).padding(.horizontal)
                        
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
                
                // 5. Condition Guides (Moved from Library)
                VStack(alignment: .leading, spacing: 0) {
                    DisclosureGroup(
                        content: {
                            VStack(alignment: .leading, spacing: 12) {
                                // Explicit Warning as requested
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(ClinicalTheme.amber500)
                                    Text("General reference only. Does not account for patient-specific safety parameters.")
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(ClinicalTheme.amber500.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.bottom, 8)
                                
                                ConditionGuidesView()
                            }
                            .padding(.top, 12)
                        },
                        label: {
                            Text("Pain Regimen By Condition")
                                .font(.title3)
                                .bold()
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                    )
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                
                // 6. Legal Footer
                DisclaimerFooter()
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("RECOMMENDATIONS")
                        .font(.footnote)
                        .fontWeight(.heavy)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .tracking(1) // Letter spacing for clean look
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showFullDetails = false }
                        .font(.body.bold())
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

struct AssessmentContextFlowCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.title2)
                    .foregroundColor(ClinicalTheme.teal500)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clinical Data Flow")
                        .font(.headline)
                        .foregroundColor(ClinicalTheme.teal500)
                    
                    Text("Your inputs here drive downstream safety logic:")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
                Spacer()
            }
            
            HStack(spacing: 8) {
                FlowBadge(icon: "pills.fill", label: "Calculator")
                Image(systemName: "arrow.right").font(.caption).foregroundColor(ClinicalTheme.textMuted)
                FlowBadge(icon: "cross.case.fill", label: "OUD Consult")
                Image(systemName: "arrow.right").font(.caption).foregroundColor(ClinicalTheme.textMuted)
                FlowBadge(icon: "books.vertical.fill", label: "Library")
            }
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(ClinicalTheme.amber500)
                    .font(.caption2)
                Text("Changes here require refresh in downstream tools.")
                    .font(.caption2)
                    .italic()
                    .foregroundColor(ClinicalTheme.textSecondary)
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.teal500.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5])))
    }
}

struct FlowBadge: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(ClinicalTheme.teal500.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: icon).foregroundColor(ClinicalTheme.teal500).font(.caption))
            
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(ClinicalTheme.textSecondary)
        }
    }
}

struct RecommendationCard: View {
    let rec: DrugRecommendation
    @State private var showDetails = false
    var color: Color {
        switch rec.type {
        case .safe: return ClinicalTheme.teal500
        case .caution: return ClinicalTheme.amber500
        case .unsafe: return ClinicalTheme.rose500
        }
    }
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: { withAnimation(.spring()) { showDetails.toggle() } }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rec.name)
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        
                        Text(rec.reason)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(ClinicalTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    Text(rec.type == .safe ? "Preferred" : "Monitor")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.15))
                        .foregroundColor(color)
                        .cornerRadius(6)
                }
                
                // Detail Text
                Text(rec.detail)
                    .font(.subheadline)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading) // Ensure left alignment
                
                // EXPANDABLE CONTENT INDICATOR
                if showDetails {
                    Divider().background(ClinicalTheme.divider)
                    
                    // 1. Standard Orders (Integrated)
                    if let orders = ClinicalData.getStandardOrders(for: rec.name), !orders.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Standard Orders", systemImage: "list.bullet.clipboard.fill")
                                .font(.caption).fontWeight(.bold).foregroundColor(ClinicalTheme.teal500)
                                .padding(.bottom, 2)
                            
                            ForEach(orders) { order in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(ClinicalTheme.teal500).frame(width: 4, height: 4).padding(.top, 6)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(order.label)
                                            .font(.caption).fontWeight(.medium)
                                            .foregroundColor(ClinicalTheme.textPrimary)
                                        if !order.note.isEmpty {
                                            Text(order.note)
                                                .font(.caption2)
                                                .foregroundColor(ClinicalTheme.textSecondary)
                                                .italic()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    // 2. Clinical Pharmacology
                    if let drug = ClinicalData.drugData.first(where: { rec.name.localizedCaseInsensitiveContains($0.name) }) {
                        VStack(alignment: .leading, spacing: 16) {
                             Label("Clinical Pharmacology", systemImage: "flask.fill")
                                .font(.caption).fontWeight(.bold).foregroundColor(ClinicalTheme.purple500)
                            
                            // PK Grid
                            HStack(spacing: 12) {
                                // IV Profile
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("IV Profile").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase)
                                    Text("\(drug.ivOnset) onset").font(.caption).foregroundColor(ClinicalTheme.textPrimary)
                                    Text("\(drug.ivDuration) duration").font(.caption).foregroundColor(ClinicalTheme.textPrimary)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ClinicalTheme.backgroundMain)
                                .cornerRadius(8)
                                
                                // Bioavailability
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Oral Bio").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase)
                                    Text(drug.bioavailability > 0 ? "\(drug.bioavailability)%" : "N/A").font(.caption).bold().foregroundColor(ClinicalTheme.teal500)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(ClinicalTheme.backgroundMain)
                                .cornerRadius(8)
                            }
                            
                            // Nuance
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "bolt.fill").foregroundColor(ClinicalTheme.amber500).font(.caption)
                                Text(drug.clinicalNuance)
                                    .font(.caption)
                                    .foregroundColor(ClinicalTheme.textSecondary)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                
                // Chevron Footer (Always visible to indicate interactivity)
                HStack {
                    Spacer()
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary.opacity(0.5))
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(showDetails ? color.opacity(0.5) : ClinicalTheme.cardBorder, lineWidth: showDetails ? 1.5 : 1))
            .shadow(color: Color.black.opacity(showDetails ? 0.05 : 0), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle()) // Important for list/scrollview behavior
        .padding(.horizontal)
    }
}

struct DisclaimerFooter: View {
    @State private var showLegal = false
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
            
            Text("Legal & Safety Limitations")
                .font(.caption).fontWeight(.bold)
                .foregroundColor(ClinicalTheme.textSecondary)
                .textCase(.uppercase)
            
            VStack(spacing: 4) {
                Text("• EDUCATIONAL TOOL ONLY: Not medical advice.")
                Text("• NOT VALIDATED for patients < 18 years.")
                Text("• NO PROVIDER-PATIENT RELATIONSHIP established.")
            }
            .font(.caption2)
            .foregroundColor(ClinicalTheme.textMuted)
            .multilineTextAlignment(.center)
            
            Button("View Full Legal Disclaimers") {
                showLegal = true
            }
            .font(.caption.bold())
            .foregroundColor(ClinicalTheme.teal500)
            .padding(.top, 4)
        }
        .padding(24)
        .background(ClinicalTheme.backgroundMain)
        .sheet(isPresented: $showLegal) {
            NavigationView {
                LegalDisclaimerView() // Assumes LegalDisclaimerView in Settings/LegalDisclaimerView.swift
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showLegal = false }
                        }
                    }
            }
        }
    }
}
