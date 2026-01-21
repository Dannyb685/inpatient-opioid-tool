import SwiftUI

struct NeuropathicMatrixView: View {
    
    // Data Structure matching User Request
    struct MatrixRow: Identifiable {
        let id = UUID()
        let opioid: String
        let primaryClass: String
        let nociceptive: String
        let neuropathic: String
        let advantage: String
        let color: Color // Visual encoding of Efficacy
    }
    
    let data: [MatrixRow] = [
        MatrixRow(opioid: "Methadone", primaryClass: "Atypical", nociceptive: "Excellent", neuropathic: "Excellent", advantage: "NMDA Antagonism (blocks sensitization)", color: ClinicalTheme.teal500),
        MatrixRow(opioid: "Levorphanol", primaryClass: "Atypical", nociceptive: "Excellent", neuropathic: "Excellent", advantage: "NMDA Antagonism + SNRI activity", color: ClinicalTheme.teal500),
        MatrixRow(opioid: "Tapentadol", primaryClass: "Atypical", nociceptive: "Good", neuropathic: "Good", advantage: "NRI (restores descending inhibition)", color: .blue),
        MatrixRow(opioid: "Buprenorphine", primaryClass: "Partial Agonist", nociceptive: "Good", neuropathic: "Good", advantage: "Kappa Antagonism (anti-hyperalgesic)", color: .blue),
        MatrixRow(opioid: "Oxycodone", primaryClass: "Pure Agonist", nociceptive: "Excellent", neuropathic: "Fair/Poor", advantage: "Slightly better coverage than morphine", color: .orange),
        MatrixRow(opioid: "Morphine", primaryClass: "Pure Agonist", nociceptive: "Excellent", neuropathic: "Poor", advantage: "Prone to tolerance/resistance", color: ClinicalTheme.rose500),
        MatrixRow(opioid: "Fentanyl", primaryClass: "Pure Agonist", nociceptive: "Excellent", neuropathic: "Poor", advantage: "High risk of hyperalgesia", color: ClinicalTheme.rose500)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    Text("Neuropathic Advantage Matrix")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Comparison of Opioid Classes for Neuropathic Pain Efficacy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Table
                VStack(spacing: 0) {
                    // Header Row
                    HStack {
                        Text("Opioid")
                            .font(.caption).fontWeight(.bold)
                            .frame(width: 80, alignment: .leading)
                        Text("Nociceptive")
                            .font(.caption).fontWeight(.bold)
                            .frame(width: 70, alignment: .center)
                        Text("Neuropathic")
                            .font(.caption).fontWeight(.bold)
                            .frame(width: 70, alignment: .center)
                        Text("Key Mechanism")
                            .font(.caption).fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    
                    Divider()
                    
                    // Data Rows
                    ForEach(data) { row in
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(row.opioid)
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text(row.primaryClass)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 80, alignment: .leading)
                                
                                Text(row.nociceptive)
                                    .font(.caption)
                                    .frame(width: 70, alignment: .center)
                                
                                Text(row.neuropathic)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(row.color)
                                    .frame(width: 70, alignment: .center)
                                
                                Text(row.advantage)
                                    .font(.caption2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                // Explainer
                VStack(alignment: .leading, spacing: 10) {
                    Text("Clinical Insight")
                        .font(.headline)
                    
                    Text("Classic opioids (Morphine, Fentanyl) target Mu-receptors but do not address NMDA-mediated central sensitization, which drives neuropathic pain. Atypical opioids with dual mechanisms (NMDA antagonism or NRI activity) demonstrate superior efficacy.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitle("Neuropathic Matrix", displayMode: .inline)
        .background(Color(.systemGroupedBackground))
    }
}

// Preview
struct NeuropathicMatrixView_Previews: PreviewProvider {
    static var previews: some View {
        NeuropathicMatrixView()
    }
}
