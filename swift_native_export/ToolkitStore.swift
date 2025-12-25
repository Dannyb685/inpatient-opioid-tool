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
        case 0...4: return "Mild"
        case 5...12: return "Moderate"
        case 13...24: return "Moderately Severe"
        case 25...36: return "Severe"
        default: return "Severe (>36)"
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
}
