import SwiftUI




// MARK: - Data Models (References)
struct ReferenceItem: Identifiable {
    let id = UUID()
    let title: String
    let citation: String
    let urlString: String
}

struct ReferenceCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let items: [ReferenceItem]
}

struct ReferenceLibrary {
    static let categories: [ReferenceCategory] = [
        ReferenceCategory(name: "Core Guidelines", icon: "text.book.closed.fill", items: [
            ReferenceItem(
                title: "CDC Clinical Practice Guideline (2022)",
                citation: "Dowell D, et al. MMWR Recomm Rep. 2022;71(3):1–95.",
                urlString: "https://doi.org/10.15585/mmwr.rr7103a1"
            ),
            ReferenceItem(
                title: "VA/DoD Clinical Practice Guideline",
                citation: "VA/DoD CPG for Opioids in Chronic Pain. Dept of Veterans Affairs; 2022.",
                urlString: "https://www.healthquality.va.gov/guidelines/Pain/cot/"
            )
        ]),
        ReferenceCategory(name: "Special Populations", icon: "person.2.circle.fill", items: [
            ReferenceItem(
                title: "AGS Beers Criteria® (2023)",
                citation: "AGS Expert Panel. J Am Geriatr Soc. 2023;71(7):2052-2081.",
                urlString: "https://doi.org/10.1111/jgs.18372"
            )
        ]),
        ReferenceCategory(name: "Pharmacology & Labels", icon: "pills.fill", items: [
            ReferenceItem(
                title: "Fentanyl Patch (Duragesic)",
                citation: "FDA. Duragesic (Fentanyl Transdermal System). Revised 2023.",
                urlString: "https://www.accessdata.fda.gov/drugsatfda_docs/label/2005/19813s039lbl.pdf"
            )
        ]),
        ReferenceCategory(name: "Monitoring Protocols", icon: "waveform.path.ecg.rectangle.fill", items: [
            ReferenceItem(
                title: "High-Risk PCA Monitoring",
                citation: "Evidence-based monitoring for high-risk PCA patients with obesity or OSA should include continuous pulse oximetry and, when available, capnography, combined with frequent sedation assessment using validated scales. The American Society of Anesthesiologists recommends increased monitoring intensity and duration for patients at increased risk of respiratory depression, specifically identifying obesity and obstructive sleep apnea as high-risk conditions requiring enhanced surveillance.[1] Continuous pulse oximetry is strongly recommended for all patients at increased perioperative risk from OSA until they can maintain baseline oxygen saturation on room air.[2]\n\nHowever, pulse oximetry alone has significant limitations—hypoxemia may be a very late sign of hypoventilation, especially in patients receiving supplemental oxygen.[3] Capnography provides earlier detection of respiratory compromise than pulse oximetry alone by identifying hypercarbia before hypoxemia develops.[3-4] The PRODIGY study demonstrated that continuous capnography and oximetry monitoring detected respiratory depression episodes in 46% of general care floor patients receiving parenteral opioids, with affected patients experiencing hospital stays 3 days longer than those without respiratory depression.[5]",
                urlString: ""
            ),
            ReferenceItem(
                title: "Sedation Assessment (POSS)",
                citation: "Sedation monitoring is critical and may be more reliable than respiratory rate alone. The National Comprehensive Cancer Network recommends using validated tools such as the Pasero Opioid-Induced Sedation Scale (POSS), noting that sedation typically precedes respiratory depression.[4] Respiratory rates below 8-10 breaths per minute are commonly used thresholds, but this measure is unreliable—some patients maintain normal respiratory rates even with severe OIVI, while carbon dioxide concentrations correlate better with sedation level than with respiratory rate.[3] Oversedation in any patient receiving opioids should be considered OIVI until proven otherwise, regardless of respiratory rate or oxygen saturation.[3]",
                urlString: ""
            ),
            ReferenceItem(
                title: "Risk Stratification (PRODIGY)",
                citation: "Risk stratification using the PRODIGY score can guide monitoring intensity. The validated prediction tool identifies five independent risk factors: age ≥60 years, male sex, opioid naivety, sleep disorders, and chronic heart failure, with an odds ratio of 6.07 between high- and low-risk groups.[5] Implementation of this score to determine need for continuous monitoring may reduce the incidence and consequences of respiratory compromise. Continuous monitoring should be maintained as long as patients remain at increased risk and may be provided in critical care units, stepdown units, telemetry on hospital wards, or by dedicated trained observers.[2]",
                urlString: ""
            ),
            ReferenceItem(
                title: "AASM Guidelines (2025)",
                citation: "Adjunctive strategies enhance safety beyond monitoring alone. Supplemental oxygen should be administered continuously until patients maintain baseline saturation on room air.[2] Patients using CPAP or noninvasive positive pressure ventilation preoperatively should continue these therapies postoperatively unless contraindicated.[2] For PCA specifically, continuous background infusions should be avoided or used with extreme caution in OSA patients.[2] The American Academy of Sleep Medicine's 2025 guideline notes that while physiologic monitoring shows promise, evidence remains limited, and implementation challenges include sensor displacement and alarm fatigue.",
                urlString: ""
            )
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
                                ForEach(category.items) { item in
                                    if let url = URL(string: item.urlString) {
                                        Link(destination: url) {
                                            ReferenceRow(item: item)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        ReferenceRow(item: item)
                                    }
                                    
                                    if item.id != category.items.last?.id {
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
    let item: ReferenceItem
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(ClinicalTheme.textPrimary)
                
                Text(item.citation)
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "arrow.up.right.square")
                .font(.caption)
                .foregroundColor(ClinicalTheme.teal500)
                .padding(.top, 2)
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
