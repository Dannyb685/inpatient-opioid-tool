import SwiftUI

Picker("Communication", selection: $store.communicationStatus)
    .accessibilityIdentifier("screening_communication_toggle") //

struct PainAssessmentView: View {
    @EnvironmentObject var store: AssessmentStore
    
    // Scale Selection Menu
    private var availableScales: [PainScaleType] {
        PainScaleType.allCases.filter { $0 != .unable }
    }
    
    var body: some View {
        VStack(spacing: 24) {
    .accessibilityIdentifier("pain_assessment_container")
            
            // SECTION 1: Clinical Screening (Compact)
            VStack(alignment: .leading, spacing: 12) {
                Text("PATIENT FACTORS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(ClinicalTheme.textSecondary)
                
                HStack(alignment: .top, spacing: 12) {
                    // 1. Communication
                    VStack(alignment: .leading) {
                        Label("Communication", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.caption).bold()
                        Picker("Comm", selection: $store.communication) {
                            Text("Verbal").tag(CommunicationAbility.verbal)
                            Text("Non-Verbal").tag(CommunicationAbility.nonCommunicative)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 2. Cognitive
                    VStack(alignment: .leading) {
                        Label("Cognition", systemImage: "brain.head.profile")
                             .font(.caption).bold()
                        Picker("Cog", selection: $store.cognitiveStatus) {
                            Text("Baseline").tag(CognitiveStatus.baseline)
                            Text("Dementia").tag(CognitiveStatus.advancedDementia)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 3. Intubation (Conditional)
                    if store.communication != .verbal {
                        VStack(alignment: .leading) {
                            Label("Airway", systemImage: "lungs.fill")
                                 .font(.caption).bold()
                            Toggle("Intubated", isOn: Binding(
                                get: { store.intubation == .intubated },
                                set: { store.intubation = $0 ? .intubated : .none }
                            ))
                            .labelsHidden()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(ClinicalTheme.backgroundInput)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // SECTION 2: Scale Selector
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Scale")
                            .font(.caption)
                            .foregroundColor(ClinicalTheme.textSecondary)
                        Text(store.recommendedScale.rawValue)
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Section("Manual Override") {
                            Button("Auto-Select (Default)", action: { store.manualScaleOverride = nil })
                            Divider()
                            ForEach(availableScales) { scale in
                                Button(scale.rawValue) {
                                    store.manualScaleOverride = scale
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Change")
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ClinicalTheme.teal500.opacity(0.1))
                        .foregroundColor(ClinicalTheme.teal500)
                        .cornerRadius(6)
                        .accessibilityIdentifier("scale_selector_menu")
                    }
                }
                .padding(.horizontal)
                
                // SECTION 3: The Active Component
                Group {
                    switch store.recommendedScale {
                    case .peg:
                        PEGScaleView(
                            painLevel: $store.pegPain,
                            enjoymentLevel: $store.pegEnjoyment,
                            activityLevel: $store.pegActivity
                        )
                        
                    case .nrs:
                        NRSView(score: $store.nrsScore)
                        
                    case .vas:
                        VASView(mmScore: $store.vasMillimeters)
                        
                    case .vds:
                        VDSView(selection: $store.vdsSelection)
                        
                    case .cpot:
                        BehavioralMatrixView(
                            title: "CPOT Assessment",
                            domains: [
                                BehavioralDomain(name: "Facial Expression", options: [
                                    (0, "Relaxed / Neutral"), (1, "Tense / Frowning"), (2, "Grimacing / Biting")
                                ]),
                                BehavioralDomain(name: "Body Movements", options: [
                                    (0, "Absence of movement"), (1, "Protection / Slow"), (2, "Restlessness / Agitation")
                                ]),
                                BehavioralDomain(name: "Muscle Tension", options: [
                                    (0, "Relaxed"), (1, "Tense / Rigid"), (2, "Very Tense / Rigid")
                                ]),
                                BehavioralDomain(name: store.intubation == .intubated ? "Compliance (Vent)" : "Vocalization", options: store.intubation == .intubated ? [
                                    (0, "Tolerating / No alarms"), (1, "Coughing / Alarms"), (2, "Fighting ventilator")
                                ] : [
                                    (0, "Normal / None"), (1, "Sighing / Moaning"), (2, "Crying out / Sobbing")
                                ])
                            ],
                            totalScore: $store.cpotScore
                        )
                        
                    case .bps, .bpsNi:
                        BehavioralMatrixView(
                            title: "Behavioral Pain Scale (BPS)",
                            domains: [
                                BehavioralDomain(name: "Facial Expression", options: [
                                    (1, "Relaxed"), (2, "Partially Tightened"), (3, "Fully Tightened"), (4, "Grimacing")
                                ]),
                                BehavioralDomain(name: "Upper Limbs", options: [
                                    (1, "No Movement"), (2, "Partially Bent"), (3, "Fully Bent"), (4, "Permanently Retracted")
                                ]),
                                BehavioralDomain(name: "Compliance", options: [
                                    (1, "Tolerating movement"), (2, "Coughing with movement"), (3, "Fighting controls"), (4, "Unable to control")
                                ])
                            ],
                            totalScore: $store.bpsScore
                        )
                        
                    case .painad:
                        BehavioralMatrixView(
                            title: "PAINAD (Dementia)",
                            domains: [
                                BehavioralDomain(name: "Breathing", options: [
                                    (0, "Normal"), (1, "Occasional labored"), (2, "Noisy / Hyperventilation")
                                ]),
                                BehavioralDomain(name: "Negative Vocalization", options: [
                                    (0, "None"), (1, "Occasional moan"), (2, "Repeated calling out")
                                ]),
                                BehavioralDomain(name: "Facial Expression", options: [
                                    (0, "Smiling / Inexpressive"), (1, "Sad / Frown"), (2, "Grimacing")
                                ]),
                                BehavioralDomain(name: "Body Language", options: [
                                    (0, "Relaxed"), (1, "Tense / Pacing"), (2, "Rigid / Fists / Pulling")
                                ]),
                                BehavioralDomain(name: "Consolability", options: [
                                    (0, "No need to console"), (1, "Distractible"), (2, "Unable to console")
                                ])
                            ],
                            totalScore: $store.painadScore
                        )
                        
                    case .unable:
                        Text("Unable to Assess Pain")
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(ClinicalTheme.backgroundInput)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .accessibilityIdentifier("active_scale_view")
            }
        }
        .padding(.vertical)
        .background(ClinicalTheme.backgroundMain) 
        // Note: Using backgroundMain (gray-50) for contrast with white cards
    }
}
