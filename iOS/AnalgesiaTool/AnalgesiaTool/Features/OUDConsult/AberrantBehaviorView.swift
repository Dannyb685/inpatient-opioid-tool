import SwiftUI

struct AberrantBehaviorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // State
    @State private var selectedYellowFlags: Set<String> = []
    @State private var selectedRedFlags: Set<String> = []
    @State private var showingAlgorithm = false
    
    // Data
    private let yellowFlags = OUDStaticData.aberrantBehaviors.filter { $0.category == .yellowFlag }
    private let redFlags = OUDStaticData.aberrantBehaviors.filter { $0.category == .redFlag }
    
    // Clinical Context (Manual Toggle for Sensitivity)
    @State private var isCancerContext: Bool = false 
    @EnvironmentObject var assessmentStore: AssessmentStore // To auto-seed if possible
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Aberrant Behavior Response")
                        .font(.title2).bold()
                        .foregroundColor(ClinicalTheme.textPrimary)
                    
                    Text("ASCO Guideline Algorithm for responding to concerning behaviors during opioid therapy.")
                        .font(.subheadline)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
                .padding(.horizontal)
                

                // Context Switcher
                Picker("Context", selection: $isCancerContext) {
                    Text("Non-Cancer Pain").tag(false)
                    Text("Cancer / Palliative").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                Divider()
                
                // 1. Red Flags (Major)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(.red)
                        Text("Red Flags (Diversion/Active SUD)")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    
                    ForEach(redFlags, id: \.self) { item in
                        AberrantRow(item: item, isSelected: selectedRedFlags.contains(item.behavior)) {
                            toggleSelection(item, category: .redFlag)
                        }
                    }
                }
                
                // 2. Yellow Flags (Minor)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Yellow Flags (Pacing/Adherence)")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                    
                    ForEach(yellowFlags, id: \.self) { item in
                        AberrantRow(item: item, isSelected: selectedYellowFlags.contains(item.behavior)) {
                            toggleSelection(item, category: .yellowFlag)
                        }
                    }
                }
                
                // 3. Action Algorithm
                if !selectedRedFlags.isEmpty || !selectedYellowFlags.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Guideline Response Algorithm")
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.textPrimary)
                            .padding(.top)
                        
                        // Red Flag Response
                        if !selectedRedFlags.isEmpty {
                            ActionCard(
                                title: "STOP / RESTRUCTURE IMMEDIATELY",
                                icon: "hand.raised.fill",
                                color: .red,
                                steps: [
                                    "1. **Confirm Diversion/SUD**: Obtain Urine Tox (GC/MS) + PDMP.",
                                    "2. **Halt Prescribing**: If diversion confirmed or safety compromised.",
                                    "3. **Refer**: Immediate Addiction Medicine consultation.",
                                    "4. **Discharge**: If behavior persists or safety unguaranteeable."
                                ]
                            )
                        } 
                        // Yellow Flag Response (Context Dependent)
                        else if !selectedYellowFlags.isEmpty {
                            if isCancerContext {
                                // ASCO 2016 / NCCN 2025: Restructure, Don't Taper
                                ActionCard(
                                    title: "RESTRUCTURE (NO TAPER)",
                                    icon: "arrow.triangle.merge",
                                    color: ClinicalTheme.purple500, // Distinct color for Palliative
                                    steps: OUDStaticData.cancerActionSteps
                                )
                            } else {
                                // CDC 2022: Tighten & Taper
                                ActionCard(
                                    title: "TIGHTEN & CONSIDER TAPER",
                                    icon: "arrow.triangle.2.circlepath",
                                    color: .orange,
                                    steps: OUDStaticData.nonCancerActionSteps
                                )
                            }
                        }
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer().frame(height: 50)
            }
            .padding(.vertical)
        }
        .background(ClinicalTheme.backgroundMain)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-seed context from global assessment if available
            if assessmentStore.indication == .cancer || assessmentStore.indication == .dyspnea { // Dyspnea implies palliative
                 isCancerContext = true
            }
        }
    }
    
    private func toggleSelection(_ item: AberrantBehavior, category: BehaviorCategory) {
        withAnimation {
            if category == .redFlag {
                if selectedRedFlags.contains(item.behavior) {
                    selectedRedFlags.remove(item.behavior)
                } else {
                    selectedRedFlags.insert(item.behavior)
                }
            } else {
                if selectedYellowFlags.contains(item.behavior) {
                    selectedYellowFlags.remove(item.behavior)
                } else {
                    selectedYellowFlags.insert(item.behavior)
                }
            }
        }
    }
}

// MARK: - Components

struct AberrantRow: View {
    let item: AberrantBehavior
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? (item.category == .redFlag ? .red : .orange) : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.behavior)
                        .font(.body)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .strikethrough(false) // Reset
                    
                    if isSelected {
                        Text("Action: \(item.action)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(item.category == .redFlag ? .red : .orange)
                            .transition(.opacity)
                    }
                }
                Spacer()
            }
            .padding()
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? (item.category == .redFlag ? Color.red : Color.orange) : Color.clear, lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(steps, id: \.self) { step in
                    Text(.init(step)) // Allows Markdown
                        .font(.subheadline)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}
