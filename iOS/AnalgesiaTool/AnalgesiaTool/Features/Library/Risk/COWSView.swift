import SwiftUI

struct COWSView: View {
    @ObservedObject var store: ToolkitStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showRecommendations = false
    
    // MARK: - Logic
    var recommendations: [AdjuvantRecommendation] {
        var recs: [AdjuvantRecommendation] = []
        
        // Bone/Joint Aches
        if store.cowsBoneAche > 0 {
            recs.append(AdjuvantRecommendation(category: "Pain", drug: "Acetaminophen", dose: "650mg PO q6h", rationale: "Bone/Joint Pain"))
            recs.append(AdjuvantRecommendation(category: "Pain", drug: "Ibuprofen", dose: "600mg PO q6h", rationale: "NSAID Option"))
        }
        
        // GI Upset
        if store.cowsGI > 0 {
            recs.append(AdjuvantRecommendation(category: "Nausea", drug: "Ondansetron", dose: "4mg PO q6h prn", rationale: "Nausea/Vomiting"))
            recs.append(AdjuvantRecommendation(category: "Diarrhea", drug: "Loperamide", dose: "2mg PO prn", rationale: "Loose Stool"))
            if store.cowsGI == 1 { // Stomach cramps
                recs.append(AdjuvantRecommendation(category: "Cramps", drug: "Dicyclomine", dose: "20mg q6h prn", rationale: "Abdominal Cramping"))
            }
        }

        // Autonomic (Clonidine)
        // Sweating, Pulse, Tremor, Anxiety, Runny Nose, Gooseflesh
        let autonomicSum = store.cowsSweating + store.cowsPulse + store.cowsTremor + store.cowsAnxiety + store.cowsRunnyNose + store.cowsGooseflesh
        if autonomicSum > 0 {
             recs.append(AdjuvantRecommendation(category: "Autonomic", drug: "Clonidine", dose: "0.1mg PO q4h prn", rationale: "Sweating, Tremors, Anxiety. Hold SBP<100."))
        }
        
        // Anxiety Specific
        if store.cowsAnxiety > 0 || store.cowsRestlessness > 0 {
             recs.append(AdjuvantRecommendation(category: "Anxiety", drug: "Hydroxyzine", dose: "25-50mg PO q6h prn", rationale: "Anxiety/Restlessness"))
        }
        
        // Insomnia
        if store.cowsYawning > 0 || store.cowsRestlessness > 0 {
             recs.append(AdjuvantRecommendation(category: "Sleep", drug: "Trazodone", dose: "50-100mg PO qhs prn", rationale: "Insomnia"))
        }
        
        // Deduplicate
        var uniqueRecs: [AdjuvantRecommendation] = []
        var seenDrugs: Set<String> = []
        for r in recs {
            if !seenDrugs.contains(r.drug) {
                uniqueRecs.append(r)
                seenDrugs.insert(r.drug)
            }
        }
        return uniqueRecs
    }
    
    var scoreColor: Color {
        if store.cowsScore > 36 { return ClinicalTheme.rose500 }
        if store.cowsScore > 24 { return .orange }
        if store.cowsScore > 12 { return ClinicalTheme.amber500 }
        return ClinicalTheme.teal500
    }
    
    var body: some View {
        VStack(spacing: 0) {
            pinnedHeader
            
            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        CowsItem(title: "Resting Pulse Rate", selection: $store.cowsPulse, options: [
                            0: "Pulse ≤ 80", 1: "Pulse 81-100", 2: "Pulse 101-120", 4: "Pulse > 120"
                        ])
                        
                        CowsItem(title: "Sweating", selection: $store.cowsSweating, options: [
                            0: "No report of chills/flushing", 1: "Subjective chills or flushing", 2: "Flushed or observable moistness", 3: "Beads of sweat on brow/face", 4: "Sweat streaming off face"
                        ])
                        
                        CowsItem(title: "Restlessness", selection: $store.cowsRestlessness, options: [
                            0: "Able to sit still", 1: "Reports difficulty sitting still", 3: "Frequent shifting/extraneous movement", 5: "Unable to sit still for more than a few seconds"
                        ])
                        
                        CowsItem(title: "Pupil Size", selection: $store.cowsPupil, options: [
                            0: "Normal size for room light", 1: "Possibly larger than normal", 2: "Moderately dilated", 5: "Extremely dilated"
                        ])
                        
                        CowsItem(title: "Bone or Joint Aches", selection: $store.cowsBoneAche, options: [
                            0: "Not present", 1: "Mild diffuse discomfort", 2: "Patient reports severe aching", 4: "Rubbing joints/muscles + unable to sit"
                        ])
                        
                        CowsItem(title: "Runny Nose or Tearing", selection: $store.cowsRunnyNose, options: [
                            0: "Not present", 1: "Nasal congestion or tearing", 2: "Symptoms are observable", 4: "Constant tearing or redness"
                        ])
                    }
                    
                    Group {
                        CowsItem(title: "GI Upset", selection: $store.cowsGI, options: [
                            0: "No GI symptoms", 1: "Stomach cramps", 2: "Nausea or loose stool", 3: "Vomiting or diarrhea", 5: "Multiple diarrhea/vomiting"
                        ])
                        
                        CowsItem(title: "Tremor", selection: $store.cowsTremor, options: [
                            0: "No tremor", 1: "Tremor can be felt/not seen", 2: "Slight tremor observable", 4: "Gross tremor / twitching"
                        ])
                        
                        CowsItem(title: "Yawning", selection: $store.cowsYawning, options: [
                            0: "No yawning", 1: "Yawning 1-2 times during assessment", 2: "Yawning 3+ times during assessment", 4: "Yawning several times per minute"
                        ])
                        
                        CowsItem(title: "Anxiety or Irritability", selection: $store.cowsAnxiety, options: [
                            0: "None", 1: "Reports increased irritability", 2: "Obviously irritable or anxious", 4: "Difficult to participate"
                        ])
                        
                        CowsItem(title: "Gooseflesh Skin", selection: $store.cowsGooseflesh, options: [
                            0: "Skin is smooth", 3: "Piloerection can be felt", 5: "Prominent piloerection"
                        ])
                    }
                    
                    Button(action: { withAnimation { store.resetCOWS() } }) {
                        Text("Reset Scale")
                            .font(.headline)
                            .foregroundColor(ClinicalTheme.teal500)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(ClinicalTheme.teal500.opacity(0.1))
                            .cornerRadius(20)
                    }
                    .padding(.top)
                }
                .padding()
                .padding(.bottom, 40)
            }
        }
        .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
        .navigationTitle("COWS Assessment")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var pinnedHeader: some View {
        VStack(spacing: 8) {
            // Score Row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL SCORE").font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(store.cowsScore)")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(scoreColor)
                        
                        Text(store.cowsSeverity)
                            .font(.headline).bold()
                            .foregroundColor(scoreColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(scoreColor.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Symptom-Triggered Recommendations
                if !recommendations.isEmpty {
                    Divider().background(ClinicalTheme.divider)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Button(action: {
                            withAnimation { showRecommendations.toggle() }
                        }) {
                            HStack {
                                Text("SYMPTOM RECOMMENDATIONS")
                                    .font(.caption2).fontWeight(.black)
                                    .foregroundColor(ClinicalTheme.textSecondary)
                                
                                Spacer()
                                
                                if !showRecommendations {
                                    Text("\(recommendations.count) Suggested")
                                        .font(.caption2)
                                        .foregroundColor(ClinicalTheme.teal500)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(ClinicalTheme.teal500.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(ClinicalTheme.textSecondary)
                                    .rotationEffect(.degrees(showRecommendations ? 90 : 0))
                            }
                            .padding(.top, 4)
                        }
                        
                        if showRecommendations {
                            ForEach(recommendations) { rec in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "pills.fill")
                                        .font(.caption)
                                        .foregroundColor(ClinicalTheme.teal500)
                                        .padding(.top, 2)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(rec.drug).font(.subheadline).bold().foregroundColor(ClinicalTheme.textPrimary)
                                        + Text("  \(rec.dose)").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                                        Text(rec.rationale).font(.caption2).italic().foregroundColor(ClinicalTheme.textMuted)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding() // Outer padding
        .zIndex(1)
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
