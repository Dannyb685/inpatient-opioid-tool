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

struct CalculatorInput: Identifiable {
    let id = UUID()
    var drug: OpioidOption
    var dose: String
}

struct OpioidOption: Hashable, Identifiable {
    let id: String
    let name: String
    let mmeFactor: Double // Factor to convert TO Oral Morphine MME
    
    static let all: [OpioidOption] = [
        OpioidOption(id: "morphine_iv", name: "Morphine IV", mmeFactor: 3.0),
        OpioidOption(id: "morphine_po", name: "Morphine PO", mmeFactor: 1.0),
        OpioidOption(id: "oxycodone_po", name: "Oxycodone PO", mmeFactor: 1.5),
        OpioidOption(id: "hydrocodone_po", name: "Hydrocodone PO", mmeFactor: 1.0),
        OpioidOption(id: "hydromorphone_iv", name: "Hydromorphone IV", mmeFactor: 20.0), // 1.5mg IV = 30 MME -> 30/1.5 = 20
        OpioidOption(id: "hydromorphone_po", name: "Hydromorphone PO", mmeFactor: 4.0), // 7.5mg PO = 30 MME -> 30/7.5 = 4
        OpioidOption(id: "fentanyl_iv", name: "Fentanyl IV (mcg)", mmeFactor: 0.3), // 100mcg = 30 MME -> 30/100 = 0.3
        OpioidOption(id: "codeine_po", name: "Codeine PO", mmeFactor: 0.15), // 200mg = 30 MME -> 30/200 = 0.15
        OpioidOption(id: "tramadol_po", name: "Tramadol PO", mmeFactor: 0.1) // 300mg = 30 MME -> 30/300 = 0.1
    ]
}

class CalculatorStore: ObservableObject {
    // Initialize with ALL options for the static list view
    @Published var inputs: [CalculatorInput] = OpioidOption.all.map { CalculatorInput(drug: $0, dose: "") } {
        didSet { calculateTargets() }
    }
    
    @Published var reduction: Double = 30 { didSet { calculateTargets() } }
    @Published var tolerance: ToleranceStatus = .naive { didSet { calculateTargets() } }
    @Published var context: ConversionContext = .rotation { didSet { calculateTargets() } }
    
    @Published var targetDoses: [TargetDose] = []
    
    // Computed property for real-time MME calc (Pinned Header)
    var resultMME: String {
        let total = calculateTotalMME()
        return String(format: "%.1f", total)
    }
    
    private func calculateTotalMME() -> Double {
        return inputs.reduce(0) { sum, input in
            guard let dose = Double(input.dose) else { return sum }
            return sum + (dose * input.drug.mmeFactor)
        }
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
    
    // Direct binding updates
    func updateDose(for inputID: UUID, dose: String) {
        if let index = inputs.firstIndex(where: { $0.id == inputID }) {
            inputs[index].dose = dose
        }
    }
    
    func calculateTargets() {
        let totalMME = calculateTotalMME()
        
        guard totalMME > 0 else {
            targetDoses = []
            return
        }
        
        var doses: [TargetDose] = []
        
        // 1. Determine Reduction Factor
        var reductionFactor = reduction / 100.0
        if context == .routeSwitch && tolerance == .tolerant {
            reductionFactor = 0.0 // No reduction for same-drug chronic switch
        }
        
        let targetMME = totalMME * (1.0 - reductionFactor)
        
        // Helper to create dose from Target MME
        func addDose(drug: String, route: String, mmeInverseFactor: Double, unit: String, ratio: String) {
            // Target Dose = Target MME / MME Factor
            // Here we use the stored factors effectively.
            // Morphine IV Factor is 3.0 (IV -> MME). So MME -> IV is / 3.0.
            
            let dailyDose = targetMME / mmeInverseFactor
            let breakthrough = dailyDose * 0.10 // 10% for BT
            
            doses.append(TargetDose(
                drug: drug,
                route: route,
                totalDaily: String(format: "%.1f", dailyDose),
                breakthrough: String(format: "%.1f", breakthrough),
                unit: unit,
                ratioLabel: ratio,
                type: "safe"
            ))
        }
        
        // 2. Logic Parity
        // Hydromorphone IV (Factor 20.0). MME / 20.
        addDose(drug: "Hydromorphone", route: "IV", mmeInverseFactor: 20.0, unit: "mg", ratio: "Ratio 1:6.7 (vs MS IV)")
        
        // Fentanyl IV (Factor 0.3). MME / 0.3.
        addDose(drug: "Fentanyl", route: "IV", mmeInverseFactor: 0.3, unit: "mcg", ratio: "Ratio 1:100 (vs MS IV)")
        
        // Oxycodone PO (Factor 1.5). MME / 1.5.
        addDose(drug: "Oxycodone", route: "PO", mmeInverseFactor: 1.5, unit: "mg", ratio: "OME Ratio 1:1.5")
        
        // Hydromorphone PO (Factor 4.0). MME / 4.0.
        addDose(drug: "Hydromorphone", route: "PO", mmeInverseFactor: 4.0, unit: "mg", ratio: "OME Ratio 1:4")
        
        self.targetDoses = doses
    }
}
