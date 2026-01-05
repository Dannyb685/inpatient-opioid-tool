import SwiftUI
import Charts

// MARK: - Methadone Data Models

struct MethadoneConversionResult {
    let totalDailyDose: Double
    let individualDose: Double
    let dosingSchedule: String
    let warnings: [String]
    let isContraindicatedForCalculator: Bool
    let transitionSchedule: [MethadoneScheduleStep]?
}

struct MethadoneScheduleStep: Hashable {
    let dayLabel: String
    let methadoneDose: String
    let instructions: String
    let methadoneDailyMg: Double // For Chart
    let prevOpioidPercentVal: Double // For Chart
    let prevMME: Int // New: Calculated MME value for display
}


enum ConversionMethod: String, CaseIterable {
    case rapid = "Rapid"
    case stepwise = "Stepwise"
}

// MARK: - Logic Engine

func calculateMethadoneConversion(totalMME: Double, patientAge: Int, method: ConversionMethod) -> MethadoneConversionResult {
    var ratio: Double
    var maxDailyDose: Double?
    var warnings: [String] = []
    var crossToleranceReduction: Double = 0.0
    
    // NCCN age-based adjustment
    let useConservativeRatio = patientAge >= 65
    
    // Check for special low-dose fixed rules first
    // Note: The new ClinicalData rules handle this via the RatioRule properties
    
    guard let rule = ClinicalData.MMEConversionRules.getRatio(for: totalMME, age: patientAge) else {
        warnings.append("🚨 SPECIALIST CONSULTATION MANDATORY")
        return MethadoneConversionResult(
            totalDailyDose: 0,
            individualDose: 0,
            dosingSchedule: "Consult Pain Specialist",
            warnings: warnings,
            isContraindicatedForCalculator: true,
            transitionSchedule: nil
        )
    }
    
    // Apply logic from rule
    // For min/max MME rules < 60, we might have fixed logic, but the struct handles ratio.
    // However, ClinicalData's RatioRule defines the ratio.
    // We need to handle the "Conservative" override if age > 65 and the rule doesn't explicitly separate it (ClinicalData rules 3 & 4 have duplicate MME ranges for ratio 10 vs 20? No, let's re-read ClinicalData I just wrote).
    // Wait, ClinicalData struct implementation I wrote:
    // RationRule(minMME: 60, maxMME: 100, ratio: 10.0 ...
    // RationRule(minMME: 100, maxMME: 200, ratio: 10.0 ...
    // UseConservativeRatio logic was: "ratio = useConservativeRatio ? 20.0 : 10.0".
    // My ClinicalData implementation didn't strictly capture the "Elderly = 20" logic within the struct unless I update the struct or logic here.
    // Implementation Plan Phase 1 said: "Use MMEConversionRules".
    // I should strictly follow the data model. If the data model I wrote (which I should check in context) doesn't have the "Elderly" flag, I need to implement the logic here using the data model's base, OR override it.
    // The previous code had: `ratio = useConservativeRatio ? 20.0 : 10.0` for 60-200.
    // The new ClinicalData struct has `ratio: 10.0` for 60-200.
    // I need to apply the elderly override here if the rule allows.
    
    ratio = rule.ratio
    if useConservativeRatio && (totalMME >= 60 && totalMME < 200) {
        ratio = 20.0 
        // This effectively overrides the 10.0 from the struct for elderly.
        // Ideally the struct would be `func getRatio(age...)` returning the correct rule, but my implemented `getRatio` just filters by MME.
        // I will keep this specific override here to maintain clinical safety until I update `ClinicalData` to be more robust for Age.
    }
    
    crossToleranceReduction = rule.reduction
    maxDailyDose = rule.maxDose
    
    if let warn = rule.warning {
        warnings.append(warn)
    }
    
    var methadoneDailyDose = totalMME / ratio
    
    // Apply Dose-Dependent Cross-Tolerance Reduction (NCCN/APS Safety Protocol)
    if crossToleranceReduction > 0 {
        methadoneDailyDose *= (1.0 - crossToleranceReduction)
        warnings.append("Applied \(Int(crossToleranceReduction * 100))% reduction for incomplete cross-tolerance (Standard Safety Protocol).")
    }

    // Apply minimum floor for very low calculations (< APS Minimum)
    let minimumDose = 7.5 // APS floor (2.5mg TID)
    if methadoneDailyDose < minimumDose && totalMME >= 30 {
        methadoneDailyDose = minimumDose
        warnings.append("Note: Dose rounded up to APS minimum (2.5mg TID).")
    }
    
    // Apply maximum cap
    if let maxDose = maxDailyDose, methadoneDailyDose > maxDose {
        methadoneDailyDose = maxDose
        warnings.append("⚠️ Dose capped at \(maxDose)mg/day per NCCN/APS guidelines.")
    }

    // Age-specific warning
    if useConservativeRatio && totalMME >= 60 {
        warnings.append("⚠️ **ELDERLY PATIENT:** Using more conservative NCCN ratios.")
    }
    
    // Step 5: Divide into dosing schedule (TID preferred for analgesia)
    var individualDose = methadoneDailyDose / 3.0
    
    // Practical Rounding (Nearest 0.5mg) to avoid "1.8mg"
    individualDose = (individualDose * 2).rounded() / 2
    
    // Recalculate daily total based on rounded val
    methadoneDailyDose = individualDose * 3.0
    
    // Step 6: Generate comprehensive warnings
    warnings.append("🚨 **METHADONE SAFETY PROTOCOL:**")
    warnings.append("**Do NOT titrate** more frequently than every 5-7 days.")
    warnings.append("**ECG required:** Baseline, 2-4 weeks, and at 100mg/day.")
    warnings.append("   • **Avoid if QTc >500ms;** Caution if 450-500ms.")
    warnings.append("**Monitor** for delayed respiratory depression (peak 2-4 days).")
    warnings.append("**Provide** naloxone rescue kit.")
    warnings.append("**UNIDIRECTIONAL conversion** - do NOT use reverse calculation.")
    
    // Generate Schedule if Stepwise
    var schedule: [MethadoneScheduleStep]? = nil
    if method == .stepwise {
        // Standard 3-Day Switch (33% increments)
        let step1Methadone = (methadoneDailyDose * 0.33 / 3.0 * 2).rounded() / 2 // TID
        let step2Methadone = (methadoneDailyDose * 0.66 / 3.0 * 2).rounded() / 2 // TID
        let finalMethadone = individualDose // Already rounded
        
        schedule = [
            MethadoneScheduleStep(
                dayLabel: "Days 1-3",
                methadoneDose: "\(String(format: "%g", step1Methadone)) mg TID",
                instructions: "Continue PRN breakthrough.",
                methadoneDailyMg: step1Methadone * 3,
                prevOpioidPercentVal: 66,
                prevMME: Int(totalMME * 0.66)
            ),
            MethadoneScheduleStep(
                dayLabel: "Days 4-6",
                methadoneDose: "\(String(format: "%g", step2Methadone)) mg TID",
                instructions: "Monitor for sedation.",
                methadoneDailyMg: step2Methadone * 3,
                prevOpioidPercentVal: 33,
                prevMME: Int(totalMME * 0.33)
            ),
            MethadoneScheduleStep(
                dayLabel: "Day 7+",
                methadoneDose: "\(String(format: "%g", finalMethadone)) mg TID",
                instructions: "Full Target Dose Reached.",
                methadoneDailyMg: finalMethadone * 3,
                prevOpioidPercentVal: 0,
                prevMME: 0
            )
        ]
        
        warnings.append("**STEPWISE INDUCTION:** Follow the 3-Step Transition Schedule below.")
    }

    return MethadoneConversionResult(
        totalDailyDose: methadoneDailyDose,
        individualDose: individualDose,
        dosingSchedule: "Every 8 hours (TID)",
        warnings: warnings,
        isContraindicatedForCalculator: false,
        transitionSchedule: schedule
    )
}

// MARK: - Methadone View

struct MethadoneView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager // Needed for color scheme
    @State private var currentTotalMME: String = ""
    @State private var conversionResult: MethadoneConversionResult?
    @State private var patientAge: Int = 50
    @State private var hasQTcProlongation: Bool = false
    @State private var showAlgorithmNote: Bool = false
    @State private var showChart: Bool = false
    @State private var conversionMethod: ConversionMethod = .rapid
    
    // Safety Gates (Passed from Calculator)
    let isPregnant: Bool
    let isNaltrexone: Bool
    
    // Optional: Initial MME passed from Calculator
    var initialMME: String?
    
    // Markdown support helper
    func markdownText(_ text: String) -> Text {
        Text(LocalizedStringKey(text))
    }
    
    init(isPresented: Binding<Bool>, initialMME: String? = nil, isPregnant: Bool = false, isNaltrexone: Bool = false) {
        self._isPresented = isPresented
        self.initialMME = initialMME
        self.isPregnant = isPregnant
        self.isNaltrexone = isNaltrexone
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 1. WARNING BANNER
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(ClinicalTheme.rose500)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SPECIALIST CONSULTATION RECOMMENDED")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.rose500)
                            Text("Methadone conversion is complex and risky. This tool calculates a STARTING dose only.")
                                .font(.caption)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                    }
                    .padding()
                    .background(ClinicalTheme.rose500.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.rose500.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal)
                    
                    // 2. INPUT CARD
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "number.square", title: "Conversion Inputs")
                        
                        // MME Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Total Daily MME")
                                .font(.subheadline)
                                .foregroundColor(ClinicalTheme.textSecondary)
                            
                            HStack {
                                TextField("Enter MME", text: $currentTotalMME)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(ClinicalTheme.backgroundInput)
                                    .cornerRadius(8)
                                    .onAppear {
                                        if let initial = initialMME, currentTotalMME.isEmpty {
                                            currentTotalMME = initial
                                        }
                                    }
                                
                                Text("mg")
                                    .foregroundColor(ClinicalTheme.textSecondary)
                            }
                        }
                        
                        Divider()
                        
                        // Patient Factors
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Patient Factors")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(ClinicalTheme.textPrimary)
                            
                            HStack {
                                Text("Age")
                                Spacer()
                                TextField("Age", value: $patientAge, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 50)
                                    .padding(8)
                                    .background(ClinicalTheme.backgroundInput)
                                    .cornerRadius(6)
                                Stepper("", value: $patientAge, in: 18...100)
                                    .labelsHidden()
                            }
                            
                            Toggle(isOn: $hasQTcProlongation) {
                                Text("QTc Prolongation Present (>450ms)")
                                    .font(.subheadline)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                            
                            if hasQTcProlongation {
                                HStack(spacing: 8) {
                                    Image(systemName: "heart.slash.fill").foregroundColor(ClinicalTheme.rose500)
                                    Text("Methadone may be contraindicated. Consider alternative.")
                                        .font(.caption).bold()
                                        .foregroundColor(ClinicalTheme.rose500)
                                }
                                .padding(8)
                                .background(ClinicalTheme.rose500.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        Divider()
                        
                        // Method
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Conversion Method")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(ClinicalTheme.textPrimary)
                                
                            Picker("Method", selection: $conversionMethod) {
                                ForEach(ConversionMethod.allCases, id: \.self) { method in
                                    Text(method.rawValue).tag(method)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Group {
                                if conversionMethod == .stepwise {
                                    Text("Strategy: Reduce previous opioid by 1/3 every few days. CONTINUE breakthrough short-acting opioid.")
                                } else {
                                    Text("Strategy: Discontinue previous opioid completely before first Methadone dose.")
                                }
                            }
                            .font(.caption)
                            .italic()
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .padding(.top, 4)
                        }
                    }

                    .padding(.horizontal)
                    
                    // SAFETY GATES (Inject Here)
                    if isNaltrexone {
                         VStack(spacing: 12) {
                             Image(systemName: "nosign")
                                 .font(.largeTitle)
                                 .foregroundColor(ClinicalTheme.rose500)
                             Text("Opioid Blockade Active")
                                 .font(.headline).foregroundColor(ClinicalTheme.rose500)
                             Text("Patient is on Naltrexone/Vivitrol. Methadone induction is CONTRAINDICATED without specialist detox protocol.")
                                 .font(.caption).multilineTextAlignment(.center).foregroundColor(ClinicalTheme.textSecondary)
                         }
                         .padding(.vertical, 40)
                         .frame(maxWidth: .infinity)
                         .background(ClinicalTheme.backgroundMain)
                    } else if isPregnant {
                        VStack(spacing: 12) {
                             Image(systemName: "person.crop.circle.badge.exclamationmark")
                                 .font(.largeTitle)
                                 .foregroundColor(ClinicalTheme.textMuted)
                             Text("Perinatal Management Required")
                                 .font(.headline).foregroundColor(ClinicalTheme.textMuted)
                             Text("Methadone is standard of care but requires OB/Addiction Specialist management. Do not use this calculator.")
                                 .font(.caption).multilineTextAlignment(.center).foregroundColor(ClinicalTheme.textSecondary)
                         }
                         .padding(.vertical, 40)
                         .frame(maxWidth: .infinity)
                         .background(ClinicalTheme.backgroundMain)
                    } else {
                        // Standard Calculator Flow
                    }
                    
                    if !isNaltrexone && !isPregnant {
                        // CALCULATE BUTTON
                        Button(action: performConversion) {
                            Text("Calculate Starting Dose")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(ClinicalTheme.teal500)
                                .cornerRadius(12)
                                .shadow(color: ClinicalTheme.teal500.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 3. RESULTS
                    if let result = conversionResult, !result.isContraindicatedForCalculator {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(icon: "pills.fill", title: "Recommended Protocol")
                            
                            HStack(alignment: .center) {
                                VStack(alignment: .leading) {
                                    Text("Scheduled Dose")
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                    Text("\(String(format: "%g", result.individualDose)) mg")
                                        .font(.system(size: 32, weight: .bold)) // Prominent
                                        .foregroundColor(ClinicalTheme.teal500)
                                    Text("TID (Every 8 hours)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(ClinicalTheme.teal500)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Total Daily")
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                    Text("\(String(format: "%.1f", result.totalDailyDose)) mg")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(ClinicalTheme.textPrimary)
                                }
                            }
                            .padding()
                            .background(ClinicalTheme.backgroundInput)
                            .cornerRadius(8)
                            
                            // SHOW SCHEDULE IF STEPWISE
                            if let schedule = result.transitionSchedule {
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
                                        .overlay(Rectangle().frame(height: 1).foregroundColor(ClinicalTheme.divider), alignment: .bottom)
                                    }
                                    
                                    if showChart {
                                        MethadoneStepwiseChart(schedule: schedule)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, -8) // Negative padding to stretch to edges of card
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        Divider()
                                    }
                                    
                                    HStack {
                                        Image(systemName: "calendar.badge.clock")
                                            .foregroundColor(ClinicalTheme.teal500)
                                        Text("Generated Schedule") // Renamed from 3-Step Transition
                                            .font(.headline)
                                            .foregroundColor(ClinicalTheme.textPrimary)
                                        Spacer()
                                        Button(action: { copyStepwiseSchedule(schedule: schedule) }) {
                                            Image(systemName: "doc.on.doc").foregroundColor(ClinicalTheme.teal500)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                    .padding(.top, 12)
                                    
                                    VStack(spacing: 12) {
                                        ForEach(schedule, id: \.self) { step in
                                            HStack(spacing: 0) {
                                                // LEFT: Day & Instructions
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(step.dayLabel)
                                                        .font(.headline)
                                                        .foregroundColor(ClinicalTheme.teal500)
                                                    
                                                    Text(step.instructions)
                                                        .font(.caption2)
                                                        .italic()
                                                        .foregroundColor(ClinicalTheme.textSecondary)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                }
                                                .frame(width: 80, alignment: .leading)
                                                
                                                Divider().padding(.horizontal, 8)
                                                
                                                // RIGHT: Dosing Logic
                                                VStack(alignment: .leading, spacing: 8) {
                                                    // Row 1: Previous Opioid
                                                    HStack {
                                                        Text("PREVIOUS")
                                                            .font(.system(size: 9, weight: .bold))
                                                            .foregroundColor(ClinicalTheme.textSecondary)
                                                            .frame(width: 60, alignment: .leading)
                                                        
                                                        if step.prevMME > 0 {
                                                            Text("Reduce to \(step.prevMME) MME")
                                                                .font(.caption).bold()
                                                                .foregroundColor(ClinicalTheme.amber500)
                                                            Text("(\(Int(step.prevOpioidPercentVal))%)")
                                                                .font(.caption2)
                                                                .foregroundColor(ClinicalTheme.textMuted)
                                                        } else {
                                                            Text("Discontinue")
                                                                .font(.caption).bold()
                                                                .foregroundColor(ClinicalTheme.textMuted)
                                                        }
                                                    }
                                                    
                                                    // Row 2: Methadone
                                                    HStack {
                                                        Text("METHADONE")
                                                            .font(.system(size: 9, weight: .bold))
                                                            .foregroundColor(ClinicalTheme.teal500)
                                                            .frame(width: 60, alignment: .leading)
                                                        
                                                        Text(step.methadoneDose)
                                                            .font(.subheadline).bold()
                                                            .foregroundColor(ClinicalTheme.textPrimary)
                                                    }
                                                }
                                            }
                                            .padding(12)
                                            .background(ClinicalTheme.backgroundCard)
                                            .cornerRadius(8)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                }
                                .padding()
                                .background(ClinicalTheme.backgroundCard)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                            }
                            
                            // WARNINGS LIST
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Safety Warnings & Monitoring")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                
                                ForEach(result.warnings, id: \.self) { warning in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .padding(.top, 6)
                                            .foregroundColor(ClinicalTheme.amber500)
                                        Text(LocalizedStringKey(warning))
                                            .font(.caption)
                                            .foregroundColor(ClinicalTheme.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(12)
                            .background(ClinicalTheme.amber500.opacity(0.1))
                            .cornerRadius(8)
                            
                        }
                        .clinicalCard()
                        .padding(.horizontal, 12)
                        .padding(.bottom, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
            }
            .padding(.top)
            
            // Transparency Card (Bottom)
            MethadoneTransparencyCard(isExpanded: $showAlgorithmNote)
                .padding()
        }
            .navigationTitle("Methadone Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
        }
    }
    

    
    // Copy Action
    func copyStepwiseSchedule(schedule: [MethadoneScheduleStep]) {
        var text = """
        Methadone Stepwise Induction Plan
        Strategy: 3-Step Rotation (33% increments)
        Target Dose: \(String(format: "%.1f", conversionResult?.totalDailyDose ?? 0)) mg/day (\(String(format: "%.1f", conversionResult?.individualDose ?? 0)) mg TID)
        
        """
        
        for step in schedule {
            text += "\(step.dayLabel):\n"
            text += " - Previous Opioid: \(step.prevMME) MME (\(Int(step.prevOpioidPercentVal))%)\n"
            text += " - Methadone: \(step.methadoneDose)\n"
            text += " - Note: \(step.instructions)\n\n"
        }
        
        text += "WARNING: Pause taper if profound sedation or respiratory issues occur."
        UIPasteboard.general.string = text
    }
    
    // Action
    func performConversion() {
        guard let mme = Double(currentTotalMME), mme > 0 else { return }
        withAnimation {
            self.conversionResult = calculateMethadoneConversion(totalMME: mme, patientAge: patientAge, method: conversionMethod)
        }
    }
}


// MARK: - Transparency Card
struct MethadoneTransparencyCard: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(ClinicalTheme.textSecondary)
                    Text("Algorithm Transparency")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ClinicalTheme.textSecondary)
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Evidence-Based Logic Source")
                        .font(.caption).bold()
                        .foregroundColor(ClinicalTheme.textPrimary)
                    
                    Text("This calculator synthesizes guidelines from:")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• VA/DoD CPG (2022): Tiered conversion ratios.").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        Text("• NCCN Guidelines: Age-based adjustments (>65y) and low-dose logic.").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        Text("• APS Guidelines: Minimum effective dose floors (Start 2.5mg TID).").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                    
                    Divider().padding(.vertical, 4)
                    
                    Text("Safety Mechanisms Applied:")
                        .font(.caption).bold()
                        .foregroundColor(ClinicalTheme.textPrimary)
                    
                    Text("• Cross-Tolerance Reduction: 15-25% (Dose-Dependent).")
                        .font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    Text("• Dose Capping: Max 40-50mg initial daily dose.")
                        .font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    Text("• Stepwise Logic: Taper recommendation generation.")
                        .font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                        
                }
                .padding()
                .background(ClinicalTheme.backgroundMain.opacity(0.5))
            }
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
    }
}

// MARK: - Stepwise Chart Visualizer
struct MethadoneStepwiseChart: View {
    let schedule: [MethadoneScheduleStep]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cross-Taper Visualization")
                .font(.caption).bold()
                .foregroundColor(ClinicalTheme.textSecondary)
                .padding(.horizontal)
            
            Chart {
                ForEach(Array(schedule.enumerated()), id: \.offset) { index, step in
                    // 1. Methadone Ramp Up (Teal Gradient Area)
                    AreaMark(
                        x: .value("Stage", "Step \(index + 1)"),
                        y: .value("Methadone (mg)", step.methadoneDailyMg)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ClinicalTheme.teal500.opacity(0.6), ClinicalTheme.teal500.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Methadone Line Anchor
                    LineMark(
                        x: .value("Stage", "Step \(index + 1)"),
                        y: .value("Methadone (mg)", step.methadoneDailyMg)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(ClinicalTheme.teal500)
                    .symbol {
                        Circle()
                            .fill(ClinicalTheme.teal500)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 2)
                    }
                    
                    // 2. Previous Opioid Ramp Down (Amber Gradient Area)
                    AreaMark(
                        x: .value("Stage", "Step \(index + 1)"),
                        y: .value("Previous Opioid (%)", step.prevOpioidPercentVal)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ClinicalTheme.amber500.opacity(0.4), ClinicalTheme.amber500.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Previous Line Anchor
                    LineMark(
                        x: .value("Stage", "Step \(index + 1)"),
                        y: .value("Previous Opioid (%)", step.prevOpioidPercentVal)
                    )
                    .interpolationMethod(.linear)
                    .foregroundStyle(ClinicalTheme.amber500)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .symbol {
                        Circle()
                            .fill(ClinicalTheme.amber500)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
            .padding(.horizontal)
            
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(ClinicalTheme.teal500).frame(width: 8, height: 8)
                    Text("Methadone (mg/day)").font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                }
                HStack(spacing: 4) {
                    Circle().fill(ClinicalTheme.amber500).frame(width: 8, height: 8)
                    Text("Previous Opioid (%)").font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
    }
}
