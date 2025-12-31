import SwiftUI

struct PatientSharedDecisionView: View {
    @EnvironmentObject var store: AssessmentStore
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // 1. RISK METER
                    VStack(spacing: 16) {
                        Text("Your Overdose Risk")
                            .font(.title2).bold()
                            .foregroundColor(ClinicalTheme.textSecondary)
                        
                        RiskMeter(riskLevel: store.prodigyRisk)
                        
                        Text("Score: \(store.prodigyRisk)")
                            .font(.largeTitle).fontWeight(.black)
                            .foregroundColor(riskColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    
                    // 2. THE PLAN
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Our Safety Plan")
                            .font(.title2).bold()
                            .foregroundColor(ClinicalTheme.textPrimary)
                        
                        PlanRow(icon: "arrow.down.circle.fill", color: ClinicalTheme.teal500, title: "Lower Dose", subtitle: "Reducing total opioid load reduces risk.")
                        
                        if store.benzos {
                            PlanRow(icon: "exclamationmark.triangle.fill", color: ClinicalTheme.rose500, title: "Avoid Sedatives", subtitle: "Combining pills increases danger.")
                        }
                        
                        if store.sleepApnea || store.copd {
                            PlanRow(icon: "lungs.fill", color: ClinicalTheme.amber500, title: "Protect Breathing", subtitle: "Your lungs are extra sensitive.")
                        }
                        
                        PlanRow(icon: "cross.case.fill", color: ClinicalTheme.teal500, title: "Naloxone", subtitle: "Emergency safety medication.")
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(20)
                    
                    Spacer()
                }
                .padding()
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Shared Decision Aid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
    
    var riskColor: Color {
        switch store.prodigyRisk {
        case "High": return ClinicalTheme.rose500
        case "Intermediate": return ClinicalTheme.amber500
        default: return ClinicalTheme.teal500
        }
    }
}

struct RiskMeter: View {
    let riskLevel: String
    
    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(ClinicalTheme.teal500)
                .frame(height: 20)
                .opacity(riskLevel == "Low" ? 1.0 : 0.3)
            
            Rectangle()
                .fill(ClinicalTheme.amber500)
                .frame(height: 20)
                .opacity(riskLevel == "Intermediate" ? 1.0 : 0.3)
            
            Rectangle()
                .fill(ClinicalTheme.rose500)
                .frame(height: 20)
                .opacity(riskLevel == "High" ? 1.0 : 0.3)
        }
        .cornerRadius(10)
        .overlay(
            // Arrow indicator could go here
            EmptyView()
        )
    }
}

struct PlanRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).bold().foregroundColor(ClinicalTheme.textPrimary)
                Text(subtitle).font(.body).foregroundColor(ClinicalTheme.textSecondary)
            }
        }
    }
}
