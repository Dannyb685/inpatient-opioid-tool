import SwiftUI

struct DrugMonographView: View {
    // The Single Source of Truth
    let drug: DrugData
    var patientContext: AssessmentStore? // Optional if not always used, or @ObservedObject if needed. ReferenceView passes it.
    
    // Environment to dismiss
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.citationService) var citationService
    
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
                        
                        // Type Badge
                        Text(drug.type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    
                    // MARK: 2. Clinical Nuance (NEW)
                    VStack(alignment: .leading, spacing: 12) {
                        MonographSectionHeader(icon: "brain.head.profile", title: "Clinical Pharmacodynamics")
                        
                        Text(drug.clinicalNuance)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.2), lineWidth: 1))
                    }
                    
                    // MARK: 3. PK Grid (Dynamic)
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
                            if let bio = pk.bioavailability {
                                PKStatBox(label: "Oral Bioavailability", value: bio, isBar: true)
                            }
                            
                            // Pharmacokinetics Text (NEW)
                            // Display the detailed PK string from DrugData
                             Text(drug.pharmacokinetics)
                                 .font(.subheadline)
                                 .foregroundColor(.secondary)
                                 .padding(.top, 4)
                        }
                    }
                    
                    // MARK: 4. Safety Profile
                    if let safety = drug.safetyProfile {
                        VStack(alignment: .leading, spacing: 12) {
                            MonographSectionHeader(icon: "cross.case.fill", title: "Safety Profile")
                            
                            // Renal Logic
                            if let renal = safety.renalNote {
                                HStack(alignment: .top) {
                                    Image(systemName: "drop.triangle")
                                        .foregroundColor(drug.renalSafety == "Unsafe" ? .red : .orange)
                                    Text(renal)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(drug.renalSafety == "Unsafe" ? Color.red.opacity(0.05) : Color.orange.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // MARK: 5. Boxed Warning
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
                    
                    // MARK: 6. Detailed Warnings (NEW)
                    // Currently using blackBoxWarnings array if available, or just generic detailed warnings
                    // For now, let's just stick to what DrugData has.
                    // The user prompted textual updates were put into 'clinicalNuance' and 'pharmacokinetics'.
                    // We can also check detailedWarnings if any were added.
                    
                    
                    // MARK: 7. Sources Footer
                    if !drug.citations.isEmpty {
                        // Resolve using the service
                        CitationFooter(citations: citationService.resolveOrLegacy(drug.citations))
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
