import SwiftUI

struct ProtocolsView: View {
    @State private var selectedTab = "proto" // proto, induct, best
    @State private var protocolMode = "guide" // guide, algo
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TabButton(id: "proto", label: "Clinical Protocols", icon: "doc.text.magnifyingglass", selected: $selectedTab)
                        TabButton(id: "induct", label: "Induction", icon: "shield.checkerboard", selected: $selectedTab)
                        TabButton(id: "best", label: "Symptom Care", icon: "heart.text.square.fill", selected: $selectedTab)
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
                                Text("Guidelines").tag("guide")
                                Text("Algorithms").tag("algo")
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            if protocolMode == "guide" {
                                ConditionGuidesView()
                            } else {
                                FlowchartView()
                            }
                        } else if selectedTab == "induct" {
                            InductionView()
                        } else if selectedTab == "best" {
                            BestPracticesView()
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

struct InductionView: View {
    @State private var mode = "temple" // temple, bernese
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Protocol", selection: $mode) {
                Text("Temple Protocol").tag("temple")
                Text("Bernese Method").tag("bernese")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            if mode == "temple" {
                VStack(alignment: .leading, spacing: 16) {
                    Text(ProtocolData.templeData.title).font(.headline).foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Oral Regimen").font(.caption).bold().foregroundColor(ClinicalTheme.teal500).textCase(.uppercase)
                        ForEach(ProtocolData.templeData.oral, id: \.self) { line in
                            Text("• " + line).font(.caption).foregroundColor(ClinicalTheme.slate300)
                        }
                    }
                    .clinicalCard()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Breakthrough / PCA").font(.caption).bold().foregroundColor(ClinicalTheme.teal500).textCase(.uppercase)
                        ForEach(ProtocolData.templeData.breakthrough, id: \.self) { line in
                            Text("• " + line).font(.caption).foregroundColor(ClinicalTheme.slate300)
                        }
                    }
                    .clinicalCard()
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bernese Method (Micro-Induction)").font(.headline).foregroundColor(.white)
                    
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
            }
        }
    }
}

struct BestPracticesView: View {
    var body: some View {
        VStack(spacing: 24) {
             // Pain Management
             VStack(alignment: .leading, spacing: 12) {
                 Text("Pain & Symptom Management").font(.headline).foregroundColor(ClinicalTheme.slate400).padding(.horizontal)
                 
                 VStack(alignment: .leading, spacing: 12) {
                     Text("Clinician Best Practices").font(.caption).bold().foregroundColor(ClinicalTheme.teal500).textCase(.uppercase)
                     Group {
                         Text("• Ask about pain/SOB/Nausea/Anxiety EVERY DAY.")
                         Text("• Never leave a patient in pain without a plan.")
                         Text("• Verify home opioid dose before hospital orders.")
                         Text("• Set expectations for OVERNIGHT care.")
                     }.font(.caption).foregroundColor(ClinicalTheme.slate300)
                 }
                 .clinicalCard()
                 .padding(.horizontal)
             }
             
             // Anti-Emetics Table
             VStack(alignment: .leading, spacing: 12) {
                 Text("Nausea & Vomiting Control").font(.headline).foregroundColor(ClinicalTheme.slate400).padding(.horizontal)
                 
                 ScrollView(.horizontal, showsIndicators: false) {
                     VStack(alignment: .leading, spacing: 0) {
                         // Header
                         HStack(spacing: 0) {
                             Text("Drug").frame(width: 120, alignment: .leading)
                             Text("Review").frame(width: 100, alignment: .leading)
                             Text("Dose").frame(width: 150, alignment: .leading)
                         }
                         .font(.caption).bold().foregroundColor(ClinicalTheme.slate500)
                         .padding()
                         .background(ClinicalTheme.slate900)
                         
                         ForEach(ProtocolData.antiEmetics) { item in
                             HStack(spacing: 0) {
                                 Text(item.drug).font(.caption).bold().foregroundColor(.white).frame(width: 120, alignment: .leading)
                                 Text(item.site).font(.caption2).foregroundColor(ClinicalTheme.slate400).frame(width: 100, alignment: .leading)
                                 Text(item.dose).font(.caption).foregroundColor(ClinicalTheme.slate300).frame(width: 150, alignment: .leading)
                             }
                             .padding()
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(ClinicalTheme.slate800),
                                alignment: .top
                            )
                         }
                     }
                     .background(ClinicalTheme.slate800)
                     .cornerRadius(12)
                 }
                 .padding(.horizontal)
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
