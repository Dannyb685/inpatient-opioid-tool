import SwiftUI
import Combine

// MARK: - Enums
enum ConsultPhase: Int, CaseIterable, Hashable {
    case screening = 1
    case diagnosis = 2
    case assessment = 3
    case action = 4
    case followUp = 5
}

enum ProtocolType {
    case standardBup       // Short acting, COWS ≥ 12
    case highDoseBup       // ER Setting, Macrodosing
    case microInduction    // (Bernese) Fentanyl or Low COWS/Urgent
    case fullAgonist       // Methadone/Oxy (Liver Failure, Acute Pain)
    case symptomManagement // COWS < 8, no immediate induction
}

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
    @Published var substanceType: String = "Short Acting" // "Fentanyl", "Methadone"
    @Published var erSetting: Bool = false
    @Published var isPregnant: Bool = false // CRITICAL: Changes drug to Monotherapy
    @Published var hasLiverFailure: Bool = false // Child-Pugh C
    @Published var hasAcutePain: Bool = false
    @Published var hasSedativeUse: Bool = false // Benzo/Alcohol
    
    // MARK: - Phase 4: Action Logic (The Brain)
    var recommendedProtocol: ProtocolType {
        var contraindications: [String] = []
        if hasLiverFailure { contraindications.append("Liver Failure") }
        if hasAcutePain { contraindications.append("Acute Pain") }
        
        let action = ClinicalData.OUDProtocolRules.determineProtocol(
            cowsScore: cowsScore,
            substance: substanceType,
            isER: erSetting,
            contraindications: contraindications
        )
        
        switch action {
        case .standardBup: return .standardBup
        case .highDoseBup: return .highDoseBup
        case .microInduction: return .microInduction
        case .fullAgonist: return .fullAgonist
        case .symptomManagement: return .symptomManagement
        }
    }
    
    var medicationName: String {
        return isPregnant ? "Buprenorphine (Subutex)" : "Buprenorphine/Naloxone (Suboxone)"
    }
    
    // MARK: - Phase 5: Discharge Logic
    var dischargeChecklist: [String] {
        var list = ["Referral to outpatient addiction medicine"]
        if recommendedProtocol != .fullAgonist {
            list.append("Prescribe \(medicationName) Bridge Script")
        }
        if dsmCount >= 6 || cowsScore > 12 || substanceType == "Fentanyl" {
            list.append("Prescribe Naloxone (Overdose Risk)")
        }
        return list
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
        substanceType = "Short Acting"
        erSetting = false
        isPregnant = false; hasLiverFailure = false; hasAcutePain = false; hasSedativeUse = false
    }
}
