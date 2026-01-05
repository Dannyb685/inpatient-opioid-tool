import Foundation
import Combine

// Validation Engine for Inpatient Opioid Tool
// Benchmarks current logic against gold standard cases (CDC 2022, etc.)

struct ValidationCase {
    let name: String
    let setup: (CalculatorStore) -> Void
    let verify: (CalculatorStore) -> ValidationResult
}

enum ValidationResult {
    case pass
    case fail(String)
}

class ValidationEngine {
    static let shared = ValidationEngine()
    
    // Core Test Suite - 10 Representative Cases covering 50+ requirements
    let testCases: [ValidationCase] = [
        
        // 1. Simple Conversion: Morphine PO to Oxycodone
        ValidationCase(
            name: "Simple Conversion: Morphine 60mg PO -> Oxycodone",
            setup: { store in
                store.reset() // Ensure clean slate
                store.activeInputsAdd(drugId: "morphine", dose: "60") // Morphine PO 60
            },
            verify: { store in
                // MME = 60 * 1 = 60
                // Oxycodone Target = 60 * (1-0.30 reduction) / 1.5 = 42 / 1.5 = 28 mg
                guard let mme = Double(store.resultMME), abs(mme - 60.0) < 1.0 else { 
                    return .fail("MME Mismatch. Expected 60, Got \(store.resultMME)") 
                }
                
                guard let oxy = store.targetDoses.first(where: { $0.drug == "Oxycodone" }),
                      let dose = Double(oxy.totalDaily) else {
                    return .fail("Oxycodone Target Missing")
                }
                
                // Allow rounding tolerance (current logic might be integer or 1 decimal)
                // 28.0 mg
                if abs(dose - 28.0) > 1.0 { return .fail("Oxycodone Dose Mismatch. Expected ~28, Got \(dose)") }
                
                return .pass
            }
        ),
        
        // 2. Renal Impairment (Hydromorphone Reduction)
        ValidationCase(
            name: "Renal Impairment: Hydromorphone Reduction (eGFR 30-60)",
            setup: { store in
                store.reset()
                store.activeInputsAdd(drugId: "morphine", dose: "60") // 60 MME
                store.renalStatus = .impaired
            },
            verify: { store in
                // MME = 60 * 0.7 (Safety Reduction) = 42 MME
                // Base Hydro = 42 / 5.0 (CDC 2022) = 8.4 mg
                // Renal Adjustment (Impaired) = 50% -> 4.2 mg
                
                guard let hydro = store.targetDoses.first(where: { $0.drug == "Hydromorphone" }) else {
                    return .fail("Hydromorphone Target Missing")
                }
                
                guard let dose = Double(hydro.totalDaily) else {
                    return .fail("Invalid Hydromorphone Dose: \(hydro.totalDaily)")
                }
                
                // Allow small rounding tolerance around 4.2
                if abs(dose - 4.2) > 0.5 {
                    return .fail("Renal Dose Mismatch. Expected ~4.2, Got \(dose). (Factor 5.0 Verified)")
                }
                
                // Check for warning label
                if !hydro.ratioLabel.contains("Renal: -50%") {
                    return .fail("Missing Renal Warning Label")
                }
                
                return .pass
            }
        ),
        
        // 3. Dialysis Contraindication (Morphine)
        ValidationCase(
            name: "Dialysis: Morphine Contraindication",
            setup: { store in
                store.reset()
                store.activeInputsAdd(drugId: "oxycodone", dose: "40") // 60 MME
                store.renalStatus = .dialysis
            },
            verify: { store in
                guard let morphine = store.targetDoses.first(where: { $0.drug == "Morphine" }) else {
                    // Logic might remove it entirely or show "AVOID".
                    // Current code: returns TargetDose with "AVOID".
                    return .pass // Valid behavior if it's there
                }
                
                if morphine.totalDaily == "AVOID" || morphine.ratioLabel.contains("CONTRAINDICATED") {
                     return .pass
                }
                
                return .fail("Morphine not flagged as Avoid in Dialysis. Got: \(morphine.totalDaily)")
            }
        ),
        
        // 4. Hepatic Failure (Hydromorphone Shunt Risk)
        ValidationCase(
            name: "Hepatic Failure: Hydromorphone Consult",
            setup: { store in
                store.reset()
                store.activeInputsAdd(drugId: "morphine", dose: "60")
                store.hepaticStatus = .failure
            },
            verify: { store in
                // Expectation: Logic now returns "CONSULT" and blocks the dose card, or sets "AVOID".
                // In CalculatorStore, we set totalDaily: "CONSULT"
                
                guard let hydro = store.targetDoses.first(where: { $0.drug == "Hydromorphone" && $0.route.contains("PO") }) else {
                    return .fail("Hydromorphone PO Target Missing")
                }
                
                if hydro.totalDaily == "CONSULT" && hydro.ratioLabel.contains("CONTRAINDICATED") {
                    return .pass
                }
                return .fail("Hepatic Failure did not trigger CONSULT. Got: \(hydro.totalDaily)")
            }
        ),
        
        // 5. Fentanyl Unit Confusion (Microgram Trap)
        ValidationCase(
            name: "Safety: Fentanyl Patch <10 Input",
            setup: { store in
                store.reset()
                store.activeInputsAdd(drugId: "fentanyl", dose: "2.5") // 2.5 mcg/hr
            },
            verify: { store in
                if store.warningText.contains("Suspected Unit Error") || store.warningText.contains("Verify value") {
                    return .pass
                }
                return .fail("Microgram Trap Warning missed for input 2.5")
            }
        ),
        
        // 6. Pregnancy Lock
        ValidationCase(
            name: "Safety: Pregnancy Lock",
            setup: { store in
                store.reset()
                store.isPregnant = true
                store.activeInputsAdd(drugId: "morphine", dose: "30")
            },
            verify: { store in
                // Decision: Pregnancy should NOT lock (Negligence risk). Must warn.
                if store.resultMME != "---" && (store.warningText.contains("Pregnancy") || store.warningText.contains("Neonatology") || store.warningText.contains("Consult")) { 
                    return .pass 
                }
                return .fail("Pregnancy locked output or missing warning. Result: \(store.resultMME)")
            }
        ),
        
        // 7. Pediatric Lock
        ValidationCase(
            name: "Safety: Pediatric Lock (<18)",
            setup: { store in
                store.reset()
                store.age = "12"
                store.activeInputsAdd(drugId: "morphine", dose: "30")
            },
            verify: { store in
                if store.resultMME == "---" && store.warningText.contains("Pediatric") { return .pass }
                return .fail("Pediatric age did not lock calculator")
            }
        ),
        
        // 8. Tramadol Factor Verification (CDC 2022)
        ValidationCase(
            name: "Core: Tramadol Factor 0.2",
            setup: { store in
                store.reset()
                store.activeInputsAdd(drugId: "tramadol", dose: "50")
            },
            verify: { store in
                // 50 mg * 0.2 = 10 MME
                if store.resultMME == "10.0" { return .pass }
                return .fail("Tramadol MME factor incorrect. Expected 10.0 (0.2), Got \(store.resultMME)")
            }
        ),
        
        // 9. Patch Rounding Logic
        ValidationCase(
            name: "Safety: Fentanyl Patch Rounding",
            setup: { store in
                store.reset()
                // Target: 25 mcg patch. 
                // Conversion: MME -> Patch (Ratio 1.5 Morphine : 1 Patch? No, standard is 2:1 MME:Patch).
                // My code uses 0.5 factor (MME * 0.5 = Patch mcg).
                // So for 25 mcg patch, we need ~50 MME adjusted.
                // Let's input 80 MME. 30% reduction = 56 MME.
                // 56 * 0.5 = 28 mcg.
                // Rounding DOWN should give 25 mcg.
                store.activeInputsAdd(drugId: "morphine", dose: "80") 
            },
            verify: { store in
                // 80 * 0.7 = 56.
                // 56 * 0.5 = 28.
                // Expected Output: 25.
                guard let patch = store.targetDoses.first(where: { $0.route == "Patch" }) else {
                    return .fail("Patch Target Missing")
                }
                
                if patch.totalDaily == "25" && patch.ratioLabel.contains("Rounded DOWN") {
                    return .pass
                }
                return .fail("Rounding Failed. Expected 25, Got \(patch.totalDaily). Label: \(patch.ratioLabel)")
            }
        ),
        
        // 10. Math Receipt: Multi-Drug Transparency
        ValidationCase(
            name: "Transparency: Multi-Drug Receipt",
            setup: { store in
                store.reset()
                store.activeInputsAdd(drugId: "morphine", dose: "30")
                store.activeInputsAdd(drugId: "oxycodone", dose: "20")
            },
            verify: { store in
                // Expect: Morphine 30 (30 MME) + Oxy 20 (30 MME) = 60 MME.
                if store.resultMME != "60.0" { return .fail("Total MME Incorrect") }
                
                // Check Receipt Lines
                let receipt = store.calculationReceipt.joined()
                if !receipt.contains("30") || !receipt.contains("20") {
                     return .fail("Receipt missing line items")
                }
                return .pass
            }
        ),
        
        // 11. Safety: Naloxone Threshold (50 MME)
        ValidationCase(
            name: "Safety: Naloxone Alert (50-90 MME)",
            setup: { store in
                store.reset()
                store.activeInputsAdd(drugId: "morphine", dose: "55")
            },
            verify: { store in
                if store.warningText.localizedCaseInsensitiveContains("naloxone") { return .pass }
                return .fail("Missing Naloxone Warning at 55 MME")
            }
        ),
        
        // 12. Safety: High Risk Threshold (>90 MME)
        ValidationCase(
            name: "Safety: High Risk Alert (>90 MME)",
            setup: { store in
                store.reset()
                store.activeInputsAdd(drugId: "morphine", dose: "95")
            },
            verify: { store in
                if (store.warningText.contains("High") && store.warningText.contains("Risk")) || store.warningText.contains("REQUIRED") { return .pass }
                return .fail("Missing High Risk Warning at 95 MME")
            }
        ),

        // 13. Oxycodone Factor
        ValidationCase(name: "Factor: Oxycodone (1.5)", setup: { $0.reset(); $0.activeInputsAdd(drugId: "oxycodone", dose: "40") }, verify: { $0.resultMME == "60.0" ? .pass : .fail("Expected 60, got \($0.resultMME)") }),
        
        // 14. Codeine Factor
        ValidationCase(name: "Factor: Codeine (0.15)", setup: { $0.reset(); $0.activeInputsAdd(drugId: "codeine", dose: "200") }, verify: { $0.resultMME == "30.0" ? .pass : .fail("Expected 30, got \($0.resultMME)") }),

        // 15. Tapentadol Factor
        ValidationCase(name: "Factor: Tapentadol (0.4)", setup: { $0.reset(); $0.activeInputsAdd(drugId: "tapentadol", dose: "100") }, verify: { $0.resultMME == "40.0" ? .pass : .fail("Expected 40, got \($0.resultMME)") }),

        // 16. Meperidine Factor
        ValidationCase(name: "Factor: Meperidine (0.1)", setup: { $0.reset(); $0.activeInputsAdd(drugId: "meperidine", dose: "300") }, verify: { $0.resultMME == "30.0" ? .pass : .fail("Expected 30, got \($0.resultMME)") }),

        // 17. Morphine IV Factor
        ValidationCase(name: "Factor: Morphine IV (3.0)", setup: { $0.reset(); $0.activeInputsAdd(drugId: "morphine_iv", dose: "10") }, verify: { $0.resultMME == "30.0" ? .pass : .fail("Expected 30, got \($0.resultMME)") }),

        // 18. Fentanyl IV Factor
        ValidationCase(name: "Factor: Fentanyl IV (0.3/mcg)", setup: { $0.reset(); $0.activeInputsAdd(drugId: "fentanyl", dose: "100") }, verify: { $0.resultMME == "30.0" ? .pass : .fail("Expected 30 (100mcg = 0.1mg * 300), got \($0.resultMME)") }),

        // 19. Mixed Regimen (Polypill)
        ValidationCase(
            name: "Mixed: Morph/Oxy/Hydrocodone",
            setup: { s in s.reset(); s.activeInputsAdd(drugId: "morphine", dose: "15"); s.activeInputsAdd(drugId: "oxycodone", dose: "10"); s.activeInputsAdd(drugId: "hydrocodone", dose: "10") },
            verify: { $0.resultMME == "40.0" ? .pass : .fail("Expected 40 (15+15+10), got \($0.resultMME)") }
        ),

        // 20. Mixed Route (IV + PO)
        ValidationCase(
            name: "Mixed: Morphine IV + PO",
            setup: { s in s.reset(); s.activeInputsAdd(drugId: "morphine", dose: "30"); s.activeInputsAdd(drugId: "morphine_iv", dose: "5") },
            verify: { $0.resultMME == "45.0" ? .pass : .fail("Expected 45 (30 + 15), got \($0.resultMME)") }
        ),

        // 21. Safety: Codeine Dialysis Avoid
        ValidationCase(
             name: "Safety: Codeine in Dialysis",
             setup: { s in s.reset(); s.renalStatus = .dialysis; s.activeInputsAdd(drugId: "codeine", dose: "60") },
             verify: { $0.warningText.contains("AVOID CODEINE") ? .pass : .fail("Missing Codeine Avoid Warning") }
        ),

        // 22. Safety: Meperidine Dialysis Avoid
        ValidationCase(
             name: "Safety: Meperidine in Dialysis",
             setup: { s in s.reset(); s.renalStatus = .dialysis; s.activeInputsAdd(drugId: "meperidine", dose: "100") },
             verify: { $0.warningText.contains("AVOID MEPERIDINE") ? .pass : .fail("Missing Meperidine Avoid Warning") }
        ),

        // 23. Safety: Benzos + Low MME
        ValidationCase(
             name: "Safety: Benzo Trigger",
             setup: { s in s.reset(); s.activeInputsAdd(drugId: "morphine", dose: "30"); s.matchesBenzos = true },
             verify: { $0.warningText.contains("Prescribe Naloxone") ? .pass : .fail("Benzo did not trigger Naloxone warning") }
        ),

        // 24. Safety: Sleep Apnea + Low MME
        ValidationCase(
             name: "Safety: Sleep Apnea Trigger",
             setup: { s in s.reset(); s.activeInputsAdd(drugId: "morphine", dose: "30"); s.sleepApnea = true },
             verify: { $0.warningText.contains("Prescribe Naloxone") ? .pass : .fail("Sleep Apnea did not trigger Naloxone warning") }
        ),

        // 25. Exclusion: Methadone
        ValidationCase(
             name: "Exclusion: Methadone",
             setup: { s in s.reset(); s.activeInputsAdd(drugId: "methadone", dose: "10") },
             verify: { 
                 // Decision: Methadone Surveillance Math allowed (4.7 ratio). Must warn about variable half-life.
                 if $0.resultMME != "---" && $0.warningText.contains("CDC 2022") { return .pass }
                 return .fail("Methadone surveillance mismatch") 
             }
        ),

        // 26. Exclusion: Buprenorphine
        ValidationCase(
             name: "Exclusion: Buprenorphine",
             setup: { s in s.reset(); s.activeInputsAdd(drugId: "buprenorphine", dose: "8") },
             verify: { ($0.resultMME == "---" && $0.warningText.contains("Buprenorphine Excluded")) ? .pass : .fail("Buprenorphine not excluded properly") }
        ),

        // 27. Edge: Zero Input
        ValidationCase(
             name: "Edge: Zero Input",
             setup: { s in s.reset() },
             verify: { $0.resultMME == "0.0" ? .pass : .fail("Zero input failed graceful handle") }
        ),

        // 28. Patch Rounding Small (<12)
        ValidationCase(
             name: "Rounding: Patch Floor",
             setup: { s in s.reset(); s.activeInputsAdd(drugId: "morphine", dose: "20") }, // 20 MME -> 10 mcg patch calc
             verify: { s in 
                 guard let patch = s.targetDoses.first(where: { $0.route == "Patch" }) else { return .fail("Patch missing") }
                 return (patch.totalDaily == "N/A" || patch.ratioLabel.contains("Too low")) ? .pass : .fail("Small patch (<12) should be N/A. Got: \(patch.totalDaily)")
             }
        )

    ]
    
    func runAll() -> String {
        var log = "Validation Suite Run at \(Date())\n-----------------------------------\n"
        var passed = 0
        
        let store = CalculatorStore() // Helper instance
        
        for test in testCases {
            // Run Setup
            test.setup(store)
            store.calculate() // Force calc
            
            // Verify
            let result = test.verify(store)
            
            switch result {
            case .pass:
                log += "✅ [PASS] \(test.name)\n"
                passed += 1
            case .fail(let msg):
                log += "❌ [FAIL] \(test.name): \(msg)\n"
            }
        }
        
        log += "\nSummary: \(passed)/\(testCases.count) tests passed."
        return log
    }
}

// Helper extension to make test setup cleaner (simulates user adding generic inputs)
extension CalculatorStore {
    func activeInputsAdd(drugId: String, dose: String) {
        // Find the input in the list and set it
        if let index = inputs.firstIndex(where: { $0.drugId == drugId }) {
            inputs[index].dose = dose
            inputs[index].isVisible = true
        } else if let index = inputs.firstIndex(where: { $0.drugId.contains(drugId) }) {
             // Fuzzy match fallback
            inputs[index].dose = dose
            inputs[index].isVisible = true
        }
    }
    
    func reset() {
        // Fix: Force clear all inputs to avoid test pollution
        for i in 0..<inputs.count {
            inputs[i].dose = ""
            inputs[i].isVisible = false
        }
        
        self.activeInputsAdd(drugId: "morphine", dose: "")
        self.activeInputsAdd(drugId: "oxycodone", dose: "")
        self.activeInputsAdd(drugId: "fentanyl", dose: "")
        self.renalStatus = .normal
        self.hepaticStatus = .normal
        self.isPregnant = false
        self.age = "30"
        self.analgesicProfile = .naive
    }
}
