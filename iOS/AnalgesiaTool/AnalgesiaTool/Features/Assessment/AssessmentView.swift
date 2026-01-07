import SwiftUI

struct AssessmentView: View {
    @EnvironmentObject var store: AssessmentStore // Inject the shared logic
    @State private var showCopyAlert = false
    @State private var isRecommendationsExpanded = false // Sticky Drawer State
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 24) {
                    
                    // 1. PATIENT PROFILE
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "person.text.rectangle", title: "Patient Profile")
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Age").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                                TextField("Yrs", text: $store.age)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Sex").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                                Picker("Sex", selection: $store.sex) {
                                    ForEach(Sex.allCases, id: \.self) { sex in
                                        Text(sex == .male ? "Male" : "Female").tag(sex)
                                    }
                                }.pickerStyle(.segmented)
                                .frame(width: 150)
                            }
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                    }
                    .clinicalCard()
                    .padding(.horizontal)
                    
                    // 2. CLINICAL STATUS (Integrated)
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "cross.case", title: "Clinical Status")
                        
                        // NEW: Analgesic Profile Picker
                        ClinicalPicker(title: "Analgesic Profile", selection: $store.analgesicProfile)
                        
                        // NEW: Integrated Modifiers
                        Group {
                            if store.analgesicProfile == .methadone {
                                Divider()
                                Toggle(isOn: $store.qtcProlonged) {
                                    VStack(alignment: .leading) {
                                        Text("QTc Prolongation (>450ms)").font(.subheadline).bold()
                                        Text("Warning: Limit QT-prolonging adjuvants").font(.caption).foregroundColor(ClinicalTheme.rose500)
                                    }
                                }.toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                                
                                Toggle(isOn: $store.splitDosing) {
                                    VStack(alignment: .leading) {
                                        Text("Already on Split Dosing?").font(.subheadline).bold()
                                        Text(store.splitDosing ? "Good for analgesia" : "Recommendation: Split dose q8h").font(.caption).foregroundColor(store.splitDosing ? ClinicalTheme.teal500 : ClinicalTheme.amber500)
                                    }
                                }.toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                            }
                            
                            if store.analgesicProfile == .buprenorphine {
                                Divider()
                                Toggle("Currently Split Dosing (q6-8h)?", isOn: $store.splitDosing)
                                    .font(.subheadline)
                                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                            }
                            
                            if store.analgesicProfile == .highPotency {
                                Divider()
                                Toggle("Tolerance Uncertain due to Lipophilicity?", isOn: $store.toleranceUncertain)
                                    .font(.subheadline)
                                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                            }
                            
                            if store.analgesicProfile == .naltrexone {
                                Divider()
                                HStack {
                                    Image(systemName: "nosign").foregroundColor(ClinicalTheme.rose500)
                                    Text("Blockade Active: Opioids Ineffective").font(.caption).bold().foregroundColor(ClinicalTheme.rose500)
                                }
                            }
                        }
                        
                        Divider().padding(.vertical, 4)

                        ClinicalPicker(title: "Renal Function", selection: $store.renalFunction)
                        ClinicalPicker(title: "Hepatic Function", selection: $store.hepaticFunction)
                        ClinicalPicker(title: "Hemodynamics", selection: $store.hemo)
                        ClinicalPicker(title: "GI / NPO", selection: $store.gi)
                        ClinicalPicker(title: "Route", selection: $store.route)
                        ClinicalPicker(title: "Indication", selection: $store.indication)
                        ClinicalPicker(title: "Pain Type", selection: $store.painType)
                    }
                    .clinicalCard()
                    .padding(.horizontal)
                    // 3. RISK FACTORS
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "exclamationmark.triangle", title: "Risk Factors")
                        Toggle("Active / Recent / History of GI Bleed", isOn: $store.historyGIBleed)
                        Toggle("CHF (Heart Failure)", isOn: $store.chf)
                        Toggle("Benzodiazepines", isOn: $store.benzos)
                        Toggle("COPD", isOn: $store.copd)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                    .clinicalCard()
                    .padding(.horizontal)
                    
                    // 4. OUTPUTS - MOVED TO STICKY DRAWER
                    // This section is now handled by RecommendationsDrawer
                    // Kept empty spacer to ensure scrolling clearance
                    Spacer(minLength: 50)
                    
                    VStack(spacing: 4) {
                        Text("Powered by Lifeline Medical Technologies")
                            .font(.system(size: 10))
                            .foregroundColor(ClinicalTheme.teal500.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
                .padding(.bottom, 100) // Extra padding for scrolling
                .addKeyboardDoneButton()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
                }
                .padding(.top)
                .padding(.bottom, 100)
                .addKeyboardDoneButton()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }
            }
            // ZStack Content (Behind Drawer)
            
            // Sticky Drawer Overlay
            if !store.recommendations.isEmpty {
                RecommendationsDrawer(store: store, isExpanded: $isRecommendationsExpanded)
                    .transition(.move(edge: .bottom))
                    .zIndex(100)
            }
        }
        .background(ClinicalTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Risk Assessment")
            .navigationBarItems(
                leading: Button("Reset") { store.reset() },
                trailing: Button(action: copyToClipboard) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(ClinicalTheme.teal500)
            })
            .alert(isPresented: $showCopyAlert) {
                Alert(title: Text("Copied"), message: Text("Assessment summary copied."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    var profileColor: Color {
        switch store.analgesicProfile {
        case .naive: return ClinicalTheme.teal500      // Safe / Standard
        case .chronicRx: return ClinicalTheme.amber500 // Moderate Tolerance
        case .highPotency: return ClinicalTheme.rose500 // Danger / Unknown
        case .buprenorphine: return ClinicalTheme.purple500 // Blockade / High Affinity
        case .methadone: return Color.indigo // QTc / Variable Half-life
        case .naltrexone: return Color.gray            // Blocked
        }
    }
    
    func copyToClipboard() {
        let text = """
        Opioid Risk Assessment
        PRODIGY: \(store.prodigyScore) (\(store.prodigyRisk))
        Recs: \(store.recommendations.map{$0.name}.joined(separator: ", "))
        """
        UIPasteboard.general.string = text
        showCopyAlert = true
    }
}

// Helpers
struct SectionHeader: View {
    let icon, title: String
    var body: some View {
        HStack { Image(systemName: icon).foregroundColor(ClinicalTheme.teal500); Text(title.uppercased()).font(.caption).bold().foregroundColor(.secondary) }
    }
}

struct ToggleCard: View {
    let title, subtitle: String
    @Binding var isOn: Bool
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading) {
                Text(title).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
        .padding(12).background(isOn ? ClinicalTheme.teal500.opacity(0.1) : Color.clear).cornerRadius(8)
    }
}

struct ClinicalPicker<T: Hashable & Identifiable & RawRepresentable & CaseIterable>: View where T.RawValue == String {
    let title: String; @Binding var selection: T
    var body: some View {
        HStack {
            Text(title).font(.caption).foregroundColor(.secondary)
            Spacer()
            Picker(title, selection: $selection) {
                ForEach(Array(T.allCases as! [T]), id: \.self) { item in Text(item.rawValue).tag(item) }
            }.labelsHidden()
            .accentColor(ClinicalTheme.teal500)
        }
    }
}

struct DrugRecRow: View {
    let rec: DrugRecommendation
    @State private var showOrders = false
    @State private var showPharmacology = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row - Tappable
            Button(action: { withAnimation { showPharmacology.toggle() } }) {
                HStack(alignment: .top) {
                    Image(systemName: rec.type == .safe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(rec.type == .safe ? .teal : .orange)
                    VStack(alignment: .leading) {
                        Text(rec.name).font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                        Text(rec.reason).font(.caption).bold().foregroundColor(.secondary)
                        Text(rec.detail).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Subtle Chevron for Expansion
                    if ClinicalData.drugData.contains(where: { rec.name.localizedCaseInsensitiveContains($0.name) }) {
                        Image(systemName: showPharmacology ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .padding(.top, 4)
                    }
                }
                .padding(12)
                .contentShape(Rectangle()) // Make entire row tappable
            }
            .buttonStyle(PlainButtonStyle()) // Remove default button highlighting if desired, or keep for feedback
            
            // Standard Orders Footer
            if let orders = ClinicalData.getStandardOrders(for: rec.name), !orders.isEmpty {
                Divider().background(ClinicalTheme.divider)
                Button(action: { withAnimation { showOrders.toggle() } }) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .foregroundColor(ClinicalTheme.teal500)
                        Text("Standard Orders")
                            .font(.caption).fontWeight(.bold)
                            .foregroundColor(ClinicalTheme.textSecondary)
                        Spacer()
                        Image(systemName: showOrders ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ClinicalTheme.backgroundMain.opacity(0.3))
                }
                
                if showOrders {
                    VStack(spacing: 8) {
                        ForEach(orders) { order in
                            HStack(alignment: .top, spacing: 12) {
                                Text("•")
                                    .foregroundColor(ClinicalTheme.teal500)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(order.label)
                                        .font(.caption).fontWeight(.medium)
                                        .foregroundColor(ClinicalTheme.textPrimary)
                                    if !order.note.isEmpty {
                                        Text(order.note)
                                            .font(.caption2)
                                            .foregroundColor(ClinicalTheme.textSecondary)
                                            .italic()
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(12)
                    .background(ClinicalTheme.backgroundMain.opacity(0.1))
                }
            }

            // Clinical Pharmacology Details (Expanded from Main Row)
            if showPharmacology {
                if let drug = ClinicalData.drugData.first(where: { rec.name.localizedCaseInsensitiveContains($0.name) }) {
                    VStack(alignment: .leading, spacing: 16) {
                        Divider() // Separation
                        
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
                    .padding(12)
                    .background(ClinicalTheme.backgroundMain.opacity(0.1))
                }
            }
        }
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
    }
}

struct BadgeView: View {
    let text: String; let color: Color
    var body: some View {
        Text(text.uppercased()).font(.caption2).bold().padding(6).background(color.opacity(0.2)).foregroundColor(color).cornerRadius(6)
    }
}

struct PalliativeEducationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(ClinicalTheme.rose500)
                Text("Palliative Care Pearls")
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.textPrimary)
            }
            .padding(.bottom, 4)
            
            Group {
                Text("• Addiction is rare in terminal illness, esp. without prior abuse history. Fear should not prevent use.")
                Text("• No specific dose limit exists. Titrate to effect or side effects.")
                Text("• Dose escalation usually indicates disease progression, rarely tolerance.")
            }
            .font(.caption)
            .foregroundColor(ClinicalTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.rose500.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - RECOMMENDATIONS DRAWER (Sticky Bottom)
struct RecommendationsDrawer: View {
    @ObservedObject var store: AssessmentStore
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // DRAWER HANDLE (Chevron)
            Button(action: { withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) { isExpanded.toggle() } }) {
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 8)
                    
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.white)
                        Text("Safety Analysis & Recommendations")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
                .background(ClinicalTheme.teal500)
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
            }
            .buttonStyle(PlainButtonStyle()) // remove click flash
            
            // SCROLLABLE CONTENT (Hidden when collapsed)
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Patient Summary One-Liner
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Assessment Summary")
                                .font(.caption2)
                                .fontWeight(.black)
                                .foregroundColor(ClinicalTheme.teal500)
                                .textCase(.uppercase)
                            
                            Text(store.generatedSummary)
                                .font(.subheadline)
                                .foregroundColor(ClinicalTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                        
                        HStack {
                            Text("PRODIGY Score: \(store.prodigyScore)").font(.caption).bold().foregroundColor(.secondary)
                            Spacer()
                            BadgeView(text: "\(store.prodigyRisk) Risk", color: store.prodigyRisk == "High" ? .red : .teal)
                        }
                        
                        ForEach(store.recommendations) { rec in
                            DrugRecRow(rec: rec)
                        }

                        // Display Non-Opioid Strategy (Adjuvants)
                        if !store.adjuvants.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Suggested Adjuvants").font(.caption).bold().foregroundColor(.secondary).textCase(.uppercase)
                                
                                ForEach(store.adjuvants) { adj in
                                    AdjuvantRow(item: adj)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        if !store.warnings.isEmpty {
                            ForEach(store.warnings, id: \.self) { warn in
                                HStack(alignment: .top) {
                                    Image(systemName: "hand.raised.fill").foregroundColor(.red).font(.caption)
                                    Text(warn).font(.caption).foregroundColor(.secondary)
                                }
                            }
                            .padding(8).background(Color.red.opacity(0.1)).cornerRadius(8)
                        }
                        
                        // MONITORING SECTION
                        if !store.monitoringPlan.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Monitoring & Safety").font(.caption).bold().foregroundColor(.secondary).textCase(.uppercase)
                                ForEach(store.monitoringPlan, id: \.self) { monitor in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "waveform.path.ecg").foregroundColor(ClinicalTheme.teal500).font(.caption)
                                        Text(monitor).font(.caption).foregroundColor(ClinicalTheme.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(ClinicalTheme.backgroundCard)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // PALLIATIVE EDUCATION
                        if store.indication == .cancer || store.indication == .dyspnea {
                            PalliativeEducationCard()
                        }
                        
                        Spacer(minLength: 120) // Extra padding for bottom safe area
                    }
                    .padding()
                }
                .background(ClinicalTheme.backgroundMain)
            }
        }
        .frame(maxHeight: isExpanded ? UIScreen.main.bounds.height * 0.85 : nil) // Max height 85%
        .background(ClinicalTheme.backgroundMain) // Ensure background covers
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
        .transition(.move(edge: .bottom))
    }
}

// Helper for rounded corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }

