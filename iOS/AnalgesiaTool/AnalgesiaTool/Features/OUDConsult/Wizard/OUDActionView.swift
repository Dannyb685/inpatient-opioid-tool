import SwiftUI

struct OUDActionView: View {
    @ObservedObject var store: OUDConsultStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Protocol Card
                VStack(spacing: 8) {
                    Image(systemName: iconName).font(.largeTitle).foregroundColor(.white)
                    Text(protocolTitle).font(.title2).bold().foregroundColor(.white)
                    Text(store.medicationName)
                        .font(.subheadline).bold()
                        .padding(6).background(Color.white.opacity(0.2)).cornerRadius(6)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity).padding().background(protocolColor).cornerRadius(12)
                
                // Detailed Instructions
                if store.recommendedProtocol == .microInduction {
                    BerneseTable()
                } else if store.recommendedProtocol == .highDoseBup {
                    InfoCard(title: "High-Dose Protocol", bodyText: "Administer 8-16mg immediately. Repeat q1h as needed.")
                } else if store.recommendedProtocol == .standardBup {
                    InfoCard(title: "Standard Induction", bodyText: "Give 4mg/2mg. Repeat in 1 hour if COWS > 8.")
                } else if store.recommendedProtocol == .symptomManagement {
                    InfoCard(title: "Supportive Care", bodyText: "COWS too low. Treat symptoms (Clonidine, Zofran). Reassess in 2h.")
                } else if store.recommendedProtocol == .fullAgonist {
                     InfoCard(title: "Specialist Consult", bodyText: "Rotate to Methadone or split-dose Oxycodone due to contraindications.")
                }
                
                Button("Proceed to Discharge") {
                    store.currentPhase = .followUp
                    store.path.append(ConsultPhase.followUp)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    var protocolColor: Color {
        switch store.recommendedProtocol {
        case .standardBup, .highDoseBup: return .blue
        case .microInduction: return .indigo
        case .symptomManagement: return .orange
        case .fullAgonist: return .purple
        }
    }
    
    var iconName: String {
        store.recommendedProtocol == .symptomManagement ? "clock.arrow.circlepath" : "cross.case.fill"
    }
    
    var protocolTitle: String {
        switch store.recommendedProtocol {
        case .standardBup: return "Standard Induction"
        case .highDoseBup: return "High-Dose Rapid Induction"
        case .microInduction: return "Bernese Method (Micro)"
        case .symptomManagement: return "Symptom Management"
        case .fullAgonist: return "Full Agonist Rotation"
        }
    }
}

// Helpers
struct InfoCard: View {
    let title: String, bodyText: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Text(bodyText).font(.body).foregroundColor(.secondary)
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(.secondarySystemBackground)).cornerRadius(12)
    }
}

struct BerneseTable: View {
    let steps = [
        ("Day 1", "0.5 mg once", "Continue full agonist"),
        ("Day 2", "0.5 mg BID", ""),
        ("Day 3", "1 mg BID", ""),
        ("Day 4", "2 mg BID", ""),
        ("Day 5", "3 mg BID", ""),
        ("Day 6", "4 mg BID", ""),
        ("Day 7", "12 mg (Stop agonist)", "Discontinue other opioids")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Micro-Dosing Schedule").font(.headline).padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.indigo.opacity(0.1))
            ForEach(steps, id: \.0) { step in
                HStack {
                    Text(step.0).bold().frame(width: 60, alignment: .leading)
                    VStack(alignment: .leading) {
                        Text(step.1).font(.system(.body, design: .monospaced))
                        if !step.2.isEmpty { Text(step.2).font(.caption).foregroundColor(.red) }
                    }
                }.padding().padding(.vertical, 4)
                Divider()
            }
        }.cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
    }
}
