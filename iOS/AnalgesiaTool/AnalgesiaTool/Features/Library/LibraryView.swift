import SwiftUI

struct LibraryView: View {
    @State private var selectedTab = "screening" // screening, risk, ref
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var screeningStore = ScreeningStore()
    @StateObject private var toolkitStore = ToolkitStore()
    

    
    // States for Library (v1.5.5 consolidation)
    @State private var refSearchText = ""
    @State private var refExpandedId: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable Segmented Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TabChip(title: "Screening", id: "screening", selected: $selectedTab)
                        TabChip(title: "Risk Tools", id: "risk", selected: $selectedTab)
                        TabChip(title: "Pharmacy", id: "ref", selected: $selectedTab)
                    }
                    .padding()
                }
                .background(ClinicalTheme.backgroundMain)
                
                // Content
                Group {
                    if selectedTab == "screening" {
                        ScrollView {
                            SBIRTModule(store: screeningStore)
                                .padding()
                                .padding(.bottom, 40)
                        }
                    } else if selectedTab == "risk" {
                        ScrollView {
                            RiskToolsModule(store: toolkitStore)
                                .padding()
                                .padding(.bottom, 40)
                        }
                    } else if selectedTab == "ref" {
                        ReferenceContentView(searchText: $refSearchText, expandedId: $refExpandedId)
                    }
                }
                .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            }
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
            .navigationTitle("Clinical Library")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TabChip: View {
    let title: String
    let id: String
    @Binding var selected: String
    
    var body: some View {
        Button(action: { withAnimation { selected = id } }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selected == id ? ClinicalTheme.teal500 : ClinicalTheme.backgroundCard)
                .foregroundColor(selected == id ? .white : ClinicalTheme.textSecondary)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
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
                // Back Button
                if history.count > 1 || outcome != nil {
                    HStack {
                        Button(action: {
                            withAnimation {
                                if outcome != nil {
                                    self.outcome = nil
                                } else {
                                    history.removeLast()
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.caption).bold()
                            .foregroundColor(ClinicalTheme.textSecondary)
                        }
                        Spacer()
                    }
                }

                if let outcome = outcome {
                    // Outcome State
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(ClinicalTheme.teal500)
                    
                    Text("Recommendation")
                        .font(.headline)
                        .textCase(.uppercase)
                        .foregroundColor(ClinicalTheme.textSecondary)
                    
                    Text(.init(outcome)) // Markdown support
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                                    .multilineTextAlignment(.leading)
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


