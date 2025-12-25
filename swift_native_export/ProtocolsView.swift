import SwiftUI

struct ProtocolsView: View {
    @State private var selectedTab = "proto" // proto, moud
    @State private var protocolMode = "guide" // guide, algo
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TabButton(id: "proto", label: "Clinical Protocols", icon: "doc.text.magnifyingglass", selected: $selectedTab)
                        TabButton(id: "moud", label: "MOUD", icon: "shield.checkerboard", selected: $selectedTab)
                    }
                    .padding()
                }
                .background(ClinicalTheme.slate900)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == "proto" {
                            // Sub-Picker for Consolidated View
                            Picker("Type", selection: $protocolMode) {
                                Text("Guide").tag("guide")
                                Text("Algorithms").tag("algo")
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
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
                .background(ClinicalTheme.slate900.edgesIgnoringSafeArea(.all))
            }
            .background(ClinicalTheme.slate900.edgesIgnoringSafeArea(.all))
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
                        .foregroundColor(ClinicalTheme.slate400)
                    
                    Text(outcome)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()
                    
                    Button(action: {
                        withAnimation {
                            history = ["root"]
                            self.outcome = nil
                        }
                    }) {
                        Text("Reset Pathway")
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.slate300)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(ClinicalTheme.slate800)
                            .cornerRadius(8)
                    }
                    
                } else if let node = currentNode {
                    // Question State
                    Text(node.text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
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
                            .background(ClinicalTheme.slate800)
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.slate700, lineWidth: 1))
                        }
                    }
                }
            }
            .padding(24)
            .background(ClinicalTheme.slate900) // Inner card bg
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ClinicalTheme.slate700, lineWidth: 1))
            
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
                .foregroundColor(ClinicalTheme.slate500)
            }
        }
    }
}

struct ConditionGuidesView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(ProtocolData.conditionGuides) { guide in
                DisclosureGroup(
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(guide.recommendations, id: \.self) { rec in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle().fill(ClinicalTheme.teal500).frame(width: 6, height: 6).padding(.top, 6)
                                    Text(rec)
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.slate300)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    },
                    label: {
                        Text(guide.title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                )
                .padding()
                .background(ClinicalTheme.slate800)
                .cornerRadius(12)
            }
        }
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
                    Text("Buprenorphine Micro-Induction (Bernese Method)").font(.headline).foregroundColor(.white)
                        .padding(.bottom, 4)
                    
                    ForEach(ProtocolData.berneseData) { step in
                        HStack(spacing: 16) {
                            Circle()
                                .fill(ClinicalTheme.teal500.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(Text("D\(step.day)").font(.caption).bold().foregroundColor(ClinicalTheme.teal500))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.dose).font(.subheadline).bold().foregroundColor(.white)
                                Text(step.note).font(.caption).foregroundColor(ClinicalTheme.slate400)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(ClinicalTheme.slate800)
                        .cornerRadius(12)
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
                                            Text(item.drug).font(.subheadline).bold().foregroundColor(.white)
                                            Spacer()
                                            Text(item.dose).font(.caption).foregroundColor(ClinicalTheme.teal500)
                                        }
                                        Text(item.note).font(.caption2).foregroundColor(ClinicalTheme.slate400)
                                    }
                                    .padding()
                                    
                                    if index < category.items.count - 1 {
                                        Divider().background(ClinicalTheme.slate700)
                                    }
                                }
                            }
                            .background(ClinicalTheme.slate800)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.slate700, lineWidth: 1))
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

struct TabButton: View {
    let id: String
    let label: String
    let icon: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: { withAnimation { selected = id } }) {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .font(.caption).bold()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selected == id ? ClinicalTheme.teal500 : ClinicalTheme.slate800)
            .foregroundColor(selected == id ? .white : ClinicalTheme.slate400)
            .cornerRadius(8)
        }
    }
}
