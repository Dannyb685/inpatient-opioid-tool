import SwiftUI

struct InformedConsentView: View {
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 48))
                        .foregroundColor(ClinicalTheme.rose500)
                    
                    Text("Informed Consent & Legal Disclaimer")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ClinicalTheme.textPrimary)
                }
                .padding(.top, 40)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        disclaimerSection(title: "Not Medical Advice", content: """
                            This application ("AnalgesiaTool") is a clinical decision support system intended for use ONLY by licensed healthcare professionals. It does NOT provide medical advice, diagnosis, or treatment.
                            
                            Calculations are estimates based on population averages. Individual patient variability in pharmacokinetics, genetics, and comorbidities cannot be fully accounted for.
                            """)
                        
                        disclaimerSection(title: "Clinical Judgment Required", content: """
                            You acknowledge that you are a licensed healthcare professional and will use your own independent clinical judgment when interpreting these results.
                            
                            Do NOT rely solely on this tool for dosing decisions. Always verify calculations with standard references and your institution's protocols.
                            """)
                        
                        disclaimerSection(title: "Pediatric Warning", content: """
                            This tool is NOT validated for pediatric use (patients under 18 years of age). Dosing logic is specific to adult physiology.
                            """)
                        
                        disclaimerSection(title: "Liability Limitation", content: """
                            The developers and affiliates of this application assume no liability for any adverse outcomes, medication errors, or damages resulting from the use or misuse of this software.
                            """)
                    }
                    .padding()
                }
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Action Button
                Button(action: {
                    withAnimation {
                        hasAcceptedDisclaimer = true
                    }
                }) {
                    Text("I Acknowledge & Accept")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ClinicalTheme.teal500)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func disclaimerSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(ClinicalTheme.rose500)
            
            Text(content)
                .font(.body)
                .foregroundColor(ClinicalTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct InformedConsentView_Previews: PreviewProvider {
    static var previews: some View {
        InformedConsentView()
            .environmentObject(ThemeManager.shared)
    }
}
