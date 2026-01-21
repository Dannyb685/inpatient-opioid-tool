import SwiftUI
import UIKit // For Haptics

struct RiskAssessmentView: View {
    @EnvironmentObject var store: AssessmentStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showFullDetails = false
    @State private var activeMonographDrug: DrugData? = nil // Monograph Sheet Logic
    
    // Keyboard Avoidance (Age Input)
    @FocusState private var focusedField: String?
    @State private var isNoteCopied: Bool = false // UI Refinement: Copy Feedback Helper

    
    var accentColor: Color {
        store.isPregnant ? ClinicalTheme.purple500 : ClinicalTheme.teal500
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                pinnedHeader
                
                // MARK: - SCROLLABLE INPUTS
                ScrollViewReader { scrollProxy in // 1. Reader Wrapper
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            
                            demographicsSection
                            clinicalInputsSection
                            additionalParametersSection
                            medicationHistorySection
                            // nonPharmSection moved to detailsSheet
                            riskFactorsSection
                            
                            AssessmentContextFlowCard()
                                .padding(.horizontal)
                        }
                        .padding(.top)
                        .padding(.bottom, 100)
                        .padding(.bottom, 100)
                        // .hideKeyboardOnTap() moved to root for better hit testing
                    }
                    .onChange(of: focusedField) { _, newField in
                        if let field = newField {
                            withAnimation {
                                scrollProxy.scrollTo(field, anchor: .center)
                            }
                        }
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
            .sheet(item: $activeMonographDrug) { drug in
                NavigationView {
                    DrugMonographView(drug: drug)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Close") { activeMonographDrug = nil }
                            }
                        }
                }
            }
        }
        .hideKeyboardOnTap() // Global dismissal for this screen
    }
    
    // MARK: - SUBVIEWS
    
    var pinnedHeader: some View {
        VStack(spacing: 4) {
             // Header Title
            HStack {
                Text("CONSIDERATIONS")
                    .font(.caption2)
                    .fontWeight(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accentColor.opacity(0.15))
                    .foregroundColor(accentColor)
                    .cornerRadius(8)
                
                Button(action: {
                    store.copySummary()
                    let gen = UINotificationFeedbackGenerator(); gen.notificationOccurred(.success)
                }) {
                    Image(systemName: "doc.on.doc").font(.caption2)
                }
                .foregroundColor(accentColor)
                .padding(4)
                
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
                
                // 2. OIRD (Secondary/Compact)
                    HStack(spacing: 8) {
                        Text("OIRD Risk Score")
                            .font(.caption).bold()
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Text("\(store.compositeOIRDScore)")
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
        .overlay {
            if store.isPediatric {
                PediatricLockScreen()
                    .zIndex(200)
            }
        }
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
                        .focused($focusedField, equals: "ageInput") // 2. Link Focus
                        .id("ageInput") // 3. Link Reader Pivot
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
        
        // Perinatal Toggles
        if store.shouldShowPregnancyToggle() {
            VStack(spacing: 12) {
                Toggle(isOn: $store.isPregnant) {
                    Text("Patient is Pregnant")
                        .font(.subheadline)
                        .foregroundColor(ClinicalTheme.textPrimary)
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.purple500))
                
                Toggle(isOn: $store.isBreastfeeding) {
                    Text("Patient is Breastfeeding")
                        .font(.subheadline)
                        .foregroundColor(ClinicalTheme.textPrimary)
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.purple500))
            }
            .padding()
            .background(ClinicalTheme.backgroundInput)
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
                selection: $store.route,
                layout: .verticalStack
            )
            
            // 2. Hemodynamics (ALWAYS SHOW - ACUTE SAFETY)
            SelectionView(
                title: "2. Hemodynamics",
                options: Hemodynamics.allCases,
                selection: $store.hemo,
                layout: .verticalStack, // Added layout
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
                layout: .verticalStack, // Added layout
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
                layout: .verticalStack,
                colorMapper: { status in
                    switch status {
                    case .normal: return ClinicalTheme.teal500
                    case .impaired: return ClinicalTheme.amber500
                    case .failure: return ClinicalTheme.rose500
                    }
                },
                footer: {
                   if store.hepaticFunction != .normal {
                       Divider().padding(.vertical, 4)
                       
                       VStack(spacing: 12) {
                           Toggle("Visible Ascites?", isOn: $store.hasAscites)
                           
                           SelectionView(
                               title: "Encephalopathy Grade",
                               options: EncephalopathyGrade.allCases,
                               selection: $store.encephalopathyGrade,
                               isEmbedded: true
                           )
                       }
                   }
                }
            )
            
            SelectionView(
                title: "5. GI / Mental Status",
                options: GIStatus.allCases,
                selection: $store.gi,
                layout: .verticalStack,
                colorMapper: { status in
                    switch status {
                    case .intact: return ClinicalTheme.teal500
                    case .tube: return ClinicalTheme.amber500
                    case .npo: return ClinicalTheme.rose500
                    }
                }
            )
            
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
            .padding(.horizontal)
            
            // PAIN ASSESSMENT MODULE
            PainAssessmentView()
                .padding(.horizontal)
        }
    }
    
    var additionalParametersSection: some View {
        Group {
            SelectionView(
                title: "7. Clinical Indication",
                options: ClinicalIndication.allCases,
                selection: $store.indication,
                layout: .verticalStack,
                footer: {
                    if store.indication == .postoperative {
                        Divider().padding(.vertical, 4)
                        
                        Toggle("Immediate Post-Op NPO?", isOn: $store.postOpNPO)
                            .padding(.top, 4)
                    }
                }
            )
            
            // 8. Pain Type (CRITICAL STEWARDSHIP GATE - ALWAYS SHOW)
            SelectionView(
                title: "8. Pain Type",
                options: PainType.allCases,
                selection: $store.painType,
                layout: .verticalStack
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
                            .stroke(store.analgesicProfile.color.opacity(0.5), lineWidth: 1.5)
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

    var nonPharmSection: some View {
        VStack(alignment: .leading, spacing: 16) {
             HStack {
                Image(systemName: "figure.mind.and.body")
                    .foregroundColor(ClinicalTheme.teal500)
                Text("Non-Pharmacological")
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.textSecondary)
            }
            
            if store.nonPharmRecs.isEmpty {
                Text("No specific non-drug interventions identified.")
                    .font(.caption)
                    .italic()
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(8)
            } else {
                ForEach(store.nonPharmRecs) { rec in
                    HStack(alignment: .top, spacing: 12) {
                        // Icon
                        Image(systemName: rec.category == "Physical" ? "figure.walk" : (rec.category == "Psychological" ? "brain.head.profile" : "leaf"))
                            .font(.title3)
                            .foregroundColor(rec.evidence.color)
                            .frame(width: 24)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(rec.intervention)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                
                                Spacer()
                                
                                Text(rec.evidence.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(rec.evidence.color)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(rec.evidence.color.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            Text(rec.detail)
                                .font(.caption)
                                .foregroundColor(ClinicalTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                }
            }
        }
        .padding(.horizontal)
    }

    var riskFactorsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
             Text("OIRD Risk Factors").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
             
              Group {
                  Toggle("Benzos / Sedatives", isOn: $store.benzos)
                  Toggle("COPD / Hypoventilation", isOn: $store.copd)
                  Toggle("Sleep Apnea (OSA)", isOn: $store.sleepApnea)
                  Toggle("CHF", isOn: $store.chf)
                  Toggle("Hx Overdose / Subst. Use", isOn: $store.historyOverdose)
                  Toggle("Depression / Anxiety", isOn: $store.psychHistory)
                  Toggle("Multiple Providers (PDMP)", isOn: $store.multipleProviders)
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
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PATIENT CONTEXT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(ClinicalTheme.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                store.copySummary()
                                let gen = UINotificationFeedbackGenerator(); gen.notificationOccurred(.success)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc").font(.caption)
                                    Text("Copy").font(.caption2).bold()
                                }
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(accentColor.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        
                        Text(LocalizedStringKey(store.generatedSummary))
                            .font(.body) // System font (no serif)
                            .foregroundColor(ClinicalTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                    
                    // 1. CONSULT NOTE (SOAP)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("CONSULT NOTE (SOAP)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(ClinicalTheme.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                let note = NoteGenerator.generateSOAP(store: store)
                                UIPasteboard.general.string = note
                                let gen = UINotificationFeedbackGenerator(); gen.notificationOccurred(.success)
                                
                                // Copy Feedback Logic
                                withAnimation { isNoteCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { isNoteCopied = false }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: isNoteCopied ? "checkmark" : "doc.on.clipboard")
                                        .font(.caption)
                                    Text(isNoteCopied ? "Copied!" : "Copy Note")
                                        .font(.caption2).bold()
                                }
                                .foregroundColor(isNoteCopied ? Color.green : ClinicalTheme.teal500)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    (isNoteCopied ? Color.green : ClinicalTheme.teal500).opacity(0.1)
                                )
                                .cornerRadius(6)
                            }
                        }
                        
                        Text("Ready for EMR Paste")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(ClinicalTheme.textSecondary)
                        
                        // Refined Text Block
                        Text(NoteGenerator.generateSOAP(store: store))
                            .font(.system(size: 14, weight: .medium, design: .monospaced)) // font-mono, text-sm, font-medium
                            .foregroundColor(Color.primary.opacity(0.8)) // text-gray-800 equivalent (#333)
                            .lineLimit(nil) // Allow full expansion or limit if preferred
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ClinicalTheme.backgroundInput) // bg-gray-50
                            .cornerRadius(8) // rounded-lg
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1) // border-gray-200
                            )
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClinicalTheme.backgroundCard) // White card
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    .padding(.horizontal)

                    // 0a. NEUROPATHIC MATRIX SHORTCUT (User Request)
                    if store.painType == .neuropathic {
                       NavigationLink(destination: NeuropathicMatrixView()) {
                           HStack {
                               Image(systemName: "brain.head.profile")
                                   .font(.title2)
                                   .foregroundColor(.white)
                               VStack(alignment: .leading, spacing: 2) {
                                   Text("Neuropathic Efficiency Matrix")
                                       .font(.headline)
                                       .foregroundColor(.white)
                                   Text("Compare Atypical Opioid Efficacy")
                                       .font(.caption)
                                       .foregroundColor(.white.opacity(0.8))
                               }
                               Spacer()
                               Image(systemName: "chevron.right")
                                   .foregroundColor(.white.opacity(0.8))
                           }
                           .padding()
                           .background(LinearGradient(gradient: Gradient(colors: [ClinicalTheme.teal500, ClinicalTheme.blue500]), startPoint: .leading, endPoint: .trailing))
                           .cornerRadius(12)
                           .shadow(color: ClinicalTheme.teal500.opacity(0.3), radius: 5, x: 0, y: 3)
                       }
                       .padding(.horizontal)
                    }

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
                    
                    // 3b. NON-PHARMACOLOGICAL (Moved from Main View)
                    nonPharmSection
                        .clinicalCard() // Ensure it has card styling if not already internal (it has internal styling but clinicalCard wrapper adds shadow consistency?)
                        // usage in main view: nonPharmSection (lines 466-528) had a padding(.horizontal) at end.
                        // inside detailsSheet, we want consistent padding.
                        // Let's looks at nonPharmSection definition: it returns a VStack with .padding(.horizontal).
                        // detailsSheet uses padding(.horizontal) on container or components?
                        // Components like MonitoringPlan use .padding(.horizontal) at the end.
                        // So just calling `nonPharmSection` should be fine, but let's check its definition again.
                        // It has .padding(.horizontal) at the end.
                        // I will just insert `nonPharmSection` here.

                    
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
                                RecommendationCard(rec: rec, activeMonographDrug: $activeMonographDrug)
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
        .sheet(item: $activeMonographDrug) { drug in
            NavigationView {
                DrugMonographView(drug: drug, patientContext: store)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") { activeMonographDrug = nil }
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
    @Binding var activeMonographDrug: DrugData? // Added Binding
    @State private var showDetails = false
    var color: Color {
        switch rec.type {
        case .safe: return ClinicalTheme.teal500
        case .caution: return ClinicalTheme.amber500
        case .unsafe: return ClinicalTheme.rose500
        }
    }

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var store: AssessmentStore
    
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
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(rec.type == .safe ? "Preferred" : "Monitor")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.15))
                            .foregroundColor(color)
                            .cornerRadius(6)
                        
                        if let profile = rec.durationProfile {
                            Text(profile.rawValue)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(profile.color.opacity(0.15))
                                .foregroundColor(profile.color)
                                .cornerRadius(6)
                        }
                    }
                }
                
                // Detail Text
                Text(rec.detail)
                    .font(.subheadline)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading) // Ensure left alignment
                
                // Citation Link (User Request)
                if let linkedDrug = ClinicalData.drugData.first(where: { rec.name.localizedCaseInsensitiveContains($0.name) }) {
                   Button(action: { activeMonographDrug = linkedDrug }) {
                       Text("citations")
                           .font(.caption2)
                           .italic()
                           .foregroundColor(.gray)
                   }
                   .padding(.top, 2)
                   .buttonStyle(PlainButtonStyle()) // Ensure it doesn't trigger parent row tap
               }
               
               // MARK: - Safety Alerts (e.g. Tube Feed)
               if store.gi == .tube {
                   HStack(spacing: 8) {
                       Image(systemName: "exclamationmark.triangle.fill")
                           .foregroundColor(ClinicalTheme.amber500)
                       Text("Liquid formulation required. Do not crush ER.")
                           .font(.caption)
                           .fontWeight(.bold)
                           .foregroundColor(ClinicalTheme.textSecondary)
                   }
                   .padding(8)
                   .background(ClinicalTheme.amber500.opacity(0.1))
                   .cornerRadius(6)
                   .padding(.top, 4)
               }

                
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
                            
                            // PK Grid (Vertical Stack)
                            VStack(alignment: .leading, spacing: 8) {
                                // PO Profile
                                if !drug.poOnset.contains("N/A") && !drug.poOnset.isEmpty {
                                    HStack {
                                        Text("PO Profile").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase).frame(width: 80, alignment: .leading)
                                        Text("\(drug.poOnset) onset / \(drug.poDuration) duration").font(.caption).foregroundColor(ClinicalTheme.textPrimary)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(ClinicalTheme.backgroundMain)
                                    .cornerRadius(8)
                                }
                                
                                // IV Profile
                                if !drug.ivOnset.contains("N/A") && !drug.ivOnset.isEmpty {
                                    HStack {
                                        Text("IV Profile").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase).frame(width: 80, alignment: .leading)
                                        Text("\(drug.ivOnset) onset / \(drug.ivDuration) duration").font(.caption).foregroundColor(ClinicalTheme.textPrimary)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(ClinicalTheme.backgroundMain)
                                    .cornerRadius(8)
                                }
                                
                                // Bioavailability (Graphical Bar)
                                if drug.bioavailability > 0 {
                                    HStack(spacing: 12) {
                                        Text("Oral Bio")
                                            .font(.caption2)
                                            .fontWeight(.black)
                                            .foregroundColor(ClinicalTheme.textSecondary)
                                            .textCase(.uppercase)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        // Flexible Bar
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.gray.opacity(0.15))
                                                    .frame(height: 8)
                                                
                                                Capsule()
                                                    .fill(ClinicalTheme.teal500)
                                                    .frame(width: geo.size.width * min(CGFloat(drug.bioavailability) / 100.0, 1.0), height: 8)
                                            }
                                            // Center vertically within the reader
                                            .frame(height: 8)
                                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                        }
                                        .frame(height: 12) // Slightly taller than bar to allow padding
                                        
                                        Text("\(drug.bioavailability)%")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(ClinicalTheme.teal500)
                                            .frame(width: 32, alignment: .trailing)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(ClinicalTheme.backgroundMain)
                                    .cornerRadius(8)
                                }
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
