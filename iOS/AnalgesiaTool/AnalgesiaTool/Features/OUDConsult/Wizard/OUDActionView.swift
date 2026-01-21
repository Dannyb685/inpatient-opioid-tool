import SwiftUI

struct OUDActionView: View {
    @ObservedObject var store: OUDConsultStore
    
    var body: some View {
        ScrollView {
            if let plan = store.generatedPlan {
                VStack(spacing: 24) {
                    
                    // 1. Header Card
                    VStack(spacing: 8) {
                        Image(systemName: "cross.case.fill").font(.largeTitle).foregroundColor(.white)
                        Text(plan.protocolName)
                            .font(.title2).bold().foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(store.medicationName)
                            .font(.subheadline).bold()
                            .padding(6).background(Color.white.opacity(0.2)).cornerRadius(6)
                            .foregroundColor(.white)
                        
                        if !plan.evidenceNote.isEmpty {
                            Text(plan.evidenceNote)
                                .font(.caption).italic().foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(headerColor)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    
                    // 2. Safety Alerts (Dynamic)
                    if !plan.safetyAlerts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Safety Alerts").font(.headline).foregroundColor(.red)
                            ForEach(plan.safetyAlerts, id: \.self) { alert in
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                                    Text(alert)
                                        .font(.subheadline).bold()
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    // 2a. CLINICAL LOGIC TRANSPARENCY (v7.2.3)
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Why this Protocol?")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                            
                            if store.hasLiverFailure {
                                Text("• Liver Failure detected: Methadone contraindicated due to unpredictable metabolism. Short-acting opioids favored.")
                                    .font(.caption)
                            } else if store.isPregnant {
                                Text("• Pregnancy detected: Standard of Care supports Buprenorphine (Subutex) or Methadone. Buprenorphine/Naloxone (Suboxone) is becoming preferred but requires patient consent.")
                                    .font(.caption)
                            } else if plan.protocolName.contains("Micro-Induction") {
                                Text("• High-Potency/Fentanyl Use: Micro-induction (Bernese Method) selected to minimize Precipitated Withdrawal risk.")
                                    .font(.caption)
                            } else {
                                Text("• Standard Stratification: Balanced for safety and efficacy based on COWS score and physiological profile.")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Label("Clinical Logic Breakdown", systemImage: "brain.head.profile")
                            .font(.caption).bold()
                            .foregroundColor(ClinicalTheme.textSecondary)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // 3. Induction Steps
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Protocol Steps").font(.headline)
                            Spacer()
                            Image(systemName: "list.number")
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        
                        ForEach(plan.inductionSteps, id: \.self) { step in
                            HStack(alignment: .top) {
                                Text("•").bold().foregroundColor(.blue)
                                Text(step).font(.body)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            Divider()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // 4. Adjunct Medications
                    if !plan.adjunctMeds.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Symptomatic Management").font(.headline)
                            ForEach(plan.adjunctMeds, id: \.self) { med in
                                Text("• \(med)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    
                    // 5. Proceed
                    Button("Proceed to Discharge") {
                        store.currentPhase = .followUp
                        store.path.append(ConsultPhase.followUp)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No Protocol Generated")
                        .font(.headline)
                    Text("Please complete the risk assessment first.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    var headerColor: Color {
        // Simple logic or can add urgency property to plan
        let name = store.generatedPlan?.protocolName ?? ""
        if name.contains("High-Dose") { return .purple }
        if name.contains("Low-Dose") { return .indigo }
        return .blue
    }
}
