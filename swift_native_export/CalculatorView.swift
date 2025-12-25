import SwiftUI

struct CalculatorView: View {
    @StateObject private var store = CalculatorStore()
    @State private var showComplexHelpers = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - PINNED MME TOTAL
                VStack(spacing: 12) {
                    Text("Total 24h MME (Oral)").font(.caption).foregroundColor(ClinicalTheme.slate400).textCase(.uppercase)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(store.resultMME)
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(ClinicalTheme.teal500)
                        Text("mg/day")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(ClinicalTheme.slate400)
                            .padding(.bottom, 6)
                    }
                    if !store.warningText.isEmpty {
                        Text(store.warningText)
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.amber500)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .clinicalCard()
                .padding()
                .background(ClinicalTheme.slate900)
                .zIndex(1)
                
                // MARK: - SCROLLABLE CONTENT
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // INPUTS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Parameters").font(.headline).foregroundColor(ClinicalTheme.slate400).padding(.horizontal)
                            Text("Estimate only. Do NOT use for Methadone conversion.")
                                .font(.caption).bold().foregroundColor(ClinicalTheme.rose500)
                                .padding(.horizontal)
                            
                            // Morphine Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Morphine IV (24h Total)").font(.caption).foregroundColor(ClinicalTheme.teal500).textCase(.uppercase)
                                HStack {
                                    TextField("0", text: $store.morphineIV)
                                        .keyboardType(.decimalPad)
                                        .font(.title3)
                                        .padding()
                                        .background(ClinicalTheme.slate800)
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                    Text("mg")
                                        .foregroundColor(ClinicalTheme.slate400)
                                }
                            }
                            .clinicalCard()
                            .padding(.horizontal)
                            
                            // Toggles
                            VStack(spacing: 16) {
                                Picker("Tolerance", selection: $store.tolerance) {
                                    ForEach(ToleranceStatus.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                                
                                Picker("Context", selection: $store.context) {
                                    ForEach(ConversionContext.allCases) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.segmented)
                                
                                // Slider
                                if !(store.context == .routeSwitch && store.tolerance == .tolerant) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Reduction").font(.caption).foregroundColor(ClinicalTheme.teal500).textCase(.uppercase)
                                            Spacer()
                                            Text("-\(Int(store.reduction))%")
                                                .font(.headline).foregroundColor(ClinicalTheme.amber500)
                                        }
                                        Slider(value: $store.reduction, in: 0...75, step: 5).accentColor(ClinicalTheme.amber500)
                                    }
                                }
                            }
                            .padding().background(ClinicalTheme.slate800).cornerRadius(12).padding(.horizontal)
                        }
                        
                        // TARGET DOSES
                        if !store.targetDoses.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Estimated Targets").font(.headline).foregroundColor(ClinicalTheme.slate400).padding(.horizontal)
                                
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
                                                Text("Fentanyl Patch").bold().foregroundColor(.white)
                                                Spacer()
                                                Text("Consult").font(.caption).foregroundColor(ClinicalTheme.slate400)
                                            }
                                            Text("WARNING: Patches take 12-24h to onset. Cover with short-acting. Package insert recommends stricter conversion.").font(.caption).foregroundColor(ClinicalTheme.amber500)
                                            Divider().background(ClinicalTheme.slate700)
                                            
                                            // Methadone
                                            HStack {
                                                Text("Methadone").bold().foregroundColor(.white)
                                                Spacer()
                                                Text("Consult Pain Svc").font(.caption).foregroundColor(ClinicalTheme.rose500)
                                            }
                                            Text("DO NOT ESTIMATE. Non-linear kinetics (Ratio 4:1 to 20:1). Risk of accumulation & overdose.").font(.caption).foregroundColor(ClinicalTheme.rose500)
                                        }
                                        .padding()
                                        .background(ClinicalTheme.slate800)
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
            .background(ClinicalTheme.slate900.edgesIgnoringSafeArea(.all))
            .navigationTitle("MME Calculator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TargetDoseCard: View {
    let dose: TargetDose
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(dose.drug) \(dose.route)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(dose.ratioLabel)
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.slate400)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(dose.totalDaily)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ClinicalTheme.teal500)
                    Text(dose.unit + "/24h")
                        .font(.caption)
                        .scaleEffect(0.8)
                        .foregroundColor(ClinicalTheme.slate400)
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
