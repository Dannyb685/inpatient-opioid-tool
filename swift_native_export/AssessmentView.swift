import SwiftUI

struct AssessmentView: View {
    @EnvironmentObject var store: AssessmentStore // Inject the shared logic
    @State private var showCopyAlert = false
    
    var body: some View {
        NavigationView {
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
                                    .addKeyboardDoneButton()
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
                        
                        // Custom Toggles
                        ToggleCard(title: "Opioid Naive", subtitle: "No exposure last 7d", isOn: $store.naive)
                        ToggleCard(title: "Home Buprenorphine", subtitle: "MAT (Suboxone)", isOn: $store.mat)
                    }
                    .clinicalCard()
                    .padding(.horizontal) // Unified padding
                    
                    // 2. CLINICAL STATUS
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(icon: "cross.case", title: "Clinical Status")
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
                        Toggle("Sleep Apnea (OSA)", isOn: $store.sleepApnea)
                        Toggle("CHF (Heart Failure)", isOn: $store.chf)
                        Toggle("Benzodiazepines", isOn: $store.benzos)
                        Toggle("COPD", isOn: $store.copd)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.rose500))
                    .clinicalCard()
                    .padding(.horizontal)
                    
                    // 4. OUTPUTS
                    if !store.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("PRODIGY Score: \(store.prodigyScore)").font(.caption).bold().foregroundColor(.secondary)
                                Spacer()
                                BadgeView(text: "\(store.prodigyRisk) Risk", color: store.prodigyRisk == "High" ? .red : .teal)
                            }
                            
                            ForEach(store.recommendations) { rec in
                                DrugRecRow(rec: rec)
                            }

                            // FIX: Display Non-Opioid Strategy (Adjuvants)
                            if !store.adjuvants.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Suggested Adjuvants").font(.caption).bold().foregroundColor(.secondary).textCase(.uppercase)
                                    
                                    ForEach(store.adjuvants, id: \.self) { adj in
                                        HStack(alignment: .top) {
                                            Image(systemName: "plus.circle.fill").foregroundColor(.teal).font(.caption)
                                            Text(adj).font(.caption).foregroundColor(ClinicalTheme.textPrimary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.teal.opacity(0.1))
                                        .cornerRadius(8)
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
                        }
                        .clinicalCard()
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .background(ClinicalTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Risk Assessment")
            .navigationBarItems(trailing: Button(action: copyToClipboard) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(ClinicalTheme.teal500)
            })
            .alert(isPresented: $showCopyAlert) {
                Alert(title: Text("Copied"), message: Text("Assessment summary copied."), dismissButton: .default(Text("OK")))
            }
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
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: rec.type == .safe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(rec.type == .safe ? .teal : .orange)
            VStack(alignment: .leading) {
                Text(rec.name).font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                Text(rec.reason).font(.caption).bold().foregroundColor(.secondary)
                Text(rec.detail).font(.caption).foregroundColor(.secondary)
            }
        }.padding(8).background(ClinicalTheme.backgroundCard).cornerRadius(8) // Updated background
    }
}

struct BadgeView: View {
    let text: String; let color: Color
    var body: some View {
        Text(text.uppercased()).font(.caption2).bold().padding(6).background(color.opacity(0.2)).foregroundColor(color).cornerRadius(6)
    }
}
