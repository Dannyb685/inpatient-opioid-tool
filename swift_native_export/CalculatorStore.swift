import UIKit // For Haptics
import Combine

// MARK: - Calculator Data Models
struct CalculatorInput: Identifiable {
    let id = UUID()
    let drugId: String // Custom ID (e.g., "morphine_iv")
    let name: String   // Display Name
    let drug: DrugData // Original Data
    var dose: String = ""
    var isVisible: Bool = false // Dynamic Visibility
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
    var originalDaily: String? // for showing strikethrough of unadjusted dose
}

enum DrugRouteType {
    case standardPO
    case ivPush
    case ivDrip
    case patch      // "mcg/hr" (Red/Bold) - Butrans, Fentanyl Patch
    case microgramIO // "mcg" (Red/Bold) - Fentanyl IV/SL
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

// MARK: - Adjuvant Models
struct AdjuvantRecommendation: Identifiable {
    let id = UUID()
    let category: String
    let drug: String
    let dose: String
    let rationale: String
}

// MARK: - Store Implementation
class CalculatorStore: ObservableObject {
    @Published var inputs: [CalculatorInput] = []
    @Published var reduction: Double = 30.0
    @Published var tolerance: ToleranceStatus = .tolerant
    @Published var context: ConversionContext = .rotation
    
    // Stewardship Inputs
    @Published var giStatus: GIStatus = .intact { didSet { calculate() } }
    @Published var renalStatus: RenalStatus = .normal { didSet { calculate() } }
    @Published var hepaticStatus: HepaticStatus = .normal { didSet { calculate() } }

    @Published var painType: PainType = .nociceptive { didSet { calculate() } }
    @Published var isPregnant: Bool = false { didSet { calculate() } }
    @Published var age: Int = 30 { didSet { calculate() } }
    @Published var matchesBenzos: Bool = false { didSet { calculate() } } // Synced from Risk
    @Published var sleepApnea: Bool = false { didSet { calculate() } } // Synced
    @Published var historyOverdose: Bool = false { didSet { calculate() } } // Synced
    
    // Quick Mode Helpers (v1.5.5)
    @Published var routePreference: OpioidRoute = .po { didSet { calculate() } }
    
    var isRenalImpaired: Bool {
        get { renalStatus != .normal }
        set { renalStatus = newValue ? .impaired : .normal }
    }
    
    var isHepaticImpaired: Bool {
        get { hepaticStatus != .normal }
        set { hepaticStatus = newValue ? .impaired : .normal }
    }
    
    var isPediatric: Bool {
        return age < 18
    }
    
    // Outputs
    @Published var resultMME: String = "0"
    @Published var targetDoses: [TargetDose] = []
    @Published var warningText: String = ""
    @Published var calculationReceipt: [String] = []
    
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
        
        // VISIBILITY DEFAULTS: Show only common drugs initially
        let defaults = ["oxycodone", "morphine_iv", "hydromorphone_iv", "morphine"]
        for i in 0..<newInputs.count {
            if defaults.contains(newInputs[i].drugId) {
                newInputs[i].isVisible = true
            }
        }
        
        self.inputs = newInputs.sorted { $0.name < $1.name }
    }
    
    // Helpers for Taper Handoff
    var primaryDrugName: String {
        return inputs.first(where: { $0.isVisible && !$0.dose.isEmpty && Double($0.dose) ?? 0 > 0 })?.name.replacingOccurrences(of: " (PO)", with: "") ?? ""
    }
    
    var totalDailyMME: String {
        return resultMME
    }
    
    // MARK: - Visibility Helpers
    
    func addInput(inputId: UUID) {
        if let index = inputs.firstIndex(where: { $0.id == inputId }) {
            inputs[index].isVisible = true
        }
    }
    
    func removeInput(inputId: UUID) {
        if let index = inputs.firstIndex(where: { $0.id == inputId }) {
            inputs[index].isVisible = false
            inputs[index].dose = "" // Clear dose when hidden
            calculate()
        }
    }
    
    func updateDose(for inputId: UUID, dose: String) {
        if let index = inputs.firstIndex(where: { $0.id == inputId }) {
            inputs[index].dose = dose
            calculate()
        }
    }
    
    func calculate() {
        var totalMME: Double = 0
        var activeWarnings: [String] = []
        calculationReceipt = [] // Clear previous receipt
        
        // PEDIATRIC LOCK: Logic handled by View, but ensure safe defaults if called
        if isPediatric {
            resultMME = "---"
            warningText = "Pediatric Dosing Required"
            return
        }
        
        var hasExclusion = false
        

        
        for input in inputs {
            guard let val = Double(input.dose), val > 0 else { continue }
            
            // MICROGRAM TRAP: Safety check for Unit Confusion
            if (input.routeType == .microgramIO || input.routeType == .patch) && val < 10 {
                activeWarnings.append("⚠️ Suspected Unit Error for \(input.name): Input is <10. Verify value is in MICROGRAMS (mcg), not mg.")
            }
            
            var factor = 0.0
            
            switch input.drugId {
            // Standard Factors
            case "morphine":
                factor = 1.0
                if renalStatus == .dialysis {
                    activeWarnings.append("⚠️ AVOID MORPHINE: Active metabolites (M3G/M6G) accumulate in dialysis. Neurotoxicity risk.")
                }
            case "morphine_iv": 
                factor = 3.0
                activeWarnings.append("NOTE: IV:PO Morphine 3:1 is standard for chronic dosing. Acute ratio may range to 1:6.")
                if renalStatus == .dialysis {
                    activeWarnings.append("⚠️ AVOID MORPHINE IV: Active metabolites (M3G/M6G) accumulate in dialysis. Neurotoxicity risk.")
                }
            case "hydromorphone": 
                factor = 5.0
                activeWarnings.append("NOTE: Hydromorphone conversion varies (3.7-5:1). Monitor closely.")
                if hepaticStatus == .failure {
                    activeWarnings.append("⚠️ HEPATIC SHUNT: Oral Hydromorphone bioavailability increases ~4x in Liver Failure (Portosystemic shunts). MME calculation may SIGNIFICANTLY underestimate risk. Use extreme caution.")
                }
            case "hydromorphone_iv": factor = 20.0
            case "oxycodone": factor = 1.5
            case "hydrocodone": factor = 1.0
            case "oxymorphone": factor = 3.0
            case "codeine": 
                factor = 0.15
                if renalStatus == .dialysis {
                    activeWarnings.append("⚠️ AVOID CODEINE: Metabolites accumulate in dialysis.")
                }
            case "tramadol": 
                factor = 0.2 // Updated CDC 2022
                if activeWarnings.isEmpty { activeWarnings.append("NOTE: Tramadol factor updated to 0.2 per CDC 2022.") }
            case "tapentadol": factor = 0.4
            case "meperidine": 
                factor = 0.1
                if renalStatus == .dialysis {
                    activeWarnings.append("⚠️ AVOID MEPERIDINE: Normeperidine accumulates. Seizure risk. Contraindicated.")
                }
                
            // DRIPS (mg/hr -> mg/24h -> MME)
            case "morphine_iv_drip": factor = 24.0 * 3.0
            case "hydromorphone_iv_drip": factor = 24.0 * 20.0
                
            // SAFETY: IV Fentanyl (Micrograms -> Milligrams -> MME)
            case "fentanyl", "sufentanil", "alfentanil":
                factor = 300.0 / 1000.0 // 100mcg = 30MME -> 1mcg = 0.3MME
                
            case "fentanyl_patch":
                factor = 2.4 // 25mcg/hr * 2.4 = 60 MME

            // SAFETY: Exclusions
            case "methadone":
                // PERINATAL LOCK: Even if recommended, Math is BLOCKED in pregnancy
                if isPregnant {
                     factor = 0
                     hasExclusion = true
                     activeWarnings.append("⚠️ Methadone Calculation Blocked in Perinatal Mode (CYP Induction). Consult Specialist.")
                } else {
                     factor = 0
                     hasExclusion = true
                     activeWarnings.append("⚠️ Methadone Excluded: Non-linear kinetics.")
                }
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
            
            let itemMME = val * factor
            totalMME += itemMME
            
            // Add to Receipt
            if factor > 0 {
                let unit = (input.routeType == .patch) ? "mcg/hr" : ((input.routeType == .microgramIO) ? "mcg" : "mg")
                let line = "\(val) \(unit) \(input.name) × \(String(format: "%.2f", factor)) = \(String(format: "%.1f", itemMME)) MME"
                calculationReceipt.append(line)
            } else if hasExclusion {
                // Document exclusions in math too
                calculationReceipt.append("\(val) \(input.name): EXCLUDED (See Warnings)")
            }
        }
        
        // Prevent "0 MME" safety illusion for excluded drugs
        if hasExclusion && totalMME == 0 {
            self.resultMME = "---"
        } else {
            // TRANSPARENCY FIX: Use 1 decimal place to match receipt sum
            self.resultMME = String(format: "%.1f", totalMME)
        }
        
        // Finalize Warnings
        // Finalize Warnings
        if totalMME > 90 {
            activeWarnings.append("⚠️ >90 MME: High Overdose Risk. Naloxone indicated.")
        }
        
        if totalMME > 50 || matchesBenzos || historyOverdose || sleepApnea {
            activeWarnings.append("📋 RECOMMENDATION: Prescribe Naloxone (High Overdose Risk per CDC criteria).")
        }
        
        self.warningText = activeWarnings.joined(separator: "\n")
        
        // 2. Reduction
        let reducedMME = totalMME * (1.0 - (reduction / 100.0))
        
        // Compliance Warning logic
        if reduction < 25 {
            complianceWarning = "Aggressive Rotation (<25%). High risk of toxicity/overdose due to incomplete cross-tolerance. Only use if pain is severe and unmanaged."
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
        
        // Target: Hydromorphone PO (5:1) - Updated Audit
        let dilDaily = reducedMME / 5.0
        targets.append(createTarget(drug: "Hydromorphone", route: "PO", total: dilDaily, ratio: "5 : 1"))
        
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
        
        // 4. SMART SORTING (Stewardship 101: Gut works? Use it.)
        if giStatus == .intact {
            // Priority: PO -> IV
            targets.sort { t1, t2 in
                if t1.route == "PO" && t2.route == "IV" { return true }
                if t1.route == "IV" && t2.route == "PO" { return false }
                return false // Keep original order
            }
        } else if giStatus == .tube {
            // Priority: PO Liquid -> IV
            // Action: Convert "PO" -> "PO Liquid" to indicate safety for tube/dysphagia
            targets = targets.map { t in
                if t.route == "PO" {
                    return TargetDose(
                        drug: t.drug,
                        route: "PO Liquid",
                        totalDaily: t.totalDaily,
                        breakthrough: t.breakthrough,
                        unit: t.unit,
                        ratioLabel: t.ratioLabel
                    )
                }
                return t
            }
            
            targets.sort { t1, t2 in
                let isLiquid1 = t1.route.contains("Liquid")
                let isLiquid2 = t2.route.contains("Liquid")
                
                // Liquid (PO) > IV
                if isLiquid1 && t2.route == "IV" { return true }
                if t1.route == "IV" && isLiquid2 { return false }
                return false
            }
        } else {
            // Priority: IV -> PO (NPO / Dysphagia / GI Failure)
            targets.sort { t1, t2 in
                if t1.route == "IV" && t2.route.contains("PO") { return true }
                if t1.route.contains("PO") && t2.route == "IV" { return false }
                return false
            }
        }
        
        self.targetDoses = targets
    }
    
    func getAdjuvants() -> [AdjuvantRecommendation] {
        var list: [AdjuvantRecommendation] = []
        
        // 1. REMOVED Universal Bowel Regimen per "Overrepresented" feedback.
        // It remains a standard of care but doesn't need to clog the calculator results.
        
        // 2. PAIN TYPE SPECIFIC
        switch painType {
        case .neuropathic:
            // Check Renal for Gabapentin
            if renalStatus == .normal {
                list.append(AdjuvantRecommendation(
                    category: "First Line Neuropathic",
                    drug: "Gabapentin",
                    dose: "300mg PO QD -> TID",
                    rationale: "Target Calcium channels. Reduce opioid requirement."
                ))
            } else {
                 list.append(AdjuvantRecommendation(
                    category: "First Line Neuropathic",
                    drug: "Gabapentin",
                    dose: "100mg PO QD (Renal Dose)",
                    rationale: "Accumulates in CKD. Start low."
                ))
            }
        case .bone, .inflammatory:
            // Check Renal/GI for NSAIDs
            if renalStatus == .normal && giStatus == .intact && hepaticStatus != .failure {
                list.append(AdjuvantRecommendation(
                    category: "Bone/Inflammation",
                    drug: "Naproxen",
                    dose: "500mg PO BID",
                    rationale: "Opioids poor for bone pain. Add NSAID."
                ))
            }
            // Logic change: Do not show "Avoid NSAIDs". If contraindicated, simply don't suggest it.
            
        case .nociceptive:
            // Tylenol
            if hepaticStatus == .normal {
                list.append(AdjuvantRecommendation(
                    category: "Multimodal Sparing",
                    drug: "Acetaminophen",
                    dose: "650mg PO q6h",
                    rationale: "Reduces opioid consumption by 20%."
                ))
            } else if hepaticStatus != .failure {
                list.append(AdjuvantRecommendation(
                    category: "Multimodal Sparing",
                    drug: "Acetaminophen",
                    dose: "Max 2g/day",
                    rationale: "Caution in mild impairment."
                ))
            }
        }
        
        return list
    }
    
    private func createTarget(drug: String, route: String, total: Double, ratio: String, unit: String) -> TargetDose {
        var adjustedTotal = total
        var adjustmentNote = ratio
        var originalTotalString: String? = nil
        
        // 1. Renal Adjustment: Hydromorphone
        if drug.contains("Hydromorphone") && renalStatus != .normal {
            // Dialysis: 0.25 (75% reduction) | Impaired: 0.5 (50% reduction)
            let reductionFactor: Double = (renalStatus == .dialysis) ? 0.25 : 0.5
            
            // Store original before modifying
            originalTotalString = String(format: "%.1f", total)
            
            adjustedTotal = total * reductionFactor
            let percentage = Int((1.0 - reductionFactor) * 100)
            adjustmentNote = "\(ratio) | ⚠️ Renal: -\(percentage)% (FDA)"
        }
        
        // 2. Renal Adjustment: Morphine

        else if drug.contains("Morphine") && renalStatus != .normal {
            if renalStatus == .dialysis {
                // Hard Avoidance
                adjustmentNote = "⚠️ CONTRAINDICATED (Neurotoxic Metabolites)"
                adjustedTotal = 0 // Will result in 0.0 displayed but handled by View logic ideally, or just text warning
                return TargetDose(
                    drug: drug, route: route,
                    totalDaily: "AVOID",
                    breakthrough: "N/A",
                    unit: unit, ratioLabel: adjustmentNote,
                    originalDaily: String(format: "%.1f", total)
                )
            } else {
                 // Impaired: 0.75 (25% reduction)
                let reductionFactor: Double = 0.75
                originalTotalString = String(format: "%.1f", total)
                adjustedTotal = total * reductionFactor
                adjustmentNote = "\(ratio) | ⚠️ Renal: -25% (Metabolites)"
            }
        }
        
        // 3. Hepatic Adjustment: Hydromorphone PO (Failure only)
        if drug.contains("Hydromorphone") && route.contains("PO") && hepaticStatus == .failure {
             // User Request: Replace math with Specialist Consult
             return TargetDose(
                drug: drug, route: route,
                totalDaily: "CONSULT",
                breakthrough: "N/A",
                unit: unit, 
                ratioLabel: "\(ratio) | ⚠️ CONTRAINDICATED (Hepatic Shunting Risk)",
                originalDaily: String(format: "%.1f", total)
             )
        }

        let bt = adjustedTotal * 0.10
        
        return TargetDose(
            drug: drug, route: route,
            totalDaily: String(format: "%.1f", adjustedTotal),
            breakthrough: String(format: "%.1f", bt),
            unit: unit, ratioLabel: adjustmentNote,
            originalDaily: originalTotalString
        )
    }
    
    // Helper with default unit
    private func createTarget(drug: String, route: String, total: Double, ratio: String) -> TargetDose {
        return createTarget(drug: drug, route: route, total: total, ratio: ratio, unit: "mg")
    }
}
