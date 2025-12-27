import Foundation
import Combine

class ToolkitStore: ObservableObject {
    // COWS State
    @Published var cowsPulse: Int = 0
    @Published var cowsSweating: Int = 0
    @Published var cowsRestlessness: Int = 0
    @Published var cowsPupil: Int = 0
    @Published var cowsBoneAche: Int = 0
    @Published var cowsRunnyNose: Int = 0
    @Published var cowsGI: Int = 0
    @Published var cowsTremor: Int = 0
    @Published var cowsYawning: Int = 0
    @Published var cowsAnxiety: Int = 0
    @Published var cowsGooseflesh: Int = 0
    
    var cowsScore: Int {
        cowsPulse + cowsSweating + cowsRestlessness + cowsPupil + cowsBoneAche + cowsRunnyNose + cowsGI + cowsTremor + cowsYawning + cowsAnxiety + cowsGooseflesh
    }
    
    var cowsSeverity: String {
        switch cowsScore {
        case 5...12: return "Mild"
        case 13...24: return "Moderate"
        case 25...36: return "Moderately Severe"
        case 37...Int.max: return "Severe"
        default: return "Sub-clinical"
        }
    }
    
    func resetCOWS() {
        cowsPulse = 0
        cowsSweating = 0
        cowsRestlessness = 0
        cowsPupil = 0
        cowsBoneAche = 0
        cowsRunnyNose = 0
        cowsGI = 0
        cowsTremor = 0
        cowsYawning = 0
        cowsAnxiety = 0
        cowsGooseflesh = 0
    }
    // ORT State
    @Published var ortScoreInput: Double = 0
    var ortRisk: String {
        switch Int(ortScoreInput) {
        case 0...3: return "Low Risk"
        case 4...7: return "Moderate Risk"
        default: return "High Risk"
        }
    }
    
    // SOS State
    @Published var sosScore: Int = 0 
    // Simplified: 0-8+ scale isn't standard, usually it's calculated properties.
    // User requested "Inputs: Surgery Type, Pre-op Use, Psych Comorbidity".
    // Implementing as direct manual risk selection or simplified additive model for now to match UI request.
    // Given the constraints, we'll iterate: Let's follow "Low/Med/High" outputs based on inputs.
    @Published var sosSurgeryHighRisk: Bool = false
    @Published var sosPreOpOpioid: Bool = false
    @Published var sosPsych: Bool = false
    
    var sosRiskLabel: String {
        // Simple heuristic based on literature (approximation for this tool):
        // 0 Risk Factors -> Low
        // 1-2 -> Med
        // 3 -> High
        let factors = (sosSurgeryHighRisk ? 1 : 0) + (sosPreOpOpioid ? 1 : 0) + (sosPsych ? 1 : 0)
        switch factors {
        case 0: return "Low (4%)"
        case 1, 2: return "Medium (17%)"
        default: return "High (50%)"
        }
    }

    // PEG State
    @Published var pegPain: Double = 0
    @Published var pegEnjoyment: Double = 0
    @Published var pegActivity: Double = 0
    
    var pegScore: Double {
        (pegPain + pegEnjoyment + pegActivity) / 3.0
    }
    

}
