import SwiftUI

struct SharedClinicalContextView: View {
    @Binding var age: String
    @Binding var analgesicProfile: AnalgesicProfile
    @Binding var renalStatus: RenalStatus
    @Binding var hepaticStatus: HepaticStatus
    @Binding var isPregnant: Bool
    @Binding var isBreastfeeding: Bool
    @Binding var benzos: Bool
    @Binding var isOUD: Bool 
    @Binding var sleepApnea: Bool
    @Binding var reduction: Double // For Taper logic visual
    var reductionGuidance: (Double) -> String // Closure for flexible guidance text
    var reductionColor: (Double) -> Color // Closure for flexible color
    
    // Config
    var isSandboxMode: Bool
    var showReduction: Bool = true // Taper might not use the same slider? Or it has its own strategy card?
    // CalculatorView has "Tolerance & Reduction" inside Clinical Context. Taper does NOT.
    // Taper has "Strategy Card" separately.
    // So for Taper, we might hide the reduction slider in this shared view.
    
    // Safety Actions
    var onRenalEscalation: () -> Void
    var onHepaticEscalation: () -> Void
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cross.case.fill").foregroundColor(ClinicalTheme.teal500)
                Text("Clinical Context").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
            }
            .padding(.horizontal)
            
            // EPHEMERAL STATUS INDICATOR
            EphemeralStatusBanner(isSandboxMode: isSandboxMode)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            VStack(spacing: 12) {
                
                // 1. AGE & PROFILE
                VStack(spacing: 8) {
                    HStack {
                        Text("Patient Age").font(.subheadline).foregroundColor(ClinicalTheme.textSecondary)
                        Spacer()
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .padding(6)
                            .background(ClinicalTheme.backgroundInput)
                            .cornerRadius(6)
                    }
                    
                    HStack {
                        Text("Opioid Profile").font(.subheadline).foregroundColor(ClinicalTheme.textSecondary)
                        Spacer()
                        Menu {
                            Picker("Profile", selection: $analgesicProfile) {
                                ForEach(AnalgesicProfile.allCases, id: \.self) { profile in
                                    Text(profile.rawValue).tag(profile)
                                }
                            }
                        } label: {
                            HStack {
                                Text(analgesicProfile.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(ClinicalTheme.textSecondary)
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(ClinicalTheme.backgroundInput)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(analgesicProfile.color.opacity(0.5), lineWidth: 1.5))
                        }
                    }
                }
                .padding(.bottom, 4)
                
                // 2. PREGNANCY (Standardized)
                Toggle(isOn: $isPregnant) {
                    VStack(alignment: .leading) {
                         Text("Pregnant Person").font(.subheadline).fontWeight(.bold).foregroundColor(ClinicalTheme.textPrimary)
                         Text("Shows warnings / gates logic").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                
                if isPregnant {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(ClinicalTheme.rose500)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Safety Warning").font(.caption).bold().foregroundColor(ClinicalTheme.rose500)
                            Text("Opioid management in pregnancy requires specialist consultation (OB/GYN / Addiction Medicine).")
                                .font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                    .padding(8)
                    .background(ClinicalTheme.rose500.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Toggle(isOn: $isBreastfeeding) {
                    VStack(alignment: .leading) {
                         Text("Breastfeeding").font(.subheadline).fontWeight(.bold).foregroundColor(ClinicalTheme.textPrimary)
                         Text("Logic for infant monitoring").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.purple500))
                
                if isBreastfeeding {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundColor(ClinicalTheme.purple500)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lactation Note").font(.caption).bold().foregroundColor(ClinicalTheme.purple500)
                            Text("Monitor infant for sedation/respiratory depression if patient is using opioids.")
                                .font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                        }
                    }
                    .padding(8)
                    .background(ClinicalTheme.purple500.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 3. RISK FACTORS (Sandbox Overrides)
                Group {
                    Toggle(isOn: $benzos) {
                        Text("Concurrent Benzodiazepines").font(.subheadline)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                    
                    Toggle(isOn: $isOUD) {
                        Text("History of Overdose / SUD").font(.subheadline)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                    
                    Toggle(isOn: $sleepApnea) {
                        Text("Obstructive Sleep Apnea").font(.subheadline)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.amber500))
                }
                
                Divider()
                
                // 4. SAFETY TOGGLES
                // Renal
                Toggle(isOn: Binding(
                    get: { renalStatus != .normal },
                    set: { newValue in
                        withAnimation { renalStatus = newValue ? .impaired : .normal }
                    }
                )) {
                    VStack(alignment: .leading) {
                        Text("Renal Impairment").font(.subheadline).fontWeight(.bold).foregroundColor(ClinicalTheme.textPrimary)
                        Text("eGFR <60 (CKD 3+)").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.amber500))
                
                if renalStatus != .normal {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(renalStatus == .dialysis ? ClinicalTheme.rose500 : ClinicalTheme.amber500)
                            Text("Status: \(renalStatus.rawValue)")
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                        
                        Text("Dialysis status requires strict avoidance of Morphine/Codeine/Meperidine due to neurotoxic metabolite accumulation.")
                            .font(.system(size: 10))
                            .foregroundColor(ClinicalTheme.textSecondary)
                        
                        Button(action: onRenalEscalation) {
                            Text(renalStatus == .dialysis ? "Revert to Standard CKD" : "Escalate to Dialysis")
                                .font(.caption2).fontWeight(.bold)
                                .foregroundColor(renalStatus == .dialysis ? ClinicalTheme.teal500 : ClinicalTheme.rose500)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background((renalStatus == .dialysis ? ClinicalTheme.teal500 : ClinicalTheme.rose500).opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(ClinicalTheme.backgroundMain.opacity(0.5))
                    .cornerRadius(8)
                }
                
                // Hepatic
                Toggle(isOn: Binding(
                    get: { hepaticStatus != .normal },
                    set: { newValue in
                        withAnimation { hepaticStatus = newValue ? .impaired : .normal }
                    }
                )) {
                    VStack(alignment: .leading) {
                        Text("Hepatic Impairment").font(.subheadline).fontWeight(.bold).foregroundColor(ClinicalTheme.textPrimary)
                        Text("Child-Pugh B+").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.amber500))
                
                if hepaticStatus != .normal {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(hepaticStatus == .failure ? ClinicalTheme.rose500 : ClinicalTheme.amber500)
                            Text("Status: \(hepaticStatus.rawValue)")
                                .font(.caption).fontWeight(.bold)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                        
                        Text("Liver Failure (Child-Pugh C) increases Hydromorphone PO bioavailability 4x via portosystemic shunting.")
                            .font(.system(size: 10))
                            .foregroundColor(ClinicalTheme.textSecondary)
                        
                        Button(action: onHepaticEscalation) {
                            Text(hepaticStatus == .failure ? "View Moderate Dosing" : "Escalate to Liver Failure (Child-Pugh C)")
                                .font(.caption2).fontWeight(.bold)
                                .foregroundColor(hepaticStatus == .failure ? ClinicalTheme.teal500 : ClinicalTheme.rose500)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background((hepaticStatus == .failure ? ClinicalTheme.teal500 : ClinicalTheme.rose500).opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(ClinicalTheme.backgroundMain.opacity(0.5))
                    .cornerRadius(8)
                }
                
                // REDUCTION SLIDER (Optional)
                if showReduction {
                    Divider().padding(.vertical, 4)
                    
                    HStack {
                        Text("Cross-Tolerance Reduction").font(.subheadline).foregroundColor(ClinicalTheme.textSecondary)
                        Spacer()
                        Text("-\(Int(reduction))%").font(.headline).fontWeight(.bold).foregroundColor(ClinicalTheme.teal500)
                    }
                    Slider(value: $reduction, in: 0...75, step: 5)
                        .accentColor(ClinicalTheme.teal500)
                    
                    HStack {
                        Spacer()
                        Text(reductionGuidance(reduction))
                            .font(.caption2)
                            .italic()
                            .foregroundColor(reductionColor(reduction))
                            .transition(.opacity)
                    }
                }
            }
            .padding()
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            .padding(.horizontal)
            
            // Logic Footer
             if renalStatus != .normal || hepaticStatus != .normal {
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

