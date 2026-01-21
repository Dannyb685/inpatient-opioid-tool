import SwiftUI

// MARK: - 1. NRS View (Numeric Rating Scale)
struct NRSView: View {
    @Binding var score: Int
    
    let range = 0...10
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Numeric Rating Scale (NRS)")
                .font(.headline)
                .foregroundColor(ClinicalTheme.textSecondary)
            
            // Segmented-style integer picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(range, id: \.self) { val in
                        Button(action: {
                            score = val
                        }) {
                            Text("\(val)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(width: 50, height: 50)
                                .background(score == val ? (val > 7 ? ClinicalTheme.rose500 : ClinicalTheme.teal500) : ClinicalTheme.backgroundInput)
                                .foregroundColor(score == val ? .white : ClinicalTheme.textPrimary)
                                .cornerRadius(8) // Square-ish look
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(score == val ? (val > 7 ? ClinicalTheme.rose500 : ClinicalTheme.teal500) : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.vertical, 8)
            
            // Labels
            HStack {
                Text("No Pain").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                Spacer()
                Text("Worst Possible").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
    }
}

// MARK: - 2. VAS View (Visual Analog Scale - Blind)
struct VASView: View {
    @Binding var mmScore: Double // 0.0 to 100.0
    
    // Severity Labels based on mm cutoffs
    var severityLabel: String {
        if mmScore <= 34 { return "Mild" }
        else if mmScore <= 74 { return "Moderate" }
        else { return "Severe" }
    }
    
    var severityColor: Color {
        if mmScore <= 34 { return ClinicalTheme.teal500 }
        else if mmScore <= 74 { return ClinicalTheme.amber500 }
        else { return ClinicalTheme.rose500 }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Visual Analog Scale")
                        .font(.headline)
                    Text("No numbers shown on slider (Blind Test)")
                        .font(.caption)
                        .foregroundColor(ClinicalTheme.textSecondary)
                }
                Spacer()
                
                // Clinician Feedback Badge
                Text(severityLabel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor)
                    .cornerRadius(4)
            }
            
            // The "Blind" Slider (0-100mm)
            Slider(value: $mmScore, in: 0...100, step: 1.0)
                .accentColor(severityColor)
            
            HStack {
                Text("No Pain").font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
                Spacer()
                Text("Worst Pain").font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
            }
            
            Divider()
            
            // Clinician View of Score (Hidden from patient ideally, but shown here for tool)
            HStack {
                Text("Recorded Value:")
                    .font(.subheadline)
                    .foregroundColor(ClinicalTheme.textSecondary)
                Spacer()
                Text("\(Int(mmScore)) mm")
                    .font(.title3)
                    .monospacedDigit()
                    .bold()
                    .foregroundColor(ClinicalTheme.textPrimary)
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
    }
}

// MARK: - 3. VDS View (Verbal Descriptor Scale)
struct VDSView: View {
    @Binding var selection: String
    
    let options = [
        "No pain",
        "Mild pain",
        "Moderate pain",
        "Severe pain",
        "Extreme pain",
        "Excruciating pain"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verbal Descriptor Scale")
                .font(.headline)
                .foregroundColor(ClinicalTheme.textSecondary)
                .padding(.bottom, 4)
            
            ForEach(options, id: \.self) { opt in
                Button(action: {
                    selection = opt
                }) {
                    HStack {
                        Text(opt)
                            .font(.body)
                            .fontWeight(selection == opt ? .bold : .medium)
                        Spacer()
                        if selection == opt {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .frame(minHeight: 50)
                    .background(selection == opt ? ClinicalTheme.teal500.opacity(0.15) : ClinicalTheme.backgroundInput)
                    .foregroundColor(selection == opt ? ClinicalTheme.teal500 : ClinicalTheme.textPrimary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selection == opt ? ClinicalTheme.teal500 : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
    }
}

// MARK: - 4. Reusable Behavioral Matrix (BPS / CPOT)
struct BehavioralDomain {
    let name: String
    let options: [(score: Int, description: String)]
}

struct BehavioralMatrixView: View {
    let title: String
    let domains: [BehavioralDomain]
    @Binding var totalScore: Int
    
    // Internal State to track selections per domain
    // We map index of domain to selected index of option
    @State private var selections: [Int: Int] = [:]
    
    // Auto-calculate total on change
    func recalculate() {
        var sum = 0
        for (dIndex, _) in domains.enumerated() {
            let selectedOptIndex = selections[dIndex] ?? 0
            // Ensure bounds
            if selectedOptIndex < domains[dIndex].options.count {
                sum += domains[dIndex].options[selectedOptIndex].score
            }
        }
        totalScore = sum
    }
    
    var severityColor: Color {
        // Generic cutoff logic (BPS > 5 or CPOT >= 3 usually significant)
        // Let's assume > half scale is red? Or just teal default.
        return totalScore >= 3 ? ClinicalTheme.rose500 : ClinicalTheme.teal500
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("Score: \(totalScore)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.1))
                    .cornerRadius(8)
            }
            
            ForEach(Array(domains.enumerated()), id: \.offset) { index, domain in
                VStack(alignment: .leading, spacing: 8) {
                    Text(domain.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(ClinicalTheme.textSecondary)
                        .textCase(.uppercase)
                    
                    // Grid of options
                    VStack(spacing: 8) {
                        ForEach(Array(domain.options.enumerated()), id: \.offset) { optIdx, option in
                            Button(action: {
                                selections[index] = optIdx
                                recalculate()
                            }) {
                                HStack {
                                    Text(option.description)
                                        .font(.caption) // Dense text
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Text("+\(option.score)")
                                        .font(.caption2)
                                        .bold()
                                }
                                .padding(10)
                                .background(selections[index] == optIdx ? ClinicalTheme.teal500.opacity(0.1) : ClinicalTheme.backgroundInput)
                                .foregroundColor(selections[index] == optIdx ? ClinicalTheme.teal500 : ClinicalTheme.textPrimary)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selections[index] == optIdx ? ClinicalTheme.teal500 : Color.clear, lineWidth: 1.5)
                                )
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .onAppear {
            // Init Default Selections (0)
            for i in 0..<domains.count {
                if selections[i] == nil { selections[i] = 0 }
            }
            recalculate()
        }
    }
}
