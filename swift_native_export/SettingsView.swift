import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // HEADER
                    VStack(spacing: 8) {
                        Image("Calculator_PixelArt") // Using existing asset or generic
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .cornerRadius(16)
                        
                        Text("Inpatient Opioid Tool")
                            .font(.title2).bold()
                            .foregroundColor(ClinicalTheme.textPrimary)
                        
                        Text("v1.5.4 • Standard of Care: CDC 2022")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ClinicalTheme.teal500.opacity(0.1))
                            .foregroundColor(ClinicalTheme.teal500)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    
                    // SECTION 1: LEGAL DISCLAIMER
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(ClinicalTheme.textMuted)
                            Text("Legal Disclaimer")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                        
                        Text("This application is a Clinical Decision Support (CDS) tool. It is intended to assist, not replace, the clinical judgment of a licensed healthcare provider. The prescriber assumes full responsibility for all dosing decisions.")
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard) // Grayish in Light Mode if configured
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    .padding(.horizontal)
                    
                    // SECTION 2: REFERENCES
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.closed.fill")
                                .foregroundColor(ClinicalTheme.teal500)
                            Text("Clinical References")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            SettingsReferenceRow(title: "CDC Clinical Practice Guideline (2022)", subtitle: "Opioid Prescribing for Pain")
                            Divider()
                            SettingsReferenceRow(title: "NCCN Guidelines", subtitle: "Adult Cancer Pain")
                            Divider()
                            SettingsReferenceRow(title: "ASCO Guidelines (2023)", subtitle: "Management of Chronic Pain")
                        }
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    .padding(.horizontal)
                    
                    // SECTION 3: SAFETY PROTOCOLS
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "shield.check.fill")
                                .foregroundColor(ClinicalTheme.textPrimary) // Dark/Light adaptive
                            Text("Active Safety Protocols")
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            SafetyRow(icon: "figure.child.and.lock.fill", color: ClinicalTheme.rose500, title: "Pediatric Lock", desc: "Blocks calculation for age <18.")
                            SafetyRow(icon: "cross.case.fill", color: ClinicalTheme.amber500, title: "Renal Gate", desc: "Filters Morphine/Codeine in Dialysis/CKD.")
                            SafetyRow(icon: "person.2.fill", color: ClinicalTheme.purple500, title: "Perinatal Mode", desc: "Prioritizes Buprenorphine/Methadone.")
                        }
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("About & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}

struct SettingsReferenceRow: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(ClinicalTheme.textPrimary)
            Text(subtitle).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
        }
    }
}

struct SafetyRow: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                Text(desc).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
            }
        }
    }
}
