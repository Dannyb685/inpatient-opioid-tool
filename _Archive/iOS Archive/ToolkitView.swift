import SwiftUI

struct ToolkitView: View {
    @StateObject private var store = ToolkitStore()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Tools Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Clinical Tools").font(.headline).foregroundColor(ClinicalTheme.slate400).padding(.leading)
                        
                        NavigationLink(destination: COWSView(store: store)) {
                            ToolkitRow(icon: "thermometer", title: "COWS Assessment", subtitle: "Clinical Opiate Withdrawal Scale")
                        }
                        
                        // Placeholder for ORT or others
                         ToolkitRow(icon: "list.clipboard.fill", title: "ORT (Opioid Risk Tool)", subtitle: "Stratification for aberrant behavior", isComingSoon: true)
                    }
                    .padding(.horizontal)
                    
                    // Evidence & Algorithm Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Evidence & Algorithm").font(.headline).foregroundColor(ClinicalTheme.slate400).padding(.leading)
                        
                        NavigationLink(destination: AlgorithmInfoView()) {
                            ToolkitRow(icon: "function", title: "How This Works", subtitle: "Logic Mappings & Guidelines")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Protocols Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Protocols").font(.headline).foregroundColor(ClinicalTheme.slate400).padding(.leading)
                        
                        NavigationLink(destination: ProtocolDetailView(title: "Temple Protocol", content: "The Temple Protocol (Buprenorphine Induction) involves...\n\n1. Wait for mild withdrawal (COWS > 8)\n2. Administer 4mg Buprenorphine\n3. Re-assess in 2 hours...\n\n(Full text would go here)")) {
                             ToolkitRow(icon: "doc.text.fill", title: "Temple Induction", subtitle: "Precipitated Withdrawal Management")
                        }
                        
                        NavigationLink(destination: ProtocolDetailView(title: "Bernese Method", content: "Micro-dosing induction method...\n\nDay 1: 0.5mg QD\nDay 2: 0.5mg BID\nDay 3: 1mg BID...")) {
                             ToolkitRow(icon: "arrow.triangle.merge", title: "Bernese Method", subtitle: "Micro-dosing Induction")
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .slateBackground()
            .navigationTitle("Toolkit")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ToolkitRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var isComingSoon: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(ClinicalTheme.teal500)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.textSecondary)
            }
            
            Spacer()
            
            if isComingSoon {
                Text("SOON")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(4)
                    .background(ClinicalTheme.slate700)
                    .cornerRadius(4)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.slate700)
            }
        }
        .clinicalCard()
    }
}

struct AlgorithmInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Algorithm & Evidence")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ClinicalTheme.textPrimary)
                
                // 1. Logic Mappings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Logic Mappings").font(.headline).foregroundColor(ClinicalTheme.teal500)
                    
                    Text("Renal Toggle (Quick Mode)")
                        .font(.subheadline).bold()
                    Text("• Maps to eGFR <60 mL/min/1.73m² (CKD Stage 3+).")
                    
                    Text("Hepatic Toggle (Quick Mode)")
                        .font(.subheadline).bold()
                    Text("• Maps to Child-Pugh B (Moderate Impairment) or worse.")
                    
                    Text("Dose Reduction")
                        .font(.subheadline).bold()
                    Text("• Standard 30% reduction applied for cross-tolerance.")
                }
                .clinicalCard()
                
                // 2. Guidelines
                VStack(alignment: .leading, spacing: 10) {
                    Text("Guidelines & Sources").font(.headline).foregroundColor(ClinicalTheme.teal500)
                    
                    Text("• CDC 2022 Clinical Practice Guideline")
                    Text("• NCCN Adult Cancer Pain Guidelines")
                    Text("• Trauma / Acute Pain Management Guidelines")
                }
                .clinicalCard()
                
                Text("This tool is for clinical decision support only. Clinical judgment always supersedes algorithmic recommendations.")
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
        .slateBackground()
        .navigationTitle("Algorithm")
    }
}
