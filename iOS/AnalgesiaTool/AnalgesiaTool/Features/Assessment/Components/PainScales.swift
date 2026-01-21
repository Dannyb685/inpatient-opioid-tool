import SwiftUI

// MARK: - 1. NRS (Numeric Rating Scale)
struct NRSView: View {
    @Binding var score: Double
    
    let range = 0...10
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Select Pain Intensity (0-10)")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                ForEach(range, id: \.self) { val in
                    Button(action: {
                        score = Double(val)
                    }) {
                        Text("\(val)")
                            .font(.title3)
                            .bold()
                            .frame(minWidth: 44, minHeight: 44)
                            .background(score == Double(val) ? ClinicalTheme.teal500 : ClinicalTheme.backgroundInput)
                            .foregroundColor(score == Double(val) ? .white : ClinicalTheme.textPrimary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ClinicalTheme.teal500, lineWidth: score == Double(val) ? 2 : 0)
                            )
                    }
                }
            }
            
            HStack {
                Text("No Pain").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
                Spacer()
                Text("Worst Imaginable").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
    }
}

// MARK: - 2. VAS (Visual Analog Scale)
struct VASView: View {
    @Binding var score: Double // Stored as 0-10 internally for consistency, but logic uses 0-100mm
    @State private var sliderVal: Double = 0 // 0-100 mm
    
    // Logic: ≤3.4 cm (Mild), 3.5 to 7.4 cm (Moderate), ≥7.5 cm (Severe)
    var severity: String {
        let cm = sliderVal / 10.0
        if cm <= 3.4 { return "Mild" }
        else if cm <= 7.4 { return "Moderate" }
        else { return "Severe" }
    }
    
    var color: Color {
        let cm = sliderVal / 10.0
        if cm <= 3.4 { return ClinicalTheme.teal500 }
        else if cm <= 7.4 { return ClinicalTheme.amber500 }
        else { return ClinicalTheme.rose500 }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Visual Analog Scale (VAS)")
                .font(.headline)
            
            HStack {
                Text("No Pain")
                Spacer()
                Text("Worst Pain")
            }
            .font(.caption).foregroundColor(ClinicalTheme.textSecondary)
            
            // 10cm Slider representation
            Slider(value: $sliderVal, in: 0...100, step: 1)
                .accentColor(color)
                .onChange(of: sliderVal) { _, newValue in
                    score = newValue / 10.0 // Convert mm to 0-10 scale
                }
            
            HStack {
                Text("\(Int(sliderVal)) mm")
                    .font(.title2).bold().monospacedDigit()
                
                Spacer()
                
                Text(severity)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(color)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .onAppear {
            sliderVal = score * 10.0
        }
    }
}

// MARK: - 3. VDS (Verbal Descriptor Scale)
struct VDSView: View {
    @Binding var score: Double
    
    let options: [(label: String, val: Double)] = [
        ("No pain", 0),
        ("Mild pain", 2),
        ("Moderate pain", 5),
        ("Severe pain", 7),
        ("Extreme pain", 9),
        ("Excruciating pain", 10)
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Verbal Descriptor Scale")
                .font(.headline)
            
            ForEach(options, id: \.label) { opt in
                Button(action: {
                    score = opt.val
                }) {
                    HStack {
                        Text(opt.label)
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                        if score == opt.val {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .padding()
                    .frame(minHeight: 44)
                    .background(score == opt.val ? ClinicalTheme.teal500.opacity(0.1) : ClinicalTheme.backgroundInput)
                    .foregroundColor(score == opt.val ? ClinicalTheme.teal500 : ClinicalTheme.textPrimary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(score == opt.val ? ClinicalTheme.teal500 : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
    }
}

// MARK: - 4. PEG (Pain, Enjoyment, General)
struct PEGView: View {
    @Binding var score: Double
    
    @State private var p: Double = 0
    @State private var e: Double = 0
    @State private var g: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Text("PEG Scale (3-Item)")
                .font(.headline)
            
            PegSlider(title: "1. Pain (Average)", value: $p)
            PegSlider(title: "2. Enjoyment of Life", value: $e)
            PegSlider(title: "3. General Activity", value: $g)
            
            Divider()
            
            HStack {
                Text("PEG Score")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f", (p+e+g)/3.0))
                    .font(.title)
                    .bold()
                    .foregroundColor(ClinicalTheme.teal500)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .onChange(of: p) { _,_ in updateScore() }
        .onChange(of: e) { _,_ in updateScore() }
        .onChange(of: g) { _,_ in updateScore() }
    }
    
    func updateScore() {
        score = (p + e + g) / 3.0
    }
}

struct PegSlider: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).bold()
            HStack {
                Text("0").font(.caption)
                Slider(value: $value, in: 0...10, step: 1)
                Text("10").font(.caption)
            }
            Text("Score: \(Int(value))").font(.caption).foregroundColor(ClinicalTheme.textSecondary)
        }
    }
}

// MARK: - 5. CPOT (Critical Care Pain Observation Tool)
struct CPOTView: View {
    @Binding var score: Double
    
    @State private var facial: Int = 0
    @State private var bodyMove: Int = 0
    @State private var muscle: Int = 0
    @State private var compliance: Int = 0 // Or Vocalization
    
    var isIntubated: Bool = true 
    
    // Alert: Flag score ≥3 as significant pain.
    var isSignificant: Bool {
        return (facial + bodyMove + muscle + compliance) >= 3
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("CPOT Assessment")
                    .font(.headline)
                Spacer()
                Text("Score: \(facial + bodyMove + muscle + compliance)")
                    .font(.title3).bold()
                    .foregroundColor(isSignificant ? ClinicalTheme.rose500 : ClinicalTheme.teal500)
            }
            
            if isSignificant {
                Text("Score ≥ 3: Significant Pain Detected")
                    .font(.caption).bold()
                    .foregroundColor(.white)
                    .padding(6)
                    .background(ClinicalTheme.rose500)
                    .cornerRadius(4)
            }
            
            CpotRow(title: "Facial Expression", options: ["Relaxed (0)", "Tense (1)", "Grimacing (2)"], selection: $facial)
            CpotRow(title: "Body Movements", options: ["Absence (0)", "Protection (1)", "Restlessness (2)"], selection: $bodyMove)
            CpotRow(title: "Muscle Tension", options: ["Relaxed (0)", "Tense/Rigid (1)", "Very Tense (2)"], selection: $muscle)
            
            if isIntubated {
                CpotRow(title: "Compliance (Vent)", options: ["Tolerating (0)", "Coughing (1)", "Fighting (2)"], selection: $compliance)
            } else {
                CpotRow(title: "Vocalization", options: ["None (0)", "Sighing/Moaning (1)", "Crying out (2)"], selection: $compliance)
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .onChange(of: facial) { _,_ in update() }
        .onChange(of: bodyMove) { _,_ in update() }
        .onChange(of: muscle) { _,_ in update() }
        .onChange(of: compliance) { _,_ in update() }
    }
    
    func update() {
        score = Double(facial + bodyMove + muscle + compliance)
    }
}

struct CpotRow: View {
    let title: String
    let options: [String]
    @Binding var selection: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).bold().foregroundColor(ClinicalTheme.textSecondary)
            Picker(title, selection: $selection) {
                ForEach(0..<options.count, id: \.self) { idx in
                    Text(options[idx]).tag(idx)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - 6. BPS (Behavioral Pain Scale)
struct BPSView: View {
    @Binding var score: Double
    // 3 domains. Range 3 to 12.
    // Facial (1-4), Upper Limb (1-4), Compliance (1-4)
    
    @State private var facial: Int = 1
    @State private var upperLimb: Int = 1
    @State private var compliance: Int = 1
    
    var isSignificant: Bool {
        return (facial + upperLimb + compliance) > 5
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Behavioral Pain Scale (BPS)")
                    .font(.headline)
                Spacer()
                Text("Score: \(facial + upperLimb + compliance)")
                    .font(.title3).bold()
                    .foregroundColor(isSignificant ? ClinicalTheme.rose500 : ClinicalTheme.teal500)
            }
            
            if isSignificant {
                Text("Score > 5: Significant Pain")
                    .font(.caption).bold()
                    .foregroundColor(.white)
                    .padding(6)
                    .background(ClinicalTheme.rose500)
                    .cornerRadius(4)
            }
            
            BpsRow(title: "Facial Expression", options: ["Relaxed (1)", "Partially Tightened (2)", "Fully Tightened (3)", "Grimacing (4)"], selection: $facial)
            BpsRow(title: "Upper Limbs", options: ["No Movt (1)", "Partially Bent (2)", "Fully Bent (3)", "Permanently Retracted (4)"], selection: $upperLimb)
            BpsRow(title: "Compliance", options: ["Tolerating (1)", "Coughing (2)", "Fighting (3)", "Unable to control (4)"], selection: $compliance)
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .onChange(of: facial) { _,_ in update() }
        .onChange(of: upperLimb) { _,_ in update() }
        .onChange(of: compliance) { _,_ in update() }
    }
    
    func update() {
        score = Double(facial + upperLimb + compliance)
    }
}

struct BpsRow: View {
    let title: String
    let options: [String]
    @Binding var selection: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline).bold().foregroundColor(ClinicalTheme.textSecondary)
            Menu {
                ForEach(0..<options.count, id: \.self) { idx in
                    Button(options[idx]) {
                        selection = idx + 1
                    }
                }
            } label: {
                HStack {
                    Text(options[selection - 1])
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                }
                .padding()
                .background(ClinicalTheme.backgroundInput)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - 7. PAINAD (Dementia)
struct PAINADView: View {
    @Binding var score: Double
    // 5 domains, 0-2 each. Total 0-10.
    // Breathing, Negative Vocalization, Facial Expression, Body Language, Consolability
    
    @State private var breathing: Int = 0
    @State private var vocal: Int = 0
    @State private var facial: Int = 0
    @State private var bodyLang: Int = 0
    @State private var console: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Text("PAINAD (Advanced Dementia)")
                .font(.headline)
            
            PainadRow(title: "Breathing", options: ["Normal (0)", "Laborious/Hypervent (1)", "Cheyne-Stokes (2)"], selection: $breathing)
            PainadRow(title: "Vocalization", options: ["None (0)", "Moan/Groan (1)", "Call Out/Crying (2)"], selection: $vocal)
            PainadRow(title: "Facial Expression", options: ["Smiling/None (0)", "Sad/Frown (1)", "Grimace (2)"], selection: $facial)
            PainadRow(title: "Body Language", options: ["Relaxed (0)", "Tense/Pacing (1)", "Rigid/Fists (2)"], selection: $bodyLang)
            PainadRow(title: "Consolability", options: ["No Need (0)", "Distractible (1)", "Unable to Console (2)"], selection: $console)
            
            Divider()
            
            HStack {
                Text("Total Score")
                Spacer()
                Text("\(breathing + vocal + facial + bodyLang + console)")
                    .font(.title2).bold()
            }
        }
        .padding()
        .background(ClinicalTheme.backgroundCard)
        .cornerRadius(12)
        .onChange(of: breathing) { _,_ in update() }
        .onChange(of: vocal) { _,_ in update() }
        .onChange(of: facial) { _,_ in update() }
        .onChange(of: bodyLang) { _,_ in update() }
        .onChange(of: console) { _,_ in update() }
    }
    
    func update() {
        score = Double(breathing + vocal + facial + bodyLang + console)
    }
}

struct PainadRow: View {
    let title: String
    let options: [String]
    @Binding var selection: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).bold().foregroundColor(ClinicalTheme.textSecondary)
            Picker(title, selection: $selection) {
                ForEach(0..<options.count, id: \.self) { idx in
                    Text(options[idx]).tag(idx)
                }
            }
            .pickerStyle(.menu)
             .padding(.vertical, 4)
             .background(ClinicalTheme.backgroundInput)
             .cornerRadius(8)
        }
    }
}
