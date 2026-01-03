import SwiftUI

struct OUDDiagnosisView: View {
    @ObservedObject var store: OUDConsultStore
    
    // DSM-5 Criteria
    let criteria = [
        (1, "Taken in larger amounts/longer than intended"),
        (2, "Persistent desire or unsuccessful efforts to cut down"),
        (3, "Great deal of time spent obtaining/using/recovering"),
        (4, "Craving or strong desire to use"),
        (5, "Recurrent use resulting in failure to fulfill obligations"),
        (6, "Continued use despite social/interpersonal problems"),
        (7, "Important activities given up or reduced"),
        (8, "Recurrent use in hazardous situations"),
        (9, "Use continued despite physical/psychological problem"),
        (10, "Tolerance (Excluded if Medically Supervised)"),
        (11, "Withdrawal (Excluded if Medically Supervised)")
    ]
    
    var body: some View {
        List {
            Section(header: Text("Status")) {
                HStack {
                    Text("Current Severity")
                    Spacer()
                    Text(store.severityClassification.0)
                        .bold().foregroundColor(store.severityClassification.1)
                }
                Toggle("Medically Supervised (Pain Mgmt)", isOn: $store.isMedicallySupervised)
            }
            
            Section(header: Text("DSM-5 Criteria")) {
                ForEach(criteria, id: \.0) { item in
                    let isExcluded = store.isMedicallySupervised && (item.0 == 10 || item.0 == 11)
                    
                    HStack {
                        Image(systemName: store.selectedDSMCriteria.contains(item.0) ? "checkmark.square.fill" : "square")
                            .foregroundColor(isExcluded ? .gray : .blue)
                        Text(item.1)
                            .foregroundColor(isExcluded ? .secondary : .primary)
                            .strikethrough(isExcluded)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isExcluded {
                            if store.selectedDSMCriteria.contains(item.0) { store.selectedDSMCriteria.remove(item.0) } 
                            else { store.selectedDSMCriteria.insert(item.0) }
                        }
                    }
                }
            }
            
            if store.dsmCount >= 2 {
                Button("Confirm & Assess Risk") {
                    store.currentPhase = .assessment
                    store.path.append(ConsultPhase.assessment)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding()
            }
        }
    }
}
