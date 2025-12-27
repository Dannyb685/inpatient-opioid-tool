import SwiftUI
import Combine

struct TaperScheduleView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    
    // Taper Configuration State
    @State private var drugName: String
    @State private var currentDose: String
    @State private var useLongDuration: Bool = false // False = Short (<1yr), True = Long (>1yr)
    @State private var reductionPerStep: Double = 10 // Default 10%
    
    // Safety Gates
    // Safety Gates
    @EnvironmentObject var assessmentStore: AssessmentStore
    @State private var showWithdrawalWarning: Bool = true
    
    // Optional Calculator Source (for Sync)
    var calculatorStore: CalculatorStore?
    
    init(calculatorStore: CalculatorStore? = nil) {
        self.calculatorStore = calculatorStore
        _drugName = State(initialValue: "")
        _currentDose = State(initialValue: "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 1. CONFIGURATION CARD
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Taper Configuration").font(.headline)
                        }
                        .foregroundColor(ClinicalTheme.textSecondary)
                        
                        // Drug & Dose
                        HStack(spacing: 12) {
                            TextField("Drug (e.g. Oxycodone)", text: $drugName)
                                .padding()
                                .background(ClinicalTheme.backgroundInput)
                                .cornerRadius(8)
                                .addKeyboardDoneButton()
                            
                            TextField("Mg/Day", text: $currentDose)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .padding()
                                .frame(width: 100)
                                .background(ClinicalTheme.backgroundInput)
                                .cornerRadius(8)
                                .addKeyboardDoneButton()
                        }
                        
                        Divider()
                        
                        // Duration Strategy (CDC 2022 Logic)
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
                        
                        // Reduction Velocity
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Reduction Rate").font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
                                Spacer()
                                Text("\(Int(reductionPerStep))%").font(.headline).bold().foregroundColor(ClinicalTheme.teal500)
                            }
                            Slider(value: $reductionPerStep, in: 5...50, step: 5)
                                .accentColor(ClinicalTheme.teal500)
                        }
                        
                        // Pregnancy Gate (Synced with Assessment Tab)
                        Toggle(isOn: $assessmentStore.isPregnant) {
                            Text("Pregnant Person").font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                        
                        if assessmentStore.isPregnant {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(ClinicalTheme.rose500)
                                Text("Specialist Required. Withdrawal risk to fetus.")
                                    .font(.caption).bold().foregroundColor(ClinicalTheme.rose500)
                            }
                            .padding(8)
                            .background(ClinicalTheme.rose500.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .clinicalCard()
                    .padding(.horizontal)
                    
                    // 2. GENERATED SCHEDULE
                    if let startDose = Double(currentDose), startDose > 0, !assessmentStore.isPregnant {
                        let schedule = generateSchedule(start: startDose)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            // Header
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(ClinicalTheme.teal500)
                                Text("Generated Schedule")
                                    .font(.headline)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                Spacer()
                                Button(action: { copySchedule(start: startDose, schedule: schedule) }) {
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
                                            Text(step.doseString)
                                                .font(.body).bold()
                                                .foregroundColor(ClinicalTheme.textPrimary)
                                            
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
                                Text("Liquid Formulations (<10mg Daily)").font(.caption).bold().foregroundColor(ClinicalTheme.textPrimary)
                                Text("When tablets limit titration, use Oral Solution (e.g. Oxycodone 5mg/5mL) to enable 1mg decrements. Alternatively, extend interval (q24h → q48h) before stopping.")
                                    .font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .background(ClinicalTheme.backgroundCard)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
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
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Taper Tool")
            .navigationBarTitleDisplayMode(.inline)
            .addKeyboardDoneButton()
            .onAppear {
                if let calc = calculatorStore {
                    // Sync only if local fields are empty (don't overwrite user work)
                    if drugName.isEmpty && !calc.primaryDrugName.isEmpty {
                        drugName = calc.primaryDrugName
                    }
                    if currentDose.isEmpty && calc.totalDailyMME != "0" && calc.totalDailyMME != "---" {
                        currentDose = calc.totalDailyMME
                    }
                }
            }
        }
    }
    
    // MARK: - Logic Models
    
    struct TaperStep {
        let label: String
        let dose: Double
        let instruction: String
        
        var doseString: String {
            if dose < 0.1 { return "Discontinue" }
            return String(format: "%.1f mg/day", dose)
        }
    }
    
    // MARK: - CDC Logic
    
    func generateSchedule(start: Double) -> [TaperStep] {
        var steps: [TaperStep] = []
        let rate = reductionPerStep / 100.0
        var current = start
        
        // CDC Short Term Logic:
        // 1. Decrease by 10% of ORIGINAL dose until 30% reached (Linear)
        // 2. Then decrease by 10% of REMAINING dose (Exponential)
        
        let threshold30 = start * 0.30
        let linearStep = start * rate // Fixed mg amount
        
        var week = 1
        
        // Max 50 steps to accommodate long tapers (>4 years if monthly)
        for _ in 1...50 {
            var nextDose = 0.0
            var instruction = ""
            
            if !useLongDuration && current > threshold30 {
                 // Phase 1: Linear (Fixed rate)
                 nextDose = current - linearStep
            } else {
                 // Phase 2 or Long Term: Exponential (Percentage of current)
                 nextDose = current * (1.0 - rate)
            }
            
            // LOW DOSE HANDLING (< 10mg) - Liquid Transition Zone
            if nextDose < 10.0 && nextDose > 0.0 {
                // FDA: "It may be necessary to provide lower dosage strengths... using liquid formulations."
                if nextDose < 2.5 {
                     instruction = "Liquid Required (e.g. 1mg/1mL) or Stop"
                } else if nextDose < 5.0 {
                     instruction = "Use Liquid (5mg/5mL) or Extend Interval (q48h)"
                } else {
                     instruction = "Consider Liquid for <1mg adjustments"
                }
            }
            
            if nextDose < 1.0 {
                steps.append(TaperStep(label: useLongDuration ? "Month \(week)" : "Week \(week)", dose: 0, instruction: "Discontinue"))
                break
            }
            
            steps.append(TaperStep(label: useLongDuration ? "Month \(week)" : "Week \(week)", dose: nextDose, instruction: instruction))
            current = nextDose
            week += 1
        }
        
        return steps
    }
    
    func copySchedule(start: Double, schedule: [TaperStep]) {
        let mode = useLongDuration ? "Long Term (>1yr)" : "Short Term (<1yr)"
        let strat = useLongDuration ? "Slow Taper (10% Monthly)" : "CDC 2-Phase Protocol"
        
        var text = """
        Opioid Taper Plan
        Drug: \(drugName.isEmpty ? "Opioid" : drugName)
        Starting Dose: \(start) mg/day
        Strategy: \(strat)
        
        """
        
        for step in schedule {
            text += "\(step.label): \(step.doseString) \(step.instruction.isEmpty ? "" : "(\(step.instruction))")\n"
        }
        
        text += "\nWARNING: Pause taper if withdrawal symptoms occur. Consult provider immediately for severe symptoms."
        
        UIPasteboard.general.string = text
    }
}
