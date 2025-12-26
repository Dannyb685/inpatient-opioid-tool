import Foundation
import Combine

// MARK: - Calculator Data Models
struct CalculatorInput: Identifiable {
    let id = UUID()
    let drug: DrugData
    var dose: String = ""
}

struct TargetDose: Identifiable {
    let id = UUID()
    let drug: String
    let route: String
    let totalDaily: String
    let breakthrough: String // ~10% of TDD
    let unit: String
    let ratioLabel: String
}

enum ToleranceStatus: String, CaseIterable, Identifiable {
    case naive = "Naive"
    case tolerant = "Tolerant"
    var id: String { self.rawValue }
}

enum ConversionContext: String, CaseIterable, Identifiable {
    case rotation = "Rotation"
    case routeSwitch = "Route Switch"
    var id: String { self.rawValue }
}

// MARK: - Store Implementation
class CalculatorStore: ObservableObject {
    @Published var inputs: [CalculatorInput] = []
    @Published var reduction: Double = 30.0
    @Published var tolerance: ToleranceStatus = .tolerant
    @Published var context: ConversionContext = .rotation
    
    // Outputs
    @Published var resultMME: String = "0"
    @Published var targetDoses: [TargetDose] = []
    @Published var warningText: String = ""
    
    init() {
        // Initialize with standard drug set for the calculator
        let commonIds = ["morphine", "hydromorphone", "oxycodone", "fentanyl"]
        self.inputs = ClinicalData.drugData
            .filter { commonIds.contains($0.id) }
            .map { CalculatorInput(drug: $0) }
    }
    
    func updateDose(for inputId: UUID, dose: String) {
        if let index = inputs.firstIndex(where: { $0.id == inputId }) {
            inputs[index].dose = dose
            calculate()
        }
    }
    
    func calculate() {
        var totalMME: Double = 0
        
        // 1. Calculate MME
        for input in inputs {
            guard let val = Double(input.dose), val > 0 else { continue }
            var factor = 0.0
            
            // Standard NCCN Factors
            switch input.drug.id {
            case "morphine": factor = 1.0 // Assuming PO input for calculator safety
            case "hydromorphone": factor = 4.0 
            case "oxycodone": factor = 1.5
            case "fentanyl": factor = 300.0 // 0.1mg IV Fent (100mcg) ~= 30mg PO Morph
            case "hydrocodone": factor = 1.0
            case "oxymorphone": factor = 3.0
            case "codeine": factor = 0.15
            case "tramadol": factor = 0.1
            default: factor = 0
            }
            totalMME += val * factor
        }
        
        self.resultMME = String(format: "%.0f", totalMME)
        
        // 2. Reduction
        let reducedMME = totalMME * (1.0 - (reduction / 100.0))
        
        if reducedMME <= 0 {
            targetDoses = []
            warningText = ""
            return
        }
        
        // 3. Targets
        var targets: [TargetDose] = []
        
        // Target: Oxycodone PO (1.5:1)
        let oxyDaily = reducedMME / 1.5
        targets.append(createTarget(drug: "Oxycodone", route: "PO", total: oxyDaily, ratio: "1.5 : 1"))
        
        // Target: Hydromorphone PO (4:1)
        let dilDaily = reducedMME / 4.0
        targets.append(createTarget(drug: "Hydromorphone", route: "PO", total: dilDaily, ratio: "4 : 1"))
        
        // Target: Morphine IV (3:1 vs PO)
        let morDaily = reducedMME / 3.0
        targets.append(createTarget(drug: "Morphine", route: "IV", total: morDaily, ratio: "IV Ratio 3:1"))
        
        self.targetDoses = targets
        
        if totalMME > 90 {
            warningText = "⚠️ >90 MME: High Overdose Risk. Naloxone indicated."
        } else {
            warningText = ""
        }
    }
    
    private func createTarget(drug: String, route: String, total: Double, ratio: String) -> TargetDose {
        let bt = total * 0.10
        return TargetDose(
            drug: drug, route: route,
            totalDaily: String(format: "%.1f", total),
            breakthrough: String(format: "%.1f", bt),
            unit: "mg", ratioLabel: ratio
        )
    }
}
