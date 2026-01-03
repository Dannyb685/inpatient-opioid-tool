import SwiftUI
import Combine
import Charts

struct TaperScheduleView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    // Taper Configuration State
    // Taper Configuration State (Now Hoisted)
    @State private var useLongDuration: Bool = false // False = Short (<1yr), True = Long (>1yr)
    // Default to 10% reduction per MME step
    @State private var reductionPerStep: Double = 10 
    
    // Reverse Conversion State
    @State private var selectedTaperDrug: TaperDrug = .morphinePO
    
    enum TaperDrug: String, CaseIterable, Identifiable {
        case mmeOnly = "MME Only (No Conversion)"
        case morphinePO = "Morphine PO"
        case oxycodonePO = "Oxycodone PO"
        case hydrocodonePO = "Hydrocodone PO"
        case hydromorphonePO = "Hydromorphone PO"
        case tramadolPO = "Tramadol PO"
        
        var id: String { self.rawValue }
        
        func conversionFactor(assessment: AssessmentStore) -> Double {
            switch self {
            case .mmeOnly: return 1.0
            case .morphinePO:
                // Renal Safety: Morphine metabolites accumulate
                if assessment.renalFunction == .dialysis { return 0.0 } // CONTRAINDICATED
                if assessment.renalFunction == .impaired { return 1.0 * 0.75 } // 25% reduction
                return 1.0
            case .oxycodonePO: return 1.5
            case .hydrocodonePO: return 1.0
            case .hydromorphonePO:
                // 1. Hepatic Failure (Priority Risk: Shunting)
                if assessment.hepaticFunction == .failure { return 0.0 } // CONTRAINDICATED (Consult Specialist)
                
                // 2. Renal Safety (Metabolite H3G)
                if assessment.renalFunction == .dialysis { return 5.0 * 0.25 } // 75% reduction
                if assessment.renalFunction == .impaired { return 5.0 * 0.5 } // 50% reduction
                
                return 5.0 // Updated CDC 2022 Ratio
            case .tramadolPO:
                 // Renal Safety
                 if assessment.renalFunction != .normal { return 0.2 * 0.5 } // 50% reduction per label
                 return 0.2
            }
        }
        
        func safetyWarning(assessment: AssessmentStore) -> (String, Color)? {
            switch self {
            case .morphinePO:
                 if assessment.renalFunction == .dialysis { return ("⛔️ CONTRAINDICATED: Avoid Morphine in Dialysis (Neurotoxic Metabolites)", ClinicalTheme.rose500) }
                 if assessment.renalFunction == .impaired { return ("⚠️ Renal Impairment: Dose reduced 25%", ClinicalTheme.amber500) }
            case .hydromorphonePO:
                 if assessment.hepaticFunction == .failure { return ("⛔️ CONTRAINDICATED: Avoid Hydromorphone in Liver Failure (Shunt Risk)", ClinicalTheme.rose500) }
                 if assessment.renalFunction == .dialysis || assessment.renalFunction == .impaired { return ("⚠️ Renal Impairment: Dose reduced \(assessment.renalFunction == .dialysis ? "75%" : "50%")", ClinicalTheme.amber500) }
            case .tramadolPO:
                 if assessment.renalFunction != .normal { return ("⚠️ Renal Impairment: Dose reduced 50%", ClinicalTheme.amber500) }
            default: return nil
            }
            return nil
        }
        
        var unit: String {
            return self == .mmeOnly ? "MME" : "mg"
        }
    }
    
    // Safety Gates
    @EnvironmentObject var assessmentStore: AssessmentStore
    @State private var showWithdrawalWarning: Bool = true
    @State private var showChart: Bool = false
    
    // Hoisted State
    @Binding var startMME: String
    @Binding var hasOverride: Bool
    
    init(startMME: Binding<String>, hasOverride: Binding<Bool>) {
        self._startMME = startMME
        self._hasOverride = hasOverride
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 1. INPUTS & CONTEXT CARD
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Clinical Data").font(.headline)
                    }
                    .foregroundColor(ClinicalTheme.textSecondary)
                    
                    // MME Input
                    HStack(spacing: 12) {
                        Text("Starting daily dose:")
                            .foregroundColor(ClinicalTheme.textPrimary)
                        
                        TextField("Total MME/Day", text: $startMME, onEditingChanged: { isEditing in
                            if isEditing { hasOverride = true }
                        })
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(ClinicalTheme.backgroundInput)
                            .cornerRadius(8)
                            .overlay(
                                HStack {
                                    Spacer()
                                    Text("MME")
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                        .padding(.trailing, 8)
                                }
                            )
                    }
                    
                    Divider()
                    
                    // Pregnancy Gate (Moved to Top)
                    Toggle(isOn: $assessmentStore.isPregnant) {
                        Text("Pregnant Person").font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                    
                    if assessmentStore.isPregnant {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(ClinicalTheme.rose500)
                            Text("Specialist Required. Withdrawal risk to fetus.")
                                .font(.caption).bold().foregroundColor(ClinicalTheme.rose500)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(8)
                        .background(ClinicalTheme.rose500.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Medication Converter (Moved to Top)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Medication").font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
                        
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundColor(ClinicalTheme.teal500)
                            Picker("Taper Medication", selection: $selectedTaperDrug) {
                                ForEach(TaperDrug.allCases) { drug in
                                    Text(drug.rawValue).tag(drug)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .accentColor(ClinicalTheme.teal500)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                         .background(ClinicalTheme.backgroundInput)
                         .cornerRadius(8)
                        
                        // Safety Warning Banner (Moved here)
                        if let warning = selectedTaperDrug.safetyWarning(assessment: assessmentStore) {
                            HStack(spacing: 8) {
                                Image(systemName: warning.1 == ClinicalTheme.rose500 ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(warning.1)
                                Text(warning.0)
                                    .font(.caption).bold()
                                    .foregroundColor(warning.1)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(warning.1.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if selectedTaperDrug != .mmeOnly {
                            Text("Schedule will show estimated \(selectedTaperDrug.unit) dose based on MME.")
                                .font(.caption2)
                                .italic()
                                .foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                }
                .clinicalCard()
                .padding(.horizontal)
                
                // 2. STRATEGY CARD
                 VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Taper Strategy").font(.headline)
                    }
                    .foregroundColor(ClinicalTheme.textSecondary)
                    
                    // Duration Strategy
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration of Therapy").font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
                        
                        Picker("Duration", selection: $useLongDuration) {
                            Text("Short (<1 Year)").tag(false)
                            Text("Long (≥1 Year)").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "info.circle").font(.caption).foregroundColor(ClinicalTheme.teal500)
                            Text(useLongDuration
                                 ? "Strategy: Slow Taper (10% Monthly). Better tolerated for long-term use."
                                 : "Strategy: CDC 2-Phase (10% Weekly Linear → 10% Exponential).")
                                .font(.caption).italic().foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                    
                    Divider()
                    
                    // Reduction Velocity (Finer Control)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Reduction Rate").font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
                            Spacer()
                            if reductionPerStep > 25 {
                                Text("⚠️ \(Int(reductionPerStep))% (Fast)").font(.headline).bold().foregroundColor(ClinicalTheme.amber500)
                            } else {
                                Text("\(Int(reductionPerStep))%").font(.headline).bold().foregroundColor(ClinicalTheme.teal500)
                            }
                        }
                        
                        // Finer Step for 1-50 range (User Requested 0-10% granularity)
                        Slider(value: $reductionPerStep, in: 1...50, step: 1)
                            .accentColor(ClinicalTheme.teal500)
                        
                        HStack {
                            Text("Slower").font(.caption2).foregroundColor(.secondary)
                            Spacer()
                            Text("Faster").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
                .clinicalCard()
                .padding(.horizontal)
                
                // MARK: - ALGORITHM TRANSPARENCY CARD
                VStack(alignment: .leading, spacing: 0) {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider().padding(.vertical, 4)
                            
                            Text("Tapering Protocol (CDC 2022)")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                            
                            HStack(alignment: .top) {
                                Text("•").bold()
                                Text("Short-Term (<1yr): Uses '2-Phase' logic. Phase 1 is Linear (10% of BASELINE dose) until 30% remains. Phase 2 is Exponential (10% of CURRENT dose) to prevent withdrawal at low thresholds.")
                            }
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            
                            HStack(alignment: .top) {
                                Text("•").bold()
                                Text("Long-Term (≥1yr): Uses 'Slow Taper' logic. Pure Exponential reduction (10% of CURRENT dose) performed monthly.")
                            }
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            
                            Divider().padding(.vertical, 4)
                            
                            Text("Reverse Conversion Logic")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                            
                            Text("Drug Dose = Target MME ÷ Factor")
                                .font(.caption.monospaced())
                                .padding(4)
                                .background(ClinicalTheme.backgroundInput)
                                .cornerRadius(4)
                            
                            Text("Factors Used:")
                                .font(.caption).bold()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Oxycodone: 1.5").font(.caption)
                                
                                // Hydromorphone Dynamic Label
                                let hmFactor = TaperDrug.hydromorphonePO.conversionFactor(assessment: assessmentStore)
                                if hmFactor < 4.0 {
                                    Text("• Hydromorphone: \(String(format: "%.1f", hmFactor)) (⚠️ SAFETY REDUCED)").font(.caption).bold().foregroundColor(ClinicalTheme.amber500)
                                } else {
                                     Text("• Hydromorphone: 4.0 (Conservative)").font(.caption)
                                }
                                
                                Text("• Tramadol: 0.1").font(.caption)
                            }
                            .foregroundColor(ClinicalTheme.textSecondary)
                        }
                        .padding(.top, 8)
                        
                    } label: {
                        HStack {
                            Image(systemName: "function")
                                .foregroundColor(ClinicalTheme.teal500)
                            Text("Algorithm & Evidence")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                    }
                }
                .clinicalCard()
                .padding(.horizontal)
                
                // 2. GENERATED SCHEDULE
                if let start = Double(startMME), start > 0, !assessmentStore.isPregnant {
                    let factor = selectedTaperDrug.conversionFactor(assessment: assessmentStore)
                    
                    // BLOCK if Factor is 0 (Contraindicated)
                    if factor > 0 {
                        let schedule = generateSchedule(start: start)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // VISUALIZE PLAN BUTTON (Collapsible)
                        Button(action: { withAnimation { showChart.toggle() } }) {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                .foregroundColor(ClinicalTheme.teal500)
                                Text("Visualize Plan")
                                    .font(.headline)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showChart ? 90 : 0))
                                    .foregroundColor(ClinicalTheme.textSecondary)
                            }
                            .padding()
                            .background(ClinicalTheme.backgroundCard)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        if showChart {
                            TaperChartVisualizer(schedule: schedule)
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Header
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(ClinicalTheme.teal500)
                            Text("Generated Schedule")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                            Spacer()
                            Button(action: { copySchedule(start: start, schedule: schedule) }) {
                                Image(systemName: "doc.on.doc").foregroundColor(ClinicalTheme.teal500)
                            }
                        }
                        .padding()
                        .background(ClinicalTheme.backgroundCard)
                        
                        Divider()
                        
                        // Steps
                        ForEach(Array(schedule.enumerated()), id: \.offset) { index, step in
                            VStack(spacing: 0) {
                                HStack {
                                    // Time Label
                                    Text(step.label)
                                        .font(.subheadline).bold()
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    // Action / Dose
                                    VStack(alignment: .trailing, spacing: 2) {
                                        // Primary Display (Variable based on selection)
                                        if selectedTaperDrug == .mmeOnly {
                                            Text(step.doseString) // MME
                                                .font(.body).bold()
                                                .foregroundColor(ClinicalTheme.textPrimary)
                                        } else {
                                            // Drug Dose
                                            Text(step.drugDoseString)
                                                .font(.body).bold()
                                                .foregroundColor(ClinicalTheme.textPrimary)
                                            // MME Subtext
                                            Text(step.doseString)
                                                .font(.caption)
                                                .foregroundColor(ClinicalTheme.textSecondary)
                                        }
                                        
                                        
                                        if !step.instruction.isEmpty {
                                            Text(step.instruction)
                                                .font(.caption)
                                                .foregroundColor(ClinicalTheme.amber500)
                                        }
                                    }
                                }
                                .padding()
                                .background(index % 2 == 0 ? ClinicalTheme.backgroundMain.opacity(0.5) : ClinicalTheme.backgroundCard)
                                
                                Divider()
                            }
                        }
                        
                        // Withdrawal Warning Footer
                        if showWithdrawalWarning {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "hand.raised.fill").foregroundColor(ClinicalTheme.amber500)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pause if Withdrawal Occurs").font(.caption).bold().foregroundColor(ClinicalTheme.textPrimary)
                                    Text("Anxiety, insomnia, diaphoresis, tachycardia. Hold dose until resolved.")
                                        .font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                                }
                            }
                            .padding()
                            .background(ClinicalTheme.amber500.opacity(0.1))
                        }
                    }
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    .padding(.horizontal)
                    
                    // Clinical Note: Liquid Formulations
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "drop.fill").foregroundColor(ClinicalTheme.teal500)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Liquid Formulations (<10 MME Daily)").font(.caption).bold().foregroundColor(ClinicalTheme.textPrimary)
                            Text("When tablets limit titration, use Oral Solution (e.g. Oxycodone 5mg/5mL or Morphine 10mg/5mL) to enable small decrements.")
                                .font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Clinical Note: Medical Cannabis (Adjuvant)
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "leaf.fill").foregroundColor(ClinicalTheme.teal500)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Medical Cannabis (Adjuvant)").font(.caption).bold().foregroundColor(ClinicalTheme.textPrimary)
                            Text("Consider as adjuvant for dose reduction (Regulated states only). Evidence suggests potential to lower opioid requirements by 22-51% during taper.")
                                .font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    }
                } else if assessmentStore.isPregnant {
                     // Empty State for Pregnancy Block
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundColor(ClinicalTheme.textMuted)
                        Text("Calculation Blocked")
                            .font(.headline).foregroundColor(ClinicalTheme.textMuted)
                        Text("Please consult addiction specialist or OB/GYN for perinatal opioid management.")
                            .font(.caption).multilineTextAlignment(.center).foregroundColor(ClinicalTheme.textSecondary)
                    }
                    .padding(.vertical, 40)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.bottom, 120)

        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)

    }
    
    // MARK: - Logic Models
    
    struct TaperStep {
        let label: String
        let dose: Double // MME
        let drugDose: Double // Converted Drug Dose
        let drugName: String // Selected Drug Name
        let drugUnit: String
        let instruction: String
        
        var doseString: String {
            if dose < 0.1 { return "Discontinue" }
            return String(format: "%.1f MME/day", dose)
        }
        
        var drugDoseString: String {
            if dose < 0.1 { return "Discontinue" }
            return String(format: "%.1f \(drugUnit)/day \(drugName)", drugDose)
        }
    }
    
    // MARK: - CDC Logic
    
    func generateSchedule(start: Double) -> [TaperStep] {
        var steps: [TaperStep] = []
        let rate = reductionPerStep / 100.0
        var current = start
        
        let factor = selectedTaperDrug.conversionFactor(assessment: assessmentStore)
        guard factor > 0 else { return [] } // Safety Gate
        
        // CDC Short Term Logic
        let threshold30 = start * 0.30
        let linearStep = start * rate
        
        var week = 1
        var heldPreviousStep = false
        
        // Max 50 steps
        for _ in 1...50 {
            var nextDose = 0.0
            var instruction = ""
            
            if !useLongDuration && current > threshold30 {
                 // Phase 1: Linear
                 nextDose = current - linearStep
            } else {
                 // Phase 2 or Long Term: Exponential
                 nextDose = current * (1.0 - rate)
            }
            
            // MINIMUM DECREMENT FLOOR (Prevent Micro-tapering)
            // If the calculated drop is < 1 MME, hold the dose for a week to consolidate, 
            // then drop by a clinically significant amount (= 2 MME or calculated amount) the next week.
            let proposedDrop = current - nextDose
            
            if proposedDrop < 1.0 && current > 5.0 {
                if !heldPreviousStep {
                    // ACTION: HOLD DOSE
                    nextDose = current
                    instruction = "Hold Dose (Consolidate Decrement)"
                    heldPreviousStep = true
                } else {
                    // ACTION: FORCE STEP
                    // Drop by at least 2.0 MME (or the rest if < 2)
                    let forcedDrop = 2.0
                    nextDose = max(0, current - forcedDrop)
                    heldPreviousStep = false // Reset
                }
            } else {
                heldPreviousStep = false
            }
            
            // LOW DOSE HANDLING (< 10 MME)
            if nextDose < 10.0 && nextDose > 0.0 && !instruction.contains("Hold") {
                instruction = "Consider liquid formulations for small decrements"
            }
            
            // Convert to Selected Drug
            // Formula: MME / Factor = Drug Dose
            // e.g. 90 MME / 1.5 (Oxy) = 60mg Oxy
            // Factor already calculated safely above
            let convertedDose = nextDose / factor
            
            let drugNameRaw = selectedTaperDrug == .mmeOnly ? "" : selectedTaperDrug.rawValue.replacingOccurrences(of: " PO", with: "")
            
            if nextDose < 1.0 { // Terminate
                steps.append(TaperStep(
                    label: useLongDuration ? "Month \(week)" : "Week \(week)",
                    dose: 0,
                    drugDose: 0,
                    drugName: drugNameRaw,
                    drugUnit: selectedTaperDrug.unit,
                    instruction: "Discontinue"
                ))
                break
            }
            
            steps.append(TaperStep(
                label: useLongDuration ? "Month \(week)" : "Week \(week)",
                dose: nextDose,
                drugDose: convertedDose,
                drugName: drugNameRaw,
                drugUnit: selectedTaperDrug.unit,
                instruction: instruction
            ))
            
            current = nextDose
            week += 1
        }
        
        return steps
    }
    
    func copySchedule(start: Double, schedule: [TaperStep]) {
        var text = """
        Opioid Taper Plan
        Starting Dose: \(start) MME/day
        Target Medication: \(selectedTaperDrug.rawValue)
        Mode: \(useLongDuration ? "Long Term (>1yr)" : "Short Term (<1yr)")
        Strategy: \(useLongDuration ? "Slow Taper (10% Monthly)" : "CDC 2-Phase Protocol")
        
        """
        
        for step in schedule {
            if selectedTaperDrug == .mmeOnly {
                text += "\(step.label): \(step.doseString) \(step.instruction.isEmpty ? "" : "(\(step.instruction))")\n"
            } else {
                text += "\(step.label): \(step.drugDoseString) [\(step.doseString)] \(step.instruction.isEmpty ? "" : "(\(step.instruction))")\n"
            }
        }
        
        text += "\nWARNING: Pause taper if withdrawal symptoms occur. Consult provider immediately for severe symptoms."
        
        UIPasteboard.general.string = text
    }
}

// MARK: - Visualizer
struct TaperChartVisualizer: View {
    let schedule: [TaperScheduleView.TaperStep]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step-Down Visualization")
                .font(.caption).bold()
                .foregroundColor(ClinicalTheme.textSecondary)
                .padding(.leading, 4)
            
            Chart {
                ForEach(Array(schedule.enumerated()), id: \.offset) { index, step in
                    LineMark(
                        x: .value("Week", index + 1),
                        y: .value("Dose (MME)", step.dose)
                    )
                    .interpolationMethod(.stepEnd) // Creates the "Stair-Step"
                    .foregroundStyle(step.dose < 10 ? ClinicalTheme.amber500 : ClinicalTheme.teal500)
                    .symbol {
                        Circle()
                            .fill(step.dose < 10 ? ClinicalTheme.amber500 : ClinicalTheme.teal500)
                            .frame(width: 6, height: 6)
                    }
                }
                
                // Liquid Threshold
                RuleMark(y: .value("Liquid Threshold", 10))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(.gray.opacity(0.5))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Liquid Form. (<10)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
            }
            .frame(height: 200)
            .padding()
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        }
    }
}
