import SwiftUI
import UIKit

// v1.5.1 verified
struct CalculatorView: View {
    @ObservedObject var store: CalculatorStore
    
    // Initializer for Injection
    init(sharedStore: CalculatorStore? = nil) {
        self._store = ObservedObject(wrappedValue: sharedStore ?? CalculatorStore())
    }
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var assessmentStore: AssessmentStore // Sync with Assessment tab
    
    // UI State
    @State private var showAddDrugSheet = false


    @State private var expandedInfoTab: String? = nil // Collapsed by default (User Feedback)
    @State private var showMathSheet = false // Show Math Feature
    
    // Mode State
    enum CalculatorMode: String, CaseIterable {
        case dosing = "Dosing"
        case taper = "Taper Schedule"
    }
    @State private var calculatorMode: CalculatorMode = .dosing
    
    // Taper Sync State (Hoisted from TaperScheduleView)
    @State private var taperStartMME: String = ""
    @State private var hasTaperOverride: Bool = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                
                // BACKGROUND
                ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    
                    // MARK: - MODE SELECTOR
                    Picker("Mode", selection: $calculatorMode) {
                        ForEach(CalculatorMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 10)
                .onChange(of: calculatorMode) { _, mode in
                    UIApplication.shared.endEditing() // Dismiss keyboard to prevent glitch
                    if mode == .taper {
                        // Sync Logic: Only update if user hasn't manually overridden the taper value
                        // and if we have a valid calculator result.
                        if !hasTaperOverride {
                            if store.resultMME != "0" && store.resultMME != "---" {
                                taperStartMME = store.resultMME
                            }
                        }
                    }
                }

                    if calculatorMode == .dosing {
                        // MARK: - 1. PINNED RESULT CARD (Hero)
                        headerSection
                        
                        // MARK: - 2. SCROLLABLE CONTENT
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                
                                // A. ACTIVE MEDICATIONS LIST
                                activeMedsList
                                
                                // B. CLINICAL CONTEXT & SAFETY (Redesigned v1.5.5)
                                clinicalContextView
                                
                                // C. ESTIMATED TARGETS
                                targetsSection
                                

                                infoSection
                            }
                            .padding(.bottom, 100)
                        }
                    } else {
                        // MARK: - TAPER SCHEDULE
                        TaperScheduleView(
                            startMME: $taperStartMME,
                            hasOverride: $hasTaperOverride
                        )
                            .transition(.opacity)
                    }
                }
            }
            .navigationTitle("MME Calculator")
            .navigationBarTitleDisplayMode(.inline)
            // Removed redundant done button modifier
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if calculatorMode == .dosing {
                            Button(action: copyToClipboard) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(ClinicalTheme.teal500)
                            }
                        }
                        
                        Button(action: {
                            withAnimation {
                                themeManager.isDarkMode.toggle()
                            }
                        }) {
                            Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.stars.fill")
                                .foregroundColor(ClinicalTheme.teal500)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddDrugSheet) {
                AddDrugSheet(store: store, isPresented: $showAddDrugSheet)
            }
            .sheet(isPresented: $showMathSheet) {
                 MathReceiptView(receipt: store.calculationReceipt, total: store.resultMME)
            }

            .overlay(alignment: .top) {
            }
            .overlay {
                if store.isPediatric {
                    PediatricLockScreen()
                        .zIndex(200)
                }
            }
            // Sync with Assessment Store
            .onAppear { syncWithAssessment() }
            .onReceive(assessmentStore.didUpdate) { _ in syncWithAssessment() }
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
            .addKeyboardDoneButton()
        }
    }
    
    private func syncWithAssessment() {
        store.giStatus = assessmentStore.gi
        store.renalStatus = assessmentStore.renalFunction
        store.hepaticStatus = assessmentStore.hepaticFunction
        store.painType = assessmentStore.painType
        store.isPregnant = assessmentStore.isPregnant
        store.age = Int(assessmentStore.age) ?? 30
        store.matchesBenzos = assessmentStore.benzos
        store.sleepApnea = assessmentStore.sleepApnea
        store.historyOverdose = assessmentStore.historyOverdose
    }
    
    // MARK: - GENERATE NOTE
    func copyToClipboard() {
        let note = """
        Opioid Risk & Stewardship Note
        -------------------------------
        PRODIGY Risk Score: \(assessmentStore.prodigyScore) (\(assessmentStore.prodigyRisk) Risk).
        
        Risk Analysis:
        - Renal Function: \(assessmentStore.renalFunction.rawValue)
        - Hepatic Function: \(assessmentStore.hepaticFunction.rawValue)
        - Comorbidities: \(assessmentStore.sleepApnea ? "OSA, " : "")\(assessmentStore.benzos ? "Concurrent Benzos, " : "")\(assessmentStore.historyOverdose ? "Hx Overdose/SUD, " : "")\(assessmentStore.psychHistory ? "Psych Hx" : "None checked")
        
        MME Calculation:
        - Total 24h MME: \(store.resultMME)
        \(store.inputs.filter{ $0.isVisible }.map{ "- \($0.name): \($0.dose) \($0.routeType == .patch ? "mcg/hr" : "mg")" }.joined(separator: "\n"))
        
        Plan:
        \(store.warningText.isEmpty ? "- Standard monitoring" : "- Caution: High Risk. " + store.warningText)
        - PDMP Checked.
        """
        UIPasteboard.general.string = note
    }
}


// MARK: - COMPONENT SUBVIEWS

struct ActiveMedicationRow: View {
    let input: CalculatorInput
    @ObservedObject var store: CalculatorStore
    
    var body: some View {
        HStack(spacing: 12) {
            // Label
            VStack(alignment: .leading, spacing: 0) {
                Text(input.name)
                    .font(.system(size: 16, weight: .semibold)) // Explicit Hierarchy
                    .foregroundColor(ClinicalTheme.textPrimary)
                
                Text(routeLabel(for: input.routeType))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .padding(.top, 2) // Separation
                    
                // SAFETY: Inline Contraindication Warning
                if shouldFlagContraindication(for: input) {
                    Text("⛔️ CONTRAINDICATED")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ClinicalTheme.rose500)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Input Field
            HStack(spacing: 4) {
                TextField("0", text: Binding(
                    get: { input.dose },
                    set: { store.updateDose(for: input.id, dose: $0) }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(TextAlignment.trailing)
                .font(Font.body.monospacedDigit().bold())
                .foregroundColor(ClinicalTheme.teal500)
                .frame(width: 70)
                
                // Unit Label
                Text(unitLabel(for: input.routeType))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .frame(width: 45, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(height: 44) // Standard Touch Target
            .background(ClinicalTheme.backgroundInput)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(shouldFlagContraindication(for: input) ? ClinicalTheme.rose500 : Color.clear, lineWidth: 2)
            )
            
            // FAT FINGER CHECK (Extreme Dose)
            if isExtremeDose(input) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(ClinicalTheme.amber500)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { store.removeInput(inputId: input.id) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func routeLabel(for type: DrugRouteType) -> String {
        switch type {
        case .ivDrip: return "Continuous Infusion"
        case .patch: return "Transdermal"
        case .ivPush: return "IV Push / SC"
        default: return "Oral / Enteral"
        }
    }
    
    func unitLabel(for type: DrugRouteType) -> String {
        switch type {
        case .ivDrip: return "mg/hr"
        case .patch: return "mcg/hr"
        case .microgramIO: return "mcg"
        default: return "mg"
        }
    }
    
    // Helper: Check for specific "AVOID" warnings in the store text matching this drug
    func shouldFlagContraindication(for input: CalculatorInput) -> Bool {
        return store.warningText.uppercased().contains("AVOID \(input.name.uppercased())") || 
               store.warningText.uppercased().contains("CONTRAINDICATED") && input.name == "Morphine" && store.renalStatus == .dialysis // Fallback exact check
    }
    
    // Helper: Fat Finger Logic
    func isExtremeDose(_ input: CalculatorInput) -> Bool {
        guard let val = Double(input.dose) else { return false }
        
        // Thresholds
        if input.routeType == .ivPush || input.routeType == .ivDrip {
             if input.name.contains("Hydromorphone") && val > 4.0 { return true }
             if input.name.contains("Morphine") && val > 20.0 { return true }
             if input.name.contains("Fentanyl") && val > 200.0 { return true } // mcg
        } else {
             // PO
             if input.name.contains("Oxycodone") && val > 120.0 { return true }
             if input.name.contains("Morphine") && val > 200.0 { return true }
        }
        return false
    }
}

struct EmptyStateView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.dashed")
                    .font(.system(size: 44))
                    .foregroundColor(ClinicalTheme.textMuted.opacity(0.5))
                
                VStack(spacing: 4) {
                    Text("No Medications Added")
                        .font(.headline)
                        .foregroundColor(ClinicalTheme.textSecondary)
                    Text("Tap to add your first drug")
                        .font(.subheadline)
                        .foregroundColor(ClinicalTheme.teal500)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(ClinicalTheme.backgroundCard.opacity(0.5))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [5])))
        }
        .padding(.horizontal)
    }
}



struct AlgorithmTransparencyCard: View {
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "chart.bar.doc.horizontal")
                    Text("Algorithm Transparency")
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(Font.caption.weight(.bold))
                .foregroundColor(ClinicalTheme.textSecondary)
                .padding()
                .background(ClinicalTheme.backgroundCard)
            }
            
            if isExpanded {
                Divider().background(ClinicalTheme.divider)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Opioid Potency (Oral MME Factor)")
                        .font(.caption).bold()
                        .foregroundColor(ClinicalTheme.textPrimary)
                    
                    PotencyBar(label: "Morphine", factor: 1.0, color: ClinicalTheme.teal500)
                    PotencyBar(label: "Oxycodone", factor: 1.5, color: ClinicalTheme.amber500)
                    PotencyBar(label: "Hydromorphone", factor: 4.0, color: ClinicalTheme.rose500) // CDC 2022 (4-5x)
                    
                    Text("Equianalgesic factors based on CDC 2022 Guidelines.")
                        .font(.caption2)
                        .foregroundColor(ClinicalTheme.textSecondary)
                        .padding(.top, 4)
                }
                .padding()
                .background(ClinicalTheme.backgroundMain.opacity(0.3))
            }
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
    }
}

// Potency Bar Component (Local Definition)
struct PotencyBar: View {
    let label: String
    let factor: Double
    let color: Color
    var isScaleBreak: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .bold()
                .foregroundColor(ClinicalTheme.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(ClinicalTheme.backgroundInput).frame(height: 8)
                    if isScaleBreak {
                        Capsule().fill(color).frame(width: geo.size.width, height: 8)
                            .overlay(Text("100x+").font(.caption2).bold().foregroundColor(.white).padding(.leading, 4), alignment: .leading)
                    } else {
                        Capsule().fill(color).frame(width: geo.size.width * CGFloat(factor / 5.0), height: 8)
                    }
                }
            }
            .frame(height: 8)
            
            Text("\(String(format: "%.1f", factor))x")
                .font(.caption)
                .bold()
                .foregroundColor(ClinicalTheme.textPrimary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}



// MARK: - INFO ACCORDION (MDCalc Style)

struct InfoAccordion: View {
    let title: String
    let icon: String
    let content: String
    @Binding var expandedItem: String?
    
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
                Text(content)
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClinicalTheme.backgroundMain)
            }
            
            if title != "Evidence (CDC 2022)" { // Hide divider on last item
                Divider()
            }
        }
    }
}

// MARK: - CONTENT DATA

struct InfoContent {
    static let instructions = """
    • Use for converting Oral/IV opioids to Oral Targets.
    • For combination drugs (e.g. Percocet), enter only the opioid component (e.g., 5mg).
    • Do NOT use for pediatric patients.
    • Buprenorphine is excluded due to partial agonism.
    """
    
    static let algorithm = """
    Transparent Calculation Logic:
    MME = Sum(Daily Dose × Factor)
    
    Factors Used:
    • Morphine PO: 1.0 (CDC Standard)
    • Morphine IV: 3.0
    • Hydromorphone PO: 5.0 (CDC 2022)
    • Hydromorphone IV: 20.0
    • Oxycodone: 1.5
    • Hydrocodone: 1.0
    • Oxymorphone: 3.0
    • Codeine: 0.15
    • Tramadol: 0.1
    • Tapentadol: 0.4
    • Meperidine: 0.1
    • Fentanyl Patch: 2.4 (x mcg/hr)
    • Fentanyl IV: 100 (0.1mg = 10 MME)
    
    Logic:
    1. Calculate Total MME.
    2. Subtract Reduction % (Cross-tolerance).
    3. Calculate Target Doses using same factors.
    """
    
    static let pearls = """
    • There is no completely safe opioid dose.
    • CDC Guidelines recommend prescribing the lowest effective dose.
    • Caution >50 MME/day. Avoid >90 MME/day without justification.
    • AVOID concurrent benzodiazepines (increases overdose risk 4x).
    """
    
    static let evidence = """
    Conversions based on CDC Clinical Practice Guideline for Prescribing Opioids for Pain (2022).
    
    • Morphine: 1.0 (Chronic). Acute IV:PO may range 1:6.
    • Hydrocodone: 1.0
    • Oxycodone: 1.5
    • Hydromorphone PO: 5.0 (Updated CDC 2022). Range 3.7-5:1.
    • Fentanyl Patch: 2.4 (Conservative)
    
    Dowell D, et al. CDC Clinical Practice Guideline for Prescribing Opioids for Pain. MMWR Recomm Rep 2022.
    """
}

// Add Drug Sheet
struct AddDrugSheet: View {
    @ObservedObject var store: CalculatorStore
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.inputs.filter { !$0.isVisible }) { input in
                    Button(action: {
                        store.addInput(inputId: input.id)
                        isPresented = false
                    }) {
                        HStack {
                            Text(input.name).foregroundColor(ClinicalTheme.textPrimary)
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundColor(ClinicalTheme.teal500)
                        }
                    }
                }
            }
            .navigationTitle("Add Medication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
             .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}

struct TargetDoseCard: View {
    let dose: TargetDose
    var sortPreference: OpioidRoute = .po // Added for visual dimming
    @EnvironmentObject var themeManager: ThemeManager

    
    var body: some View {
        VStack(spacing: 0) { // Wrapped in VStack for collapsible section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(dose.drug) \(dose.route)")
                        .font(.headline)
                        .foregroundColor(ClinicalTheme.textPrimary)
                    Text(dose.ratioLabel)
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    // Visual Indicator for Safety Adjustments
                    if let original = dose.originalDaily {
                        Text(original)
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(ClinicalTheme.textMuted)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(dose.totalDaily)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(dose.originalDaily != nil ? ClinicalTheme.amber500 : ClinicalTheme.teal500)
                        Text(dose.unit + (dose.unit.contains("/hr") ? "" : "/24h"))
                            .font(.caption)
                            .scaleEffect(0.8)
                            .foregroundColor(ClinicalTheme.textSecondary)
                    }
                    Text("BT: \(dose.breakthrough) \(dose.unit) q2-4h")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ClinicalTheme.teal500.opacity(0.15))
                        .foregroundColor(ClinicalTheme.teal500)
                        .cornerRadius(4)
                }
            }
        }
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        .padding(.horizontal)
        .opacity(isDimmed ? 0.5 : 1.0)
    }

    // Helper: Dim Cards based on Priority
    var isDimmed: Bool {
        if sortPreference == .po {
             // If wanting PO, dim IV
             return dose.route == "IV"
        } else if sortPreference == .iv {
             // If wanting IV, dim PO
             return dose.route.contains("PO")
        }
        return false
    }
}


// MARK: - SAFETY OVERLAYS

struct PediatricLockScreen: View {
    var body: some View {
        ZStack {
            ClinicalTheme.backgroundMain.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "figure.child.and.lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(ClinicalTheme.rose500)
                
                Text("Pediatric Patient Detected")
                    .font(.title2).bold()
                    .foregroundColor(ClinicalTheme.textPrimary)
                
                Text("This calculator is validated only for adults (18+).\n\nPediatric Opioid Dosing requires weight-based calculations (mg/kg). Please refer to WHO or Pediatric Formulary.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .padding(.horizontal)
                
                Link("Manage in WHO Guidelines", destination: URL(string: "https://www.who.int")!)
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.teal500)
            }
            .padding()
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }
}


// MARK: - MATH RECEIPT
struct MathReceiptView: View {
    @Environment(\.dismiss) var dismiss
    let receipt: [String]
    let total: String // Added property to match usage
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Total: \(total) MME").font(.headline)) {
                    ForEach(receipt, id: \.self) { line in
                        Text(line)
                            .font(.custom("Menlo", size: 14)) // Monospaced for math
                            .foregroundColor(ClinicalTheme.textPrimary)
                    }
                }
            }
            .navigationTitle("Math Receipt")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

extension CalculatorView {
    var clinicalContextView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cross.case.fill").foregroundColor(ClinicalTheme.teal500)
                Text("Clinical Context").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                // 1. Route Preference
                Picker("Route Preference", selection: $store.routePreference) {
                    Text("Oral Preferred (PO)").tag(OpioidRoute.po)
                    Text("IV / SubQ Priority").tag(OpioidRoute.iv)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Divider().padding(.vertical, 4)
                
                // 2. Safety Toggles (Binary - Synced with Assessment Tab)
                Toggle(isOn: $assessmentStore.isRenalImpaired) {
                    VStack(alignment: .leading) {
                        Text("Renal Impairment").font(.subheadline).fontWeight(.bold).foregroundColor(ClinicalTheme.textPrimary)
                        Text("eGFR <60 (CKD 3+)").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.amber500))
                
                // Renal Escalation Footer (v1.5.5 Safety)
                if assessmentStore.renalFunction != .normal {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(assessmentStore.renalFunction == .dialysis ? ClinicalTheme.rose500 : ClinicalTheme.amber500)
                            Text("Status: \(assessmentStore.renalFunction.rawValue)")
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                        
                        Text("Dialysis status requires strict avoidance of Morphine/Codeine/Meperidine due to neurotoxic metabolite accumulation.")
                            .font(.system(size: 10))
                            .foregroundColor(ClinicalTheme.textSecondary)
                        
                        Button(action: {
                            withAnimation {
                                assessmentStore.renalFunction = (assessmentStore.renalFunction == .dialysis) ? .impaired : .dialysis
                            }
                        }) {
                            Text(assessmentStore.renalFunction == .dialysis ? "Revert to Standard CKD" : "Escalate to Dialysis")
                                .font(.caption2).fontWeight(.bold)
                                .foregroundColor(assessmentStore.renalFunction == .dialysis ? ClinicalTheme.teal500 : ClinicalTheme.rose500)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background((assessmentStore.renalFunction == .dialysis ? ClinicalTheme.teal500 : ClinicalTheme.rose500).opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(ClinicalTheme.backgroundMain.opacity(0.5))
                    .cornerRadius(8)
                }
                
                Toggle(isOn: $assessmentStore.isHepaticImpaired) {
                    VStack(alignment: .leading) {
                        Text("Hepatic Impairment").font(.subheadline).fontWeight(.bold).foregroundColor(ClinicalTheme.textPrimary)
                        Text("Child-Pugh B+").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.amber500))
                
                // Hepatic Escalation Footer (v1.5.5 Safety)
                if assessmentStore.hepaticFunction != .normal {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(assessmentStore.hepaticFunction == .failure ? ClinicalTheme.rose500 : ClinicalTheme.amber500)
                            Text("Status: \(assessmentStore.hepaticFunction.rawValue)")
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                        
                        Text("Liver Failure (Child-Pugh C) increases Hydromorphone PO bioavailability 4x via portosystemic shunting.")
                            .font(.system(size: 10))
                            .foregroundColor(ClinicalTheme.textSecondary)
                        
                        Button(action: {
                            withAnimation {
                                assessmentStore.hepaticFunction = (assessmentStore.hepaticFunction == .failure) ? .impaired : .failure
                            }
                        }) {
                            Text(assessmentStore.hepaticFunction == .failure ? "Revert to Moderate Impairment" : "Escalate to Liver Failure (Child-Pugh C)")
                                .font(.caption2).fontWeight(.bold)
                                .foregroundColor(assessmentStore.hepaticFunction == .failure ? ClinicalTheme.teal500 : ClinicalTheme.rose500)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background((assessmentStore.hepaticFunction == .failure ? ClinicalTheme.teal500 : ClinicalTheme.rose500).opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(ClinicalTheme.backgroundMain.opacity(0.5))
                    .cornerRadius(8)
                }
                
                Divider().padding(.vertical, 4)
                
                // 3. Tolerance & Reduction
                HStack {
                    Text("Correction").font(.subheadline).foregroundColor(ClinicalTheme.textSecondary)
                    Spacer()
                    Text("-\(Int(store.reduction))%").font(.headline).fontWeight(.bold).foregroundColor(ClinicalTheme.teal500)
                }
                Slider(value: $store.reduction, in: 0...75, step: 5)
                    .accentColor(ClinicalTheme.teal500)
            }
            .padding()
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            .padding(.horizontal)
            
            // LOGIC CLARIFICATION
            if assessmentStore.renalFunction != .normal || assessmentStore.hepaticFunction != .normal {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled").foregroundColor(ClinicalTheme.teal500)
                    Text("Safety Logic: Renal/Hepatic restrictions applied IN ADDITION to this reduction.")
                        .font(.caption2)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

extension CalculatorView {
    var activeMedsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Medications").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
                Spacer()
                Button(action: { showAddDrugSheet = true }) {
                    Label("Add Drug", systemImage: "plus")
                        .font(Font.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ClinicalTheme.teal500)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            if store.inputs.filter({ $0.isVisible }).isEmpty {
                EmptyStateView(action: { showAddDrugSheet = true })
            } else {
                List {
                    ForEach(store.inputs.filter { $0.isVisible }) { input in
                        ActiveMedicationRow(input: input, store: store)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(.plain)
                .frame(height: CGFloat(store.inputs.filter { $0.isVisible }.count) * 92) // Exact height for 76pt card + 16pt spacing
            }
        }
    }
}

extension CalculatorView {
    var infoSection: some View {
        Group {
            // E. CLINICAL CONTEXT (MDCalc Style)
            // Instructions, Pearls, Evidence
            VStack(spacing: 1) {
                InfoAccordion(title: "Instructions & Warnings", icon: "exclamationmark.circle", content: InfoContent.instructions, expandedItem: $expandedInfoTab)
                MergedAlgorithmTransparencyAccordion(expandedItem: $expandedInfoTab)
                InfoAccordion(title: "Pearls & Pitfalls", icon: "lightbulb", content: InfoContent.pearls, expandedItem: $expandedInfoTab)
                InfoAccordion(title: "Evidence (CDC 2022)", icon: "book.closed", content: InfoContent.evidence, expandedItem: $expandedInfoTab)
            }
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [5])))
            .padding(.horizontal)
            .padding(.bottom, 140)
            
            Spacer().frame(height: 100)
        }
    }
}

extension CalculatorView {
    var targetsSection: some View {
        Group {
            if !store.targetDoses.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Estimated Targets").font(.headline).foregroundColor(ClinicalTheme.textSecondary).padding(.horizontal)
                    
                    ForEach(store.targetDoses) { dose in
                        TargetDoseCard(dose: dose, sortPreference: store.routePreference)
                    }
                    

                }
            }
        }
    }
}

extension CalculatorView {
    var headerSection: some View {
        VStack(spacing: 12) {
            ScoreResultCard(
                title: "Total 24h MME",
                subtitle: "Oral Morphine Equivalents",
                value: store.resultMME,
                valueLabel: "mg daily",
                badgeText: store.resultMME == "---" ? "Exclusion" : "Daily Load",
                badgeColor: store.resultMME == "---" ? ClinicalTheme.amber500 : ClinicalTheme.teal500
            )
            .padding(.horizontal)
            
            // Stewardship Warning (Pinned Below Card)
            if !store.warningText.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(ClinicalTheme.amber500)
                        .font(.headline)
                    Text(store.warningText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(12)
                .background(ClinicalTheme.amber500.opacity(0.1))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.amber500.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 12)
        .background(ClinicalTheme.backgroundMain) // Opaque background for pinning
        .zIndex(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
    }
}
