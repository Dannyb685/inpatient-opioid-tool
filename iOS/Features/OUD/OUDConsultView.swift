import SwiftUI

struct OUDConsultView: View {
    @StateObject private var store = OUDConsultStore()
    @State private var showToolbox = false
    @State private var showCopyAlert = false
    
    let gridColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. Triage / Severity Badge
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Severity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        HStack {
                            Circle()
                                .fill(store.severityClassification.color)
                                .frame(width: 12, height: 12)
                            Text(store.severityClassification.title)
                                .font(.title2)
                                .bold()
                        }
                    }
                    Spacer()
                    
                    Button(action: { showToolbox = true }) {
                        VStack {
                            Image(systemName: "briefcase.fill")
                                .font(.title2)
                            Text("Toolbox")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // 2. Medical Supervision Toggle
                // Critical logic for filtering Tolerance/Withdrawal
                Toggle(isOn: $store.isMedicallySupervised) {
                    VStack(alignment: .leading) {
                        Text("Medical Supervision")
                            .font(.headline)
                        Text("Exclude physiological tolerance/withdrawal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1) // Fixed .slate to .primary
                )
                
                // 3. The Grid (DSM-5 Criteria)
                LazyVGrid(columns: gridColumns, spacing: 12) {
                    ForEach(OUDStaticData.dsmCriteria) { criterion in
                        CriteriaCard(
                            text: criterion.text,
                            isSelected: store.selectedCriteria.contains(criterion.id),
                            isDisabled: store.isMedicallySupervised && criterion.isPhysiological
                        ) {
                            store.toggleCriterion(criterion.id)
                        }
                    }
                }
                
                // 4. Risk Footer
                if store.showNaloxoneAlert {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        VStack(alignment: .leading) {
                            Text("Overdose Risk Detected")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Ensure Naloxone is prescribed/available.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                        Toggle("", isOn: $store.hasNaloxonePlan)
                            .labelsHidden()
                            .tint(.white.opacity(0.2))
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                    .animation(.easeInOut, value: store.showNaloxoneAlert)
                }
                
                // 5. Clinical Note Generator
                Button(action: copyNote) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Clinical Note")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("OUD Consult")
        .sheet(isPresented: $showToolbox) {
            ClinicalToolboxView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    withAnimation {
                        store.reset()
                    }
                }
            }
        }
        .alert("Note Copied", isPresented: $showCopyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ensure you are pasting into a secure chart/EMR. Do not share PHI via unsecure channels.")
        }
    }
    
    private func copyNote() {
        UIPasteboard.general.string = store.generatedClinicalNote
        showCopyAlert = true
    }
}

// Subcomponent for the Grid
struct CriteriaCard: View {
    let text: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
                
                // Content
                VStack(alignment: .leading) {
                    HStack {
                        // Visual Logic: If disabled but selected (Supervision Mode), show distinct icon
                        if isDisabled && isSelected {
                            Image(systemName: "checkmark.circle.trianglebadge.exclamationmark")
                                .foregroundColor(.gray)
                        } else {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(iconColor)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    
                    Text(text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .strikethrough(isDisabled && isSelected) // Strikethrough if excluded
                }
                .padding(12)
            }
            .frame(minHeight: 110) // Fixed height -> minHeight for Dynamic Type
        }
        .disabled(isDisabled)
        .opacity(isDisabled && !isSelected ? 0.5 : 1.0)
        // Accessibility Hardening
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
        .accessibilityValue(isSelected ? (isDisabled ? "Selected but Excluded from count" : "Selected") : "Not Selected")
        .accessibilityHint(isDisabled ? "Requires Medical Supervision toggle off to modify" : "Double tap to toggle")
    }
    
    // UI Logic Helpers
    private var cardFillColor: Color {
        if isDisabled { return Color(.systemGray6) }
        return isSelected ? Color.blue.opacity(0.05) : Color.white
    }
    
    private var borderColor: Color {
        if isDisabled { return Color.clear }
        return isSelected ? Color.blue : Color.gray.opacity(0.2)
    }
    
    private var iconColor: Color {
        if isDisabled { return Color.gray }
        return isSelected ? Color.blue : Color.gray.opacity(0.4)
    }
    
    private var textColor: Color {
        if isDisabled { return Color.gray }
        return isSelected ? Color.blue.opacity(0.8) : Color.primary
    }
}
