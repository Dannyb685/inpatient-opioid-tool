import SwiftUI

struct OUDConsultWizardView: View {
    @StateObject private var store = OUDConsultStore()
    
    var body: some View {
        NavigationStack(path: $store.path) {
            // PHASE 1: SCREENING (ROOT)
            OUDScreeningView(store: store)
                .navigationDestination(for: ConsultPhase.self) { phase in
                    switch phase {
                    case .diagnosis:
                        OUDDiagnosisView(store: store)
                    case .assessment:
                        OUDRiskAssessmentView(store: store)
                    case .action:
                        OUDActionView(store: store)
                    case .followUp:
                        OUDFollowUpView(store: store)
                    default: EmptyView()
                    }
                }
                .navigationTitle(phaseTitle)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Reset") { store.reset() }
                    }
                }
        }
    }
    
    var phaseTitle: String {
        switch store.currentPhase {
        case .screening: return "Screening"
        case .diagnosis: return "Diagnosis"
        case .assessment: return "Assessment"
        case .action: return "Plan"
        case .followUp: return "Discharge"
        }
    }
}
