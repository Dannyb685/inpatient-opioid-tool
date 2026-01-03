import SwiftUI

struct OUDConsultView: View {
    @State private var selectedTab = "screeners" // screeners, induction, withdrawal, tools
    @State private var selectedTool = "counseling"
    @State private var showArchivedWizard = false
    
    // Protocol Stores
    @StateObject private var screeningStore = ScreeningStore()
    @StateObject private var toolkitStore = ToolkitStore()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Segmented Control
                Picker("Mode", selection: $selectedTab) {
                    Text("Screeners").tag("screeners")
                    Text("Induction").tag("induction")
                    Text("Withdrawal").tag("withdrawal")
                    Text("Tools").tag("tools")
                }
                .pickerStyle(.segmented)
                .padding()
                .background(ClinicalTheme.backgroundMain)
                
                // Content Area
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: - SCREENERS TAB
                        if selectedTab == "screeners" {
                            VStack(alignment: .leading, spacing: 8) {
                                OUDProtocolHeader(title: "Clinical Screeners")
                                
                                VStack(spacing: 12) {
                                    // DAST-10
                                    NavigationLink(destination: ScrollView { DASTView(store: screeningStore).padding() }
                                        .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
                                        .navigationTitle("DAST-10")
                                    ) {
                                        ScreenerRow(icon: "list.clipboard", title: "DAST-10", subtitle: "Drug Abuse Screening Test", color: ClinicalTheme.blue500)
                                    }
                                    
                                    // ASSIST-Lite
                                    NavigationLink(destination: ScrollView { AssistLyteView(store: screeningStore).padding() }
                                        .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
                                        .navigationTitle("ASSIST-Lite")
                                    ) {
                                        ScreenerRow(icon: "person.fill.questionmark", title: "ASSIST-Lite", subtitle: "WHO Substance Involvement", color: ClinicalTheme.teal500)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        
                        // MARK: - INDUCTION TAB
                        } else if selectedTab == "induction" {
                            VStack(alignment: .leading, spacing: 8) {
                                OUDProtocolHeader(title: "Induction Protocols")
                                
                                // 1. Standard Induction
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        CircleIcon(icon: "timer", color: ClinicalTheme.blue500)
                                        Text("Standard Induction")
                                            .font(.headline)
                                            .foregroundColor(ClinicalTheme.textPrimary)
                                    }
                                    
                                    VStack(spacing: 0) {
                                        ForEach(ProtocolData.standardInduction) { step in
                                            HStack(alignment: .top, spacing: 12) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    // Header Row
                                                    Text(step.step)
                                                        .font(.caption).bold()
                                                        .foregroundColor(ClinicalTheme.teal500)
                                                        .padding(.bottom, 2)
                                                    
                                                    // Content
                                                    Text(step.action)
                                                        .font(.subheadline).bold()
                                                        .foregroundColor(ClinicalTheme.textPrimary)
                                                    
                                                    if !step.note.isEmpty {
                                                        Text(step.note)
                                                            .font(.caption)
                                                            .foregroundColor(ClinicalTheme.textSecondary)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                    }
                                                }
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            
                                            if step.id != ProtocolData.standardInduction.last?.id {
                                                Divider().background(ClinicalTheme.divider)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(ClinicalTheme.backgroundCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                                
                                // 2. Micro-Induction (Bernese)
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        CircleIcon(icon: "tortoise.fill", color: ClinicalTheme.teal500)
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("Micro-Induction (Bernese)")
                                                .font(.headline)
                                                .foregroundColor(ClinicalTheme.textPrimary)
                                            Text("For Fentanyl/Methadone overlap")
                                                .font(.caption2)
                                                .foregroundColor(ClinicalTheme.textSecondary)
                                        }
                                    }
                                    
                                    VStack(spacing: 0) {
                                        ForEach(ProtocolData.berneseData) { step in
                                            HStack {
                                                Text("Day \(step.day)")
                                                    .font(.caption).bold()
                                                    .foregroundColor(ClinicalTheme.teal500)
                                                    .frame(width: 45, alignment: .leading)
                                                
                                                Text(step.dose)
                                                    .font(.subheadline).bold()
                                                    .foregroundColor(ClinicalTheme.textPrimary)
                                                
                                                Spacer()
                                                
                                                Text(step.note)
                                                    .font(.caption)
                                                    .foregroundColor(ClinicalTheme.textSecondary)
                                            }
                                            .padding(.vertical, 8)
                                            
                                            if step.day != 6 {
                                                Divider().background(ClinicalTheme.divider)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(ClinicalTheme.backgroundCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))

                                // 3. High Dose
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        CircleIcon(icon: "bolt.fill", color: ClinicalTheme.rose500)
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("High-Dose Rapid Induction")
                                                .font(.headline)
                                                .foregroundColor(ClinicalTheme.textPrimary)
                                            Text("For ER/Inpatient Management")
                                                .font(.caption2)
                                                .foregroundColor(ClinicalTheme.textSecondary)
                                        }
                                    }
                                    
                                    VStack(spacing: 0) {
                                        // Step 1
                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Assess")
                                                    .font(.caption).bold()
                                                    .foregroundColor(ClinicalTheme.rose500)
                                                Text("Goal COWS ≥ 8")
                                                    .font(.subheadline).bold()
                                                    .foregroundColor(ClinicalTheme.textPrimary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        Divider().background(ClinicalTheme.divider)

                                        // Step 2
                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Dose")
                                                    .font(.caption).bold()
                                                    .foregroundColor(ClinicalTheme.rose500)
                                                Text("8-16 mg SL Buprenorphine")
                                                    .font(.subheadline).bold()
                                                    .foregroundColor(ClinicalTheme.textPrimary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        Divider().background(ClinicalTheme.divider)

                                        // Step 3
                                        HStack(alignment: .top, spacing: 12) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Monitor")
                                                    .font(.caption).bold()
                                                    .foregroundColor(ClinicalTheme.rose500)
                                                Text("Re-assess in 60 mins")
                                                    .font(.subheadline).bold()
                                                    .foregroundColor(ClinicalTheme.textPrimary)
                                                Text("If symptoms persist, may repeat dose.")
                                                    .font(.caption)
                                                    .foregroundColor(ClinicalTheme.textSecondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(16)
                                .background(ClinicalTheme.backgroundCard)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                            }
                            .padding(.horizontal)
                            
                        
                        // MARK: - WITHDRAWAL TAB
                        } else if selectedTab == "withdrawal" {
                            VStack(alignment: .leading, spacing: 8) {
                                OUDProtocolHeader(title: "Withdrawal Management")
                                
                                VStack(spacing: 16) {
                                    // COWS Scale (Moved from Screeners)
                                    NavigationLink(destination: COWSView(store: toolkitStore)) {
                                        ScreenerRow(icon: "waveform.path.ecg", title: "COWS Scale", subtitle: "Clinical Opiate Withdrawal Scale", color: ClinicalTheme.rose500)
                                    }
                                    
                                    ForEach(ProtocolData.symptomManagement) { category in
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(category.title)
                                                .font(.subheadline).bold()
                                                .foregroundColor(ClinicalTheme.teal500)
                                                .textCase(.uppercase)
                                            
                                            ForEach(category.items, id: \.self) { item in
                                                HStack(alignment: .top) {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(item.drug)
                                                            .font(.body).bold()
                                                            .foregroundColor(ClinicalTheme.textPrimary)
                                                        Text(item.dose)
                                                            .font(.caption)
                                                            .foregroundColor(ClinicalTheme.textSecondary)
                                                    }
                                                    Spacer()
                                                    Text(item.note)
                                                        .font(.caption)
                                                        .italic()
                                                        .foregroundColor(ClinicalTheme.textMuted)
                                                        .multilineTextAlignment(.trailing)
                                                }
                                                
                                                if item != category.items.last {
                                                    Divider().background(ClinicalTheme.divider)
                                                }
                                            }
                                        }
                                        .padding(16)
                                        .background(ClinicalTheme.backgroundCard)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                        // MARK: - TOOLS TAB
                        } else if selectedTab == "tools" {
                            // Sub-Picker for Tools
                            Picker("Tool", selection: $selectedTool) {
                                Text("Counseling").tag("counseling")
                                Text("Visual Aids").tag("visuals")
                                Text("Urine Tox").tag("tox")
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            if selectedTool == "counseling" {
                                CounselingView()
                            } else if selectedTool == "visuals" {
                                VisualAidsView()
                            } else if selectedTool == "tox" {
                                UrineToxView()
                            }
                            
                            // TIPS / REFERENCE (Moved to Bottom of Tools Tab)
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Clinical Pearls").font(.headline)
                                Text("• Start low and go slow for opioid naive patients.").font(.caption)
                                Text("• Rotate to methadone only in consultation with a specialist.").font(.caption)
                                
                                Divider()
                                
                                // Archive Link
                                Button(action: { showArchivedWizard = true }) {
                                    HStack {
                                        Image(systemName: "archivebox.fill")
                                        Text("Dev: Archived Wizard")
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .clinicalCard()
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(ClinicalTheme.backgroundMain)
            }
            .navigationTitle("OUD Consult")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showArchivedWizard) {
                OUDConsultWizardView()
            }
        }
    }
}


// MARK: - Helper Components (Private to OUDConsultView)

struct OUDProtocolHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.black)
            .textCase(.uppercase)
            .foregroundColor(ClinicalTheme.textSecondary)
            .padding(.leading, 4)
            .padding(.bottom, 2)
    }
}

private struct CircleIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

private struct ScreenerRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            CircleIcon(icon: icon, color: color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ClinicalTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .bold()
                .foregroundColor(ClinicalTheme.textMuted)
        }
        .padding(16)
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
    }
}
