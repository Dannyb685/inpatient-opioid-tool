import SwiftUI

struct CalculatorView: View {
    @StateObject private var store = CalculatorStore()
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showComplexHelpers = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {


                // MARK: - PINNED MME TOTAL
                VStack(spacing: 0) {
                    ScoreResultCard(
                        title: "Total 24h MME",
                        subtitle: "Oral Morphine Equivalents",
                        value: store.inputs.isEmpty ? "0" : store.resultMME, // Handle empty state gracefully if needed, logic in store usually handles it
                        valueLabel: "mg/day",
                        badgeText: "Oral",
                        badgeColor: ClinicalTheme.teal500
                    )
                    
                    if !store.warningText.isEmpty {
                        Text(store.warningText)
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.amber500)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                            .padding(.horizontal)
                    }
                }
                .clinicalCard()
                .padding()
                .background(ClinicalTheme.backgroundMain)
                .zIndex(1)
                
                // MARK: - SCROLLABLE CONTENT
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // INPUTS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Parameters").font(.headline).foregroundColor(ClinicalTheme.textSecondary).padding(.horizontal)
                            Text("Estimate only. Do NOT use for Methadone conversion.")
                                .font(.caption).bold().foregroundColor(ClinicalTheme.rose500)
                                .padding(.horizontal)
                            
                            // DRUG INPUT LIST
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(store.inputs) { input in
                                        // Name is now pre-formatted in Store (e.g. "Morphine (IV)")
                                    HStack {
                                        Text(input.name)
                                            .foregroundColor(ClinicalTheme.textPrimary)
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        HStack(spacing: 4) {
                                            ZStack(alignment: .trailing) {
                                                if input.dose.isEmpty {
                                                    Text("0").foregroundColor(ClinicalTheme.textMuted)
                                                }
                                                TextField("", text: Binding(
                                                    get: { input.dose },
                                                    set: { store.updateDose(for: input.id, dose: $0) }
                                                ))
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                                .font(.body.monospacedDigit())
                                                .foregroundColor(ClinicalTheme.teal500)
                                                // .addKeyboardDoneButton() moved to container
                                            }
                                            
                                                // DYNAMIC UNIT LABEL: Precise Patch Units
                                                // DYNAMIC UNIT LABEL: Type-Safe Logic
                                                let unitLabel: String = {
                                                    switch input.routeType {
                                                    case .patch: return "mcg/hr"
                                                    case .ivDrip: return "mg/hr"
                                                    case .microgramIO: return "mcg"
                                                    default: return "mg"
                                                    }
                                                }()
                                                
                                                let isHighRisk = input.routeType == .patch || input.routeType == .microgramIO

                                                Text(unitLabel)
                                                    .font(.caption)
                                                    .fontWeight(isHighRisk ? .bold : .regular)
                                                    .foregroundColor(isHighRisk ? ClinicalTheme.rose500 : ClinicalTheme.textSecondary)
                                        }
                                        .frame(width: 100)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(ClinicalTheme.backgroundInput)
                                        .cornerRadius(6)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    
                                    if input.id != store.inputs.last?.id {
                                        Divider().background(ClinicalTheme.divider)
                                    }
                                }
                            }
                            // Removed redundant backgroundMain
                            .background(ClinicalTheme.backgroundCard)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                            .padding(.horizontal)
                            
                            // Toggles
                            VStack(spacing: 16) {
                                Picker("Tolerance", selection: $store.tolerance) {
                                    ForEach(ToleranceStatus.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                                
                                Picker("Context", selection: $store.context) {
                                    ForEach(ConversionContext.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                                
                                // Presets & Slider
                                if !(store.context == .routeSwitch && store.tolerance == .tolerant) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Presets
                                        HStack(spacing: 8) {
                                            ForEach([0, 30, 50], id: \.self) { val in
                                                Button(action: { store.reduction = Double(val) }) {
                                                    VStack(spacing: 2) {
                                                        Text("\(val)%").font(.headline)
                                                        Text(val == 0 ? "Aggressive" : (val == 30 ? "Standard" : "Conservative"))
                                                            .font(.system(size: 8)).textCase(.uppercase)
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 8)
                                                    .background(store.reduction == Double(val) ? ClinicalTheme.teal500.opacity(0.15) : ClinicalTheme.backgroundMain)
                                                    .foregroundColor(store.reduction == Double(val) ? ClinicalTheme.teal500 : ClinicalTheme.textSecondary)
                                                    .cornerRadius(8)
                                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(store.reduction == Double(val) ? ClinicalTheme.teal500 : ClinicalTheme.cardBorder, lineWidth: 1))
                                                }
                                            }
                                        }
                                        
                                        // Slider Header
                                        HStack {
                                            Text("Reduction").font(.caption).foregroundColor(ClinicalTheme.teal500).textCase(.uppercase)
                                            Spacer()
                                            Text("-\(Int(store.reduction))%")
                                                .font(.headline).foregroundColor(ClinicalTheme.amber500)
                                        }
                                        Slider(value: $store.reduction, in: 0...75, step: 5).accentColor(ClinicalTheme.amber500)
                                        
                                        // Compliance Warning
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: store.reduction > 40 ? "exclamationmark.triangle.fill" : (store.reduction < 25 ? "bolt.fill" : "checkmark.circle.fill"))
                                                .foregroundColor(store.reduction > 40 ? .orange : (store.reduction < 25 ? .red : .teal))
                                                .font(.caption)
                                            Text(store.complianceWarning)
                                                .font(.caption)
                                                .foregroundColor(ClinicalTheme.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(8)
                                        .background(ClinicalTheme.backgroundMain)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding().background(ClinicalTheme.backgroundCard).cornerRadius(12).padding(.horizontal)
                        }
                        
                        // TARGET DOSES
                        if !store.targetDoses.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Estimated Targets").font(.headline).foregroundColor(ClinicalTheme.textSecondary).padding(.horizontal)
                                
                                ForEach(store.targetDoses) { dose in
                                    TargetDoseCard(dose: dose)
                                }
                                
                                // SAFETY INTERSTITIAL (Complex Conversions)
                                VStack(spacing: 0) {
                                    Button(action: { withAnimation { showComplexHelpers.toggle() } }) {
                                        HStack {
                                            Image(systemName: "exclamationmark.shield.fill")
                                            Text("Complex Conversions (Patch/Methadone)")
                                            Spacer()
                                            Image(systemName: showComplexHelpers ? "chevron.up" : "chevron.down")
                                        }
                                        .font(.caption).bold()
                                        .foregroundColor(ClinicalTheme.amber500)
                                        .padding()
                                        .background(ClinicalTheme.amber500.opacity(0.1))
                                    }
                                    
                                    if showComplexHelpers {
                                        VStack(alignment: .leading, spacing: 12) {
                                            // Fentanyl Patch
                                            HStack {
                                                Text("Fentanyl Patch").bold().foregroundColor(ClinicalTheme.textPrimary)
                                                Spacer()
                                                Text("Consult").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                                            }
                                            Text("WARNING: Patches take 12-24h to onset. Cover with short-acting. Package insert recommends stricter conversion.").font(.caption).foregroundColor(ClinicalTheme.amber500)
                                            Divider().background(ClinicalTheme.divider)
                                            
                                            // Methadone
                                            HStack {
                                                Text("Methadone").bold().foregroundColor(ClinicalTheme.textPrimary)
                                                Spacer()
                                                Text("Consult Pain Svc").font(.caption).foregroundColor(ClinicalTheme.rose500)
                                            }
                                            Text("DO NOT ESTIMATE. Non-linear kinetics (Ratio 4:1 to 20:1). Risk of accumulation & overdose.").font(.caption).foregroundColor(ClinicalTheme.rose500)
                                        }
                                        .padding()
                                        .background(ClinicalTheme.backgroundCard)
                                    }
                                }
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.amber500.opacity(0.3), lineWidth: 1))
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top)
                }
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .addKeyboardDoneButton() // Applies to all inputs in this view
            .navigationTitle("MME Calculator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TargetDoseCard: View {
    let dose: TargetDose
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
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
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(dose.totalDaily)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ClinicalTheme.teal500)
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
        .clinicalCard()
        .padding(.horizontal)
    }
}
