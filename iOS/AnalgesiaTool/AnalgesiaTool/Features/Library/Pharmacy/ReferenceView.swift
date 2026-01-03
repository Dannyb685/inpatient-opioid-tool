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
    @Binding var expandedId: String?
    @State private var showComplexConversion = false
    
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
                
                Divider().padding(.vertical, 8)
                
             // Complex Conversion Tool (Moved here, scrollable)
            ComplexConversionCard(isExpanded: $showComplexConversion)
                .padding(.horizontal)
                .padding(.bottom, 12)

             Divider().padding(.vertical, 8)
                
                // CITATIONS \u0026 REFERENCES SECTION
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
    }
}

struct ReferenceCard: View {
    let drug: DrugData
    let isExpanded: Bool
    let onTap: () -> Void
    @EnvironmentObject var store: AssessmentStore
    
    var body: some View {
        let renalBadge = drug.getRenalBadge(patientRenal: store.renalFunction)
        let hepaticBadge = drug.getHepaticBadge(patientHepatic: store.hepaticFunction)
        
        return VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(drug.name)
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                            

                            // Dynamic Badges
                            ReferenceBadgeView(label: renalBadge.label, color: renalBadge.color, icon: renalBadge.icon)
                            if hepaticBadge.label != "Compatible" {
                                ReferenceBadgeView(label: hepaticBadge.label, color: hepaticBadge.color, icon: hepaticBadge.icon)
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
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
            }
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // PK Grid
                    HStack(spacing: 16) {
                        // IV Profile
                        VStack(alignment: .leading, spacing: 6) {
                            Text("IV Profile").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase)
                            Text("\(drug.ivOnset) onset")
                                .font(.caption).foregroundColor(ClinicalTheme.textPrimary)
                            Text("\(drug.ivDuration) duration")
                                .font(.caption).foregroundColor(ClinicalTheme.textPrimary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ClinicalTheme.backgroundMain)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                        
                        // Bioavailability
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Oral Bio").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase)
                            HStack {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(ClinicalTheme.cardBorder).frame(height: 6)
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
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ClinicalTheme.backgroundMain)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                    
                    // Clinical Nuance
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bolt.fill").foregroundColor(ClinicalTheme.amber500).font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clinical Nuance").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.textPrimary).textCase(.uppercase)
                            Text(drug.clinicalNuance)
                                .font(.caption)
                                .foregroundColor(ClinicalTheme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    
                    // Pharmacokinetics
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "waveform.path.ecg").foregroundColor(ClinicalTheme.textSecondary).font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pharmacokinetics").font(.caption2).fontWeight(.black).foregroundColor(ClinicalTheme.textPrimary).textCase(.uppercase)
                            Text(drug.pharmacokinetics)
                                .font(.caption)
                                .foregroundColor(ClinicalTheme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                }
                .padding()
                .background(ClinicalTheme.backgroundCard.opacity(0.5))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(ClinicalTheme.divider),
                    alignment: .top
                )
            }
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
    }
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

// MARK: - Complex Conversion Card (Moved from Calculator)
struct ComplexConversionCard: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                    Text("Complex Conversions (Palliative)")
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(Font.caption.weight(.bold))
                .foregroundColor(ClinicalTheme.amber500)
                .padding()
                .background(ClinicalTheme.amber500.opacity(0.1))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Patch
                    HStack {
                        Text("Fentanyl Patch").bold().foregroundColor(ClinicalTheme.textPrimary)
                        Spacer()
                        Text("Consult").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                    Text("WARNING: Patches take 12-24h to onset. Cover with short-acting during transition.")
                        .font(.caption).foregroundColor(ClinicalTheme.amber500)
                    
                    Divider().background(ClinicalTheme.divider)
                    
                    // Methadone
                    HStack {
                        Text("Methadone").bold().foregroundColor(ClinicalTheme.textPrimary)
                        Spacer()
                        Text("Consult Pain Svc").font(.caption).bold().foregroundColor(ClinicalTheme.rose500)
                    }
                    Text("DO NOT ESTIMATE. Non-linear kinetics (Ratio 4:1 to 20:1). Risk of accumulation & overdose.")
                        .font(.caption).foregroundColor(ClinicalTheme.rose500)
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
            }
        }
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.amber500.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Workup Checkbox Component (Moved from OUDConsultView)

