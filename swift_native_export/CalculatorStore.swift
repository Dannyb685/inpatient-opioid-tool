import Foundation
import Combine

enum ToleranceStatus: String, CaseIterable, Identifiable {
    case naive = "Opioid Naive"
    case tolerant = "Opioid Tolerant" // e.g., >60mg MME/day for 7 days
    var id: String { self.rawValue }
}

enum ConversionContext: String, CaseIterable, Identifiable {
    case rotation = "Opioid Rotation" // Switching drugs
    case routeSwitch = "Route Change Only" // Same drug, new route (e.g. IV -> PO)
    var id: String { self.rawValue }
}

struct TargetDose: Identifiable {
    let id = UUID()
    let drug: String
    let route: String
    let totalDaily: String
    let breakthrough: String
    let unit: String
    let ratioLabel: String
    let type: String // "safe", "caution"
}

class CalculatorStore: ObservableObject {
    @Published var morphineIV: String = "" { didSet { calculateTargets() } }
    @Published var reduction: Double = 30 { didSet { calculateTargets() } }
    @Published var tolerance: ToleranceStatus = .naive { didSet { calculateTargets() } }
    @Published var context: ConversionContext = .rotation { didSet { calculateTargets() } }
    
    @Published var targetDoses: [TargetDose] = []
    
    // Computed property for real-time MME calc (Pinned Header)
    var resultMME: String {
        guard let input = Double(morphineIV) else { return "0" }
        // Base MME is 3x Morphine IV
        return String(format: "%.1f", input * 3.0)
    }
    
    var warningText: String {
        if context == .routeSwitch && tolerance == .tolerant {
            return "Note: No cross-tolerance reduction applied for active chronic therapy (same drug)."
        }
        if tolerance == .naive {
             return "Warning: Opioid Naive. Recommended start: 50% of calculated dose."
        }
        return "Standard Cross-Tolerance Reduction Applied."
    }
    
    func calculateTargets() {
        guard let input = Double(morphineIV) else {
            targetDoses = []
            return
        }
        
        var doses: [TargetDose] = []
        
        // 1. Determine Reduction Factor
        var reductionFactor = reduction / 100.0
        if context == .routeSwitch && tolerance == .tolerant {
            reductionFactor = 0.0 // No reduction for same-drug chronic switch
        }
        
        // Helper to create dose
        func addDose(drug: String, route: String, factor: Double, unit: String, ratio: String) {
            let rawConverted = input * factor
            let reducedTotal = rawConverted * (1.0 - reductionFactor)
            let breakthrough = reducedTotal * 0.10 // 10% for BT
            
            doses.append(TargetDose(
                drug: drug,
                route: route,
                totalDaily: String(format: "%.1f", reducedTotal),
                breakthrough: String(format: "%.1f", breakthrough),
                unit: unit,
                ratioLabel: ratio,
                type: "safe"
            ))
        }
        
        // 2. Logic Parity with React
        // Hydromorphone IV (Factor 0.15, Ratio 1:6.7)
        addDose(drug: "Hydromorphone", route: "IV", factor: 0.15, unit: "mg", ratio: "Ratio 1:6.7")
        
        // Fentanyl IV (Factor 10, Ratio 1:100mcg)
        // React uses factor 10 for Morphine mg -> Fentanyl mcg
        addDose(drug: "Fentanyl", route: "IV", factor: 10.0, unit: "mcg", ratio: "Ratio 1:100")
        
        // Oxycodone PO (Factor 2.0, Ratio 1:1.5)
        // 10mg IV MS = 30mg PO MS = 20mg PO Oxy. (30 / 1.5 = 20). So factor is 2.0.
        addDose(drug: "Oxycodone", route: "PO", factor: 2.0, unit: "mg", ratio: "OME Ratio 1:1.5")
        
        // Hydromorphone PO (Factor 0.75, Ratio 1:4)
        // 10mg IV MS = 30mg PO MS = 7.5mg PO Hydro. (30 / 4 = 7.5). So factor is 0.75.
        addDose(drug: "Hydromorphone", route: "PO", factor: 0.75, unit: "mg", ratio: "OME Ratio 1:4")
        
        self.targetDoses = doses
    }
}
