import Foundation

// MARK: - Methadone Data Models

struct MethadoneConversionResult {
    let totalDailyDose: Double
    let individualDose: Double
    let dosingSchedule: String
    let warnings: [String]
    let isContraindicatedForCalculator: Bool
    let transitionSchedule: [MethadoneScheduleStep]?
    let ratioUsed: Double // Added for note context
    let reductionApplied: Double // Added for note context
    let originalDailyDose: Double? // Transparency: What the dose WOULD be without age/hepatic reduction
}

struct MethadoneScheduleStep: Hashable {
    let dayLabel: String
    let methadoneDose: String
    let instructions: String
    let methadoneDailyMg: Double // For Chart
    let prevOpioidPercentVal: Double // For Chart
    let prevMME: Int // New: Calculated MME value for display
}


enum ConversionMethod: String, CaseIterable {
    case rapid = "Rapid"
    case stepwise = "Stepwise"
}

// MARK: - Logic Engine

class MethadoneCalculator {
    
    static func calculate(
        totalMME: Double, 
        patientAge: Int, 
        method: ConversionMethod,
        hepaticStatus: HepaticStatus = .normal,
        renalStatus: RenalStatus = .normal,
        isPregnant: Bool = false,
        isBreastfeeding: Bool = false,
        benzos: Bool = false,
        isOUD: Bool = false,
        qtcProlonged: Bool = false,
        manualReduction: Double? = nil // User-controllable reduction
    ) -> MethadoneConversionResult {
        var ratio: Double
        var maxDailyDose: Double?
        var warnings: [String] = []
        var crossToleranceReduction: Double = 0.0
        
        // 1. CRITICAL SAFETY HARD STOPS (Top Priority)
        
        // Hepatorenal Syndrome (Double Hit)
        if hepaticStatus == .failure && (renalStatus == .dialysis || renalStatus == .impaired) {
             warnings.append("HEPATORENAL SYNDROME: Extreme caution. Consider alternative opioid (e.g., fentanyl, buprenorphine). Specialist consultation mandatory.")
        }
        
        // Pregnancy Safety Gate
        if isPregnant {
            warnings.append("PREGNANCY: Methadone conversion requires Maternal-Fetal Medicine and Addiction Medicine consultation. Risk of Neonatal Abstinence Syndrome (NAS). Do NOT abruptly discontinue prior opioid.")
        }
        
        // Lactation Safety Gate
        if isBreastfeeding {
            warnings.append("LACTATION: Methadone is secreted in breast milk. Breastfeeding is generally encouraged if the patient is stable on MAT, but infant must be monitored for sedation and weight gain.")
        }
        
        // Benzodiazepine Black Box Warning
        if benzos {
            warnings.append("BLACK BOX WARNING: Concurrent benzodiazepines increase risk of fatal respiratory depression. Taper benzodiazepines if possible. If unavoidable, use lowest effective doses and monitor closely.")
        }
        
        // OUD Context Validation
        if isOUD {
            warnings.append("OUD CONTEXT: This calculator is designed for PAIN management. For OUD, consult Addiction Medicine. Typical OUD doses (60-120mg+) differ from Pain protocols.")
        }
        
        // QTc Check
        if qtcProlonged {
            warnings.append("QTc PROLONGATION (>500ms): Methadone is CONTRAINDICATED. Risk of Torsades de Pointes. Consult Cardiology/Pain Specialist.")
        }
        
        // NCCN age-based adjustment
        let useConservativeRatio = patientAge >= 65
        
        // Check for special low-dose fixed rules first
        guard let rule = ClinicalData.MMEConversionRules.getRatio(for: totalMME, age: patientAge, qtcProlonged: qtcProlonged) else {
            warnings.append("SPECIALIST CONSULTATION MANDATORY")
            return MethadoneConversionResult(
                totalDailyDose: 0,
                individualDose: 0,
                dosingSchedule: "Consult Pain Specialist",
                warnings: warnings, // Pass accumulated warnings
                isContraindicatedForCalculator: true,
                transitionSchedule: nil,
                ratioUsed: 0,
                reductionApplied: 0,
                originalDailyDose: nil
            )
        }
        
        // Apply logic from rule
        ratio = rule.ratio
        
        // Override for Elderly Patients (>65y) per NCCN Guidelines
        // FIX: Removed hardcoded 20:1 clamp for MME 60-200. Rely on tiered ratio + reduction.
        /* if useConservativeRatio && (totalMME >= 60 && totalMME < 200) {
            ratio = 20.0
        } */
        
        if let manual = manualReduction {
            crossToleranceReduction = manual / 100.0 // UI usually sends Int percentage
        } else {
            crossToleranceReduction = rule.reduction
        }
        
        maxDailyDose = rule.maxDose
        
        if let warn = rule.warning {
            warnings.append(warn)
        }
        
        var methadoneDailyDose = totalMME / ratio
        
        // Apply Dose-Dependent Cross-Tolerance Reduction (NCCN/APS Safety Protocol)
        if crossToleranceReduction > 0 {
            methadoneDailyDose *= (1.0 - crossToleranceReduction)
            warnings.append("Applied \(Int(crossToleranceReduction * 100))% reduction for incomplete cross-tolerance.")
        }
        
        // Hepatic Safety Gate (Dose Reduction)
        if hepaticStatus == .failure {
            methadoneDailyDose *= 0.5
            warnings.append("HEPATIC FAILURE: Methadone clearance reduced. Dose reduced by 50%. Titrate slowly.")
        }

        // Apply minimum floor for very low calculations (< APS Minimum)
        let minimumDose = 7.5 // APS floor (2.5mg TID)
        if methadoneDailyDose < minimumDose && totalMME >= 30 {
            methadoneDailyDose = minimumDose
            warnings.append("Note: Dose rounded up to APS minimum (2.5mg TID).")
        }
        
        // Apply maximum cap of 40mg (User Request / Guideline Hard Stop)
        let absoluteMax: Double = 40.0
        
        if methadoneDailyDose > absoluteMax {
            methadoneDailyDose = absoluteMax
            warnings.append("Dose CAPPED at \(Int(absoluteMax))mg/day (Guideline Safety Limit).")
        } else if let maxDose = maxDailyDose, methadoneDailyDose > maxDose {
            // Apply rule-based cap if lower than absolute (though 40 is usually the ceiling)
             methadoneDailyDose = maxDose
             warnings.append("Dose capped at \(maxDose)mg/day per NCCN/APS guidelines.")
        }

        // Age-specific warning
        var originalDailyDose: Double? = nil
        if useConservativeRatio && totalMME >= 60 {
            warnings.append("**ELDERLY PATIENT:** Using more conservative NCCN ratios.")
            
            // TRANSPARENCY: Calculate what the Standard Dose would have been
            if let standardRule = ClinicalData.MMEConversionRules.getRatio(for: totalMME, age: 50, qtcProlonged: qtcProlonged) { // Use Age 50 as proxy for standard
                 let standardRatio = standardRule.ratio
                 let standardDose = totalMME / standardRatio
                 originalDailyDose = standardDose
            }
        }
        
        // Also capture pre-hepatic reduction if applicable
        if hepaticStatus == .failure && originalDailyDose == nil {
             // If we didn't already capture it via Age, capture strictly pre-reduction here
             originalDailyDose = methadoneDailyDose * 2.0 // Reverse the 0.5 mult
        }
        
        // Step 5: Divide into dosing schedule (TID preferred for analgesia)
        var individualDose = methadoneDailyDose / 3.0
        
        // Practical Rounding (Nearest 0.5mg) to avoid "1.8mg"
        individualDose = (individualDose * 2).rounded() / 2
        
        // Recalculate daily total based on rounded val
        methadoneDailyDose = individualDose * 3.0
        
        // Step 6: Generate comprehensive warnings
        // Standard Warnings (Always Append)
        if !warnings.contains(where: { $0.contains("**Do NOT titrate**") }) { // Avoid dupes if re-calculating
            warnings.append("**METHADONE SAFETY PROTOCOL:**")
            warnings.append("**TITRATION:** Do NOT increase dose before 5-7 days.")
            warnings.append("**INCREMENT:** Max increase 5mg/day (up to 30-40mg total).")
            warnings.append("**ECG required:** Baseline, 2-4 weeks, and at 100mg/day.")
            warnings.append("   • **Avoid if QTc >500ms;** Caution if 450-500ms.")
            warnings.append("**Monitor** for delayed respiratory depression (peak 2-4 days).")
            warnings.append("**Provide** naloxone rescue kit.")
            warnings.append("**UNIDIRECTIONAL conversion** - do NOT use reverse calculation.")
        }
        
        // Generate Schedule if Stepwise
        var schedule: [MethadoneScheduleStep]? = nil
        if method == .stepwise {
            // Standard 3-Day Switch (33% increments)
            let step1Methadone = (methadoneDailyDose * 0.33 / 3.0 * 2).rounded() / 2 // TID
            let step2Methadone = (methadoneDailyDose * 0.66 / 3.0 * 2).rounded() / 2 // TID
            let finalMethadone = individualDose // Already rounded
            
            schedule = [
                MethadoneScheduleStep(
                    dayLabel: "Days 1-3",
                    methadoneDose: "\(String(format: "%g", step1Methadone)) mg TID",
                    instructions: "Continue PRN breakthrough.",
                    methadoneDailyMg: step1Methadone * 3,
                    prevOpioidPercentVal: 66,
                    prevMME: Int(totalMME * 0.66)
                ),
                MethadoneScheduleStep(
                    dayLabel: "Days 4-6",
                    methadoneDose: "\(String(format: "%g", step2Methadone)) mg TID",
                    instructions: "Monitor for sedation.",
                    methadoneDailyMg: step2Methadone * 3,
                    prevOpioidPercentVal: 33,
                    prevMME: Int(totalMME * 0.33)
                ),
                MethadoneScheduleStep(
                    dayLabel: "Day 7+",
                    methadoneDose: "\(String(format: "%g", finalMethadone)) mg TID",
                    instructions: "Full Target Dose Reached.",
                    methadoneDailyMg: finalMethadone * 3,
                    prevOpioidPercentVal: 0,
                    prevMME: 0
                )
            ]
            
            warnings.append("**STEPWISE INDUCTION:** Follow the 3-Step Transition Schedule below.")
        }

        return MethadoneConversionResult(
            totalDailyDose: methadoneDailyDose,
            individualDose: individualDose,
            dosingSchedule: "Every 8 hours (TID)",
            warnings: warnings,
            isContraindicatedForCalculator: false,
            transitionSchedule: schedule,
            ratioUsed: ratio,
            reductionApplied: crossToleranceReduction,
            originalDailyDose: originalDailyDose
        )
    }
}
