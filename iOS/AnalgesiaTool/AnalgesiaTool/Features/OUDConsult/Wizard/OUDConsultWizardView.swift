import SwiftUI

struct OUDConsultWizardView: View {
    @ObservedObject var store: OUDConsultStore
    @EnvironmentObject var assessmentStore: AssessmentStore
    
    // Mismatch Logic
    var hasContextMismatch: Bool {
        // 1. Pregnancy Mismatch (Most Critical)
        if assessmentStore.isPregnant && !store.isPregnant { return true }
        
        // 2. Liver Failure Mismatch (Child-Pugh C)
        if assessmentStore.hepaticFunction == .failure && !store.hasLiverFailure { return true }
        
        return false
    }
    
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
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink(destination: AberrantBehaviorView()) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        }
                    }
                }
        }
        .overlay(alignment: .top) {
            if hasContextMismatch {
                ContextMismatchBanner(
                    assessmentStore: assessmentStore,
                    oudStore: store
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
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

struct ContextMismatchBanner: View {
    @ObservedObject var assessmentStore: AssessmentStore
    @ObservedObject var oudStore: OUDConsultStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Safety Critical Context Mismatch")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .textCase(.uppercase)
                    
                    Text("Assessment Tab data differs from this isolated module:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                    
                    if assessmentStore.isPregnant && !oudStore.isPregnant {
                        Text("• Assessment: PREGNANT | OUD: Not Pregnant")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                            .padding(.top, 2)
                    }
                    if assessmentStore.hepaticFunction == .failure && !oudStore.hasLiverFailure {
                        Text("• Assessment: LIVER FAILURE | OUD: Intact")
                            .font(.caption2).bold()
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                
                Button(action: {
                    // Quick Sync Action
                    withAnimation {
                        if assessmentStore.isPregnant { oudStore.isPregnant = true }
                        if assessmentStore.hepaticFunction == .failure { oudStore.hasLiverFailure = true }
                    }
                }) {
                    Text("Sync")
                        .font(.caption2).bold()
                        .foregroundColor(ClinicalTheme.rose500)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.white)
                        .cornerRadius(4)
                }
            }
        }
        .padding(12)
        .background(ClinicalTheme.rose500)
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding()
    }
}
