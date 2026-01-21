import SwiftUI

struct InfusionView: View {
    // Decoupled Wrapper
    @ObservedObject var calculatorStore: CalculatorStore // Shared State
    @State private var selectedTab = 0
    @Environment(\.presentationMode) var presentationMode
    
    // Shared Clinical Context
    @State private var isNaive: Bool = true
    @State private var hasOSA: Bool = false
    @State private var isRenalImpaired: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Infusion Tools")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ClinicalTheme.textPrimary)
                        Spacer()
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(ClinicalTheme.blue500)
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    
                    // Context Toggles (Always Visible or in a collapsible header?)
                    // Let's put them in a collapsible section or just at the top of ScrollView.
                    // Or keep them in the views? If we want them shared, they should probably be passed down.
                    
                    // Tabs
                    Picker("Mode", selection: $selectedTab) {
                        Text("PCA Calculator").tag(0)
                        Text("Drip Converter").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Clinical Context Card (Shared)
                             ClinicalCard(title: "Patient Context", icon: "person.text.rectangle.fill", color: ClinicalTheme.teal500) {
                                VStack(spacing: 12) {
                                    Toggle("Opioid Naive", isOn: $isNaive)
                                    Divider()
                                    Toggle("Obstructive Sleep Apnea (OSA)", isOn: $hasOSA)
                                    Divider()
                                    Toggle("Renal Impairment (<60 mL/min)", isOn: $isRenalImpaired)
                                }
                                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                                .onChange(of: isNaive) { _, _ in syncStoreContext() }
                                .onChange(of: hasOSA) { _, _ in syncStoreContext() }
                                .onChange(of: isRenalImpaired) { _, _ in syncStoreContext() }
                            }
                            
                            if selectedTab == 0 {
                                PCAView(isNaive: $isNaive, hasOSA: $hasOSA, isRenalImpaired: $isRenalImpaired, age: calculatorStore.age)
                            } else {
                                DripView(calculatorStore: calculatorStore, isNaive: isNaive, hasOSA: hasOSA, isRenalImpaired: isRenalImpaired, age: calculatorStore.age)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    func syncStoreContext() {
        calculatorStore.syncContext(isNaive: isNaive, hasOSA: hasOSA, renalImpaired: isRenalImpaired)
    }
}

// MARK: - PCA View
struct PCAView: View {
    // Phase 15: Decoupled from AssessmentStore for Sandbox usage
    @Binding var isNaive: Bool
    @Binding var hasOSA: Bool
    @Binding var isRenalImpaired: Bool
    var age: String // Passed from store
    
    @State private var settings = PCASettings()
    @State private var selectedDrug = "Morphine"
    
    let drugs = ["Morphine", "Hydromorphone", "Fentanyl"]
    
    var unit: String {
        selectedDrug == "Fentanyl" ? "mcg" : "mg"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Context moved to Parent
            
            // 2. Drug Selection
            ClinicalCard(title: "PCA Configuration", icon: "cross.case.fill", color: ClinicalTheme.blue500) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Drug")
                            .foregroundColor(ClinicalTheme.textSecondary)
                        Spacer()
                        Picker("Drug", selection: $selectedDrug) {
                            ForEach(drugs, id: \.self) { drug in
                                Text(drug).tag(drug)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedDrug) { _, newValue in
                            // Reset defaults based on drug?
                            if newValue == "Fentanyl" {
                                settings.concentration = 10 // mcg/mL
                                settings.demandDose = 25 // mcg
                                settings.basalRate = 0
                            } else if newValue == "Hydromorphone" {
                                settings.concentration = 0.2 // mg/mL
                                settings.demandDose = 0.2 // mg
                                settings.basalRate = 0
                            } else {
                                settings.concentration = 1.0 // mg/mL
                                settings.demandDose = 1.0 // mg
                                settings.basalRate = 0
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Parameters
                    HStack {
                        Text("Concentration (\(unit)/mL)")
                        Spacer()
                        TextField("Conc", value: $settings.concentration, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Demand Dose (\(unit))")
                        Spacer()
                        TextField("Dose", value: $settings.demandDose, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Lockout (min)")
                        Spacer()
                        TextField("Min", value: $settings.lockoutInterval, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Basal Rate (\(unit)/hr)")
                        Spacer()
                        TextField("Rate", value: $settings.basalRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            
            // Warnings
            let warnings = settings.validate(
                isNaive: isNaive,
                hasOSA: hasOSA,
                isRenalImpaired: isRenalImpaired,
                age: Int(age) ?? 50
            )
            
            if !warnings.isEmpty {
                ForEach(warnings, id: \.self) { warn in
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(warn)
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            // Output
            ClinicalCard(title: "Safety Limits", icon: "speedometer", color: ClinicalTheme.purple500) {
                VStack(spacing: 8) {
                    HStack {
                        Text("1-Hour Limit")
                        Spacer()
                        Text("\(Int(settings.oneHourLimit)) \(unit)")
                            .bold()
                    }
                    Divider()
                    HStack {
                        Text("4-Hour Limit")
                        Spacer()
                        Text("\(Int(settings.fourHourLimit)) \(unit)")
                            .bold()
                    }
                }
            }
        }
    }
}

// MARK: - Drip View
struct DripView: View {
    @ObservedObject var calculatorStore: CalculatorStore
    var isNaive: Bool
    var hasOSA: Bool
    var isRenalImpaired: Bool
    var age: String
    
    @State private var config = DripConfig()
    @State private var selectedDrug = "Fentanyl"
    @State private var showRotationWarning = false
    
    // Methadone excluded due to long/variable half-life and complex conversion (1:5 to 1:12+).
    // See CDC/PRODIGY guidelines regarding respiratory depression risk vs analgesic peak mismatch.
    let drugs = ["Fentanyl", "Hydromorphone", "Morphine"]
    
    var unit: String {
        selectedDrug == "Fentanyl" ? "mcg" : "mg"
    }
    

    
    var body: some View {
        VStack(spacing: 16) {
            ClinicalCard(title: "Continuous Infusion", icon: "iv.bag.fill", color: ClinicalTheme.teal500) {
                VStack(alignment: .leading, spacing: 12) {
                     Picker("Drug", selection: $selectedDrug) {
                            ForEach(drugs, id: \.self) { drug in
                                Text(drug).tag(drug)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedDrug) { _, newValue in
                             if newValue == "Fentanyl" {
                                config.concentration = 10 // mcg/mL
                                config.unit = "mcg"
                            } else {
                                config.concentration = 1.0 // mg/mL
                                config.unit = "mg"
                            }
                        }
                    
                    if selectedDrug == "Fentanyl" {
                        // TRANSPARENCY FOOTNOTE (v7.2.3)
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                            Text("Using Factor 0.12 (Continuous Infusion) vs 0.3 (Acute) per CMS 2024 Guidelines.")
                                .font(.caption2)
                                .italic()
                                .foregroundColor(ClinicalTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Duration Context")
                        Spacer()
                        Picker("Duration", selection: $config.infusionDuration) {
                            ForEach(DripConfig.InfusionDuration.allCases, id: \.self) { duration in
                                Text(duration.rawValue).tag(duration)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Concentration (\(unit)/mL)")
                        Spacer()
                        TextField("Conc", value: $config.concentration, format: .number)
                            .keyboardType(.decimalPad)

                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Rate (mL/hr)")
                        Spacer()
                        TextField("Rate", value: $config.rate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            

            
            // Warnings
            let warnings = config.validate(
                isNaive: isNaive, 
                isRenalImpaired: isRenalImpaired, 
                hasOSA: hasOSA,
                age: Int(age) ?? 50
            )
            let strictMMEWarning = "CRITICAL: MME values are for RISK STRATIFICATION ONLY. Do NOT use for dose conversion. Reduce calculated dose by 25-50% for incomplete cross-tolerance."
            
            VStack(spacing: 8) {
                if !warnings.isEmpty {
                    ForEach(warnings, id: \.self) { warn in
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(warn)
                                .font(.caption)
                                .foregroundColor(ClinicalTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                // Always show strict MME warning
                HStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.red)
                    Text(strictMMEWarning)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Output
            ClinicalCard(title: "Calculated Output", icon: "equal.circle.fill", color: ClinicalTheme.blue500) {
                VStack(spacing: 8) {
                    HStack {
                        Text("Hourly Dose")
                        Spacer()
                        Text("\(String(format: "%.1f", config.hourlyDose)) \(unit)/hr")
                            .bold()
                    }
                    Divider()
                    HStack {
                        Text("24h Total")
                        Spacer()
                        Text("\(Int(config.dailyTotal)) \(unit)")
                            .bold()
                    }
                    Divider()
                    HStack {
                        Text("Approx Daily MME")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(Int(config.computedMME)) MME")
                                .font(.title3)
                                .fontWeight(.heavy)
                                .foregroundColor(ClinicalTheme.blue500)
                            
                            let adjusted = config.riskAdjustedMME(isRenal: isRenalImpaired, osae: hasOSA, patientAge: Int(age) ?? 50)
                            if adjusted > config.computedMME {
                                Text("Physiology Risk: \(Int(adjusted)) MME")
                                    .font(.caption2)
                                    .italic()
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    

                    
                    HStack {
                         Text("Evidence Quality")
                         Spacer()
                         HStack(spacing: 4) {
                             Image(systemName: config.evidenceQuality == .high ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                             Text(config.evidenceQuality.rawValue)
                         }
                         .font(.caption)
                         .foregroundColor(config.evidenceQuality == .high ? .green : .orange)
                         .padding(6)
                         .background(
                             (config.evidenceQuality == .high ? Color.green : Color.orange)
                                 .opacity(0.1)
                         )
                         .cornerRadius(8)
                    }

                    Divider()
                    
                    // Add Button
                    Button(action: {
                        showRotationWarning = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Daily MME")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ClinicalTheme.blue500)
                        .cornerRadius(8)
                    }
                }
                }
            }
            .alert(isPresented: $showRotationWarning) {
                Alert(
                    title: Text("ROTATION WARNING"),
                    message: Text("When converting opioids, reduce calculated dose by 25-50% for incomplete cross-tolerance.\n\nDo NOT use MME values directly for dose conversion."),
                    primaryButton: .default(Text("I Understand, Add MME")) {
                        syncStoreContext()
                        
                        let drugId: String
                        switch selectedDrug {
                        case "Fentanyl": 
                            if config.infusionDuration == .continuous {
                                drugId = "fentanyl_drip"
                            } else {
                                drugId = "fentanyl" // Acute/Bolus maps to standard IV
                            }
                        case "Hydromorphone": drugId = "hydromorphone_iv_drip"
                        case "Morphine": drugId = "morphine_iv_drip"
                        default: drugId = "morphine"
                        }
                        
                        calculatorStore.activeInputsAdd(drugId: drugId, dose: String(format: "%.1f", config.dailyTotal))
                        
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                    },
                    secondaryButton: .cancel()
                )
            }
            
            // Context Sync Logic
        }

    
    func syncStoreContext() {
        calculatorStore.syncContext(isNaive: isNaive, hasOSA: hasOSA, renalImpaired: isRenalImpaired)
    }
}
