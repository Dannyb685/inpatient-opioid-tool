import SwiftUI

struct ScreeningView: View {
    @State private var selectedTab = "sbirt" // sbirt, cows, tools
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var screeningStore = ScreeningStore()
    @StateObject private var toolkitStore = ToolkitStore()
    
    var body: some View {
        NavigationView {
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == "sbirt" {
                            SBIRTModule(store: screeningStore)
                        } else if selectedTab == "cows" {
                            COWSView(store: toolkitStore)
                        } else if selectedTab == "tools" {
                            RiskToolsModule(store: toolkitStore)
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
                .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Screening")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { selectedTab = "sbirt" }) {
                            Label("SBIRT", systemImage: "text.book.closed")
                        }
                        Button(action: { selectedTab = "cows" }) {
                            Label("COWS Assessment", systemImage: "waveform.path.ecg")
                        }
                        Button(action: { selectedTab = "tools" }) {
                            Label("Risk Tools", systemImage: "star.of.life")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(tabName(for: selectedTab))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(ClinicalTheme.teal500)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ClinicalTheme.teal500.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }

    }
    
    func tabName(for tab: String) -> String {
        switch tab {
        case "sbirt": return "SBIRT"
        case "cows": return "COWS"
        case "tools": return "Tools"
        default: return "Screening"
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
            // Sub-Tabs
            // Sub-Tabs (Chips)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([("dast", "DAST-10"), ("assist", "ASSIST-Lyte"), ("visual", "Visual Aids"), ("brief", "Intervention")], id: \.0) { key, label in
                        Button(action: { withAnimation { subTab = key } }) {
                            Text(label)
                                .font(.caption).fontWeight(.bold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(subTab == key ? ClinicalTheme.teal500 : ClinicalTheme.backgroundCard)
                                .foregroundColor(subTab == key ? .white : ClinicalTheme.textSecondary)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if subTab == "dast" {
                // Existing DAST Logic
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Risk Level").font(.caption).foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase)
                            Text(store.riskLevel)
                                .font(.title2)
                                .fontWeight(.black)
                                .foregroundColor(store.riskScore > 2 ? ClinicalTheme.rose500 : ClinicalTheme.teal500)
                        }
                        Spacer()
                        Text("\(store.riskScore)/10")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(ClinicalTheme.textPrimary)
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    
                    Text("Questionnaire (Last 12 Months)").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
                    
                    ForEach($store.questions) { $q in
                        Toggle(isOn: $q.isYes) {
                            Text(q.text)
                                .foregroundColor(ClinicalTheme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 4)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                        .padding()
                        .background(ClinicalTheme.backgroundCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                }
            } else if subTab == "assist" {
                AssistLyteView(store: store)
            } else if subTab == "visual" {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Standard Drink Equivalents").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                    
                    // Visual Asset Placeholder
                    // Visual Asset Placeholder
                    HStack(alignment: .bottom, spacing: 12) {
                        // Beer
                        VStack {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 2).stroke(ClinicalTheme.textSecondary, lineWidth: 1).frame(width: 30, height: 60)
                                RoundedRectangle(cornerRadius: 2).fill(ClinicalTheme.amber500.opacity(0.8)).frame(width: 30, height: 55)
                            }
                            Text("Beer").font(.caption2).bold()
                            Text("12oz").font(.caption2).foregroundColor(.secondary)
                        }
                        // Malt
                        VStack {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 2).stroke(ClinicalTheme.textSecondary, lineWidth: 1).frame(width: 25, height: 50)
                                RoundedRectangle(cornerRadius: 2).fill(ClinicalTheme.amber500.opacity(0.6)).frame(width: 25, height: 40)
                            }
                            Text("Malt").font(.caption2).bold()
                            Text("8oz").font(.caption2).foregroundColor(.secondary)
                        }
                        // Wine
                        VStack {
                            ZStack(alignment: .bottom) {
                                Image(systemName: "wineglass").resizable().frame(width: 20, height: 30).foregroundColor(ClinicalTheme.textSecondary)
                                Circle().fill(ClinicalTheme.rose500.opacity(0.8)).frame(width: 15, height: 15).offset(y: 4)
                            }
                            Text("Wine").font(.caption2).bold()
                            Text("5oz").font(.caption2).foregroundColor(.secondary)
                        }
                        // Spirits
                        VStack {
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 1).stroke(ClinicalTheme.textSecondary, lineWidth: 1).frame(width: 20, height: 25)
                                RoundedRectangle(cornerRadius: 1).fill(ClinicalTheme.textPrimary.opacity(0.8)).frame(width: 20, height: 15)
                            }
                            Text("Shot").font(.caption2).bold()
                            Text("1.5oz").font(.caption2).foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(ToolkitData.drinkEquivalents.enumerated()), id: \.offset) { index, item in
                             HStack {
                                Text(item.0).bold().foregroundColor(ClinicalTheme.textPrimary)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(item.1).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                                    Text(item.2).font(.caption2).bold().foregroundColor(ClinicalTheme.teal500)
                                }
                            }
                            .padding()
                            
                            if index < ToolkitData.drinkEquivalents.count - 1 {
                                Divider().background(ClinicalTheme.divider)
                            }
                        }
                    }
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                }
                
                // Opioid Visuals
                VStack(alignment: .leading, spacing: 12) {
                    Text("Opioid Potency (Oral MME Factor)").font(.headline).foregroundColor(ClinicalTheme.textPrimary).padding(.top, 16)
                    
                    VStack(spacing: 12) {
                        PotencyBar(label: "Morphine", factor: 1.0, color: ClinicalTheme.teal500)
                        PotencyBar(label: "Oxycodone", factor: 1.5, color: ClinicalTheme.amber500)
                        PotencyBar(label: "Hydromorphone", factor: 4.0, color: ClinicalTheme.rose500)
                        PotencyBar(label: "Fentanyl (IV)", factor: 100.0, color: .purple, isScaleBreak: true) // 0.1mg = 30 MME implies 300x? No, 100mcg = 30 MME. But visual needs to be readable.
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                }
            } else if subTab == "brief" {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FRAMES Model").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                    ForEach(ToolkitData.framesData, id: \.0) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Text(item.0)
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(ClinicalTheme.teal500)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(item.1).bold().foregroundColor(ClinicalTheme.textPrimary)
                                Text(item.2).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ClinicalTheme.backgroundCard)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                }
            }
        }
    }
}

struct AssistLyteView: View {
    @ObservedObject var store: ScreeningStore
    
    var body: some View {
        VStack(spacing: 24) {
             Text("Past 3 Months Only").font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary).textCase(.uppercase)
            
            ForEach($store.assistSubstances) { $substance in
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $substance.usedInPast3Months) {
                        Text("Did you use \(substance.name)?")
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
                    
                    if substance.usedInPast3Months {
                        Divider()
                        if substance.id == "tobacco" {
                            Toggle("Usually smoke > 10 cigs/day?", isOn: $substance.q1_Frequency)
                            Toggle("Smoke within 30 mins of waking?", isOn: $substance.q3_Extra)
                        } else if substance.id == "alcohol" {
                            Toggle(">4 drinks on any occasion?", isOn: $substance.q1_Frequency)
                            Toggle("Failed to control/stop?", isOn: $substance.q3_Extra)
                            Toggle("Anyone expressed concern?", isOn: $substance.q2_Concern)
                        } else if substance.id == "other" {
                            Text("Not scored. Prompts further assessment.")
                                .font(.caption).italic().foregroundColor(ClinicalTheme.textSecondary)
                        } else {
                            // General Logic (Cannabis, Stimulants, Sedatives, Opioids)
                            Toggle("Strong urge/use weekly or more?", isOn: $substance.q1_Frequency)
                            Toggle("Anyone expressed concern?", isOn: $substance.q2_Concern)
                            if substance.id == "opioids" {
                                Toggle("Failed to control/stop?", isOn: $substance.q3_Extra) // Used q3 slot for "Failed to stop"
                            }
                        }
                        
                        if substance.id != "other" {
                            HStack {
                                Text("Risk Category:")
                                    .font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                                Spacer()
                                Text(substance.riskCategory)
                                    .font(.caption).fontWeight(.bold)
                                    .foregroundColor(substance.riskCategory == "Low" ? ClinicalTheme.teal500 : (substance.riskCategory == "Moderate" ? ClinicalTheme.amber500 : ClinicalTheme.rose500))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background((substance.riskCategory == "Low" ? ClinicalTheme.teal500 : (substance.riskCategory == "Moderate" ? ClinicalTheme.amber500 : ClinicalTheme.rose500)).opacity(0.1))
                                    .cornerRadius(4)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            }
            
            // Key
            VStack(alignment: .leading, spacing: 8) {
                Text("Rapid Guide").font(.headline).foregroundColor(ClinicalTheme.textSecondary)
                HStack { Text("Low").bold().foregroundColor(ClinicalTheme.teal500); Text("Health advice, encourage not to increase.") }
                HStack { Text("Mod").bold().foregroundColor(ClinicalTheme.amber500); Text("Brief Intervention (FRAMES), take-home info.") }
                HStack { Text("High").bold().foregroundColor(ClinicalTheme.rose500); Text("Brief Intervention + Specialist Referral.") }
            }
            .font(.caption)
            .padding()
            .background(ClinicalTheme.backgroundMain)
            .cornerRadius(8)
        }
    }
}

struct RiskToolsModule: View {
    @ObservedObject var store: ToolkitStore
    
    var body: some View {
        VStack(spacing: 20) {
            // SOS SCORE
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SOS Score").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                        Text("Surgical Risk Prediction").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                    Spacer()
                    Text(store.sosRiskLabel)
                        .font(.headline)
                        .fontWeight(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(store.sosRiskLabel.contains("Low") ? ClinicalTheme.teal500.opacity(0.2) : (store.sosRiskLabel.contains("Med") ? ClinicalTheme.amber500.opacity(0.2) : ClinicalTheme.rose500.opacity(0.2)))
                        .foregroundColor(store.sosRiskLabel.contains("Low") ? ClinicalTheme.teal500 : (store.sosRiskLabel.contains("Med") ? ClinicalTheme.amber500 : ClinicalTheme.rose500))
                        .cornerRadius(8)
                }
                
                Toggle("High Risk Surgery (Thoracic/Upper Abd)", isOn: $store.sosSurgeryHighRisk)
                Toggle("Preoperative Opioid Use", isOn: $store.sosPreOpOpioid)
                Toggle("Psych Comorbidity (Depression/Anxiety)", isOn: $store.sosPsych)
            }
            .toggleStyle(SwitchToggleStyle(tint: ClinicalTheme.teal500))
            .clinicalCard()
            
            // ORT
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opioid Risk Tool (ORT)").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                        Text("Aberrant Behavior Risk").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                    Spacer()
                    Text(store.ortRisk)
                        .font(.headline)
                        .fontWeight(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(store.ortRisk.contains("Low") ? ClinicalTheme.teal500.opacity(0.2) : (store.ortRisk.contains("Mod") ? ClinicalTheme.amber500.opacity(0.2) : ClinicalTheme.rose500.opacity(0.2)))
                        .foregroundColor(store.ortRisk.contains("Low") ? ClinicalTheme.teal500 : (store.ortRisk.contains("Mod") ? ClinicalTheme.amber500 : ClinicalTheme.rose500))
                        .cornerRadius(8)
                }
                
                HStack {
                    Text("Total Score: \(Int(store.ortScoreInput))")
                        .font(.title3).bold().foregroundColor(ClinicalTheme.textPrimary)
                    Spacer()
                    Stepper("", value: $store.ortScoreInput, in: 0...26)
                        .labelsHidden()
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            }
            .clinicalCard()
            
            // PEG SCALE
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PEG Scale").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                        Text("Pain, Enjoyment, General Activity").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f / 10", store.pegScore))
                            .font(.title2).fontWeight(.black).foregroundColor(ClinicalTheme.teal500)
                        Text("Goal: < \(String(format: "%.1f", store.pegScore * 0.7))")
                            .font(.caption).foregroundColor(ClinicalTheme.textMuted)
                    }
                }
                
                VStack(spacing: 12) {
                    PegSlider(label: "Pain (Average)", value: $store.pegPain)
                    PegSlider(label: "Enjoyment of Life", value: $store.pegEnjoyment)
                    PegSlider(label: "General Activity", value: $store.pegActivity)
                }
            }
            .clinicalCard()
        }
    }
}

struct PegSlider: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
                Spacer()
                Text("\(Int(value))").font(.caption).bold().foregroundColor(ClinicalTheme.textPrimary)
            }
            Slider(value: $value, in: 0...10, step: 1)
                .accentColor(ClinicalTheme.teal500)
                .frame(height: 44) // Increase touch target
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

struct PotencyBar: View {
    let label: String
    let factor: Double
    let color: Color
    var isScaleBreak: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .bold()
                .foregroundColor(ClinicalTheme.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(ClinicalTheme.backgroundInput).frame(height: 8)
                    if isScaleBreak {
                        Capsule().fill(color).frame(width: geo.size.width, height: 8)
                            .overlay(Text("100x+").font(.caption2).bold().foregroundColor(.white).padding(.leading, 4), alignment: .leading)
                    } else {
                        Capsule().fill(color).frame(width: geo.size.width * CGFloat(factor / 5.0), height: 8)
                    }
                }
            }
            .frame(height: 8)
            
            Text("\(String(format: "%.1f", factor))x")
                .font(.caption)
                .bold()
                .foregroundColor(ClinicalTheme.textPrimary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}
