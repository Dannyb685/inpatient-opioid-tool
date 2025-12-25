import SwiftUI

struct ReferenceView: View {
    @State private var searchText = ""
    // Track expanded item ID locally
    @State private var expandedId: String? = nil
    
    var filteredDrugs: [DrugData] {
        if searchText.isEmpty {
            return ClinicalData.drugData
        } else {
            return ClinicalData.drugData.filter { drug in
                drug.name.localizedCaseInsensitiveContains(searchText) ||
                drug.clinicalNuance.localizedCaseInsensitiveContains(searchText) ||
                drug.type.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ClinicalTheme.slate400)
                    TextField("Search drug, metabolite, mechanism...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding()
                .background(ClinicalTheme.slate800)
                .cornerRadius(12)
                .padding()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredDrugs) { drug in
                            ReferenceCard(drug: drug, isExpanded: expandedId == drug.id) {
                                withAnimation(.spring()) {
                                    if expandedId == drug.id {
                                        expandedId = nil
                                    } else {
                                        expandedId = drug.id
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(ClinicalTheme.slate900.edgesIgnoringSafeArea(.all))
            .navigationTitle("Pharmacology")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ReferenceCard: View {
    let drug: DrugData
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(drug.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            SafetyBadge(safety: drug.renalSafety, label: "Renal")
                        }
                        Text(drug.type)
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.slate400)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.slate500)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(ClinicalTheme.slate800)
            }
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // PK Grid
                    HStack(spacing: 12) {
                        // IV Profile
                        VStack(alignment: .leading, spacing: 4) {
                            Text("IV Profile").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.slate500).textCase(.uppercase)
                            Text("\(drug.ivOnset) onset")
                                .font(.caption).foregroundColor(ClinicalTheme.slate300)
                            Text("\(drug.ivDuration) duration")
                                .font(.caption).foregroundColor(ClinicalTheme.slate300)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(ClinicalTheme.slate900)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.slate700, lineWidth: 1))
                        
                        // Bioavailability
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Oral Bioavailability").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.slate500).textCase(.uppercase)
                            HStack {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(ClinicalTheme.slate800).frame(height: 6)
                                        Capsule().fill(ClinicalTheme.teal500)
                                            .frame(width: geo.size.width * (CGFloat(drug.bioavailability) / 100.0), height: 6)
                                    }
                                }
                                .frame(height: 6)
                                
                                Text(drug.bioavailability > 0 ? "\(drug.bioavailability)%" : "N/A")
                                    .font(.caption2).bold().foregroundColor(ClinicalTheme.teal500)
                                    .frame(width: 30, alignment: .trailing)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(ClinicalTheme.slate900)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.slate700, lineWidth: 1))
                    }
                    
                    // Clinical Nuance
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bolt.fill").foregroundColor(ClinicalTheme.amber500).font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clinical Nuance").font(.caption2).fontWeight(.black).foregroundColor(.white).textCase(.uppercase)
                            Text(drug.clinicalNuance)
                                .font(.caption)
                                .foregroundColor(ClinicalTheme.slate300)
                                .lineSpacing(2)
                        }
                    }
                    
                    // Pharmacokinetics
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "waveform.path.ecg").foregroundColor(ClinicalTheme.slate500).font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pharmacokinetics").font(.caption2).fontWeight(.black).foregroundColor(.white).textCase(.uppercase)
                            Text(drug.pharmacokinetics)
                                .font(.caption)
                                .foregroundColor(ClinicalTheme.slate400)
                                .lineSpacing(2)
                        }
                    }
                }
                .padding()
                .background(ClinicalTheme.slate800.opacity(0.5))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ClinicalTheme.slate700),
                    alignment: .top
                )
            }
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.slate700, lineWidth: 1))
    }
}

struct SafetyBadge: View {
    let safety: String
    let label: String
    
    var color: Color {
        switch safety {
        case "Safe": return ClinicalTheme.teal500
        case "Caution": return ClinicalTheme.amber500
        case "Unsafe": return ClinicalTheme.rose500
        default: return ClinicalTheme.slate400
        }
    }
    
    var body: some View {
        Text(safety == "Safe" ? "\(label) Safe" : (safety == "Unsafe" ? "Avoid" : "Caution"))
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
