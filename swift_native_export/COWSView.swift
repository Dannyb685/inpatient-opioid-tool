import SwiftUI

struct COWSView: View {
    @ObservedObject var store: ToolkitStore
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Score
                VStack {
                    Text("Total Score")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                        .textCase(.uppercase)
                    Text("\(store.cowsScore)")
                        .font(.system(size: 64, weight: .black))
                        .foregroundColor(store.cowsScore > 12 ? ClinicalTheme.rose500 : ClinicalTheme.teal500)
                    Text(store.cowsSeverity)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(ClinicalTheme.textSecondary)
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .clinicalCard()
                .padding(.horizontal)
                
                // Assessment Items
                VStack(spacing: 16) {
                    CowsItem(title: "Resting Pulse Rate", selection: $store.cowsPulse, options: [
                        0: "Pulse ≤ 80",
                        1: "Pulse 81-100",
                        2: "Pulse 101-120",
                        4: "Pulse > 120"
                    ])
                    
                    CowsItem(title: "Sweating", selection: $store.cowsSweating, options: [
                        0: "No report of chills/flushing",
                        1: "Subjective chills or flushing",
                        2: "Flushed or observable moistness",
                        3: "Beads of sweat on brow/face",
                        4: "Sweat streaming off face"
                    ])
                    
                    CowsItem(title: "Restlessness", selection: $store.cowsRestlessness, options: [
                        0: "Able to sit still",
                        1: "Reports difficulty sitting still",
                        3: "Frequent shifting/extraneous movement",
                        5: "Unable to sit still for more than a few seconds"
                    ])
                    
                    CowsItem(title: "Pupil Size", selection: $store.cowsPupil, options: [
                        0: "Normal size for room light",
                        1: "Possibly larger than normal",
                        2: "Moderately dilated",
                        5: "Extremely dilated"
                    ])
                    
                    CowsItem(title: "Bone or Joint Aches", selection: $store.cowsBoneAche, options: [
                        0: "Not present",
                        1: "Mild diffuse discomfort",
                        2: "Patient reports severe aching",
                        4: "Rubbing joints/muscles + unable to sit"
                    ])
                    
                    CowsItem(title: "Runny Nose or Tearing", selection: $store.cowsRunnyNose, options: [
                        0: "Not present",
                        1: "Nasal congestion or tearing",
                        2: "Symptoms are observable",
                        4: "Constant tearing or redness"
                    ])
                    
                    CowsItem(title: "GI Upset", selection: $store.cowsGI, options: [
                        0: "No GI symptoms",
                        1: "Stomach cramps",
                        2: "Nausea or loose stool",
                        3: "Vomiting or diarrhea",
                        5: "Multiple diarrhea/vomiting"
                    ])
                    
                    CowsItem(title: "Tremor", selection: $store.cowsTremor, options: [
                        0: "No tremor",
                        1: "Tremor can be felt/not seen",
                        2: "Slight tremor observable",
                        4: "Gross tremor / twitching"
                    ])
                    
                    CowsItem(title: "Yawning", selection: $store.cowsYawning, options: [
                        0: "No yawning",
                        1: "Yawning 1-2 times during assessment",
                        2: "Yawning 3+ times during assessment",
                        4: "Yawning several times per minute"
                    ])
                    
                    CowsItem(title: "Anxiety or Irritability", selection: $store.cowsAnxiety, options: [
                        0: "None",
                        1: "Reports increased irritability",
                        2: "Obviously irritable or anxious",
                        4: "Difficult to participate"
                    ])
                    
                    CowsItem(title: "Gooseflesh Skin", selection: $store.cowsGooseflesh, options: [
                        0: "Skin is smooth",
                        3: "Piloerection can be felt",
                        5: "Prominent piloerection"
                    ])
                    
                }
                .padding(.horizontal)
                
                Button(action: { store.resetCOWS() }) {
                    Text("Reset Scale")
                        .font(.headline)
                        .foregroundColor(ClinicalTheme.teal500)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(ClinicalTheme.teal500.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            .padding(.vertical)
        }
        .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
        .navigationTitle("COWS Assessment")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CowsItem: View {
    let title: String
    @Binding var selection: Int
    let options: [Int: String]
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundColor(ClinicalTheme.textPrimary)
            
            ForEach(options.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                Button(action: { selection = key }) {
                    HStack {
                        Text(value)
                            .foregroundColor(selection == key ? .primary : ClinicalTheme.textSecondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if selection == key {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ClinicalTheme.teal500)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(ClinicalTheme.textMuted)
                        }
                    }
                    .padding()
                    .background(selection == key ? ClinicalTheme.teal500.opacity(0.15) : ClinicalTheme.backgroundMain)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selection == key ? ClinicalTheme.teal500 : ClinicalTheme.cardBorder, lineWidth: 1)
                    )
                }
            }
        }
        .clinicalCard()
    }
}
