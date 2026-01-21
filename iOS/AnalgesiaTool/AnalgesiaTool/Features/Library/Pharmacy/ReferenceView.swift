import SwiftUI




// MARK: - Data Models (References)
struct ReferenceCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let citationIDs: [String]
}

struct ReferenceLibrary {
    static let categories: [ReferenceCategory] = [
        ReferenceCategory(name: "Core Guidelines", icon: "text.book.closed.fill", citationIDs: [
            "cdc_opioids_2022",
            "va_dod_cpg_2022",
            "cms_conversion_2016",
            "cms_mme_2024"
        ]),
        ReferenceCategory(name: "Special Populations", icon: "person.2.circle.fill", citationIDs: [
            "ags_beers_2023",
            "fda_gabapentin_2019"
        ]),
        ReferenceCategory(name: "Pharmacology & Labels", icon: "pills.fill", citationIDs: [
            "fda_fentanyl_2025",
            "fda_duragesic_2023",
            "fda_morphine_2025",
            "fda_hydromorphone_2025"
        ]),
        ReferenceCategory(name: "Monitoring Protocols", icon: "waveform.path.ecg.rectangle.fill", citationIDs: [
            "monitoring_high_risk_pca",
            "sedation_poss",
            "risk_strat_prodigy",
            "aasm_2025"
        ])
    ]
}

struct ReferenceView: View {
    @EnvironmentObject var store: AssessmentStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var searchText = ""
    // Track expanded item ID locally
    @State private var expandedId: String? = nil
    @State private var showSettings = false // For About/Settings Sheet
    
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
            ReferenceContentView(searchText: $searchText, expandedId: $expandedId)
                .navigationTitle("Pharmacology")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation {
                                    themeManager.isDarkMode.toggle()
                                }
                            }) {
                                Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.stars.fill")
                                    .foregroundColor(ClinicalTheme.textSecondary)
                            }
                            
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(ClinicalTheme.teal500)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
    }
}

struct ReferenceContentView: View {
    @EnvironmentObject var store: AssessmentStore
    // Inject OUD Store for Workup persistence if needed, or use local state for checklist
 
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.citationService) var citationService
    @Binding var searchText: String
    @Binding var expandedId: String? // Kept for API compatibility, though unused now due to Sheet migration
    @State private var selectedMonograph: DrugData? = nil
    // State for Search

    
    var filteredDrugs: [DrugData] {
        if searchText.isEmpty {
            return ClinicalData.drugData
        } else {
            return ClinicalData.drugData.filter { drug in
                drug.name.localizedCaseInsensitiveContains(searchText) ||
                drug.clinicalNuance.localizedCaseInsensitiveContains(searchText) ||
                drug.type.localizedCaseInsensitiveContains(searchText) ||
                drug.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(ClinicalTheme.textSecondary)
                TextField("Search drug, metabolite, mechanism...", text: $searchText)
                    .foregroundColor(ClinicalTheme.textPrimary)
            }
            .padding()
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            .padding()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(filteredDrugs) { drug in
                        ReferenceCard(drug: drug, onTap: {
                             self.selectedMonograph = drug
                        })
                    }
                }
                .padding(.horizontal)
                
                Divider().padding(.vertical, 8)
                
                // Clinical Tools Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Clinical Algorithms")
                        .font(.title2).bold().foregroundColor(ClinicalTheme.teal500)
                        .padding(.horizontal)
                        
                    NavigationLink(destination: NeuropathicMatrixView()) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Neuropathic Efficacy Matrix")
                                    .font(.headline)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                Text("Mechanism-based selection (NMDA/Kappa/Mu)")
                                    .font(.caption)
                                    .foregroundColor(ClinicalTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(ClinicalTheme.teal500)
                        }
                        .padding()
                        .background(ClinicalTheme.backgroundCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                    .padding(.horizontal)
                    
                    NavigationLink(destination: ClinicalMethodologyView()) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Methodology & Evidence")
                                    .font(.headline)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                Text("Opioid Verification & Validation (CDC/FDA/PRODIGY/RIOSORD)")
                                    .font(.caption)
                                    .foregroundColor(ClinicalTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(ClinicalTheme.teal500)
                        }
                        .padding()
                        .background(ClinicalTheme.backgroundCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                    .padding(.horizontal)
                }
                
                Divider().padding(.vertical, 8)
                
                // CITATIONS & REFERENCES SECTION
                VStack(alignment: .leading, spacing: 16) {
                    Text("Clinical References")
                        .font( .title2).bold().foregroundColor(ClinicalTheme.teal500)
                        .padding(.horizontal)
                    
                    // Disclaimer Card
                    DisclaimerCard()
                        .padding(.horizontal)

                    // Reference Categories
                    ForEach(ReferenceLibrary.categories) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: category.icon).foregroundColor(ClinicalTheme.teal500)
                                Text(category.name).font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach(citationService.resolve(category.citationIDs)) { item in
                                    if let urlString = item.url, let url = URL(string: urlString) {
                                        Link(destination: url) {
                                            ReferenceRow(item: item)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        ReferenceRow(item: item)
                                    }
                                    
                                    if item.id != category.citationIDs.last {
                                        Divider()
                                    }
                                }
                            }
                            .background(ClinicalTheme.backgroundCard)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Footer
                    VStack(alignment: .center, spacing: 4) {
                        Text("Opioid Precision v1.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\u{00A9} 2025 Clinical Tools Inc.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
        .sheet(item: $selectedMonograph) { drug in
            NavigationView {
                DrugMonographView(drug: drug, patientContext: store)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") { selectedMonograph = nil }
                        }
                    }
            }
        }
    }
}

struct ReferenceCard: View {
    let drug: DrugData

    // Removed isExpanded
    let onTap: () -> Void
    @EnvironmentObject var store: AssessmentStore
    
    // Computed property for badges using centralized BadgeService
    private var activeBadges: [(label: String, color: Color, icon: String, priority: Int)] {
        // DYNAMIC TAGS (via BadgeService)
        let generatedBadges = BadgeService.shared.generateBadges(for: drug, context: store)
        
        // Map SafetyBadge to tuple format
        var badges: [(label: String, color: Color, icon: String, priority: Int)] = generatedBadges.map {
            (label: $0.label, color: $0.color, icon: $0.icon, priority: $0.priority)
        }
        
        // Suppression Logic (Red Trumps Green)
        if badges.contains(where: { $0.priority == 2 }) {
            // Filter out "Compatible" or "Preferred" (Priority 0)
            badges.removeAll { $0.priority == 0 }
        }
        
        return badges
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(drug.name)
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Dynamic Badges (Consolidated Logic)
                        FlowLayout(spacing: 6, lineSpacing: 6) {
                            ForEach(activeBadges, id: \.label) { b in
                                ReferenceBadgeView(label: b.label, color: b.color, icon: b.icon)
                            }
                        }
                        Text(drug.type)
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textMuted)
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textMuted)
                        // Removed rotationEffect
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
            }
            
            // Expanded content block removed (Moved to Sheet)
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
    }
    
    // Helper to fetch standard orders for both PO and IV if applicable

}

struct ReferenceBadgeView: View {
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
// MARK: - Reference Subviews (ReferenceRow & DisclaimerCard)

struct ReferenceRow: View {
    let item: Citation
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ClinicalTheme.textPrimary)
                
                Text(item.source + " (\(item.year))")
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let excerpt = item.excerpt {
                    Text("\"\(excerpt)\"")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(ClinicalTheme.textMuted)
                        .padding(.top, 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            if item.url != nil {
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.teal500)
                    .padding(.top, 2)
            }
        }
        .padding()
    }
}

struct DisclaimerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                Text("Clinical Decision Support Disclaimer")
                    .font(.headline)
                    .bold()
                    .foregroundColor(ClinicalTheme.textPrimary)
            }
            
            Text("'Opioid Precision' is a clinical decision support tool intended for use by licensed healthcare professionals. The calculation of Morphine Milligram Equivalents (MME) is based on published equianalgesic tables (CDC 2022, ASCO 2023).")
                .font(.caption)
                .foregroundColor(ClinicalTheme.textSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Important Safety Limitations:")
                    .font(.caption)
                    .bold()
                    .foregroundColor(ClinicalTheme.textPrimary)
                
                HStack(alignment: .top) {
                    Text("•").bold()
                    Text("Estimates Only: Patient response varies due to genetics and organ function.")
                }.font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                
                HStack(alignment: .top) {
                    Text("•").bold()
                    Text("Non-Linear Drugs: Methadone & Buprenorphine linear conversion is suppressed to prevent overdose.")
                }.font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                
                HStack(alignment: .top) {
                    Text("•").bold()
                    Text("Pediatric Exclusion: NOT validated for patients <18 years.")
                }.font(.caption).foregroundColor(ClinicalTheme.textSecondary)
            }
            
            Text("This application does not replace clinical judgment. The treating physician is solely responsible for final dosing.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}



// MARK: - Workup Checkbox Component (Moved from OUDConsultView)
