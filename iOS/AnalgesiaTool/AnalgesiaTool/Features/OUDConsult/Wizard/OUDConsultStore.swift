import Combine
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

struct COWSItem: Identifiable {
    let id: Int
    let title: String
    let options: [(Int, String)]
}

// MARK: - Enums
enum ConsultPhase: Int, CaseIterable, Hashable {
    case screening = 1
    case diagnosis = 2
    case assessment = 3
    case action = 4
    case followUp = 5
}

// ProtocolType moved to SubstanceLogic.swift

@MainActor
class OUDConsultStore: ObservableObject {
    
    // MARK: - Navigation State
    @Published var path = NavigationPath()
    @Published var currentPhase: ConsultPhase = .screening
    
    // MARK: - Phase 1: Screening
    @Published var nidaScreenPositive: Bool = false
    @Published var dastScore: Int = 0
    
    // MARK: - Phase 2: Diagnosis (DSM-5)
    @Published var selectedDSMCriteria: Set<Int> = []
    @Published var isMedicallySupervised: Bool = false
    
    var dsmCount: Int {
        if isMedicallySupervised {
            // Exclude Tolerance (10) & Withdrawal (11) if supervised (DSM-5 specifier)
            return selectedDSMCriteria.filter { $0 != 10 && $0 != 11 }.count
        }
        return selectedDSMCriteria.count
    }
    
    var severityClassification: (String, Color) {
        switch dsmCount {
        case 0...1: return ("No Diagnosis", .gray)
        case 2...3: return ("Mild OUD", .yellow)
        case 4...5: return ("Moderate OUD", .orange)
        case 6...11: return ("Severe OUD", .red)
        default: return ("Indeterminate", .gray)
        }
    }
    
    // MARK: - Phase 3: Assessment (COWS & Risk)
    // Key: Item ID (1-11), Value: Selected Score
    @Published var cowsSelections: [Int: Int] = [:] 
    
    var cowsScore: Int { cowsSelections.values.reduce(0, +) }
    
    var withdrawalSeverity: String {
        switch cowsScore {
        case 0...4: return "None/Minimal"
        case 5...12: return "Mild"
        case 13...24: return "Moderate"
        case 25...36: return "Mod. Severe"
        default: return "Severe"
        }
    }
    
    // Risk Factors
    @Published var entries: [SubstanceEntry] = []
    @Published var physiology: PhysiologyProfile?
    @Published var generatedPlan: ClinicalPlan?
    
    // Legacy / Ported Properties (Still used for initial seeding)
    @Published var hasLiverFailure: Bool = false 
    @Published var hasRenalFailure: Bool = false 
    @Published var hasRenalImpairment: Bool = false 
    @Published var hasAcutePain: Bool = false
    @Published var hasSedativeUse: Bool = false 
    @Published var isPregnant: Bool = false
    @Published var isBreastfeeding: Bool = false
    @Published var erSetting: Bool = false
    @Published var hasUlcers: Bool = false // Xylazine risk marker
    @Published var substanceType: SubstanceType = .oxycodone // Legacy support
    
    // Computed Wrappers for UI Binding if needed, or we migrate UI to use entries.
    // For now, let's keep the flags but use the new engine for protocol generation.
    
    // MARK: - Phase 4: Action Logic (The Brain)
    func generateClinicalPlan() {
        // 1. Construct Entries from Legacy Toggles if empty (Migration/Fallback)
        if entries.isEmpty {
            // This ensures backward compatibility with the toggles we just ported
            // Default to Oxycodone if nothing specified
            // Default to Oxycodone if nothing specified
            
            // If Fentanyl Toggle was implied by context
            // actually substanceType property is removed, so we rely on entries.
            // Let's rely on the View to populate entries.
        }
        
        // 2. Assess Physiology
        self.physiology = OUDCalculator.assess(
            entries: entries, 
            hasUlcers: hasUlcers, 
            isPregnant: isPregnant,
            isBreastfeeding: isBreastfeeding,
            hasLiverFailure: hasLiverFailure,
            hasAcutePain: hasAcutePain
        )
        
        if let phys = physiology {
            self.generatedPlan = ProtocolGenerator.generate(profile: phys, cows: cowsScore, isERSetting: erSetting)
        }
    }
    
    // Legacy Adapter for View Binding (Read-Only basically)
    var recommendedProtocolName: String {
        return generatedPlan?.protocolName ?? "Pending"
    }

    var recommendedProtocol: ProtocolType? {
        return generatedPlan?.type
    }
    
    var medicationName: String {
        if recommendedProtocol == .fullAgonist {
            return hasLiverFailure ? "Short-acting Opioids (Oxycodone)" : "Methadone (Full Agonist)"
        }
        // Standard of care is Combo product (Suboxone), even in pregnancy (latest guidelines)
        return "Buprenorphine/Naloxone (Suboxone)"
    }
    
    // MARK: - Phase 5: Discharge Logic
    var dischargeChecklist: [String] {
        var list = ["Referral to outpatient addiction medicine"]
        if self.recommendedProtocol != ProtocolType.fullAgonist {
            list.append("Prescribe \(medicationName) Bridge Script")
        }
        if dsmCount >= 6 || cowsScore > 12 || entries.contains(where: { $0.type == .streetFentanylPowder || $0.type == .pressedPills }) {
            list.append("Prescribe Naloxone (Overdose Risk)")
        }
        if isBreastfeeding {
            list.append("Lactation: Monitor infant for sedation/poor feeding if using MOUD.")
        }
        return list
    }
    
    // MARK: - COWS Metadata
    let cowsItems: [COWSItem] = [
        .init(id: 1, title: "Resting Pulse", options: [(0,"<80"), (1,"80-100"), (2,"100-120"), (4,">120")]),
        .init(id: 2, title: "Sweating", options: [(0,"None"), (1,"Chills"), (2,"Flushed"), (3,"Beads"), (4,"Stream")]),
        .init(id: 3, title: "Restlessness", options: [(0,"None"), (1,"Hard to sit"), (3,"Shift"), (5,"Can't sit")]),
        .init(id: 4, title: "Pupil Size", options: [(0,"Normal"), (1,"Large"), (2,"Dilated"), (5,"Rim only")]),
        .init(id: 5, title: "Bone/Joint Aches", options: [(0,"None"), (1,"Mild"), (2,"Severe"), (4,"Rubbing")]),
        .init(id: 6, title: "Runny Nose", options: [(0,"None"), (1,"Moist"), (2,"Running"), (4,"Stream")]),
        .init(id: 7, title: "GI Upset", options: [(0,"None"), (1,"Cramps"), (2,"Nausea"), (3,"Vomit"), (5,"Multi-Epis")]),
        .init(id: 8, title: "Tremor", options: [(0,"None"), (1,"Felt"), (2,"Slight"), (4,"Gross")]),
        .init(id: 9, title: "Yawning", options: [(0,"None"), (1,"1-2x"), (2,"3+ times"), (4,"Freq/Min")]),
        .init(id: 10, title: "Anxiety", options: [(0,"None"), (1,"Reported"), (2,"Obvious"), (4,"Difficult")]),
        .init(id: 11, title: "Gooseflesh", options: [(0,"Smooth"), (3,"Felt"), (5,"Prominent")])
    ]

    func copyCOWSAssessment() {
        // 1. Ensure latest logic is applied for adjuvants
        generateClinicalPlan()
        
        // 2. Build Symptom Narrative
        let scoredItems = cowsItems.filter { (cowsSelections[$0.id] ?? 0) > 0 }
        let symptomList = scoredItems.map { item in
            let score = cowsSelections[item.id] ?? 0
            let desc = item.options.first(where: { $0.0 == score })?.1.lowercased() ?? ""
            return "\(item.title.lowercased()) (\(desc))"
        }.joined(separator: ", ")
        
        // 3. Adjuvants Narrative
        var adjunctsText = ""
        if let plan = generatedPlan, !plan.adjunctMeds.isEmpty {
            adjunctsText = plan.adjunctMeds.map { "- \($0)" }.joined(separator: "\n")
        } else {
            // High-fidelity fallback for OUD supportive care
            adjunctsText = "- Zofran 4mg q6h PRN Nausea\n- Clonidine 0.1mg q6h PRN Anxiety/HTN (Hold if SBP < 90)\n- Acetaminophen 1g q8h PRN Aches\n- Methocarbamol 750mg q8h PRN Spasms"
        }
        
        // 4. Construct Note
        let text = """
        CLINICAL OPIATE WITHDRAWAL ASSESSMENT
        COWS Score: \(cowsScore) (\(withdrawalSeverity)).
        Clinical Findings: Patient scoring for \(symptomList.isEmpty ? "no physical symptoms" : symptomList).
        
        Recommended Supportive Care (Adjuvants):
        \(adjunctsText)
        
        Assessment Date: \(Date().formatted(date: .abbreviated, time: .shortened))
        Note generated via OP Precision Analgesia Tool.

        DISCLAIMER: This calculation is for informational purposes. Individual patient physiology varies. Clinical decisions should be individualized. (Lifeline Medical Technologies)
        """
        
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
    
    // MARK: - Actions
    func reset() {
        path = NavigationPath()
        currentPhase = .screening
        selectedDSMCriteria = []
        cowsSelections = [:]
        dastScore = 0
        nidaScreenPositive = false
        // Reset toggles
        entries = []
        physiology = nil
        generatedPlan = nil
        erSetting = false
        isPregnant = false; isBreastfeeding = false; hasLiverFailure = false; hasRenalFailure = false; hasRenalImpairment = false; hasAcutePain = false; hasSedativeUse = false
    }
    
    // MARK: - Context Porting
    func seed(from assessment: AssessmentStore) {
        // Only port if we are in a clean state (Screening Phase) or if explicit overwrite is desired (we'll assume clean for now to be safe)
        // Actually, user wants it to port. Let's do a smart seed.
        
        // 1. Pregnancy
        if assessment.isPregnant && !self.isPregnant {
            self.isPregnant = true
        }
        
        // 1b. Breastfeeding
        if assessment.isBreastfeeding && !self.isBreastfeeding {
            self.isBreastfeeding = true
        }
        
        // 2. Hepatic Failure
        if assessment.hepaticFunction == .failure && !self.hasLiverFailure {
            self.hasLiverFailure = true
        }
        
        // 3. Renal Status
        if assessment.renalFunction == .dialysis {
            self.hasRenalFailure = true
        } else if assessment.renalFunction == .impaired {
            self.hasRenalImpairment = true
        }
        
        // 4. Benzo Use (Sedative)
        if assessment.benzos && !self.hasSedativeUse {
            self.hasSedativeUse = true
        }
    }
}
