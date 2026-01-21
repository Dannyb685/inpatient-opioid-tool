import Foundation
import SwiftUI

/// Breakdown item for the OIRD Risk Score transparency
struct RiskAuditItem: Identifiable, Hashable {
    let id = UUID()
    let factor: String
    let points: Int
}

/// Consolidated advice from the Safety Advisory Service
struct SafetyAdvice {
    var adjuvants: [AdjuvantRecommendation] = []
    var warnings: [String] = []
    var monitoring: [String] = []
}

struct AssessmentSnapshot: CalculatorInputs {
    // Inputs required for CalculatorInputs
    let renalFunction: RenalStatus
    let hepaticFunction: HepaticStatus
    let painType: PainType
    let isPregnant: Bool
    let isBreastfeeding: Bool
    let age: String
    let benzos: Bool
    let sleepApnea: Bool
    let historyOverdose: Bool
    let analgesicProfile: AnalgesicProfile
    let sex: Sex
    let chf: Bool
    let copd: Bool
    let psychHistory: Bool
    let currentMME: String
    
    // Additional Context needed for Validation
    let qtcProlonged: Bool // Required for Methadone Gate
    let historyGIBleed: Bool
    let hasAscites: Bool
    let encephalopathyGrade: EncephalopathyGrade
    let adjuvantList: [AdjuvantRecommendation] // Snapshot of current adjuvants
    let recList: [DrugRecommendation] // Snapshot of current recommendations
}

class SafetyAdvisoryService {
    static let shared = SafetyAdvisoryService()
    
    /// Generates the points breakdown for the OIRD Risk Index
    func calculateRiskBreakdown(inputs: CalculatorInputs) -> (score: Int, breakdown: [RiskAuditItem]) {
        var score = 0
        var breakdown: [RiskAuditItem] = []
        
        // 1. PRODIGY FACTORS
        if let ageInt = Int(inputs.age) {
            if ageInt >= 80 {
                score += 16
                breakdown.append(RiskAuditItem(factor: "Age ≥ 80", points: 16))
            } else if ageInt >= 70 {
                score += 12
                breakdown.append(RiskAuditItem(factor: "Age 70-79", points: 12))
            } else if ageInt >= 60 {
                score += 8
                breakdown.append(RiskAuditItem(factor: "Age 60-69", points: 8))
            }
        }
        
        if inputs.sex == .male {
            score += 3
            breakdown.append(RiskAuditItem(factor: "Male Sex", points: 3))
        }
        
        if inputs.chf {
            score += 5
            breakdown.append(RiskAuditItem(factor: "Congestive Heart Failure", points: 5))
        }
        
        if inputs.sleepApnea {
            score += 5
            breakdown.append(RiskAuditItem(factor: "Sleep Apnea (OSA)", points: 5))
        }
        
        if inputs.analgesicProfile == .naive {
            score += 3
            breakdown.append(RiskAuditItem(factor: "Opioid Naive", points: 3))
        }
        
        // 2. RIOSORD / ADDICTION RISK FACTORS
        if inputs.historyOverdose {
            score += 25
            breakdown.append(RiskAuditItem(factor: "History of Overdose/SUD", points: 25))
        }
        
        if inputs.psychHistory {
            score += 10
            breakdown.append(RiskAuditItem(factor: "Psychiatric History", points: 10))
        }
        
        if inputs.benzos {
            score += 9
            breakdown.append(RiskAuditItem(factor: "Benzodiazepines", points: 9))
        }
        
        if inputs.renalFunction.isImpaired {
            score += 8
            breakdown.append(RiskAuditItem(factor: "Renal Impairment", points: 8))
        }
        
        if inputs.copd {
            score += 5
            breakdown.append(RiskAuditItem(factor: "COPD", points: 5))
        }
        
        if inputs.hepaticFunction == .failure {
            score += 7
            breakdown.append(RiskAuditItem(factor: "Hepatic Failure", points: 7))
        }
        
        let mmeVal = Double(inputs.currentMME) ?? 0
        if mmeVal >= 100 {
            score += 7
            breakdown.append(RiskAuditItem(factor: "High Dose (>100 MME)", points: 7))
        }
        
        return (score, breakdown)
    }
    
    /// Detects high-mortality multi-organ failure scenarios
    func detectHepatorenalSyndrome(inputs: CalculatorInputs) -> Bool {
        return inputs.hepaticFunction == .failure && inputs.renalFunction.isImpaired
    }
    
    /// Generates context-aware adjuvant recommendations and associated warnings
    func generateAdvice(inputs: CalculatorInputs, isPregnant: Bool, isBreastfeeding: Bool) -> SafetyAdvice {
        var advice = SafetyAdvice()
        
        // 1. suzetrigine logic (Nav1.8 precision)
        if inputs.painType == .nociceptive {
            if inputs.renalFunction != .dialysis && inputs.hepaticFunction != .failure {
                let reason = inputs.sleepApnea ? "Preferred (Resp Safety)" : "Standard"
                advice.adjuvants.append(AdjuvantRecommendation(
                    category: "NAV1.8 Inhibitor",
                    drug: "Suzetrigine",
                    dose: "Reference",
                    rationale: "\(reason): Novel Nav1.8 Blocker. Safe down to eGFR 15 mL/min (Avoid in Dialysis)."
                ))
            } else if inputs.renalFunction == .dialysis {
                advice.warnings.append("Suzetrigine: Avoid use in eGFR < 15 mL/min or Dialysis (not studied).")
            }
        }
        


        
        // 2. Respiratory & Sedation Warnings
        // 2. Respiratory & Sedation Warnings (Whisper Protocol)
        // Consolidate risk factors to reduce alert fatigue
        var respRisks: [String] = []
        if inputs.benzos { respRisks.append("Benzodiazepines") }
        if inputs.copd { respRisks.append("COPD") }
        if inputs.sleepApnea { respRisks.append("OSA") }
        if (Int(inputs.age) ?? 0) >= 70 { respRisks.append("Age ≥70") }
        
        // MME Threshold Warning
        if (Double(inputs.currentMME) ?? 0) >= 50 {
            advice.warnings.append("Prescriptions ≥ 50 MME/day are unlikely to improve pain and also increase the risk of adverse effects of opioids.")
        }
        
        let hasTripleThreat = inputs.benzos && (inputs.copd || inputs.sleepApnea)
        
        if hasTripleThreat {
             // CRITICAL: Overrides individual warnings
             advice.warnings.append("CRITICAL: TRIPLE THREAT (\(respRisks.joined(separator: " + "))). Synergistic CNS depression risk. Continuous Monitoring Required.")
        } else if respRisks.count >= 2 {
             // MODERATE: Combined risk (Grouped)
             advice.warnings.append("RESPIRATORY ALERT: Combined Risk Factors (\(respRisks.joined(separator: ", "))). Monitor for sedation.")
        } else {
             // LOW: Individual warnings (Whisper)
             if inputs.benzos { advice.warnings.append(ClinicalData.benzodiazepineBlackBoxWarning) }
             if inputs.copd || inputs.sleepApnea { advice.warnings.append("Respiratory Risk: Compromised drive.") }
        }
        
        // Gabapentinoids (Renal Adjustment)
        if inputs.painType == .neuropathic {
           if inputs.renalFunction.isImpaired {
               // Renal Adjustment Logic
               let dose = inputs.renalFunction == .dialysis ? "100mg Post-HD" : "100-300mg qhs"
               advice.adjuvants.append(AdjuvantRecommendation(
                   category: "Gabapentinoid",
                   drug: "Gabapentin (Renally Adjusted)",
                   dose: dose,
                   rationale: "Renal Impairment requires aggressive dose reduction."
               ))
               
               if (Int(inputs.age) ?? 0) >= 80 {
                   advice.warnings.append("Gabapentinoids: High fall risk in elderly with renal impairment.")
               }
           } else {
               // Standard
               advice.adjuvants.append(AdjuvantRecommendation(
                   category: "Gabapentinoid",
                   drug: "Gabapentin",
                   dose: "300mg TID",
                   rationale: "First-line for neuropathic pain."
               ))
           }
        }

        // 3. Hepatic Failure Acetaminophen Gate
        if inputs.hepaticFunction == .failure {
            advice.adjuvants.append(AdjuvantRecommendation(
                category: "Analgesic",
                drug: "Acetaminophen",
                dose: "Max 2g/day",
                rationale: "Hepatic Limit/Caution."
            ))
        } else {
            advice.adjuvants.append(AdjuvantRecommendation(
                category: "Analgesic",
                drug: "Acetaminophen",
                dose: "650mg q6h",
                rationale: "Multimodal opioid sparing."
            ))
        }
        
        // 4. Breastfeeding Safety
        if isBreastfeeding {
             advice.warnings.append("BREASTFEEDING: Monitor infant for sedation, poor feeding, or respiratory distress. Oxycodone passes into milk.")
             advice.monitoring.append("Lactation: Monitor infant for sedation if using opioids.")
        }

        return advice
    }
    
    // MARK: - Validation API (Stateless)
    
    func validateHepaticRenalCombination(snapshot: AssessmentSnapshot) -> [String] {
        var warnings: [String] = []
        
        // Hepatorenal Syndrome Risk
        if snapshot.hepaticFunction == .failure && snapshot.renalFunction.isImpaired {
            warnings.append("CRITICAL: Hepatorenal Syndrome Risk. Combined hepatic failure + renal impairment increases mortality >50%. Avoid Morphine/Codeine/Hydrocodone. Prefer Fentanyl (Redistribution/Inactive Metabolites) or Remifentanil (Plasma Esterase - if ICU).")
            
            // MELD Score Estimation (if age available)
            if Int(snapshot.age) != nil {
                 // Simplified MELD estimation based on dual organ failure
                 warnings.append("VALIDATION: Estimated MELD ≥15 (hepatic failure + renal impairment). Consider hepatology consult for medication review.")
            }
        }
        return warnings
    }

    func validateHepaticCoagulopathy(snapshot: AssessmentSnapshot) -> [String] {
        var warnings: [String] = []
        
        if snapshot.hepaticFunction == .failure {
             // NSAID warning (even topical)
             if snapshot.adjuvantList.contains(where: { $0.drug.contains("NSAID") || $0.drug.contains("Diclofenac") || $0.drug.contains("Ibuprofen") }) {
                 warnings.append("BLEEDING RISK: NSAIDs (including topical) increase bleeding risk in hepatic failure with coagulopathy. Use acetaminophen (max 2g/day) instead.")
             }
             
             // Antiplatelet/anticoagulant interaction
             if snapshot.benzos {
                 warnings.append("HEPATIC ENCEPHALOPATHY RISK: Benzodiazepines + opioids in hepatic failure dramatically increase encephalopathy risk. Avoid if possible.")
             }
        }
        return warnings
    }
    
    func validateAscitesImpact(snapshot: AssessmentSnapshot) -> [String] {
        var warnings: [String] = []
        
        if snapshot.hepaticFunction == .failure && snapshot.hasAscites {
            warnings.append("ASCITES: Volume of distribution altered for hydrophilic drugs. Morphine/hydromorphone loading doses may need reduction, but maintenance doses may be unchanged.")
            
            // Gabapentin adjustment
            if snapshot.adjuvantList.contains(where: { $0.drug.contains("Gabapentin") }) {
                warnings.append("Gabapentin: Ascites increases Vd. Monitor for delayed onset and prolonged effect.")
            }
        }
        return warnings
    }
    
    func validateEncephalopathyRisk(snapshot: AssessmentSnapshot) -> [String] {
        var warnings: [String] = []
        
        if snapshot.hepaticFunction == .failure {
            if snapshot.encephalopathyGrade.isCerebralFailure {
                warnings.append("CEREBRAL ORGAN FAILURE: HE Grade 3-4. Opioids are relatively contraindicated. Consider regional anesthesia or non-opioid alternatives.")
            }
        }
        return warnings
    }
    
    func validateStateConsistency(snapshot: AssessmentSnapshot) -> [String] {
        var warnings: [String] = []
        
        // 1. Pregnancy/Breastfeeding + Male
        if snapshot.sex == .male {
            if snapshot.isPregnant { warnings.append("DATA ERROR: Pregnancy selected for male patient.") }
            if snapshot.isBreastfeeding { warnings.append("DATA ERROR: Breastfeeding selected for male patient.") }
        }
        
        // 2. Naive + High MME
        if snapshot.analgesicProfile == .naive {
            let mmeVal = Double(snapshot.currentMME.filter("0123456789.".contains)) ?? 0
            if mmeVal > 50 {
                warnings.append("INCONSISTENCY: Patient marked 'Opioid Naive' but current MME is \(Int(mmeVal)). Naive patients should have MME = 0. Consider changing profile to 'Chronic Rx'.")
            }
        }
        
        return warnings
    }
    
    // Returns (errors, IDs needed to be removed)
    func validateSafetyGates(snapshot: AssessmentSnapshot) -> ([String], Set<UUID>) {
        var errors: [String] = []
        var removalIDs = Set<UUID>()
        
        let recs = snapshot.recList
        let adjuvants = snapshot.adjuvantList
        
        // 1. Renal Safety Gate Validation
        if snapshot.renalFunction.isImpaired {
            let contraindicated: Set<OpioidMolecule> = [.morphine, .codeine, .meperidine]
            for rec in recs {
                if contraindicated.contains(rec.molecule) {
                    errors.append("SAFETY GATE FAILURE: \(rec.molecule.displayName) recommended despite renal impairment (eGFR < 60). Removing Recommendation.")
                    removalIDs.insert(rec.id)
                }
            }
        }
        
        // 2. Hepatic Safety Gate Validation
        if snapshot.hepaticFunction == .failure {
             let contraindicated: Set<OpioidMolecule> = [.morphine, .codeine, .tramadol, .oxycodone, .methadone]
             
             for rec in recs {
                 if contraindicated.contains(rec.molecule) {
                      if snapshot.renalFunction.isImpaired || snapshot.encephalopathyGrade.isCerebralFailure {
                          errors.append("SAFETY GATE FAILURE: \(rec.molecule.displayName) prohibited in Decompensated Hepatic Failure (Hepatorenal/HE). Removing Recommendation.")
                          removalIDs.insert(rec.id)
                      }
                 }
             }
            
            // 2b. Explicit Methadone "Double Hit" Gate
            if snapshot.renalFunction.isImpaired {
                for rec in recs {
                    if rec.molecule == .methadone {
                         errors.append("SAFETY GATE FAILURE: Methadone prohibited in multi-organ dysfunction (Hepatic Failure + Renal Impairment). Consult Specialist.")
                         removalIDs.insert(rec.id)
                    }
                }
            }
        }
        
        // 3. Pregnancy Safety Gate
        if snapshot.isPregnant {
             let contraindicated: Set<OpioidMolecule> = [.codeine, .tramadol]
             for rec in recs {
                 if contraindicated.contains(rec.molecule) {
                      errors.append("PREGNANCY GATE: \(rec.molecule.displayName) contraindicated. Removing.")
                      removalIDs.insert(rec.id)
                 }
             }
        }
        
        // 4. Pediatric Safety Gate
        if (Int(snapshot.age.filter("0123456789".contains)) ?? 20) < 18 { // Helper logic inside snapshot or verify logic
             let contraindicated: Set<OpioidMolecule> = [.codeine, .tramadol]
             for rec in recs {
                 if contraindicated.contains(rec.molecule) {
                     errors.append("PEDIATRIC GATE: \(rec.molecule.displayName) contraindicated (FDA Black Box). Removing.")
                     removalIDs.insert(rec.id)
                 }
             }
        }
        
        // 5. Methadone Safety Gates
        for rec in recs where rec.molecule == .methadone {
            // A. QTc Gate (>450ms)
            if snapshot.qtcProlonged {
                errors.append("SAFETY GATE FAILURE: Methadone Risk (QTc Prolonged). High risk of Torsades. Contraindicated for new starts; use extreme caution if rotating OFF.")
                removalIDs.insert(rec.id)
            }
            // B. OUD/Overdose Gate (Logic from AssessmentStore)
            // if historyOverdose && !analgesicProfile.isChronic ...
            // Wait, we need to make sure we replicate the exact logic.
            // AssessmentStore Line 457: if historyOverdose && !analgesicProfile.isChronic
            if snapshot.historyOverdose && !snapshot.analgesicProfile.isChronic {
                 errors.append("CRITICAL: Methadone in Naive/High-Risk Patient. Extreme risk of accumulation & respiratory depression. Specialist use only.")
            }
        }
        
        // 6. Breastfeeding
        if snapshot.isBreastfeeding {
             let contraindicated: Set<OpioidMolecule> = [.codeine, .tramadol]
             for rec in recs {
                 if contraindicated.contains(rec.molecule) {
                      errors.append("BREASTFEEDING GATE: \(rec.molecule.displayName) contraindicated (FDA Black Box). Removing.")
                      removalIDs.insert(rec.id)
                 }
             }
        }
        
        return (errors, removalIDs)
    }
}
