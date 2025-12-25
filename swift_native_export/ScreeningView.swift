import SwiftUI

struct ScreeningView: View {
    @State private var selectedTab = "sbirt" // sbirt, cows, tools
    @StateObject private var screeningStore = ScreeningStore()
    @StateObject private var toolkitStore = ToolkitStore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TabButton(id: "sbirt", label: "SBIRT (Addiction)", icon: "person.fill.questionmark", selected: $selectedTab)
                        TabButton(id: "cows", label: "COWS (Withdrawal)", icon: "activity", selected: $selectedTab)
                        TabButton(id: "tools", label: "Risk Tools", icon: "exclamationmark.triangle", selected: $selectedTab)
                    }
                    .padding()
                }
                .background(ClinicalTheme.slate900)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == "sbirt" {
                            SBIRTModule(store: screeningStore)
                        } else if selectedTab == "cows" {
                            COWSView(store: toolkitStore)
                        } else if selectedTab == "tools" {
                            RiskToolsModule()
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
                .background(ClinicalTheme.slate900.edgesIgnoringSafeArea(.all))
            }
            .background(ClinicalTheme.slate900.edgesIgnoringSafeArea(.all))
            .navigationTitle("Screening & Tools")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Modules

struct SBIRTModule: View {
    @ObservedObject var store: ScreeningStore
    @State private var subTab = "dast" // dast, visual, brief
    
    var body: some View {
        VStack(spacing: 16) {
            // Sub-Tabs
            HStack {
                Button("DAST-10") { subTab = "dast" }
                    .font(.caption).bold()
                    .foregroundColor(subTab == "dast" ? .white : .gray)
                    .padding(8)
                    .background(subTab == "dast" ? ClinicalTheme.teal500 : Color.clear)
                    .cornerRadius(6)
                
                Button("Visual Aids") { subTab = "visual" }
                    .font(.caption).bold()
                    .foregroundColor(subTab == "visual" ? .white : .gray)
                    .padding(8)
                    .background(subTab == "visual" ? ClinicalTheme.teal500 : Color.clear)
                    .cornerRadius(6)
                
                Button("Intervention") { subTab = "brief" }
                    .font(.caption).bold()
                    .foregroundColor(subTab == "brief" ? .white : .gray)
                    .padding(8)
                    .background(subTab == "brief" ? ClinicalTheme.teal500 : Color.clear)
                    .cornerRadius(6)
            }
            .padding(4)
            .background(ClinicalTheme.slate800)
            .cornerRadius(8)
            
            if subTab == "dast" {
                // Existing DAST Logic
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Risk Level").font(.caption).foregroundColor(ClinicalTheme.slate400).textCase(.uppercase)
                            Text(store.riskLevel)
                                .font(.title2)
                                .fontWeight(.black)
                                .foregroundColor(store.riskScore > 2 ? ClinicalTheme.rose500 : ClinicalTheme.teal500)
                        }
                        Spacer()
                        Text("\(store.riskScore)/10")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(ClinicalTheme.slate800)
                    .cornerRadius(12)
                    
                    Text("Questionnaire (Last 12 Months)").font(.headline).foregroundColor(ClinicalTheme.slate400)
                    
                    ForEach($store.questions) { $q in
                        Toggle(isOn: $q.isYes) {
                            Text(q.text)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 4)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                        .padding()
                        .background(ClinicalTheme.slate800)
                        .cornerRadius(12)
                    }
                }
            } else if subTab == "visual" {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Standard Drink Equivalents").font(.headline).foregroundColor(.white)
                    ForEach(ToolkitData.drinkEquivalents, id: \.0) { item in
                        HStack {
                            Text(item.0).bold().foregroundColor(.white)
                            Spacer()
                            Text(item.1).foregroundColor(ClinicalTheme.teal500)
                        }
                        .padding()
                        .background(ClinicalTheme.slate800)
                        .cornerRadius(8)
                    }
                }
            } else if subTab == "brief" {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FRAMES Model").font(.headline).foregroundColor(.white)
                    ForEach(ToolkitData.framesData, id: \.0) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Text(item.0)
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(ClinicalTheme.teal500)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(item.1).bold().foregroundColor(.white)
                                Text(item.2).font(.caption).foregroundColor(ClinicalTheme.slate400)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ClinicalTheme.slate800)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct RiskToolsModule: View {
    var body: some View {
        VStack(spacing: 20) {
            // SOS
            VStack(alignment: .leading, spacing: 8) {
                Text("SOS Score (Surgical Risk)").font(.headline).foregroundColor(.white)
                Text("Predicts sustained opioid use after surgery.").font(.caption).foregroundColor(ClinicalTheme.slate400)
                HStack {
                    Badge(text: "Low (4%)", type: "safe")
                    Badge(text: "Med (17%)", type: "caution")
                    Badge(text: "High (50%)", type: "unsafe")
                }
                Text("Inputs: Surgery Type, Pre-op Use, Psych Comorbidity").font(.caption2).foregroundColor(ClinicalTheme.slate500)
            }
            .clinicalCard()
            
            // ORT
            VStack(alignment: .leading, spacing: 8) {
                Text("Opioid Risk Tool (ORT)").font(.headline).foregroundColor(.white)
                Text("Validates risk for aberrant behaviors.").font(.caption).foregroundColor(ClinicalTheme.slate400)
                HStack {
                    Badge(text: "0-3 Low", type: "safe")
                    Badge(text: "4-7 Mod", type: "caution")
                    Badge(text: ">8 High", type: "unsafe")
                }
            }
            .clinicalCard()
            
            // PEG
            VStack(alignment: .leading, spacing: 8) {
                Text("PEG Scale").font(.headline).foregroundColor(.white)
                Text("Pain, Enjoyment, General Activity (0-10)").font(.caption).foregroundColor(ClinicalTheme.slate400)
                Text("Clinically meaningful improvement: ≥30% reduction.").font(.caption).bold().foregroundColor(ClinicalTheme.teal500)
            }
            .clinicalCard()
        }
    }
}

struct Badge: View {
    let text: String
    let type: String // safe, caution, unsafe
    
    var color: Color {
        switch type {
        case "safe": return ClinicalTheme.teal500
        case "caution": return ClinicalTheme.amber500
        case "unsafe": return ClinicalTheme.rose500
        default: return .gray
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption2).bold()
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
