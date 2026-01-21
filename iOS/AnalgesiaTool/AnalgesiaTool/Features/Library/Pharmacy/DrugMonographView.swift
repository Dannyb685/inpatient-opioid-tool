import SwiftUI

struct DrugMonographView: View {
    // The Single Source of Truth
    let drug: DrugPharmacology
    
    // Environment to dismiss
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: 1. Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(drug.name)
                                .font(.system(.largeTitle, design: .serif)) // Medical feel
                                .bold()
                            Spacer()
                            // Route Badge
                            if let route = drug.route {
                                Text(route)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.teal.opacity(0.15))
                                    .foregroundColor(.teal)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if let subtitle = drug.subtitle {
                            Text(subtitle)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // MARK: 2. PK Grid (Dynamic)
                    if let pk = drug.pkProfile {
                        VStack(alignment: .leading, spacing: 12) {
                            MonographSectionHeader(icon: "timer", title: "Pharmacokinetics")
                            
                            HStack(alignment: .top, spacing: 12) {
                                PKStatBox(label: "Onset", value: pk.onset)
                                
                                // Only show Peak if data exists
                                if let peak = pk.peak {
                                     PKStatBox(label: "Peak", value: peak)
                                }
                                
                                PKStatBox(label: "Duration", value: pk.duration)
                            }
                            
                            // LOGIC GATE: Only show Bioavailability if it exists (e.g. Oral)
                            // This prevents "Oral Bioavailability" showing up on Fentanyl IV cards
                            if let bio = pk.bioavailability {
                                PKStatBox(label: "Oral Bioavailability", value: bio, isBar: true)
                            }
                        }
                    }
                    
                    // MARK: 3. Safety Profile
                    if let safety = drug.safetyProfile {
                        VStack(alignment: .leading, spacing: 12) {
                            MonographSectionHeader(icon: "cross.case.fill", title: "Safety Profile")
                            
                            // Renal Logic
                            if let renal = safety.renalNote {
                                HStack(alignment: .top) {
                                    Image(systemName: "drop.triangle")
                                        .foregroundColor(.orange)
                                    Text(renal)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // MARK: 4. Boxed Warning (Moved to Bottom as requested)
                    if let warning = drug.safetyProfile?.boxedWarning {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("BOXED WARNING")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                            }
                            Text(warning)
                                .font(.callout)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // MARK: 5. Sources Footer
                    if let citations = drug.citations {
                        SourcesFooterView(citations: citations)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Helper for consistent headers
struct MonographSectionHeader: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.teal)
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.bottom, 4)
    }
}
