import Foundation
import Combine

// MARK: - Calculator Data Models
struct CalculatorInput: Identifiable {
    let id = UUID()
    let drugId: String // Custom ID (e.g., "morphine_iv")
    let name: String   // Display Name
    let drug: DrugData // Original Data
    var dose: String = ""
    let routeType: DrugRouteType
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

enum DrugRouteType {
    case standardPO
    case ivPush
    case ivDrip
    case patch      // "mcg/hr" (Red/Bold) - Butrans, Fentanyl Patch
    case microgramIO // "mcg" (Red/Bold) - Fentanyl IV/SL


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
    @Published var complianceWarning: String = "Standard / Reason for Rotation (25-40%). Routine rotation or standard safety margin (2025 Consensus)."
    
    init() {
        // Initialize with standard drug set for the calculator
        var newInputs: [CalculatorInput] = []
        
        for drug in ClinicalData.drugData {
            // 1. Standard (PO) Entry
            // Detect Type
            let isPatch = drug.id.contains("patch") || drug.id == "butrans"
            let isFent = drug.id == "fentanyl" || drug.id == "sufentanil" || drug.id == "alfentanil" || drug.id.contains("sublingual")
            
            var name = drug.name
            var type: DrugRouteType = .standardPO
            
            if isPatch {
                type = .patch
            } else if isFent {
                type = .microgramIO
            } else {
                // Standard PO
                name += " (PO)"
                type = .standardPO
            }
            
            newInputs.append(CalculatorInput(drugId: drug.id, name: name, drug: drug, routeType: type))
            
            // 2. Add Explicit IV Variants (Only for Morphine/Dilaudid currently)
            if drug.id == "morphine" {
                newInputs.append(CalculatorInput(drugId: "morphine_iv", name: "Morphine (IV)", drug: drug, routeType: .ivPush))
                newInputs.append(CalculatorInput(drugId: "morphine_iv_drip", name: "Morphine (IV Drip)", drug: drug, routeType: .ivDrip))
            }
            if drug.id == "hydromorphone" {
                newInputs.append(CalculatorInput(drugId: "hydromorphone_iv", name: "Hydromorphone (IV)", drug: drug, routeType: .ivPush))
                newInputs.append(CalculatorInput(drugId: "hydromorphone_iv_drip", name: "Hydromorphone (IV Drip)", drug: drug, routeType: .ivDrip))
            }
        }
        self.inputs = newInputs.sorted { $0.name < $1.name }
    }
    
    func updateDose(for inputId: UUID, dose: String) {
        if let index = inputs.firstIndex(where: { $0.id == inputId }) {
            inputs[index].dose = dose
            calculate()
        }
    }
    
    func calculate() {
        var totalMME: Double = 0
        var activeWarnings: [String] = [] // FIX: Use array to prevent overwriting
        
        var hasExclusion = false
        
        for input in inputs {
            guard let val = Double(input.dose), val > 0 else { continue }
            // MICROGRAM TRAP: Safety check for Unit Confusion
            // If user enters val < 10 for Fentanyl/Patch, they likely meant Milligrams (e.g. 0.1 mg) but entered it into a Microgram field.
            // 0.1 mcg is clinically irrelevant; 0.1 mg is a standard dose.
            if (input.routeType == .microgramIO || input.routeType == .patch) && val < 10 {
                activeWarnings.append("⚠️ Suspected Unit Error for \(input.name): Input is <10. Verify value is in MICROGRAMS (mcg), not mg.")
            }
            
            var factor = 0.0
            
            switch input.drugId {
            // Standard Factors
            case "morphine": factor = 1.0
            case "morphine_iv": factor = 3.0
            case "hydromorphone": factor = 4.0
            case "hydromorphone_iv": factor = 20.0
            case "oxycodone": factor = 1.5
            case "hydrocodone": factor = 1.0
            case "oxymorphone": factor = 3.0
            case "codeine": factor = 0.15
            case "tramadol": factor = 0.1
            case "tapentadol": factor = 0.4
            case "meperidine": factor = 0.1
                
            // DRIPS (mg/hr -> mg/24h -> MME)
            // Morphine IV Drip: rate * 24 * 3.0
            case "morphine_iv_drip": factor = 24.0 * 3.0
            // Dilaudid IV Drip: rate * 24 * 20.0
            case "hydromorphone_iv_drip": factor = 24.0 * 20.0
                
            // SAFETY: IV Fentanyl (Micrograms -> Milligrams -> MME)
            case "fentanyl", "sufentanil", "alfentanil": // Removed sublingual
                factor = 300.0 / 1000.0
                
            // FIX: Add Fentanyl Patch
            case "fentanyl_patch":
                factor = 2.4 // 25mcg/hr * 2.4 = 60 MME (Standard approximation)

            // SAFETY: Exclusions (Non-Linear / Complex Bioavailability)
            case "methadone":
                factor = 0
                hasExclusion = true
                activeWarnings.append("⚠️ Methadone Excluded: Non-linear kinetics.")
            case "sublingual_fentanyl":
                factor = 0
                hasExclusion = true
                activeWarnings.append("⚠️ Sublingual Fentanyl Excluded: Bioavailability varies.")
            case "buprenorphine", "butrans":
                factor = 0
                hasExclusion = true
                activeWarnings.append("⚠️ Buprenorphine Excluded: Partial agonist.")
                
            default: factor = 0
            }
            totalMME += val * factor
        }
        
        // Prevent "0 MME" safety illusion for excluded drugs
        if hasExclusion && totalMME == 0 {
            self.resultMME = "---"
        } else {
            self.resultMME = String(format: "%.0f", totalMME)
        }
        
        // Finalize Logic
        if totalMME > 90 {
            activeWarnings.append("⚠️ >90 MME: High Overdose Risk. Naloxone indicated.")
        }
        
        // FIX: Join warnings so none are lost
        self.warningText = activeWarnings.joined(separator: "\n")
        
        // 2. Reduction
        let reducedMME = totalMME * (1.0 - (reduction / 100.0))
        
        // Compliance Warning logic
        if reduction < 25 {
            complianceWarning = "Inadequate Analgesia (10-25%). Pain is uncontrolled. Lower reduction maintains higher potency."
        } else if reduction <= 40 {
            complianceWarning = "Standard / Reason for Rotation (25-40%). Routine rotation or standard safety margin (2025 Consensus)."
        } else {
            complianceWarning = "Severe Adverse Effects (>40%). Patient experiencing sedation/delirium. Requires significant dose reduction. Mandatory for elderly/frail."
        }
        
        if reducedMME <= 0 {
            targetDoses = []
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
        
        // Target: Fentanyl IV (Ratio 10:1 to Morphine IV)
        // MorIV (mg) * 10 = FentIV (mcg)
        // MME / 3.0 = MorIV. (MME/3)*10 = MME * 3.33
        let fentIV = reducedMME * 3.33
        targets.append(createTarget(drug: "Fentanyl", route: "IV", total: fentIV, ratio: "10mg Mor : 100mcg Fent", unit: "mcg"))
        
        // Target: Fentanyl Patch (Ratio 1.5:1 to Morphine IV)
        // MorIV (mg) * 1.5 = Patch (mcg/hr)
        // (MME / 3.0) * 1.5 = MME * 0.5
        let fentPatchRaw = reducedMME * 0.5
        
        // SAFETY ROUNDING: Round DOWN to nearest commercial patch size
        let patchSizes = [12, 25, 50, 75, 100]
        let safePatch = patchSizes.last(where: { Double($0) <= fentPatchRaw }) ?? 0
        
        // Construct label
        let patchLabel = safePatch > 0 ? "Rounded DOWN from \(Int(fentPatchRaw)) mcg/hr" : "Calculated \(Int(fentPatchRaw)) mcg/hr (Too low for patch)"
        let patchValue = safePatch > 0 ? "\(safePatch)" : "N/A"

        targets.append(TargetDose(
            drug: "Fentanyl",
            route: "Patch",
            totalDaily: patchValue,
            breakthrough: "N/A", // Patch BT is not standard, usually uses short acting
            unit: "mcg/hr",
            ratioLabel: patchLabel
        ))
        
        self.targetDoses = targets
    }
    
    private func createTarget(drug: String, route: String, total: Double, ratio: String) -> TargetDose {
        let bt = total * 0.10
        return TargetDose(
            drug: drug, route: route,
            totalDaily: String(format: "%.1f", total),
            breakthrough: String(format: "%.1f", bt),
            unit: unit, ratioLabel: ratio
        )
    }
    
    // Helper with default unit
    private func createTarget(drug: String, route: String, total: Double, ratio: String) -> TargetDose {
        return createTarget(drug: drug, route: route, total: total, ratio: ratio, unit: "mg")
    }
}
