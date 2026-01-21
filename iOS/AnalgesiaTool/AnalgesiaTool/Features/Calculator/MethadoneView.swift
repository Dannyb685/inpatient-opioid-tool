import SwiftUI
import Charts

// MARK: - Methadone Data Models

// Struct moved to MethadoneCalculator.swift

// Models moved to MethadoneCalculator.swift

// MARK: - Logic Engine

// Logic moved to MethadoneCalculator.swift

// MARK: - Methadone View

struct MethadoneView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var themeManager: ThemeManager // Needed for color scheme
    @State private var currentTotalMME: String = ""
    @State private var conversionResult: MethadoneConversionResult?

    @State private var patientAge: Int = 50
    // NEW: Allow auto-seeding
    var initialAge: Int?
    @State private var hasQTcProlongation: Bool = false
    @State private var showAlgorithmNote: Bool = false
    @State private var showChart: Bool = false
    @State private var conversionMethod: ConversionMethod = .rapid
    @State private var manualReduction: Double = 25.0 // Default 25% Reduction (NCCN/APS Recommendation)
    
    // Safety Gates (Passed from Calculator)
    let isPregnant: Bool
    let isBreastfeeding: Bool
    let isNaltrexone: Bool
    // Safety Enhancement 1/9/26
    let hepaticStatus: HepaticStatus
    let renalStatus: RenalStatus
    let benzos: Bool
    let isOUD: Bool
    
    // Optional: Initial MME passed from Calculator
    var initialMME: String?
    
    // Markdown support helper
    func markdownText(_ text: String) -> Text {
        Text(LocalizedStringKey(text))
    }
    
    init(isPresented: Binding<Bool>, initialMME: String? = nil, initialAge: Int? = nil, isPregnant: Bool = false, isBreastfeeding: Bool = false, isNaltrexone: Bool = false, hepaticStatus: HepaticStatus = .normal, renalStatus: RenalStatus = .normal, benzos: Bool = false, isOUD: Bool = false) {
        self._isPresented = isPresented
        self.initialMME = initialMME
        self.initialAge = initialAge
        self.isPregnant = isPregnant
        self.isBreastfeeding = isBreastfeeding
        self.isNaltrexone = isNaltrexone
        self.hepaticStatus = hepaticStatus
        self.renalStatus = renalStatus
        self.benzos = benzos
        self.isOUD = isOUD
    }
    
    var warningBanner: some View {
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
        .addKeyboardDoneButton()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // 1. WARNING BANNER
                    warningBanner
                    
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
                                        // Auto-Seed Age if provided
                                        if let age = initialAge, patientAge == 50 { // Only overwrite default
                                            patientAge = age
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
                        
                        Divider()
                        
                        // Cross-Tolerance Reduction Slider (User Request 1/9/26)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Cross-Tolerance Reduction")
                                    .font(.subheadline)
                                    .foregroundColor(ClinicalTheme.textSecondary)
                                Spacer()
                                Text("-\(Int(manualReduction))%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(manualReduction <= 25 ? ClinicalTheme.rose500 : ClinicalTheme.teal500)
                            }
                            
                            // Safety: Minimum unbound 15% to prevent complete accidental 1:1 rotation
                            Slider(value: $manualReduction, in: 15...75, step: 5)
                                .accentColor(manualReduction <= 25 ? ClinicalTheme.rose500 : ClinicalTheme.teal500)
                            
                            HStack {
                                Spacer()
                                if manualReduction <= 25 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                                        Text("HIGH RISK: Incomplete Cross-Tolerance")
                                            .font(.caption2).bold()
                                    }
                                    .foregroundColor(ClinicalTheme.rose500)
                                } else {
                                    Text(manualReduction > 50 ? "Aggressive Reduction" : "Standard Safety Protocol")
                                        .font(.caption2)
                                        .italic()
                                        .foregroundColor(manualReduction > 50 ? ClinicalTheme.amber500 : ClinicalTheme.textSecondary)
                                }
                            }
                        }
                    } // Closing brace for the Input Card VStack
                    .padding(.horizontal)
                    
                    // SAFETY GATES (Inject Here)
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
                         .onAppear {
                             SafetyLogger.shared.log(.safetyGateFailure(errors: ["Methadone Calculator Blocked: Naltrexone Active"]))
                         }
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
                         .onAppear {
                             SafetyLogger.shared.log(.safetyGateFailure(errors: ["Methadone Calculator Blocked: Pregnancy"]))
                         }
                    } else {
                        // Standard Calculator Flow
                    }
                    
                    // KEYBOARD DONE BUTTON
                    Spacer(minLength: 0)
                    
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
                            
                            // HIDE RAPID DISPLAY IF STEPWISE (User Request)
                            if conversionMethod == .rapid {
                                HStack(alignment: .center) {
                                    VStack(alignment: .leading) {
                                        Text("Scheduled Dose")
                                            .font(.caption)
                                            .foregroundColor(ClinicalTheme.textSecondary)
                                        Text("\(String(format: "%.1f", result.individualDose)) mg")
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
                                        
                                        // Transparency: Original Calculation
                                        if let original = result.originalDailyDose, original > result.totalDailyDose {
                                            HStack(spacing: 4) {
                                                Text("Ratio Protected").font(.system(size: 8)).bold().foregroundColor(ClinicalTheme.teal500).padding(2).background(ClinicalTheme.teal500.opacity(0.1)).cornerRadius(2)
                                                Text("\(String(format: "%.1f", original)) mg")
                                                    .font(.caption)
                                                    .strikethrough()
                                                    .foregroundColor(ClinicalTheme.textMuted)
                                            }
                                        }
                                        
                                        Text("\(String(format: "%.1f", result.totalDailyDose)) mg")
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(ClinicalTheme.textPrimary)
                                    }
                                }
                                .padding()
                                .background(ClinicalTheme.backgroundInput)
                                .cornerRadius(8)
                            }
                            
                            // COPY ACTIONS
                            HStack(spacing: 12) {
                                Button(action: {
                                    copyClinicalNote()
                                    // Optional: Show alert/feedback
                                }) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                        Text("Copy Note")
                                    }
                                    .font(.caption).bold()
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(ClinicalTheme.teal500.opacity(0.1))
                                    .foregroundColor(ClinicalTheme.teal500)
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    copyPatientInstructions()
                                    // Optional: Show alert/feedback
                                }) {
                                    HStack {
                                        Image(systemName: "person.text.rectangle")
                                        Text("Patient Instr.")
                                    }
                                    .font(.caption).bold()
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(ClinicalTheme.amber500.opacity(0.1))
                                    .foregroundColor(ClinicalTheme.amber500)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.top, 4)
                            
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
                
            VStack(spacing: 4) {
                Text("Powered by Lifeline Medical Technologies")
                    .font(.system(size: 10))
                    .foregroundColor(ClinicalTheme.teal500.opacity(0.6))
                CitationFooter(citations: CitationRegistry.resolve(["cdc_opioids_2022", "aps_opioids_2024"]))
                    .padding(.top, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
        }
            .navigationTitle("Methadone Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
            .onChange(of: currentTotalMME) { _, _ in performConversion() }
            .onChange(of: patientAge) { _, _ in performConversion() }
            .onChange(of: conversionMethod) { _, _ in performConversion() }
            .onChange(of: manualReduction) { _, _ in performConversion() }
            .onChange(of: hepaticStatus) { _, _ in performConversion() }
            .onChange(of: renalStatus) { _, _ in performConversion() }
            .onChange(of: isPregnant) { _, _ in performConversion() }
            .onChange(of: isBreastfeeding) { _, _ in performConversion() }
            .onChange(of: benzos) { _, _ in performConversion() }
            .onAppear { performConversion() }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
        }
    }
    

    
    // Copy Action
    // Unified Copy Action
    func copyClinicalNote() {
        guard let result = conversionResult else { return }
        
        let text = """
        Methadone Conversion Note
        Input: \(currentTotalMME) MME (Age: \(patientAge))
        Context: \(isPregnant ? "Pregnant" : (isBreastfeeding ? "Breastfeeding" : "Standard"))
        Ratio Used: ~1:\(Int(result.ratioUsed)) (NCCN Guidelines)
        Reduction: \(Int(result.reductionApplied * 100))% for cross-tolerance
        
        Plan: Methadone \(String(format: "%.1f", result.individualDose)) mg TID
        Total Daily: \(String(format: "%.1f", result.totalDailyDose)) mg
        
        Safety:
        - ECG monitoring required (Baseline, Day 30)
        - Naloxone kit prescribed
        - Titrate no faster than q5-7 days
        """
        UIPasteboard.general.string = text
    }
    
    func copyPatientInstructions() {
        guard let result = conversionResult else { return }
        
        var text = """
        Your Methadone Schedule
        Start Date: _____________
        
        Dose: Take \(String(format: "%.1f", result.individualDose)) mg every 8 hours.
        (Example: 8:00 AM, 4:00 PM, 12:00 AM)
        
        IMPORTANT SAFETY:
        1. Methadone builds up slowly. Do NOT take extra doses.
        2. If you feel very sleepy, SKIP your next dose and call the clinic.
        3. Do not mix with alcohol or sedatives.
        
        """
        
        if let schedule = result.transitionSchedule {
            text += "\nTRANSITION SCHEDULE:\n"
            for step in schedule {
                text += "[ ] \(step.dayLabel): Take Methadone \(step.methadoneDose). \(step.instructions)\n"
            }
        }
        
        UIPasteboard.general.string = text
    }
    
    // Legacy Stepwise Helper (kept but unused if button removed, or reused)
    func copyStepwiseSchedule(schedule: [MethadoneScheduleStep]) {
        copyPatientInstructions() // Redirect to new format
    }
    
    func performConversion() {
        guard let mme = Double(currentTotalMME), mme > 0 else { return }
        
        // Auto-adjust reduction if it's still at default and MME is low
        if manualReduction == 25.0 && mme < 100 {
            // NCCN Suggests 15% for <100 MME baseline
            manualReduction = 15.0
        }
        
        withAnimation {
            self.conversionResult = MethadoneCalculator.calculate(
                totalMME: mme,
                patientAge: patientAge,
                method: conversionMethod,
                hepaticStatus: hepaticStatus,
                renalStatus: renalStatus,
                isPregnant: isPregnant,
                isBreastfeeding: isBreastfeeding,
                benzos: benzos,
                isOUD: isOUD,
                qtcProlonged: hasQTcProlongation,
                manualReduction: manualReduction
            )
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

struct SectionHeader: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(ClinicalTheme.blue500)
            
            Text(title)
                .font(.headline)
                .foregroundColor(ClinicalTheme.textPrimary)
            
            Spacer()
        }
        .padding(.top, 8)
    }
}
