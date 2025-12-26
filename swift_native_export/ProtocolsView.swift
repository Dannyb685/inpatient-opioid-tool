import SwiftUI

struct ProtocolsView: View {
    @State private var selectedTab = "proto" // proto, moud
    @EnvironmentObject var themeManager: ThemeManager
    @State private var protocolMode = "guide" // guide, algo
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                // Segmented Picker Header
                Picker("Tab", selection: $selectedTab) {
                    Text("Clinical Protocols").tag("proto")
                    Text("MOUD").tag("moud")
                }
                .pickerStyle(.segmented)
                .padding()
                .background(ClinicalTheme.backgroundMain)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == "proto" {
                            // Sub-Picker for Consolidated View
                            // Sub-Picker (Chips)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach([("guide", "Condition Guide"), ("algo", "Algorithms")], id: \.0) { key, label in
                                        Button(action: { withAnimation { protocolMode = key } }) {
                                            Text(label)
                                                .font(.caption).fontWeight(.bold)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(protocolMode == key ? ClinicalTheme.teal500 : ClinicalTheme.backgroundCard)
                                                .foregroundColor(protocolMode == key ? .white : ClinicalTheme.textSecondary)
                                                .cornerRadius(20)
                                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            if protocolMode == "guide" {
                                ConditionGuidesView()
                            } else {
                                FlowchartView()
                            }
                        } else if selectedTab == "moud" {
                            MOUDView()
                        }
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
                .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Protocols")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Sub Views

struct FlowchartView: View {
    @State private var history: [String] = ["root"]
    @State private var outcome: String? = nil
    
    var currentNode: DecisionNode? {
        guard let id = history.last else { return nil }
        return ProtocolData.flowcharts[id]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Card
            VStack(spacing: 16) {
                if let outcome = outcome {
                    // Outcome State
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(ClinicalTheme.teal500)
                    
                    Text("Recommendation")
                        .font(.headline)
                        .textCase(.uppercase)
                        .foregroundColor(ClinicalTheme.textSecondary)
                    
                    Text(outcome)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .padding()
                    
                    Button(action: {
                        withAnimation {
                            history = ["root"]
                            self.outcome = nil
                        }
                    }) {
                        Text("Reset Pathway")
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(ClinicalTheme.backgroundCard)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                    
                } else if let node = currentNode {
                    // Question State
                    Text(node.text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .padding(.bottom, 10)
                    
                    ForEach(node.options) { option in
                        Button(action: {
                            withAnimation {
                                if let out = option.outcome {
                                    self.outcome = out
                                } else if let next = option.nextId {
                                    history.append(next)
                                }
                            }
                        }) {
                            HStack {
                                Text(option.label)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .padding()
                            .background(ClinicalTheme.backgroundCard)
                            .cornerRadius(12)
                            .foregroundColor(ClinicalTheme.textPrimary)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                        }
                    }
                }
            }
            .padding(24)
            .background(ClinicalTheme.backgroundCard) // Inner card bg
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
            
            // Breadcrumbs
            if history.count > 1 {
                HStack(spacing: 4) {
                    ForEach(Array(history.enumerated()), id: \.offset) { idx, step in
                        if idx > 0 {
                            Text("/")
                        }
                        Text(step.replacingOccurrences(of: "_", with: " "))
                            .font(.caption)
                    }
                }
                .foregroundColor(ClinicalTheme.textMuted)
            }
        }
    }
}

struct ConditionGuidesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(ProtocolData.conditionGuides.enumerated()), id: \.element.id) { index, guide in
                DisclosureGroup(
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(guide.recommendations, id: \.self) { rec in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(ClinicalTheme.teal500).frame(width: 6, height: 6).padding(.top, 6)
                                    Text(rec)
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.textSecondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    },
                    label: {
                        Text(guide.title)
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.textPrimary)
                    }
                )
                .padding()
                
                if index < ProtocolData.conditionGuides.count - 1 {
                    Divider().background(ClinicalTheme.divider)
                }
            }
        }
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
        .padding(.horizontal)
    }
}

struct MOUDView: View {
    @State private var mode = "bernese" // bernese, symptom
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Protocol", selection: $mode) {
                Text("Micro-Induction").tag("bernese")
                Text("Symptom Care").tag("symptom")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if mode == "bernese" {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Buprenorphine Micro-Induction (Bernese Method)").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                        .padding(.bottom, 4)
                    
                    ForEach(ProtocolData.berneseData) { step in
                        HStack(spacing: 16) {
                            Circle()
                                .fill(ClinicalTheme.teal500.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(Text("D\(step.day)").font(.caption).bold().foregroundColor(ClinicalTheme.teal500))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.dose).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                                Text(step.note).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(ClinicalTheme.backgroundCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                }
            } else {
                VStack(spacing: 24) {
                    ForEach(ProtocolData.symptomManagement) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.title)
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.teal500)
                                .textCase(.uppercase)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(category.items.enumerated()), id: \.element.id) { index, item in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.drug).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                                            Spacer()
                                            Text(item.dose).font(.caption).foregroundColor(ClinicalTheme.teal500)
                                        }
                                        Text(item.note).font(.caption2).foregroundColor(ClinicalTheme.textSecondary)
                                    }
                                    .padding()
                                    
                                    if index < category.items.count - 1 {
                                        Divider().background(ClinicalTheme.divider)
                                    }
                                }
                            }
                            .background(ClinicalTheme.backgroundCard)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}


