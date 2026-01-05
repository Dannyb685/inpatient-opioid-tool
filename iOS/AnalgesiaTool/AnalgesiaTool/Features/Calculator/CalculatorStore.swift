import Foundation
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
    var warningMessage: String? = nil // Inline Warning (v1.6)
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
    @Published var age: String = "" { 
        didSet { 
            if !isSeeding { isSandboxMode = true }
            calculate() 
        } 
    }
    @Published var matchesBenzos: Bool = false { didSet { calculate() } } // Synced from Risk
    @Published var sleepApnea: Bool = false { didSet { calculate() } } // Synced
    @Published var historyOverdose: Bool = false { didSet { calculate() } } // Synced
    @Published var analgesicProfile: AnalgesicProfile = .naive { // Synced
        didSet {
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
        self.age = data.age
        self.matchesBenzos = data.benzos
        self.sleepApnea = data.sleepApnea
        self.historyOverdose = data.historyOverdose
        self.analgesicProfile = data.analgesicProfile
        
        // Auto-Calculation happens via duplicate property didSet observers
    }
    
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
        
        var totalMME: Double = 0
        var activeWarnings: [String] = []
        var shouldBlockTargets = false
        calculationReceipt = [] // Clear previous receipt
        
        // PEDIATRIC LOCK: Logic handled by View, but ensure safe defaults if called
        if isPediatric {
            resultMME = "---"
            warningText = "Pediatric Dosing Required"
            return
        }
        
        // PROFILE WARNINGS
        switch analgesicProfile {
        case .highPotency:
             activeWarnings.append("• Note: Tolerance Unpredictable. Lipophilic storage prevents accurate MME calculation. Titrate by effect.")
        case .buprenorphine:
             activeWarnings.append("⚠️ BUPRENORPHINE BLOCKADE: High-affinity binding may block full agonists.")
        case .methadone:
             activeWarnings.append("NOTE: Baseline Methadone creates complex cross-tolerance.")
        case .naltrexone:
             activeWarnings.append("⛔️ OPIOID BLOCKADE (NALTREXONE): Agonists ineffective/Dangerous. Consult Expert.")
             shouldBlockTargets = true
        default: break
        }
        
        if isPregnant {
             activeWarnings.append("⚠️ PREGNANCY ALERT: Neonatology Consult Required. Risk of Neonatal Abstinence Syndrome.")
        }
        
        var hasExclusion = false
        

        
        // METHADONE CHECK
        if inputs.contains(where: { $0.drugId == "methadone" && $0.isVisible }) {
             activeWarnings.append("⚠️ METHADONE DETECTED: Standard MME calculation may not apply.")
             activeWarnings.append("Use dedicated Methadone Conversion Tool for switching TO methadone.")
        }
        
            for (idx, input) in inputs.enumerated() {
                // Ensure index is valid & get fresh reference
                guard let val = Double(input.dose), val > 0 else { continue }
                
                // MICROGRAM TRAP: Safety check for Unit Confusion
                // Note: We modify inputs[idx] directly to set inline warnings
                if (input.drugId == "sufentanil" || input.drugId == "alfentanil") && val < 1.0 {
                     inputs[idx].warningMessage = "⚠️ CRITICAL: Doses <1mcg detected. Verify vs decimal error."
                } else if (input.routeType == .microgramIO || input.routeType == .patch) && val < 10 {
                    inputs[idx].warningMessage = "⚠️ Suspected Unit Error: Input <10. Verify MICROGRAMS (mcg), not mg."
                }
                
                var factor = 0.0
                
                // EXTREME DOSE VERIFICATION (Safety Gates) -> INLINE WARNINGS (v1.6)
                if input.drugId == "hydromorphone_iv" && val > 4.0 {
                    inputs[idx].warningMessage = "⚠️ Unusually high single dose (>4mg). Verify."
                } else if input.drugId == "morphine_iv" && val > 20.0 {
                    inputs[idx].warningMessage = "⚠️ Unusually high single dose (>20mg). Verify."
                } else if input.drugId == "fentanyl" && val > 200.0 {
                    inputs[idx].warningMessage = "⚠️ Unusually high single dose (>200mcg). Verify."
                } else if input.drugId == "oxycodone" && val > 120.0 {
                    inputs[idx].warningMessage = "⚠️ Unusually high single dose (>120mg). Verify."
                }
                
                switch input.drugId {
            // Standard Factors
            case "morphine":
                factor = 1.0
                if renalStatus == .dialysis {
                    activeWarnings.append("AVOID MORPHINE: Active metabolites (M3G/M6G) accumulate in dialysis. Neurotoxicity risk.")
                }
            case "morphine_iv": 
                factor = 3.0
                activeWarnings.append("NOTE: Potency Ratio: Oral Morphine dose is ~3x IV dose (3:1 Standard). Acute ratio may range to 6:1 (Oral:IV).")
                if renalStatus == .dialysis {
                    activeWarnings.append("AVOID MORPHINE IV: Active metabolites (M3G/M6G) accumulate in dialysis. Neurotoxicity risk.")
                }
            case "hydromorphone": 
                factor = 5.0
                activeWarnings.append("NOTE: Hydromorphone conversion varies (3.7-5:1). Monitor closely.")
                if hepaticStatus == .failure {
                    activeWarnings.append("HEPATIC SHUNT: Oral Hydromorphone bioavailability increases ~4x in Liver Failure (Portosystemic shunts). MME calculation may SIGNIFICANTLY underestimate risk. Use extreme caution.")
                }
            case "hydromorphone_iv": 
                factor = 11.5
                if activeWarnings.isEmpty { activeWarnings.append("NOTE: IV Hydromorphone factor set to 11.5 (Evidence-Based Median) to avoid overestimating tolerance. Standard 20:1 is often unsafe for rotation.") }
            case "oxycodone": factor = 1.5
            case "hydrocodone": factor = 1.0
            case "oxymorphone": factor = 3.0
            case "codeine": 
                factor = 0.15
                if renalStatus == .dialysis {
                    activeWarnings.append("AVOID CODEINE: Metabolites accumulate in dialysis.")
                }
            case "tramadol": 
                factor = 0.2 // Updated CDC 2022
                if activeWarnings.isEmpty { activeWarnings.append("NOTE: Tramadol factor updated to 0.2 per CDC 2022.") }
            case "tapentadol": factor = 0.4
            case "meperidine": 
                factor = 0.1
                if renalStatus == .dialysis {
                    activeWarnings.append("AVOID MEPERIDINE: Normeperidine accumulates. Seizure risk. Contraindicated.")
                }
                
            // DRIPS (mg/hr -> mg/24h -> MME)
            case "morphine_iv_drip": factor = 24.0 * 3.0
            case "hydromorphone_iv_drip": factor = 24.0 * 11.5
                
            case "methadone":
                if isPregnant {
                     factor = 0
                     hasExclusion = true
                     activeWarnings.append("Methadone Calculation Blocked in Perinatal Mode (CYP Induction). Consult Specialist.")
                } else {
                     factor = 4.7 // CDC 2022 surveillance only
                     if activeWarnings.isEmpty || !activeWarnings.contains(where: { $0.contains("CDC 2022 fixed") }) {
                         activeWarnings.append("⚠️ METHADONE MME CALCULATION: Using CDC 2022 fixed 4.7:1 ratio for surveillance ONLY.")
                         activeWarnings.append("🚨 DO NOT USE THIS MME TO CONVERT FROM METHADONE TO OTHER OPIOIDS.")
                         activeWarnings.append("Converting FROM methadone requires specialist consultation and different methodology.")
                     }
                }
                
            // SAFETY: IV Fentanyl (Micrograms -> Milligrams -> MME)
            case "fentanyl":
                factor = 0.3 // 1mcg = 0.3 MME (Based on NCCN Single Dose 100mcg:10mg MS IV)
                if activeWarnings.isEmpty { 
                     activeWarnings.append("NOTE: Fentanyl MME (0.3) based on NCCN Single-Dose. Chronic steady-state equivalence may be lower (0.12). Caution rotating FROM Fentanyl.")
                }
                
            case "sufentanil":
                factor = 1.0 // 1mcg = 1 MME (Conservative Extrapolation)
                if activeWarnings.isEmpty {
                     activeWarnings.append("⚠️ SUFENTANIL: Conversion factor extrapolated from anesthesia literature. NOT validated for chronic pain. Requires specialist consultation and ICU-level monitoring.")
                     activeWarnings.append("NOTE: Theoretical potency 5-10x fentanyl, but clinical dosing patterns suggest lower ratios. Use extreme caution.")
                }
                
            case "alfentanil":
                factor = 0.1 // 1mcg = 0.1 MME (Approx 1/4 Fentanyl)
                if activeWarnings.isEmpty {
                    activeWarnings.append("⚠️ ALFENTANIL: Conversion factor based on anesthesia pharmacokinetics. NOT validated for chronic pain management.")
                    activeWarnings.append("NOTE: Ultra-short duration (5-10 min). Primarily used for procedural sedation, not chronic analgesia.")
                }
                
            case "fentanyl_patch":
                factor = 2.4 // 25mcg/hr * 2.4 = 60 MME

            // SAFETY: Exclusions

            case "sublingual_fentanyl":
                factor = 0
                hasExclusion = true
                activeWarnings.append("Sublingual Fentanyl Excluded: Bioavailability varies.")
            case "buprenorphine", "butrans":
                factor = 0
                hasExclusion = true
                activeWarnings.append("Buprenorphine Excluded: Partial agonist.")
                
                
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
        if totalMME > 90 {
            activeWarnings.append(">90 MME: High Overdose Risk. Naloxone indicated.")
        }
        
        if totalMME > 50 || matchesBenzos || historyOverdose || sleepApnea {
            activeWarnings.append("RECOMMENDATION: Prescribe Naloxone (High Overdose Risk per CDC criteria).")
        }
        
        self.warningText = activeWarnings.joined(separator: "\n")
        
        if shouldBlockTargets {
            targetDoses = []
            // Keep resultMME visible (input sum) but targets are blocked
            return
        }
        
        // 2. Reduction
        let reducedMME = totalMME * (1.0 - (reduction / 100.0))
        
        // Compliance Warning logic (Rotation Specific)
        if reduction < 25 {
            complianceWarning = "Aggressive Rotation (<25%). Valid for Poorly Controlled Pain, but carries high risk of toxicity due to incomplete cross-tolerance. Monitor closely."
        } else if reduction <= 50 {
            complianceWarning = "Standard Rotation (25-50%). Accounts for incomplete cross-tolerance (25-50% reduction recommended for Well-Controlled Pain)."
        } else {
            complianceWarning = "Conservative Rotation (>50%). Recommended for Frail/Elderly or patients with Significant Adverse Effects."
        }
        
        if reducedMME <= 0 {
            targetDoses = []
            return
        }
        
        // 3. Targets
        var targets: [TargetDose] = []
        
        // Target: Oxycodone PO (1.5:1)
        let oxyDaily = reducedMME / 1.5
        targets.append(createTarget(drug: "Oxycodone", route: "PO", routeType: .standardPO, total: oxyDaily, ratio: "1.5 : 1"))
        
        // Target: Hydromorphone PO (5:1) - Updated Audit
        let dilDaily = reducedMME / 5.0
        targets.append(createTarget(drug: "Hydromorphone", route: "PO", routeType: .standardPO, total: dilDaily, ratio: "5 : 1"))
        
        // Target: Morphine IV (3:1 vs PO)
        let morDaily = reducedMME / 3.0
        targets.append(createTarget(drug: "Morphine", route: "IV", routeType: .ivPush, total: morDaily, ratio: "IV Ratio 3:1"))
        
        // Target: Fentanyl IV (Ratio 10:1 to Morphine IV)
        // MorIV (mg) * 10 = FentIV (mcg)
        // MME / 3.0 = MorIV. (MME/3)*10 = MME * 3.33
        let fentIV = reducedMME * 3.33
        targets.append(createTarget(drug: "Fentanyl", route: "IV", routeType: .microgramIO, total: fentIV, ratio: "10mg Mor : 100mcg Fent", unit: "mcg"))
        
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
            // User Preference Check
            if routePreference == .iv {
                // Priority: IV -> PO (User Request)
                targets.sort { t1, t2 in
                    if t1.route == "IV" && t2.route.contains("PO") { return true }
                    if t1.route.contains("PO") && t2.route == "IV" { return false }
                    return false
                }
            } else {
                // Stewardship Standard: PO -> IV
                targets.sort { t1, t2 in
                    if t1.route == "PO" && t2.route == "IV" { return true }
                    if t1.route == "IV" && t2.route == "PO" { return false }
                    return false // Keep original order
                }
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
    

    
    private func createTarget(drug: String, route: String, routeType: DrugRouteType, total: Double, ratio: String, unit: String = "mg") -> TargetDose {
        var adjustedTotal = total
        var adjustmentNote = ratio
        var originalTotalString: String? = nil
        
        // 1. Renal Adjustment: Hydromorphone
        if drug.contains("Hydromorphone") && renalStatus != .normal {
            // Dialysis: 0.25 (75% reduction) | Impaired: 0.5 (50% reduction)
            let reductionFactor: Double = (renalStatus == .dialysis) ? 0.25 : 0.5
            
            // Store original before modifying
            originalTotalString = total.toClinicalString(route: routeType, unit: unit)
            
            adjustedTotal = total * reductionFactor
            let percentage = Int((1.0 - reductionFactor) * 100)
            adjustmentNote = "\(ratio) | ⚠️ Renal: -\(percentage)% (FDA)"
        }
        
        // 2. Renal Adjustment: Morphine

        else if drug.contains("Morphine") && renalStatus != .normal {
            if renalStatus == .dialysis {
                // Hard Avoidance
                adjustmentNote = "CONTRAINDICATED (Neurotoxic Metabolites)"
                adjustedTotal = 0 // Will result in 0.0 displayed but handled by View logic ideally, or just text warning
                return TargetDose(
                    drug: drug, route: route,
                    totalDaily: "AVOID",
                    breakthrough: "N/A",
                    unit: unit, ratioLabel: adjustmentNote,
                    originalDaily: total.toClinicalString(route: routeType, unit: unit)
                )
            } else {
                 // Impaired: 0.75 (25% reduction)
                let reductionFactor: Double = 0.75
                originalTotalString = total.toClinicalString(route: routeType, unit: unit)
                adjustedTotal = total * reductionFactor
                adjustmentNote = "\(ratio) | Renal: -25% (Metabolites)"
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
                ratioLabel: "\(ratio) | CONTRAINDICATED (Hepatic Shunting Risk)",
                originalDaily: String(format: "%.1f", total)
             )
        }

        // 4. Hepatic Failure: General Reduction (Oxycodone, Morphine, Hydromorphone IV)
        if hepaticStatus == .failure && !drug.contains("Fentanyl") {
             let reductionFactor: Double = 0.50
             if originalTotalString == nil { originalTotalString = String(format: "%.1f", adjustedTotal) }
             adjustedTotal = adjustedTotal * reductionFactor
             adjustmentNote += " | Hepatic: -50% (Clearance)"
        }

        // 4. Final Formatting (Smart Rounding)
        // If adjustedTotal was set to 0 by contraindication, show "AVOID".
        let finalString = (adjustedTotal == 0 && adjustmentNote.contains("CONTRAINDICATED")) ? "AVOID" : adjustedTotal.toClinicalString(route: routeType, unit: unit)
        
        return TargetDose(
            drug: drug, route: route,
            totalDaily: finalString,
            breakthrough: "PRN", // View Logic handles calc (10%)
            unit: unit,
            ratioLabel: adjustmentNote,
            originalDaily: originalTotalString
        )
    }
    

}
