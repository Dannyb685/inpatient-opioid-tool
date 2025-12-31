import SwiftUI

struct SettingsView: View {
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var diagnosticLog: String = ""
    @State private var showDiagnostics: Bool = false
    
    var body: some View {
        NavigationView {
             ScrollView {
                 VStack(alignment: .leading, spacing: 24) {
                     
                     // 1. LEGAL DISCLAIMER (The Shield)
                     VStack(alignment: .leading, spacing: 12) {
                         HStack {
                             Image(systemName: "exclamationmark.shield.fill")
                                 .font(.title2)
                                 .foregroundColor(ClinicalTheme.rose500)
                             Text("Educational Use Only")
                                 .font(.title3).bold()
                                 .foregroundColor(ClinicalTheme.textPrimary)
                         }
                         
                         Text("This application is intended solely as an educational aid for qualified healthcare professionals. It is NOT a substitute for clinical judgment or professional medical advice.")
                             .font(.subheadline)
                             .foregroundColor(ClinicalTheme.textPrimary)
                             .fixedSize(horizontal: false, vertical: true)
                         
                         Text("The authors and developers assume no liability for any diagnosis, treatment, decision, or action taken in reliance upon information contained in this application. Always verify calculations and check official prescribing information.")
                             .font(.caption)
                             .foregroundColor(ClinicalTheme.textSecondary)
                             .fixedSize(horizontal: false, vertical: true)
                     }
                     .clinicalCard()
                     .padding(.horizontal)
                     .padding(.top)
                     
                     // 2. CLINICAL REFERENCES
                     VStack(alignment: .leading, spacing: 12) {
                         HStack {
                             Image(systemName: "book.fill")
                                 .foregroundColor(ClinicalTheme.teal500)
                             Text("Evidence Base")
                                 .font(.headline)
                                 .foregroundColor(ClinicalTheme.textPrimary)
                         }
                         
                         VStack(alignment: .leading, spacing: 8) {
                             Text("CDC Clinical Practice Guideline for Prescribing Opioids for Pain (2022)")
                                 .font(.subheadline).bold()
                                 .foregroundColor(ClinicalTheme.textPrimary)
                             
                             Text("Dowell D, Ragan KR, Jones CM, Baldwin GT, Chou R. MMWR Recomm Rep 2022;71(No. RR-3):1–95.")
                                 .font(.caption)
                                 .foregroundColor(ClinicalTheme.textSecondary)
                                 .italic()
                                 .fixedSize(horizontal: false, vertical: true)
                             
                             Link("View Guideline Source ↗", destination: URL(string: "https://www.cdc.gov/mmwr/volumes/71/rr/rr7103a1.htm")!)
                                 .font(.caption).bold()
                                 .foregroundColor(ClinicalTheme.teal500)
                         }
                         
                         Divider()
                         
                         VStack(alignment: .leading, spacing: 8) {
                             Text("Equianalgesic Dosing Data")
                                 .font(.subheadline).bold()
                                 .foregroundColor(ClinicalTheme.textPrimary)
                             Text("Compiled from CMS, FDA Prescribing Information, and peer-reviewed literature (McPherson 2018).")
                                 .font(.caption)
                                 .foregroundColor(ClinicalTheme.textSecondary)
                                 .fixedSize(horizontal: false, vertical: true)
                         }
                     }
                     .clinicalCard()
                     .padding(.horizontal)
                     
                     // 3. APP INFO
                     VStack(alignment: .leading, spacing: 12) {
                         HStack {
                             Image(systemName: "info.circle")
                                 .foregroundColor(ClinicalTheme.textSecondary)
                             Text("About")
                                 .font(.headline)
                                 .foregroundColor(ClinicalTheme.textPrimary)
                         }
                         
                         HStack {
                             Text("Version").foregroundColor(ClinicalTheme.textSecondary)
                             Spacer()
                             Text("1.0.0 (Release Candidate)").bold().foregroundColor(ClinicalTheme.textPrimary)
                         }
                         
                         Divider()
                         
                         HStack {
                             Text("Build").foregroundColor(ClinicalTheme.textSecondary)
                             Spacer()
                             Text("2025.12.RC1").font(.caption).monospaced().foregroundColor(ClinicalTheme.textSecondary)
                         }
                     }
                     .clinicalCard()
                     .padding(.horizontal)
                     
                     Spacer()
                     
                     // Footer
                     VStack(spacing: 8) {
                         Text("Designed with 🤍 for Patient Safety")
                             .font(.caption2)
                             .foregroundColor(ClinicalTheme.textMuted)
                         Text("© 2025 Inpatient Opioid Tool")
                             .font(.caption2)
                             .foregroundColor(ClinicalTheme.textMuted)
                         
                         // Developer Diagnostics
                         Button("Run Clinical Validation Suite") {
                             diagnosticLog = ValidationEngine.shared.runAll()
                             showDiagnostics = true
                         }
                         .font(.caption2)
                         .foregroundColor(ClinicalTheme.teal500.opacity(0.5))
                         .padding(.top, 20)
                     }
                     .frame(maxWidth: .infinity)
                     .padding(.bottom, 20)
                 }
                 .padding(.vertical)
             }
             .sheet(isPresented: $showDiagnostics) {
                 NavigationView {
                     ScrollView {
                         Text(diagnosticLog)
                             .font(.system(.caption, design: .monospaced))
                             .padding()
                     }
                     .navigationTitle("Validation Results")
                     .navigationBarTitleDisplayMode(.inline)
                 }
             }
             .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
             .navigationTitle("Settings & Info")
             .navigationBarTitleDisplayMode(.inline)
             .toolbar {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button(action: {
                         withAnimation {
                             themeManager.isDarkMode.toggle()
                         }
                     }) {
                         Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.stars.fill")
                             .foregroundColor(ClinicalTheme.teal500)
                     }
                 }
             }
        }
    }
}
