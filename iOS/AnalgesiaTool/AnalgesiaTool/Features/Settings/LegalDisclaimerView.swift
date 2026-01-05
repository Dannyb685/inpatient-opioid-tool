import SwiftUI

struct LegalDisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Legal Disclaimers & Terms of Use")
                        .font(.title2).bold()
                        .foregroundColor(ClinicalTheme.textPrimary)
                    Text("The following terms constitute a binding agreement between you and the Application Developers. Use of this Application constitutes acceptance.")
                        .font(.subheadline)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
                .padding(.bottom, 8)

                // 1. Core Disclaimers
                DisclaimerSection(title: "1. Core & Clinical Disclaimers", items: [
                    ("No Medical Advice", "THIS APPLICATION IS AN EDUCATIONAL TOOL ONLY. It does NOT provide medical advice, professional diagnosis, opinion, treatment, or services to you or to any other individual. The information provided is for educational and informational purposes only and is not a substitute for the independent professional judgment of a healthcare provider."),
                    ("Licensed Provider Use Only", "By using this Application, you represent and warrant that you are a validly licensed healthcare professional in good standing in your jurisdiction. This Application is NOT intended for use by patients or the general public."),
                    ("No Provider–Patient Relationship", "Use of this Application does not create a physician-patient or provider-patient relationship between you and the Developers, nor does it create any duty of care."),
                    ("Compliance with Law", "You are solely responsible for compliance with all applicable local, state, and federal laws regarding the prescribing of controlled substances, including DEA and CDC regulations. Content in this Application may not reflect the most current legal developments.")
                ])
                
                // 2. Opioid-Specific Risk Disclaimers
                DisclaimerSection(title: "2. Opioid & Safety Risks", items: [
                    ("Controlled Substances", "This Application DOES NOT authorize, prescribe, or dispense controlled substances. All dosing and prescribing decisions regarding opioids are the sole and exclusive responsibility of the licensed provider, who must account for individual patient factors."),
                    ("Clinical Variability", "Algorithms used in this Application do NOT account for individual patient history, comorbidities, polypharmacy, genetics, or risk of misuse. Outputs may be inappropriate for specific clinical scenarios."),
                    ("No Emergency Use", "This Application is NOT designed for use in the diagnosis or treatment of medical emergencies, including but not limited to overdose or acute withdrawal. In an emergency, standard clinical protocols must be followed immediately.")
                ])
                
                // 3. Technology & Data Disclaimers
                DisclaimerSection(title: "3. Technology Limitations", items: [
                    ("Algorithmic Limitation", "The algorithms and data provided are subject to error, bias, and potential inaccuracies. They are based on static guidelines which may become outdated. The Application does not guarantee clinical outcomes or patient safety."),
                    ("No Warranty (AS IS)", "THIS APPLICATION IS PROVIDED ON AN \"AS IS\" AND \"AS AVAILABLE\" BASIS. TO THE FULLEST EXTENT PERMITTED BY LAW, THE DEVELOPERS DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.")
                ])
                
                // 4. Legal Protection Clauses
                DisclaimerSection(title: "4. Legal Protections", items: [
                    ("Limitation of Liability", "TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING PROCUREMENT OF SUBSTITUTE GOODS; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT, ARISING IN ANY WAY OUT OF THE USE OF THIS APPLICATION."),
                    ("Indemnification", "You agree to defend, indemnify, and hold harmless the Developers from and against any claims, liabilities, damages, judgments, awards, losses, costs, expenses, or fees (including reasonable attorneys' fees) resulting from your violation of these Terms or your use of the Application, including any clinical decisions made using its data."),
                    ("Governing Law", "These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which the Developers act, without giving effect to any principles of conflicts of law.")
                ])
            }
            .padding()
        }
        .navigationTitle("Legal")
        .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
    }
}

struct DisclaimerSection: View {
    let title: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(ClinicalTheme.teal500)
                .padding(.bottom, 4)
            
            ForEach(items, id: \.0) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.0)
                        .font(.subheadline).bold()
                        .foregroundColor(ClinicalTheme.textPrimary)
                    Text(item.1)
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if item.0 != items.last?.0 {
                    Divider().padding(.vertical, 4)
                }
            }
        }
        .clinicalCard()
    }
}
