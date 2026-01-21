import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Calculator Data Models
struct CalculatorInput: Identifiable {
    let id = UUID()
    let drugId: String // Custom ID (e.g., "morphine_iv")
    let name: String   // Display Name
    let drug: DrugData // Original Data
    var dose: String = ""
    var isVisible: Bool = false // Dynamic Visibility
    let routeType: DrugRouteType
    var warningMessage: String? = nil // Inline Warning (v1.6)
    var activeFactor: ConversionFactor? // Glass Box Evidence
}

struct TargetDose: Identifiable {
    let id = UUID()
    let drug: String
    let route: String
    let totalDaily: String
    let breakthrough: String // ~10% of TDD
    let unit: String
    let ratioLabel: String
    let factor: Double // Glass Box transparency
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
// MARK: - Adjuvant Models
// Moved to OUDDataModels.swift


// MARK: - Store Implementation
class CalculatorStore: ObservableObject {
    @Published var inputs: [CalculatorInput] = []
    @Published var reduction: Double = 30.0 { didSet { calculate() } }
    @Published var tolerance: ToleranceStatus = .tolerant
    @Published var context: ConversionContext = .rotation
    
    // Sandbox Tracking
    @Published var isSandboxMode: Bool = false
    private var isSeeding: Bool = false // Flag to prevent dirty state during sync
    
    // Stewardship Inputs
    @Published var giStatus: GIStatus = .intact { didSet { calculate() } }
    @Published var renalStatus: RenalStatus = .normal { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var hepaticStatus: HepaticStatus = .normal { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }

    @Published var painType: PainType = .nociceptive { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var isPregnant: Bool = false { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var isBreastfeeding: Bool = false { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var age: String = "" { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var matchesBenzos: Bool = false { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var sleepApnea: Bool = false { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var historyOverdose: Bool = false { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var analgesicProfile: AnalgesicProfile = .naive { // Synced
        didSet {
            if !isSeeding { isSandboxMode = true }
            // Auto-update tolerance based on profile
            switch analgesicProfile {
            case .naive: self.tolerance = .naive
            default: self.tolerance = .tolerant
            }
            calculate()
        }
    }
    
    // MARK: - Transactional Injection (Protocol Based)
    func seed(from data: CalculatorInputs) {
        // Prevent manual triggers from marking dirty
        isSeeding = true
        defer { isSeeding = false }
        
        // Reset Sandbox Mode (Clean State)
        self.isSandboxMode = false
        
        self.renalStatus = data.renalFunction
        self.hepaticStatus = data.hepaticFunction
        self.painType = data.painType
        self.isPregnant = data.isPregnant
        self.isBreastfeeding = data.isBreastfeeding
        self.age = data.age
        self.matchesBenzos = data.benzos
        self.sleepApnea = data.sleepApnea
        self.historyOverdose = data.historyOverdose
        self.analgesicProfile = data.analgesicProfile
        
        // Auto-Calculation happens via duplicate property didSet observers
    }
    
    // Target Preference Context (v1.6)
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
        // UX: Allow single digit typing ("1" -> "18") without triggering lock.
        // Assumes users are not calculating MME for <10 year olds (Tool scope is Adult).
        // If they enter "05", it will lock.
        return (Int(age) ?? 30) < 18 && age.count > 1
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
            var name = drug.name
            var type: DrugRouteType = .standardPO
            
            // 1. Detect Type based on ID/Suffix
            if drug.id.contains("patch") || drug.id == "butrans" {
                type = .patch
            } else if drug.id.contains("_iv") || drug.id.contains("intravenous") {
                type = .ivPush
            } else if drug.id == "fentanyl" || drug.id == "sufentanil" || drug.id == "alfentanil" || drug.id.contains("sublingual") {
                type = .microgramIO
            } else {
                // Standard PO
                if !name.contains("(PO)") { name += " (PO)" }
                type = .standardPO
            }
            
            newInputs.append(CalculatorInput(drugId: drug.id, name: name, drug: drug, routeType: type))
            
            // 2. Variants Injection
            
            // Morphine Drip (Auto-inject for IV)
            if drug.id == "morphine_iv" {
                newInputs.append(CalculatorInput(drugId: "morphine_iv_drip", name: "Morphine (IV Drip)", drug: drug, routeType: .ivDrip))
            }
            
            // Legacy Manual Variants (Hydromorphone, Fentanyl, Others not yet split)
            if drug.id == "hydromorphone" {
                newInputs.append(CalculatorInput(drugId: "hydromorphone_iv", name: "Hydromorphone (IV)", drug: drug, routeType: .ivPush))
                newInputs.append(CalculatorInput(drugId: "hydromorphone_iv_drip", name: "Hydromorphone (IV Drip)", drug: drug, routeType: .ivDrip))
            }
            if drug.id == "oxymorphone" {
                newInputs.append(CalculatorInput(drugId: "oxymorphone_iv", name: "Oxymorphone (IV)", drug: drug, routeType: .ivPush))
            }
            if drug.id == "meperidine" {
                newInputs.append(CalculatorInput(drugId: "meperidine_iv", name: "Meperidine (IV)", drug: drug, routeType: .ivPush))
            }
            if drug.id == "methadone" {
                newInputs.append(CalculatorInput(drugId: "methadone_iv", name: "Methadone (IV)", drug: drug, routeType: .ivPush))
            }
            if drug.id == "fentanyl" {
                newInputs.append(CalculatorInput(drugId: "fentanyl_drip", name: "Fentanyl (IV Drip)", drug: drug, routeType: .ivDrip))
                newInputs.append(CalculatorInput(drugId: "fentanyl_patch", name: "Fentanyl Patch", drug: drug, routeType: .patch))
            }
        }
        
        // VISIBILITY DEFAULTS: Show only common drugs initially
        let defaults = ["oxycodone", "morphine_iv", "hydromorphone_iv", "morphine_po_ir"]
        for i in 0..<newInputs.count {
            if defaults.contains(newInputs[i].drugId) {
                newInputs[i].isVisible = true
            }
        }
        
        self.inputs = newInputs.sorted { $0.name < $1.name }
    }
    
    // Dirty State Helper
    var hasActiveDrugs: Bool {
        return inputs.contains { $0.isVisible && !$0.dose.isEmpty && (Double($0.dose) ?? 0) > 0 }
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
            inputs[index].warningMessage = nil // Clear warning on edit
            calculate()
        }
    }
    
    func calculate() {
        // SAFETY GATE: Pediatric Hard Stop
        if isPediatric {
            resultMME = "---"
            targetDoses = []
            warningText = "Pediatric Dosing Not Validated. Please use weight-based formulary."
            return
        }
        
        // 1. Working Storage (Avoid multiple @Published updates)
        var localInputs = inputs
        var localCalculationReceipt: [String] = []
        var localWarningText = ""
        var localActiveWarnings: [String] = []
        var localResultMME = "0"
        var localTargetDoses: [TargetDose] = []
        var localComplianceWarning = "Standard / Reason for Rotation (25-40%). Routine rotation or standard safety margin (2025 Consensus)."
        
        var totalMME: Double = 0
        var shouldBlockTargets = false
        var hasExclusion = false
        
        // PROFILE WARNINGS
        switch analgesicProfile {
        case .highPotency:
             localActiveWarnings.append("• Note: Tolerance Unpredictable. Lipophilic storage prevents accurate MME calculation. Titrate by effect.")
        case .buprenorphine:
             localActiveWarnings.append("BUPRENORPHINE BLOCKADE: High-affinity binding may block full agonists.")
        case .methadone:
             localActiveWarnings.append("NOTE: Baseline Methadone creates complex cross-tolerance.")
        case .naltrexone:
             localActiveWarnings.append("OPIOID BLOCKADE (NALTREXONE): Agonists ineffective/Dangerous. Consult Expert.")
             shouldBlockTargets = true
        default: break
        }
        
        if isPregnant {
             localActiveWarnings.append("PREGNANCY ALERT: Neonatology Consult Required. Risk of Neonatal Abstinence Syndrome.")
        }
        
        // METHADONE CHECK
        if localInputs.contains(where: { $0.drugId == "methadone" && $0.isVisible }) {
             localActiveWarnings.append("METHADONE DETECTED: Standard MME calculation may not apply.")
             localActiveWarnings.append("Use dedicated Methadone Conversion Tool for switching TO methadone.")
        }
        
        for (idx, input) in localInputs.enumerated() {
            // Skip hidden or empty
            guard input.isVisible, let val = Double(input.dose), val > 0 else {
                // Clear state for silent items
                localInputs[idx].warningMessage = nil
                continue
            }
            
            print("DEBUG: Calculating for \(input.name) (ID: \(input.drugId)). Dose: \(val)")
            
            // Clear previous warning
            localInputs[idx].warningMessage = nil
            
            // ... (Checks omitted for brevity in replace, keeping existing code structure is hard with replace_file_content for just inserting logs scattered. I will replace the loop or block)
            // Actually, best to just insert the logs at key points.
            
            // MICROGRAM TRAP: Safety check for Unit Confusion
            if (input.drugId == "sufentanil" || input.drugId == "alfentanil") && val < 1.0 {
                 localInputs[idx].warningMessage = "CRITICAL: Doses <1mcg detected. Verify vs decimal error."
            } else if (input.routeType == .microgramIO || input.routeType == .patch) && val < 10 {
                localInputs[idx].warningMessage = "Suspected Unit Error: Input <10. Verify MICROGRAMS (mcg), not mg."
            }
            
            // EXTREME DOSE VERIFICATION
            if input.drugId == "hydromorphone_iv" && val > 4.0 {
                localInputs[idx].warningMessage = "Unusually high single dose (>4mg). Verify."
            } else if input.drugId == "morphine_iv" && val > 20.0 {
                localInputs[idx].warningMessage = "Unusually high single dose (>20mg). Verify."
            } else if input.drugId == "fentanyl" && val > 200.0 {
                localInputs[idx].warningMessage = "Unusually high single dose (>200mcg). Verify."
            } else if input.drugId == "oxycodone" && val > 120.0 {
                localInputs[idx].warningMessage = "Unusually high single dose (>120mg). Verify."
            } else if input.drugId == "oxymorphone_iv" && val > 1.5 {
                localInputs[idx].warningMessage = "CRITICAL: 1.5mg IV = ~45mg MME. Verify High Potency."
            } else if input.drugId == "meperidine_iv" && val > 100.0 {
                localInputs[idx].warningMessage = "High Dose (>100mg) increases Seizure Risk."
            }
            
            var factor = 0.0
            var lookupRoute = "po"
            if input.routeType == .ivPush { lookupRoute = "iv" }
            if input.name.contains("IV Drip") { lookupRoute = "iv_continuous" }
            if input.routeType == .patch { lookupRoute = "transdermal" }
            
            if input.drugId == "fentanyl" && input.routeType == .microgramIO { lookupRoute = "iv_acute" }
            if input.drugId == "morphine_iv" { lookupRoute = "iv" }
            if input.drugId == "hydromorphone_iv" { lookupRoute = "iv" }
            if input.drugId == "methadone_iv" { lookupRoute = "iv" }
            if input.drugId == "sufentanil" || input.drugId == "alfentanil" { lookupRoute = "iv" }
            
            // ID Cleaning Logic (Refactored for Split Formulations)
            var cleanId = input.drugId.replacingOccurrences(of: "_drip", with: "")
            
            // For Split Formulations (Morphine), keep the full ID (e.g. morphine_iv).
            // For Legacy (Hydro, etc.), strip the suffix to find the master entry.
            if !cleanId.starts(with: "morphine_") {
                 cleanId = cleanId.replacingOccurrences(of: "_iv", with: "").replacingOccurrences(of: "_patch", with: "")
            }
            
            print("DEBUG: Lookup Factor -> Drug: \(cleanId), Route: \(lookupRoute)")
            
            if let evidence = ConversionService.shared.getFactor(drugId: cleanId, route: lookupRoute) {
                factor = evidence.factor
                print("DEBUG: Factor Found: \(factor)")
                
                localInputs[idx].activeFactor = evidence
                
                if let warns = evidence.warnings {
                    localActiveWarnings.append(contentsOf: warns.map { "\(input.name): \($0)" })
                }
                
                if input.drugId.contains("morphine") && renalStatus == .dialysis {
                        localActiveWarnings.append("AVOID MORPHINE: Active metabolites (M3G/M6G) accumulate in dialysis. Neurotoxicity risk.")
                }
                if input.drugId.contains("hydromorphone") && hepaticStatus == .failure {
                        localActiveWarnings.append("HEPATIC SHUNT: Bioavailability increases ~4x. Use extreme caution.")
                }
                if input.drugId == "methadone" && (isPregnant || isBreastfeeding) {
                        factor = 0
                        hasExclusion = true
                        localActiveWarnings.append("Methadone Blocked in Perinatal Mode (Pregnancy/Lactation). Specialist Consult Required.")
                }
                if input.routeType == .ivDrip && input.drugId.contains("fentanyl") {
                    if localActiveWarnings.isEmpty { localActiveWarnings.append("Using Continuous Infusion Factor (0.12). For acute/bolus, use IV Push (0.3).") }
                }
            } else {
                 print("DEBUG: Factor Lookup Failed (Returned nil)")
                 switch input.drugId {
                    case "sublingual_fentanyl":
                        factor = 0; hasExclusion = true; localActiveWarnings.append("Sublingual Fentanyl Excluded: Bioavailability varies.")
                    case "buprenorphine", "butrans":
                        factor = 0; hasExclusion = true; localActiveWarnings.append("Buprenorphine Excluded: Partial agonist.")
                    default:
                        factor = 0
                        if !localActiveWarnings.contains(where: { $0.contains("Lookup Failed") }) {
                            localActiveWarnings.append("Data Error: Factor not found for \(cleanId) \(lookupRoute)")
                        }
                }
            }
            
            let itemMME = val * factor
            print("DEBUG: Item MME: \(itemMME)")
            totalMME += itemMME
            
            
            // FIX: Handle Excluded items (Factor 0) from DB, like Buprenorphine or Fentanyl Transdermal in Naive
            if factor == 0 && !hasExclusion {
                hasExclusion = true
                // Ensure there's a visible reason if possible
                if localActiveWarnings.isEmpty {
                     if let warns = input.activeFactor?.warnings, !warns.isEmpty {
                         // already appended
                     } else {
                         localActiveWarnings.append("Excluded from MME Calculation (Factor 0).")
                     }
                }
            }

            if factor > 0 {
                let unit = (input.routeType == .patch) ? "mcg/hr" : ((input.routeType == .microgramIO) ? "mcg" : "mg")
                let line = "\(val) \(unit) \(input.name) × \(String(format: "%.2f", factor)) = \(String(format: "%.1f", itemMME)) MME"
                localCalculationReceipt.append(line)
            } else if hasExclusion {
                localCalculationReceipt.append("\(val) \(input.name): EXCLUDED (See Warnings)")
            }
        }
        
        print("DEBUG: Total MME: \(totalMME)")
        
        if hasExclusion && totalMME == 0 {
            localResultMME = "---"
        } else {
            localResultMME = String(format: "%.1f", totalMME)
        }
        
        if totalMME > 90 {
            localActiveWarnings.append(">90 MME: High Overdose Risk. Naloxone indicated.")
        }
        if totalMME > 50 || matchesBenzos || historyOverdose || sleepApnea {
            localActiveWarnings.append("RECOMMENDATION: Prescribe Naloxone (High Overdose Risk per CDC criteria).")
        }
        
        if totalMME > 50 {
            localActiveWarnings.append("Caution (>50 MME/day): Risk of harm increases without additional analgesic benefit. Consider taper or specialist review.")
        }
        
        if isPregnant { localActiveWarnings.append("PERINATAL CONTEXT: Patient is Pregnant. NSAIDs contraindicated (3rd Tri). Prefer Tylenol/Prednisone.") }
        if isBreastfeeding { localActiveWarnings.append("LACTATION CONTEXT: Monitor infant for sedation and respiratory distress.") }
        
        localWarningText = localActiveWarnings.joined(separator: "\n")
        
        if !shouldBlockTargets && totalMME > 0 {
            let reducedMME = totalMME * (1.0 - (reduction / 100.0))
            let ageInt = Int(age) ?? 0
            
            if reduction < 25 {
                localComplianceWarning = "Aggressive Rotation (<25%). Valid for Poorly Controlled Pain, but carries high risk of toxicity due to incomplete cross-tolerance. Monitor closely."
            } else if reduction <= 50 {
                var recommendation = "Standard Rotation (25-50%)."
                if totalMME >= 90 || ageInt >= 65 {
                    recommendation += " **Guideline Tip:** Lean towards 50% for High Dose/Elderly/Frail patients."
                } else {
                    recommendation += " **Guideline Tip:** Lean towards 25% for switching route (same drug) or healthy patients."
                }
                localComplianceWarning = recommendation
            } else {
                localComplianceWarning = "Conservative Rotation (>50%). Recommended for Frail/Elderly or patients with Significant Adverse Effects."
            }
            
                if reducedMME > 0 {
                var targets: [TargetDose] = []
                var ageMultiplier = 1.0
                var ageWarning = ""
                
                if ageInt >= 80 {
                    ageMultiplier = 0.50
                    ageWarning = " (Geriatric Safety: -50%)"
                } else if ageInt >= 60 {
                    ageMultiplier = 0.75
                    ageWarning = " (Geriatric Safety: -25%)"
                }
                
                // Fetch Dynamic Factors (Single Source of Truth)
                let oxyFactor = (ConversionService.shared.getFactor(drugId: "oxycodone", route: "po")?.factor) ?? 1.5
                let hydroFactor = (ConversionService.shared.getFactor(drugId: "hydromorphone", route: "po")?.factor) ?? 4.0
                let morIVFactor = (ConversionService.shared.getFactor(drugId: "morphine_iv", route: "iv")?.factor) ?? 3.0
                let hydIVFactor = (ConversionService.shared.getFactor(drugId: "hydromorphone", route: "iv")?.factor) ?? 20.0 
                let fentIVFactor = (ConversionService.shared.getFactor(drugId: "fentanyl", route: "iv_acute")?.factor) ?? 0.3 // Use Acute for Targets
                
                // Targets
                let oxyStandard = reducedMME / oxyFactor
                targets.append(createTarget(drug: "Oxycodone", route: "PO", routeType: .standardPO, total: oxyStandard * ageMultiplier, ratio: "\(oxyFactor):1" + ageWarning, unit: "mg", factor: oxyFactor, originalTotal: (ageMultiplier < 1.0 ? oxyStandard : nil)))
                
                let dilStandard = reducedMME / hydroFactor
                targets.append(createTarget(drug: "Hydromorphone", route: "PO", routeType: .standardPO, total: dilStandard * ageMultiplier, ratio: "\(hydroFactor):1" + ageWarning, unit: "mg", factor: hydroFactor, originalTotal: (ageMultiplier < 1.0 ? dilStandard : nil)))
                
                let morStandard = reducedMME / morIVFactor
                targets.append(createTarget(drug: "Morphine", route: "IV", routeType: .ivPush, total: morStandard * ageMultiplier, ratio: "IV Ratio \(morIVFactor):1" + ageWarning, unit: "mg", factor: morIVFactor, originalTotal: (ageMultiplier < 1.0 ? morStandard : nil)))
                
                let hydIVStandard = reducedMME / hydIVFactor
                targets.append(createTarget(drug: "Hydromorphone", route: "IV", routeType: .ivPush, total: hydIVStandard * ageMultiplier, ratio: "IV Ratio \(hydIVFactor):1" + ageWarning, unit: "mg", factor: hydIVFactor, originalTotal: (ageMultiplier < 1.0 ? hydIVStandard : nil)))
                
                // Fentanyl (Special Logic for Micrograms)
                // 1 MME = (1/Factor) mcg. Fentanyl Factor 0.3 means 100mcg = 30 MME. Correct math: Target = MME / Factor.
                // Note: Fentanyl typically stored as mg-eq in DB? No, Factor 0.3 is "0.3 MME per 1 mcg"? 
                // Let's check Logic: 100mcg Fent = 30 MME (Factor 0.3). 30 / 0.3 = 100. Correct.
                // Wait, typically factor is "MME per 1 Unit". If unit is mcg, factor 0.3.
                let fentStandard = reducedMME / fentIVFactor
                targets.append(createTarget(drug: "Fentanyl", route: "IV Push (Acute)", routeType: .microgramIO, total: fentStandard * ageMultiplier, ratio: "10mg Mor : 100mcg Fent \(ageWarning)", unit: "mcg", factor: fentIVFactor, originalTotal: (ageMultiplier < 1.0 ? fentStandard : nil)))
                
                // CRITICAL FIX: Use reducedMME for Patch to respect safety slider (was totalMME)
                let fentPatchRaw = reducedMME * 0.5 * ageMultiplier
                let patchSizes = [12, 25, 50, 75, 100]
                let safePatch = patchSizes.last(where: { Double($0) <= fentPatchRaw }) ?? 0
                let patchLabel = safePatch > 0 ? "Rounded DOWN from \(Int(fentPatchRaw)) mcg/hr" : "Calculated \(Int(fentPatchRaw)) mcg/hr (Too low for patch)"
                targets.append(TargetDose(drug: "Fentanyl", route: "Patch", totalDaily: safePatch > 0 ? "\(safePatch)" : "N/A", breakthrough: "N/A", unit: "mcg/hr", ratioLabel: patchLabel, factor: 2.0, originalDaily: nil))
                
                // Stewardship Sorting
                if giStatus == .intact {
                    targets.sort { t1, t2 in (routePreference == .iv) ? (t1.route == "IV") : (t1.route == "PO") }
                } else {
                    targets.sort { t1, t2 in t1.route == "IV" }
                }
                localTargetDoses = targets
                
                // SINGLE OUTPUT SAFEGUARD (v7.2.3)
                if localTargetDoses.count == 1 {
                     let safeguardMsg = "SINGLE TARGET GENERATED: Lack of rotation options. Specialist Consult Recommended."
                     // Append to warning text if not already present (optimization)
                     if localWarningText.isEmpty {
                         localWarningText = safeguardMsg
                     } else {
                         localWarningText += "\n" + safeguardMsg
                     }
                }
            }
        }
        
        // 4. Batch Atomic Update (Triggers UI once)
        self.inputs = localInputs
        self.calculationReceipt = localCalculationReceipt
        self.resultMME = localResultMME
        self.warningText = localWarningText
        self.complianceWarning = localComplianceWarning
        self.targetDoses = localTargetDoses
        
        // Log Safety (Only if active)
        if !localInputs.isEmpty && totalMME > 0 {
            SafetyLogger.shared.log(.calculationPerformed(
                inputCount: localInputs.count,
                hasWarnings: !localActiveWarnings.isEmpty,
                warningDetails: localActiveWarnings
            ))
        }
    }
    

    
    private func createTarget(drug: String, route: String, routeType: DrugRouteType, total: Double, ratio: String, unit: String = "mg", factor: Double, originalTotal: Double? = nil) -> TargetDose {
        var adjustedTotal = total
        var adjustmentNote = ratio
        var originalTotalString: String? = nil
        
        // 1. Renal Adjustment: Hydromorphone
        if drug.contains("Hydromorphone") && renalStatus != .normal {
            // Dialysis/Severe: 0.5 (50% reduction) - Relaxed from 0.25 based on clinical feedback
            // Mild/Mod: No auto-reduction (Alert Only)
            
            if renalStatus == .dialysis {
                let reductionFactor: Double = 0.5
                originalTotalString = total.toClinicalString(route: routeType, unit: unit)
                adjustedTotal = total * reductionFactor
                adjustmentNote = "\(ratio) | Renal Failure: -50%"
            } else {
                // Mild/Mod
                adjustmentNote = "\(ratio) | Renal Caution: Start Low (Metabolite Risk)"
            }
        }
        
        // 2. Renal Adjustment: Morphine
        else if drug.contains("Morphine") && renalStatus != .normal {
            if renalStatus == .dialysis {
                // Hard Avoidance
                adjustmentNote = "CONTRAINDICATED (Neurotoxic Metabolites per FDA/CDC)"
                adjustedTotal = 0
                return TargetDose(
                    drug: drug, route: route,
                    totalDaily: "AVOID",
                    breakthrough: "N/A",
                    unit: unit, ratioLabel: adjustmentNote,
                    factor: factor,
                    originalDaily: total.toClinicalString(route: routeType, unit: unit)
                )
            } else {
                // Impaired (Mild/Mod): Warn but don't force reduction (Alert Specificity)
                adjustmentNote = "\(ratio) | Renal Caution: Consider -25% (Metabolite Accumulation)"
            }
        }
        
        // 2b. Renal Adjustment: Oxycodone
        else if drug.contains("Oxycodone") && renalStatus != .normal {
            // Reduction not as aggressive as Morphine, but still needed for safety
            let reductionFactor: Double = 0.75 // 25% reduction
            originalTotalString = total.toClinicalString(route: routeType, unit: unit)
            adjustedTotal = total * reductionFactor
            adjustmentNote = "\(ratio) | Renal Caution: -25% (Metabolite Accumulation)"
        }
        
        // 3. Hepatic Adjustment: Hydromorphone PO (Failure only)
        if drug.contains("Hydromorphone") && route.contains("PO") && hepaticStatus == .failure {
             // User Request: Replace math with Specialist Consult
             return TargetDose(
                drug: drug, route: route,
                totalDaily: "CONSULT",
                breakthrough: "N/A",
                unit: unit, 
                ratioLabel: "\(ratio) | CONTRAINDICATED (High First-Pass Shunting Risk)",
                factor: factor,
                originalDaily: String(format: "%.1f", total)
             )
        }

        // 4. Hepatic Failure: General Reduction (Oxycodone, Morphine, Hydromorphone IV)
        if hepaticStatus == .failure && !drug.contains("Fentanyl") {
             let reductionFactor: Double = 0.50
             if originalTotalString == nil { originalTotalString = String(format: "%.1f", adjustedTotal) }
             adjustedTotal = adjustedTotal * reductionFactor
             adjustmentNote += " | Hepatic Failure: -50% (Impaired Clearance/Half-Life)"
        }

        // 5. Format Final String
        let finalString = adjustedTotal.toClinicalString(route: routeType, unit: unit)
        
        // 6. Breakthrough Calculation (10% of Total)
        let btDose = adjustedTotal * 0.1
        let btString = (adjustedTotal == 0 && adjustmentNote.contains("CONTRAINDICATED")) ? "N/A" : btDose.toClinicalString(route: routeType, unit: unit)

        if let orig = originalTotal {
            // Calculate what the daily allocation WOULD have been
            // Just for display. 
            // We use the same qFrequency logic? 
            // Actually, best to just show "Daily: X mg" -> "Daily: Y mg"
            
            // To fit in UI, we might just pass string.
            // But TargetDose has 'originalDaily' as String?
            
            // Let's perform smart rounding on original
            let origRounded = orig.toClinicalString(route: routeType, unit: unit)
            originalTotalString = origRounded
        }
        
        return TargetDose(
            drug: drug,
            route: route,
            totalDaily: finalString,
            breakthrough: btString,
            unit: unit,
            ratioLabel: adjustmentNote,
            factor: factor,
            originalDaily: originalTotalString
        )
    }
    
    
    // MARK: - Clipboard & Export
    
    func copyToClipboard() {
        var log = ""
        log += "--- OPIOID CONVERSION WORKSHEET ---\n"
        log += "Date: \(Date().formatted())\n"
        log += "Patient Age: \(age)\n"
        log += "Clinical Context: \(tolerance == .naive ? "Opioid Naive" : "Tolerant") | \(renalStatus == .normal ? "Renal Function Normal" : "Renal Impairment") | \(hepaticStatus == .normal ? "Hepatic Function Normal" : "Hepatic Failure")\n"
        
        log += "\n[INPUTS]\n"
        for input in inputs where input.isVisible && !input.dose.isEmpty {
            // CalculatorInput does not share .unit directly. It wraps DrugData.
            let unitLabel = (input.routeType == .patch) ? "mcg/hr" : ((input.routeType == .microgramIO) ? "mcg" : "mg")
            log += "- \(input.drugId): \(input.dose) \(unitLabel)\n"
        }
        log += "Total 24h MME: \(Int(Double(resultMME) ?? 0))\n"
        
        log += "\n[ESTIMATED TARGETS]\n"
        for target in targetDoses {
            log += "- \(target.drug) (\(target.route)): \(target.totalDaily) \(target.unit)/day"
            if target.breakthrough != "N/A" {
                log += " + \(target.breakthrough) \(target.unit) PRN"
            }
            log += "\n"
        }
        
        if !warningText.isEmpty {
            log += "\n[WARNINGS]\n"
            log += warningText + "\n"
        }
        
        log += "\n--- ASSERTION OF JUDGMENT ---\n"
        log += "I, the treating clinician, certify that I have independently reviewed these results against the patient's specific clinical context. I acknowledge that this tool provides educational estimates only and does not substitute for my professional medical judgment.\n"
        
        log += "\nValues generated by PrecisionAnalgesia (v7.2.4). Not a medical record until verified."
        
        #if canImport(UIKit)
        UIPasteboard.general.string = log
        #endif
    }

    // MARK: - External Interaction Helpers
    
    /// Used by InfusionView and OUD Tool to inject doses into the sandbox
    func activeInputsAdd(drugId: String, dose: String) {
        // 1. Precise Match (Priority)
        if let index = inputs.firstIndex(where: { $0.drugId == drugId }) {
            inputs[index].dose = dose
            inputs[index].isVisible = true
            calculate()
            return
        }
        
        // 2. Fallback: Fuzzy Name Match (e.g., "morphine" matches "morphine (PO)")
        if let index = inputs.firstIndex(where: { $0.drugId.lowercased().contains(drugId.lowercased()) }) {
            inputs[index].dose = dose
            inputs[index].isVisible = true
            calculate()
        }
    }
    
    func reset() {
        for i in 0..<inputs.count {
            inputs[i].dose = ""
            inputs[i].isVisible = false
            inputs[i].warningMessage = nil
        }
        isSandboxMode = false
        calculate()
    }
    
    /// Syncs context flags from external views (Infusion/OUD) back to the main store
    func syncContext(isNaive: Bool, hasOSA: Bool, renalImpaired: Bool, hepaticFailure: Bool = false) {
        self.tolerance = isNaive ? .naive : .tolerant
        self.sleepApnea = hasOSA
        self.renalStatus = renalImpaired ? .impaired : .normal
        if hepaticFailure { self.hepaticStatus = .failure }
        calculate()
    }
}
