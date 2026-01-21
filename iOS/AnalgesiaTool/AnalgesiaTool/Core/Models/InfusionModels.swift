import Foundation

// MARK: - PCA Settings
struct PCASettings: Equatable, Codable {
    var drugId: String = "Morphine"
    var concentration: Double = 1.0 // mg/mL
    var demandDose: Double = 1.0 // mg
    var lockoutInterval: Int = 10 // minutes
    var basalRate: Double = 0.0 // mg/hr
    
    // Computed Safety Limits
    var maxDosesPerHour: Double {
        return 60.0 / Double(lockoutInterval)
    }
    
    var oneHourLimit: Double {
        return (maxDosesPerHour * demandDose) + basalRate
    }
    
    var fourHourLimit: Double {
        return oneHourLimit * 4.0
    }
    
    // Clinical Validation Checks
    func validate(isNaive: Bool, hasOSA: Bool, isRenalImpaired: Bool, age: Int = 50) -> [String] {
        var warnings: [String] = []
        
        let isElderly = age >= 65
        
        // 0. Geriatric Safety
        if isElderly {
            if lockoutInterval < 15 {
                warnings.append("Geriatric Safety (Age \(age)): Recommend extending lockout to ≥15 min due to slower clearance.")
            }
            if basalRate > 0 {
                warnings.append("HIGH RISK (Geriatric): Basal infusions in elderly increase delirium/sedation risk. Avoid if possible.")
            }
        }
        
        // 1. Basal Rate Logic
        if basalRate > 0 {
            if isNaive {
                warnings.append("SAFETY ALERT: Basal infusions in opioid-naive patients are NOT recommended. Evidence shows no analgesic benefit with increased risk of respiratory depression. (APS/ASA Guidelines).")
            }
            if hasOSA {
                warnings.append("HIGH RISK: Basal infusion in OSA significantly increases risk of respiratory depression. Continuous monitoring required if basal is strictly necessary. (AASM/ASA).")
            }
        }
        
        // 2. Lockout Logic
        if isNaive && lockoutInterval < 10 {
            warnings.append("Parameter Check: APS/ASA Guidelines suggest ≥10 minute lockout for opioid-naive patients to prevent stacking.")
        }
        
        if lockoutInterval < 6 {
            warnings.append("Pharmacokinetic Warning: Lockout < 6 min (< CNS onset). Risk of dose stacking before peak effect.")
        }
        
        // 3. Renal Impairment
        if isRenalImpaired {
            if drugId == "Morphine" {
                warnings.append("Renal Alert: Morphine is NOT first-line (active M6G metabolites accumulate). Consider Fentanyl or Methadone (requires specialist consultation). (FDA/ASCO).")
            }
            if drugId == "Hydromorphone" {
                 warnings.append("Renal Caution: Hydromorphone metabolites (H3G) accumulate, increasing neurotoxicity risk (agitation/seizures). Titrate carefully.")
            }
        }
        
        // 4. Monitoring Recommendations (High Risk)
        if hasOSA || (isNaive && basalRate > 0) || isRenalImpaired || isElderly {
             warnings.append("Monitoring Required: Continuous Pulse Oximetry + Capnography (if available). Assess sedation (POSS) frequently. (PRODIGY/CDC).")
        }
        
        return warnings
    }
}

// MARK: - Drip Configuration
struct DripConfig: Equatable, Codable {
    var drugId: String = "Fentanyl"
    var concentration: Double = 10.0 // mcg/mL or mg/mL depending on drug
    var rate: Double = 0.0 // mL/hr
    var unit: String = "mcg" // "mg" or "mcg"
    var infusionDuration: InfusionDuration = .continuous

    enum InfusionDuration: String, Codable, CaseIterable {
        case bolus = "Bolus/PRN (<4 hrs)"
        case continuous = "Continuous (≥24 hrs)"
    }
    
    
    // Computed Dose Rate per Hour
    var hourlyDose: Double {
        return rate * concentration
    }
    
    // Computed 24h Total
    var dailyTotal: Double {
        return hourlyDose * 24.0
    }
    
    // Computed Daily MME (Clinical Logic)
    // Computed Daily MME (Clinical Logic)
    var computedMME: Double {
        // UNIFIED LOGIC: Use centralized ConversionService
        let routeKey: String
        let targetId = drugId.lowercased()
        
        switch drugId {
        case "Fentanyl":
            // Distinguish Acute vs Continuous
            routeKey = (infusionDuration == .continuous) ? "iv_continuous" : "iv_acute"
        case "Hydromorphone", "Morphine":
            routeKey = "iv"
        default:
            routeKey = "iv"
        }
        
        // Fetch Factor
        do {
            let factorData = try ConversionService.shared.getFactor(drugId: targetId, route: routeKey)
            return dailyTotal * factorData.factor
        } catch {
             print("DripConfig MME Error: \(error)")
             return 0.0
        }
    }
    
    // Evidence Quality Logic
    var evidenceQuality: EvidenceQuality {
        let routeKey: String
        let targetId = drugId.lowercased()
        
        switch drugId {
        case "Fentanyl":
            routeKey = (infusionDuration == .continuous) ? "iv_continuous" : "iv_acute"
        default:
            routeKey = "iv"
        }
        
        do {
            let factorData = try ConversionService.shared.getFactor(drugId: targetId, route: routeKey)
            // Map String from JSON to Enum
            switch factorData.evidenceQuality.lowercased() {
            case "high": return .high
            case "moderate": return .moderate
            case "low": return .low
            default: return .low
            }
        } catch {
             return .low // Default to low quality on lookup error
        }
    }
    
    enum EvidenceQuality: String, Codable {
        case high = "High Quality" // RPC/Guidelines
        case moderate = "Moderate Quality" // Consensus/Single Study
        case low = "Low Quality" // Extrapolation
        case insufficient = "Insufficient Data"
    }
    
    // NEW: Physiologic Risk Multiplier
    // While MME is fixed for reporting, clinical risk is a function of physiology.
    func riskMultiplier(isRenalImpaired: Bool, hasOSA: Bool, age: Int) -> Double {
        var multiplier = 1.0
        if age >= 65 { multiplier *= 1.25 } // 25% increased sensitivity
        if age >= 80 { multiplier *= 1.5 }  // 50% increased sensitivity
        if hasOSA { multiplier *= 1.5 }     // 50% increased risk of obstructive events
        if isRenalImpaired && drugId == "Morphine" { multiplier *= 2.0 } // Toxic metabolite risk
        return multiplier
    }
    
    func riskAdjustedMME(isRenal: Bool, osae: Bool, patientAge: Int) -> Double {
        return computedMME * riskMultiplier(isRenalImpaired: isRenal, hasOSA: osae, age: patientAge)
    }
    
    // Clinical Validation
    func validate(isNaive: Bool, isRenalImpaired: Bool, hasOSA: Bool, age: Int = 50) -> [String] {
        var warnings: [String] = []
        let isElderly = age >= 65
        
        if isElderly {
             warnings.append("Geriatric Context (Age \(age)): Consider 25-50% rate reduction due to decreased clearance and increased sensitivity.")
        }
        
        if isRenalImpaired && drugId == "Morphine" {
             warnings.append("Renal Alert: Morphine drips accumulate active metabolites. Fentanyl is preferred in renal failure.")
        }
        
        if hasOSA && rate > 0 {
             warnings.append("OSA Warning: Continuous infusions in OSA require extreme caution and continuous monitoring. (AASM).")
        }
        
        // Monitoring Recommendations (High Risk)
        // Triggers: OSA, Opioid Naive + Basal, or Renal Impairment
        if hasOSA || (isNaive && rate > 0) || isRenalImpaired || isElderly {
             warnings.append("Monitoring Required: Continuous Pulse Oximetry + Capnography (if available). Assess sedation (POSS) frequently. (PRODIGY/CDC).")
        }
        
        if drugId == "Fentanyl" {
             if infusionDuration == .continuous {
                 warnings.append("Continuous Infusion: Using steady-state conversion ratio (0.12 MME/mcg). Acute bolus ratio is 0.3 MME/mcg.")
             } else {
                 warnings.append("Bolus/PRN Dosing: Using acute conversion ratio (0.3 MME/mcg). If transitioning to continuous infusion, recalculate using steady-state ratio.")
             }
        }
        
        return warnings
    }
}
