import SwiftUI

struct OUDConsultView: View {
    @StateObject private var store = OUDConsultStore()
    @StateObject private var screeningStore = ScreeningStore()
    @StateObject private var toolkitStore = ToolkitStore()
    @State private var showCopyAlert = false
    @State private var selectedTool: ToolOption = .dsm // Default to DSM-5
    
    enum ToolOption: String, CaseIterable, Identifiable {
        case dsm = "DSM-5 Criteria"
        case cows = "COWS Scale"
        case dast = "DAST-10"
        case assist = "ASSIST-Lite"
        case ort = "ORT Risk"
        case sos = "SOS Score"
        case peg = "PEG Scale"
                    
        var id: String { self.rawValue }
    }
    
    let gridColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
        ScrollView {
            VStack(spacing: 20) {
                // Main Feature Picker
                Picker("View Mode", selection: $store.viewMode) {
                    Text("Consult Tool").tag("consult")
                    Text("Protocols").tag("protocols")
                    Text("Tips / Reference").tag("tips")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                if store.viewMode == "consult" {
                    // Tool Picker
                    Picker("Tool", selection: $selectedTool) {
                        ForEach(ToolOption.allCases) { tool in
                            Text(tool.rawValue).tag(tool)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)
                    
                    VStack(spacing: 20) {
                        switch selectedTool {
                        case .dsm:
                            dsmContent
                            
                            // Clinical Note Generator (DSM Only)
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
                            .padding(.horizontal)
                            .padding(.top, 8)
                            
                        case .cows:
                            COWSView(store: toolkitStore)
                                .padding(.horizontal)
                        case .dast:
                            DASTView(store: screeningStore)
                                .padding(.horizontal)
                        case .assist:
                            AssistLyteView(store: screeningStore)
                                .padding(.horizontal)
                        case .ort:
                            ORTView(store: toolkitStore)
                                .padding(.horizontal)
                        case .sos:
                            SOSView(store: toolkitStore)
                                .padding(.horizontal)
                        case .peg:
                            PEGView(store: toolkitStore)
                                .padding(.horizontal)
                        }
                    }

                } else if store.viewMode == "protocols" {
                    // 2. Protocols View
                    OUDProtocolsList()
                        .padding(.horizontal)
                        
                } else if store.viewMode == "tips" {
                     // 3. Tips / Reference View
                     VStack(spacing: 20) {
                        // Standard Workup (Moved Back)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Standard Workup (DSM-5)").font(.headline).foregroundColor(ClinicalTheme.textPrimary).padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(OUDStaticData.workupItems, id: \.self) { item in
                                        WorkupToggle(
                                            item: item,
                                            isCompleted: store.completedWorkupItems.contains(item.id)
                                        ) {
                                            if store.completedWorkupItems.contains(item.id) {
                                                store.completedWorkupItems.remove(item.id)
                                            } else {
                                                store.completedWorkupItems.insert(item.id)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                         VisualAidsView()
                             .padding(.horizontal)
                            
                        UrineToxView()
                            .padding(.horizontal)
                            
                        CounselingView()
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("OUD Consult")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if store.viewMode == "consult" {
                    Button("Reset") {
                        withAnimation {
                            store.reset()
                            // Reset other stores too if needed?
                        }
                    }
                }
            }
        }
            .alert("Note Copied", isPresented: $showCopyAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Ensure you are pasting into a secure chart/EMR. Do not share PHI via unsecure channels.")
            }
        } // End NavigationView
    } // End body
    
    // Extracted DSM Content for readability
    var dsmContent: some View {
        VStack(spacing: 20) {
            // Severity Badge
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
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Medical Supervision Toggle
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
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal)
            
            // The Grid (DSM-5 Criteria)
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
            .padding(.horizontal)
            
            // Risk / Safety Footer (Simplified)
            HStack {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundColor(ClinicalTheme.rose500)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Risk Stratification Required").font(.headline).foregroundColor(ClinicalTheme.textPrimary)
                    Text("Check PDMP & Prescribe Naloxone").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                }
                Spacer()
            }
            .padding()
            .background(ClinicalTheme.rose500.opacity(0.1))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.rose500.opacity(0.3), lineWidth: 1))
            .padding(.horizontal)
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

struct ScreenToggle: View {
    let title: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        Button(action: { withAnimation { isOn.toggle() } }) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .padding(10)
            .background(isOn ? ClinicalTheme.teal500 : Color(.systemGray6)) // Grey when OFF, Teal when ON
            .foregroundColor(isOn ? .white : ClinicalTheme.textPrimary)
            .cornerRadius(8)
        }
    }
}

// MARK: - Workup Checkbox Component
// WorkupToggle moved to ReferenceView.swift
// MARK: - MOUD Protocol Views


struct OUDProtocolsList: View {
    @State private var mode = "standard" // standard, bernese, withdrawal
    
    var body: some View {
        VStack(spacing: 20) {
            Picker("Protocol", selection: $mode) {
                Text("Standard").tag("standard")
                Text("Micro (Bernese)").tag("bernese")
                Text("Symptom Care").tag("withdrawal")
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 8)
            
            if mode == "standard" {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Standard Buprenorphine Induction")
                        .font(.headline)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .padding(.bottom, 4)
                    
                    ForEach(ProtocolData.standardInduction) { item in
                        HStack(alignment: .top, spacing: 16) {
                            // Step Indicator
                            Text(item.step.components(separatedBy: " ").last ?? "#")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(ClinicalTheme.teal500))
                                .shadow(color: ClinicalTheme.teal500.opacity(0.3), radius: 4, x: 0, y: 2)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.step).font(.caption).bold().foregroundColor(ClinicalTheme.teal500).textCase(.uppercase)
                                Text(item.action).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                                Text(item.note).font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(ClinicalTheme.backgroundCard)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                }
            } else if mode == "bernese" {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Buprenorphine Micro-Induction (Bernese)")
                        .font(.headline)
                        .foregroundColor(ClinicalTheme.textPrimary)
                        .padding(.bottom, 20)
                    
                    // Timeline Logic
                    ForEach(Array(ProtocolData.berneseData.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            // Timeline Column
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(ClinicalTheme.teal500)
                                    .frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                
                                if index < ProtocolData.berneseData.count - 1 {
                                    Rectangle()
                                        .fill(ClinicalTheme.teal500.opacity(0.3))
                                        .frame(width: 2)
                                        .frame(maxHeight: .infinity)
                                        .padding(.vertical, -4) // Connect dots
                                }
                            }
                            .frame(width: 20)
                            
                            // Content
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Day \(step.day)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(ClinicalTheme.teal500)
                                        .textCase(.uppercase)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(ClinicalTheme.teal500.opacity(0.1))
                                        .cornerRadius(4)
                                    Spacer()
                                }
                                
                                Text(step.dose)
                                    .font(.headline)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                
                                Text(step.note)
                                    .font(.caption)
                                    .foregroundColor(ClinicalTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                
            } else {
                // Symptom Management
                VStack(spacing: 16) {
                    ForEach(ProtocolData.symptomManagement) { category in
                        VStack(alignment: .leading, spacing: 0) {
                            // Header
                            HStack {
                                Image(systemName: "pills.fill")
                                    .font(.caption)
                                    .foregroundColor(ClinicalTheme.teal500)
                                Text(category.title)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                                Spacer()
                            }
                            .padding()
                            .background(ClinicalTheme.teal500.opacity(0.1))
                            
                            // Medications
                            VStack(spacing: 0) {
                                ForEach(Array(category.items.enumerated()), id: \.element.id) { index, item in
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.drug)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundColor(ClinicalTheme.textPrimary)
                                            Text(item.dose)
                                                .font(.caption)
                                                .bold()
                                                .foregroundColor(ClinicalTheme.teal500)
                                        }
                                        Spacer()
                                        Text(item.note)
                                            .font(.caption2)
                                            .foregroundColor(ClinicalTheme.textSecondary)
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: 120, alignment: .trailing)
                                    }
                                    .padding()
                                    
                                    if index < category.items.count - 1 {
                                        Divider().padding(.leading, 16)
                                    }
                                }
                            }
                        }
                        .background(ClinicalTheme.backgroundCard)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    }
                }
            }
        }
    }
}

// Re-add WorkupToggle Here
struct WorkupToggle: View {
    let item: WorkupItem
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: { withAnimation { action() } }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? .green : .gray)
                        .font(.title3)
                    
                    if item.isRequired {
                        Text("REQ")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isCompleted ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(width: 140, height: 100)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? Color.green.opacity(0.5) : Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

