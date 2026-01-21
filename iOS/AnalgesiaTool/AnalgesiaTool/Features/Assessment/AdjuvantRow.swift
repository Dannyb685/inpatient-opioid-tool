import SwiftUI

struct AdjuvantRow: View {
    let item: AdjuvantRecommendation
    
    @State private var showMonograph = false
    
    // Helper to find full DrugData object
    private var linkedDrugData: DrugData? {
        // Simple string matching (e.g. "Gabapentin" in "Gabapentin 300mg")
        return ClinicalData.drugData.first { drug in
            item.drug.localizedCaseInsensitiveContains(drug.name)
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle().fill(ClinicalTheme.teal500.opacity(0.1)).frame(width: 32, height: 32)
                Image(systemName: item.category.contains("Neuropathic") ? "brain.head.profile" : "pills.fill")
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.teal500)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.drug).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                
                Text(item.dose)
                    .font(.caption2).bold()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ClinicalTheme.teal500.opacity(0.1))
                    .foregroundColor(ClinicalTheme.teal500)
                    .cornerRadius(4)
                
                Text(item.rationale)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Citation Link (User Request)
                if linkedDrugData != nil {
                    Button(action: { showMonograph = true }) {
                        Text("citations")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Sheet Presentation
        .sheet(isPresented: $showMonograph) {
            if let drug = linkedDrugData {
                NavigationView {
                    DrugMonographView(drug: drug)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showMonograph = false }
                            }
                        }
                }
            }
        }
    }
}
