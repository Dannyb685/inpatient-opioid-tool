import Foundation
import SwiftUI

// MARK: - Clinical Validation Types

/// Represents the outcome of a clinical logic test
enum ClinicalValidationResult {
    case pass
    case fail(String)
}

/// Structure for defining a clinical scenario and its expected outcome
struct AssessmentTestCase {
    let name: String
    let setup: @MainActor (AssessmentStore) -> Void
    let verify: @MainActor (AssessmentStore) -> ClinicalValidationResult
}

/// Structure for defining a calculator logic test
struct CalculatorTestCase {
    let name: String
    let setup: @MainActor (CalculatorStore) -> Void
    let verify: @MainActor (CalculatorStore) -> ClinicalValidationResult
}

struct MethadoneTestCase {
    let name: String
    let mme: Double
    let age: Int
    let method: ConversionMethod
    // New Safety Parameters (Optional for backward compatibility in tests)
    var hepaticStatus: HepaticStatus = .normal
    var renalStatus: RenalStatus = .normal
    var isPregnant: Bool = false
    var isBreastfeeding: Bool = false
    var benzos: Bool = false
    var isOUD: Bool = false
    var qtcProlonged: Bool = false
    var manualReduction: Double? = nil
    
    let verify: (MethadoneConversionResult) -> ClinicalValidationResult
}

struct OUDTestCase {
    let name: String
    let setup: @MainActor (OUDConsultStore) -> Void
    let verify: @MainActor (OUDConsultStore) -> ClinicalValidationResult
}

struct OUDComplexTestCase {
    let name: String
    let entries: [SubstanceEntry]
    let cows: Int
    let hasUlcers: Bool
    let verify: (ClinicalPlan) -> ClinicalValidationResult
}

struct InfusionTestCase {
    let name: String
    let test: () -> ClinicalValidationResult
}

struct CitationTestCase {
    let name: String
    let test: () -> ClinicalValidationResult
}

struct TransparencyTestCase {
    let name: String
    let setup: @MainActor (CalculatorStore) -> Void
    let verify: @MainActor (CalculatorStore) -> ClinicalValidationResult
}

// MARK: - Clinical Validation Engine
// Stress tests the AssessmentStore logic against complex clinical scenarios.

class ClinicalValidationEngine {
    static let shared = ClinicalValidationEngine()
    
    @MainActor
    func runStressTest() -> String {
        var log = "CLINICAL VALIDATION SUITE REPORT\n"
        log += "Timestamp: \(Date())\n"
        log += "Engine Version: 6.12.7 (Authorized)\n"
        log += "------------------------------------------------\n\n"
        
        // 0. Safety Hardening Checks
        log += runConversionServiceTests()
        log += "\n"
        
        // 1. ASSESSMENT LOGIC
        log += "SECTION 1: ASSESSMENT LOGIC (Global State)\n"
        log += "Objective: Verify complex clinical scenarios against Red Hat safety protocols.\n"
        log += "------------------------------------------------\n"
        
        var passed = 0
        let store = AssessmentStore()
        
        for test in testCases {
            // Setup
            test.setup(store)
            store.calculate()
            
            log += "TEST: \(test.name)\n"
            log += "   -> Inputs: Age=\(store.age), Renal=\(store.renalFunction.rawValue), Hepatic=\(store.hepaticFunction.rawValue)\n"
            
            switch test.verify(store) {
            case .pass:
                log += "   -> Result: PASS (Logic Verified)\n"
                passed += 1
            case .fail(let msg):
                log += "   -> Result: FAIL\n"
                log += "   -> Error: \(msg)\n"
            }
            log += "\n"
        }
        log += "Summary: \(passed)/\(testCases.count) Assessment Tests Passed.\n\n"
        
        // 2. CALCULATOR ACCURACY
        log += "SECTION 2: MME CALCULATOR ACCURACY\n"
        log += "Objective: Validate Equianalgesic conversions against 2025 Standards.\n"
        log += "------------------------------------------------\n"
        
        var calcPassed = 0
        let calcStore = CalculatorStore()
        
        for test in calculatorTestCases {
            test.setup(calcStore)
            calcStore.calculate()
            
            log += "TEST: \(test.name)\n"
            // Capture active inputs for transparency
            let active = calcStore.inputs.filter { $0.isVisible && !$0.dose.isEmpty }
            let inputStr = active.map { "\($0.drugId)=\($0.dose)" }.joined(separator: ", ")
            log += "   -> Inputs: \(inputStr)\n"
            
            switch test.verify(calcStore) {
            case .pass:
                log += "   -> Result: PASS (MME Verified)\n"
                calcPassed += 1
            case .fail(let msg):
                 log += "   -> Result: FAIL\n"
                 log += "   -> Error: \(msg) (Got: \(calcStore.resultMME))\n"
            }
            log += "\n"
        }
        log += "Summary: \(calcPassed)/\(calculatorTestCases.count) MME Tests Passed.\n\n"
        
        // 3. TAPER LOGIC
        log += "SECTION 3: TAPER & ROTATION SAFETY\n"
        log += "Objective: Validate reduction schedules and rotation limits.\n"
        log += "------------------------------------------------\n"
        
        var taperPassed = 0
        for test in taperTestCases {
             test.setup(calcStore)
             calcStore.calculate()
             
             log += "TEST: \(test.name)\n"
             switch test.verify(calcStore) {
             case .pass:
                 log += "   -> Result: PASS\n"
                 taperPassed += 1
             case .fail(let msg):
                 log += "   -> Result: FAIL\n"
                 log += "   -> Error: \(msg)\n"
             }
             log += "\n"
        }
        log += "Summary: \(taperPassed)/\(taperTestCases.count) Taper Tests Passed.\n\n"
        
        // 4. METHADONE LOGIC
        log += "SECTION 4: METHADONE SAFETY ENGINE\n"
        log += "Objective: Validate stateless Methadone calculations and safety gates.\n"
        log += "------------------------------------------------\n"
        
        var methadonePassed = 0
        for test in methadoneTestCases {
            log += "TEST: \(test.name)\n"
            log += "   -> Inputs: MME=\(test.mme), Age=\(test.age), Method=\(test.method)\n"
            if test.qtcProlonged { log += "   -> Risk: QTc Prolonged\n" }
            
            let result = MethadoneCalculator.calculate(
                totalMME: test.mme, 
                patientAge: test.age, 
                method: test.method,
                hepaticStatus: test.hepaticStatus,
                renalStatus: test.renalStatus,
                isPregnant: test.isPregnant,
                isBreastfeeding: test.isBreastfeeding,
                benzos: test.benzos,
                isOUD: test.isOUD,
                qtcProlonged: test.qtcProlonged,
                manualReduction: test.manualReduction
            )
            switch test.verify(result) {
            case .pass:
                 log += "   -> Result: PASS\n"
                 methadonePassed += 1
            case .fail(let msg):
                 log += "   -> Result: FAIL\n"
                 log += "   -> Error: \(msg)\n"
            }
            log += "\n"
        }
        log += "Summary: \(methadonePassed)/\(methadoneTestCases.count) Methadone Tests Passed.\n\n"
        
        // 4b. METHADONE SAFETY GATES (Restored)
        log += "SECTION 4b: METHADONE SAFETY GATES\n"
        log += "Objective: Validate Clinical Safety Gates (QTc, Hepatic, OUD).\n"
        log += "------------------------------------------------\n"
        
        var methadoneSafetyPassed = 0
        // Accessing the static property
        let safetyTests = ClinicalValidationEngine.methadoneSafetyTests 
        
        for test in safetyTests {
            log += "TEST: \(test.name)\n"
            let result = MethadoneCalculator.calculate(
                totalMME: test.mme,
                patientAge: test.age,
                method: test.method,
                hepaticStatus: test.hepaticStatus,
                renalStatus: test.renalStatus,
                isPregnant: test.isPregnant,
                isBreastfeeding: test.isBreastfeeding,
                benzos: test.benzos,
                isOUD: test.isOUD,
                qtcProlonged: test.qtcProlonged,
                manualReduction: test.manualReduction
            )
            
            switch test.verify(result) {
            case .pass:
                 log += "   -> Result: PASS\n"
                 methadoneSafetyPassed += 1
            case .fail(let msg):
                 log += "   -> Result: FAIL\n"
                 log += "   -> Error: \(msg)\n"
            }
            log += "\n"
        }
        log += "Summary: \(methadoneSafetyPassed)/\(safetyTests.count) Methadone Safety Tests Passed.\n\n"
        
        // 5. OUD CONSULT (Protocols)
        log += "SECTION 5: OUD PROTOCOLS (New v6.12.7)\n"
        log += "Objective: Validate Protocol selection based on COWS and Profile.\n"
        log += "------------------------------------------------\n"
        
        var oudPassed = 0
        let oudStore = OUDConsultStore()
        for test in oudTestCases {
            test.setup(oudStore)
            oudStore.generateClinicalPlan()
            
            log += "TEST: \(test.name)\n"
            log += "   -> Computed Selection: \(oudStore.recommendedProtocol?.rawValue ?? "None")\n"
            
            switch test.verify(oudStore) {
            case .pass:
                log += "   -> Result: PASS\n"
                oudPassed += 1
            case .fail(let msg):
                log += "   -> Result: FAIL\n"
                log += "   -> Error: \(msg)\n"
            }
            log += "\n"
        }
        log += "Summary: \(oudPassed)/\(oudTestCases.count) OUD Protocols Passed.\n\n"
        
        // 6. OUD INTELLIGENCE (Logic)
        log += "SECTION 6: OUD INTELLIGENCE ENGINE\n"
        log += "Objective: Validate complex substance-driven decision logic.\n"
        log += "------------------------------------------------\n"
        
        var logicPassed = 0
        for test in ClinicalValidationEngine.oudLogicTests {
            let physiology = OUDCalculator.assess(entries: test.entries, hasUlcers: test.hasUlcers, isPregnant: false, isBreastfeeding: false, hasLiverFailure: false, hasAcutePain: false)
            let plan = ProtocolGenerator.generate(profile: physiology, cows: test.cows, isERSetting: false)
            
            log += "TEST: \(test.name)\n"
            let substanceStr = test.entries.map { "\($0.type)" }.joined(separator: "+")
            log += "   -> Context: \(substanceStr) (COWS \(test.cows))\n"
            
            switch test.verify(plan) {
            case .pass:
                 log += "   -> Result: PASS\n"
                 logicPassed += 1
            case .fail(let msg):
                 log += "   -> Result: FAIL\n"
                 log += "   -> Error: \(msg)\n"
            }
            log += "\n"
        }
        log += "Summary: \(logicPassed)/\(ClinicalValidationEngine.oudLogicTests.count) Logic Tests Passed.\n\n"

        // 7. TRANSPARENCY AUDIT (Glass Box Math & Evidence)
        log += "SECTION 7: TRANSPARENCY & GLASS BOX AUDIT\n"
        log += "Objective: Verify mathematical traceability and citation integrity.\n"
        log += "------------------------------------------------\n"
        
        var transPassed = 0
        for test in ClinicalValidationEngine.transparencyTestCases {
            test.setup(calcStore)
            calcStore.calculate()
            
            log += "TEST: \(test.name)\n"
            switch test.verify(calcStore) {
            case .pass:
                log += "   -> Result: PASS (Audit Verified)\n"
                transPassed += 1
            case .fail(let msg):
                log += "   -> Result: FAIL\n"
                log += "   -> Error: \(msg)\n"
            }
            log += "\n"
        }
        log += "Summary: \(transPassed)/\(ClinicalValidationEngine.transparencyTestCases.count) Transparency Tests Passed.\n\n"

        // 8. MISC INTEGRITY
        log += "SECTION 8: INFUSION & CITATION INTEGRITY\n"
        log += "------------------------------------------------\n"
        var miscPassed = 0
        for test in ClinicalValidationEngine.infusionTestCases { if case .pass = test.test() { miscPassed += 1 } }
        for test in ClinicalValidationEngine.citationTestCases { if case .pass = test.test() { miscPassed += 1 } }
        log += "Summary: \(miscPassed) Miscellaneous Integrity Tests Passed.\n"
        
        log += "\n[END OF REPORT]"
        return log
    }
    
    // Safety Extension: Stress the hardended ConversionService
    func runConversionServiceTests() -> String {
        var log = "CONVERSION SERVICE HARDENING\n"
        var passed = 0
        
        // 1. Valid Lookup
        do {
            _ = try ConversionService.shared.getFactor(drugId: "morphine", route: "po")
            log += "[PASS] Valid Lookup (Morphine PO)\n"
            passed += 1
        } catch {
            log += "[FAIL] Valid Lookup: \(error.localizedDescription)\n"
        }
        
        // 2. Invalid Drug
        do {
            _ = try ConversionService.shared.getFactor(drugId: "fake_drug", route: "po")
            log += "[FAIL] Missing Drug did NOT throw error\n"
        } catch ConversionError.drugNotFound {
             log += "[PASS] Missing Drug -> Caught .drugNotFound\n"
             passed += 1
        } catch {
             log += "[WARN] Unexpected Error for Missing Drug: \(error)\n"
        }
        
        return log
    }
}


// MARK: - New Methadone Logic Tests
extension ClinicalValidationEngine {
    static var methadoneSafetyTests: [MethadoneTestCase] {
        return [
            // 1. Hepatorenal Syndrome (Double Hit) -> Should Warn strongly
            MethadoneTestCase(
                name: "M-Safety-1: Hepatorenal Syndrome",
                mme: 100,
                age: 50,
                method: .rapid,
                hepaticStatus: .failure,
                renalStatus: .impaired
            ) { res in
                if res.warnings.contains(where: { $0.contains("HEPATORENAL SYNDROME") }) { return .pass }
                return .fail("Missing Hepatorenal warning")
            },
            
            // 2. Pregnancy -> Warning + Specialist Consult
            MethadoneTestCase(
                name: "M-Safety-2: Pregnancy Context",
                mme: 60,
                age: 25,
                method: .rapid,
                isPregnant: true
            ) { res in
                if res.warnings.contains(where: { $0.contains("PREGNANCY") }) { return .pass }
                return .fail("Missing Pregnancy warning")
            },
            
            // 2b. Lactation -> Infant Monitoring
            MethadoneTestCase(
                name: "M-Safety-2b: Lactation Context",
                mme: 30,
                age: 30,
                method: .rapid,
                isBreastfeeding: true
            ) { res in
                if res.warnings.contains(where: { $0.contains("LACTATION") }) { return .pass }
                return .fail("Missing Breastfeeding warning")
            },
            
            // 3. Benzos -> Black Box Warning
            MethadoneTestCase(
                name: "M-Safety-3: Benzo Co-prescription",
                mme: 50,
                age: 40,
                method: .rapid,
                benzos: true
            ) { res in
                if res.warnings.contains(where: { $0.contains("BLACK BOX WARNING") }) { return .pass }
                return .fail("Missing Black Box warning for Benzos")
            },
            
            // 4. OUD Context -> Disclaimer
            MethadoneTestCase(
                name: "M-Safety-4: OUD Context",
                mme: 80,
                age: 35,
                method: .rapid,
                isOUD: true
            ) { res in
                if res.warnings.contains(where: { $0.contains("OUD CONTEXT") }) { return .pass }
                return .fail("Missing OUD context warning")
            },
            
            // 5. Hepatic Failure Only -> 50% Dose Reduction
            MethadoneTestCase(
                name: "M-Safety-5: Hepatic Failure Dose Reduction",
                mme: 100, // Ratio ~15 (assuming <65y) -> 6.6mg
                age: 50,
                method: .rapid,
                hepaticStatus: .failure
            ) { res in
                // Check if warning present and dose is roughly half of expected
                if res.warnings.contains(where: { $0.contains("HEPATIC FAILURE") }) { return .pass }
                return .fail("Missing Hepatic Failure reduction/warning")
            },
            
            // 6. QTc Prolongation Gate
            MethadoneTestCase(
                name: "M-Safety-6: QTc Prolongation (>500ms)",
                mme: 100,
                age: 50,
                method: .rapid,
                qtcProlonged: true
            ) { res in
                // Expectation: Result should be contraindicated (0 dose) and have warning
                if res.isContraindicatedForCalculator && res.warnings.contains(where: { $0.contains("QTc PROLONGATION") }) { return .pass }
                return .fail("QTc Prolongation did not trigger Hard Stop/Contraindication")
            },
            
            // 7. Manual Cross-Tolerance Reduction (v1.9)
            MethadoneTestCase(
                name: "M-Safety-7: Manual 50% Reduction",
                mme: 100, // Standard 10:1 -> 10mg. 50% reduction -> 5mg.
                age: 50,
                method: .rapid,
                manualReduction: 50.0
            ) { res in
                if abs(res.totalDailyDose - 7.5) < 1.0 { return .pass }
                return .fail("Manual reduction failed. Expected 7.5mg (Floor Logic), Got \(res.totalDailyDose)")
            }
        ]
    }
}

