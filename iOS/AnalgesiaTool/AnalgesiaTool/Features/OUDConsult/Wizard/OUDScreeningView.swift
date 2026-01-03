import SwiftUI

struct OUDScreeningView: View {
    @ObservedObject var store: OUDConsultStore
    
    var body: some View {
        Form {
            Section(header: Text("Pre-Screen (NIDA)")) {
                Text("In the past year, has the patient used an illegal drug or used a prescription medication for non-medical reasons?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Positive Screen", isOn: $store.nidaScreenPositive)
            }
            
            if store.nidaScreenPositive {
                Section(header: Text("DAST-10 Assessment")) {
                    Stepper("DAST-10 Score: \(store.dastScore)", value: $store.dastScore, in: 0...10)
                    
                    HStack {
                        Text("Risk Level:")
                        Spacer()
                        Text(riskLabel)
                            .bold()
                            .foregroundColor(riskColor)
                    }
                }
                
                Section {
                    Button(action: {
                        store.currentPhase = .diagnosis
                        store.path.append(ConsultPhase.diagnosis)
                    }) {
                        Text("Proceed to Diagnosis")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            } else {
                Section {
                    Text("Screening Negative. No further intervention required.")
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    var riskLabel: String {
        switch store.dastScore {
        case 0: return "None"
        case 1...2: return "Low"
        case 3...5: return "Moderate"
        case 6...10: return "Severe"
        default: return ""
        }
    }
    
    var riskColor: Color {
        store.dastScore >= 3 ? .red : .orange
    }
}
