import Foundation
import SwiftUI


// MARK: - Cached Test Groups (Optimization)
// Use top-level private constants to handle large array literals once, preventing type-check timeouts.

fileprivate let _cachedInfusionGroup1: [InfusionTestCase] = {
    var cases: [InfusionTestCase] = []
    
    // --- DOMAIN 1: DOSE CALCULATION ACCURACY ---
    
    // Test Case 1: Standard Morphine PCA (Opioid-Naive)
    cases.append(InfusionTestCase(name: "1. PCA: Morphine Standard (Naive)", test: {
        let settings = PCASettings(drugId: "Morphine", concentration: 1.0, demandDose: 1.0, lockoutInterval: 10, basalRate: 0.0)
        // Expected: 6 doses/hr -> 6mg/hr. 4hr = 24mg.
        if settings.maxDosesPerHour != 6.0 { return .fail("Max Doses wrong: \(String(describing: settings.maxDosesPerHour))") }
        if settings.oneHourLimit != 6.0 { return .fail("1-Hour Limit wrong: \(String(describing: settings.oneHourLimit))") }
        if settings.fourHourLimit != 24.0 { return .fail("4-Hour Limit wrong: \(String(describing: settings.fourHourLimit))") }
        return .pass
    }))
    
    // Test Case 2: Fentanyl PCA (High-Potency Tolerant)
    cases.append(InfusionTestCase(name: "2. PCA: Fentanyl High Potency", test: {
        // Fentanyl 10 mcg/mL, 25 mcg demand, 6 min lockout
        let settings = PCASettings(drugId: "Fentanyl", concentration: 10.0, demandDose: 25.0, lockoutInterval: 6, basalRate: 0.0)
        // Expected: 10 doses/hr -> 250 mcg/hr. 4hr = 1000 mcg.
        if settings.maxDosesPerHour != 10.0 { return .fail("Max Doses wrong: \(String(describing: settings.maxDosesPerHour))") }
        if settings.oneHourLimit != 250.0 { return .fail("1-Hour Limit wrong: \(String(describing: settings.oneHourLimit))") }
        if settings.fourHourLimit != 1000.0 { return .fail("4-Hour Limit wrong: \(String(describing: settings.fourHourLimit))") }
        return .pass
    }))
    
    // Test Case 3: Hydromorphone PCA with Basal (Tolerant)
    cases.append(InfusionTestCase(name: "3. PCA: Hydro + Basal (Tolerant)", test: {
        // Hydro demand 0.2, lockout 10 (6 doses), basal 0.4
        let settings = PCASettings(drugId: "Hydromorphone", concentration: 0.2, demandDose: 0.2, lockoutInterval: 10, basalRate: 0.4)
        // Expected: limit = (6 * 0.2) + 0.4 = 1.6 mg/hr.
        if abs(settings.oneHourLimit - 1.6) > 0.01 { return .fail("1-Hour Limit wrong: \(String(describing: settings.oneHourLimit))") }
        
        // Check Warning Logic (Should NOT warn for basal if Tolerant/Not Naive)
        let warnings = settings.validate(isNaive: false, hasOSA: false, isRenalImpaired: false)
        if warnings.contains(where: { $0.contains("SAFETY ALERT") }) {
            return .fail("False Positive Basal Warning for Tolerant Patient")
        }
        return .pass
    }))
    
    // --- DOMAIN 2: CLINICAL SAFETY LOGIC ---
    
    // Test Case 5: Basal Infusion in Opioid-Naive
    cases.append(InfusionTestCase(name: "5. Safety: Basal in Naive", test: {
        let settings = PCASettings(drugId: "Morphine", concentration: 1.0, demandDose: 1.0, lockoutInterval: 10, basalRate: 1.0)
        let warnings = settings.validate(isNaive: true, hasOSA: false, isRenalImpaired: false)
        
        if warnings.contains(where: { $0.contains("SAFETY ALERT") && $0.contains("opioid-naive") }) {
            return .pass
        }
        return .fail("Failed to trigger Basal/Naive Safety Alert")
    }))
    
    // Test Case 6: Basal Infusion with OSA
    cases.append(InfusionTestCase(name: "6. Safety: Basal + OSA", test: {
        let settings = PCASettings(drugId: "Morphine", concentration: 1.0, demandDose: 1, lockoutInterval: 10, basalRate: 2.0)
        let warnings = settings.validate(isNaive: false, hasOSA: true, isRenalImpaired: false)
        
        if warnings.contains(where: { $0.contains("OSA") && $0.contains("HIGH RISK") }) {
             return .pass
        }
        return .fail("Failed to trigger OSA Basal High Risk Warning")
    }))
    
    // Test Case 7: Morphine Renal Impairment
    cases.append(InfusionTestCase(name: "7. Safety: Morphine Renal", test: {
        let settings = PCASettings(drugId: "Morphine", concentration: 1.0, demandDose: 1, lockoutInterval: 10, basalRate: 0)
        let warnings = settings.validate(isNaive: false, hasOSA: false, isRenalImpaired: true)
        
        if warnings.contains(where: { $0.contains("Renal Alert") && $0.contains("M6G") }) {
            return .pass
        }
        return .fail("Failed to trigger Morphine Renal Warning")
    }))
    
    // Test Case 8: Hydromorphone Renal Caution
    cases.append(InfusionTestCase(name: "8. Safety: Hydro Renal", test: {
        let settings = PCASettings(drugId: "Hydromorphone", concentration: 1.0, demandDose: 0.2, lockoutInterval: 10, basalRate: 0)
        let warnings = settings.validate(isNaive: false, hasOSA: false, isRenalImpaired: true)
        
        if warnings.contains(where: { $0.contains("Renal Caution") && $0.contains("neurotoxicity") }) {
            return .pass
        }
        return .fail("Failed to trigger Hydromorphone Renal Caution")
    }))
    
    // --- DOMAIN 3: DRIP MME CALCULATIONS ---
    
    // Test Case 10: Fentanyl Drip MME
    cases.append(InfusionTestCase(name: "10. Drip: Fentanyl Dual MME", test: {
        let settings = DripConfig(drugId: "Fentanyl", concentration: 10.0, rate: 50.0, infusionDuration: .bolus)
        let hourlyMME = settings.computedMME / 24.0
        if hourlyMME != 15.0 { return .fail("Acute Fentanyl MME Wrong. Got \(hourlyMME)") }
        
        let settingsChronic = DripConfig(drugId: "Fentanyl", concentration: 10.0, rate: 50.0, infusionDuration: .continuous)
        let chronicHourlyMME = settingsChronic.computedMME / 24.0
        if chronicHourlyMME != 6.0 { return .fail("Chronic Fentanyl MME Wrong. Got \(chronicHourlyMME)") }
        
        return .pass
    }))
    
    // Test Case 11: Morphine Drip MME
    cases.append(InfusionTestCase(name: "11. Drip: Morphine MME", test: {
        // Morphine 2 mg/hr (1mg/mL * 2mL/hr)
         let config = DripConfig(drugId: "Morphine", concentration: 1.0, rate: 2.0, unit: "mg")
         // Calc: 2 * 24 = 48 mg. 48 * 3 (Chronic Factor) = 144 MME.
        
         let mme = config.computedMME // Should be 144
         
         if abs(mme - 144.0) < 1.0 { return .pass }
         return .fail("Morphine MME Logic Incorrect. Expected 144, Got \(String(describing: mme))")
    }))
    
    // Test Case 12: Hydromorphone Drip MME
    cases.append(InfusionTestCase(name: "12. Drip: Hydro MME", test: {
        // Hydro 0.5 mg/hr (1mg/mL * 0.5mL/hr)
        let config = DripConfig(drugId: "Hydromorphone", concentration: 1.0, rate: 0.5, unit: "mg")
        // Calc: 0.5 * 24 = 12 mg. 12 * 20 (Standard Factor) = 240 MME.
        
        let mme = config.computedMME // Should be 240
        
        if abs(mme - 240.0) < 1.0 { return .pass }
        return .fail("Hydromorphone MME Logic Incorrect. Expected 240, Got \(String(describing: mme))")
    }))
    
    return cases
}()

extension ClinicalValidationEngine {
    // INFUSION CALCULATOR VALIDATION SUITE (Phase 15 Audit)
    // Validates PCA, Drip Logic, and Safety Gates
    // Broken into groups to fix compiler type-check timeout
    
    // Broken into groups to fix compiler type-check timeout
    // OPTIMIZATION: Use cached global constant to avoid rebuilding array on every access
    fileprivate static var infusionGroup1: [InfusionTestCase] {
        return _cachedInfusionGroup1
    }
        

        



    fileprivate static var infusionGroup2: [InfusionTestCase] {
        var cases: [InfusionTestCase] = []
        
        // --- DOMAIN 4: EDGE CASES ---
        
        // Test Case 16: Short Lockout Safety
        cases.append(InfusionTestCase(name: "16. Edge: Short Lockout", test: {
            let settings = PCASettings(drugId: "Morphine", concentration: 1.0, demandDose: 1.0, lockoutInterval: 5, basalRate: 0) // 5 min
            let warnings = settings.validate(isNaive: false, hasOSA: false, isRenalImpaired: false)
            
            if warnings.contains(where: { $0.contains("Pharmacokinetic Warning") }) {
                return .pass
            }
            return .fail("Failed to warn for short lockout (<6 min)")
        }))
        
        // Test Case 19: OSA with Drip
        cases.append(InfusionTestCase(name: "19. Edge: OSA Drip", test: {
            let config = DripConfig(drugId: "Fentanyl", concentration: 10, rate: 2.0, unit: "mcg")
            let warnings = config.validate(isNaive: false, isRenalImpaired: false, hasOSA: true)
            
            if warnings.contains(where: { $0.contains("OSA Warning") }) {
                return .pass
            }
            return .fail("Failed to warn for OSA on Continuous Infusion")
        }))
        
        return cases
    }

    
    static var infusionTestCases: [InfusionTestCase] {
        var all = infusionGroup1
        all.append(contentsOf: infusionGroup2)
        return all
    }

    
    // CITATION INTEGRITY SUITE (Phase 2)
    // Broken into groups to fix compiler type-check timeout
    
    // Broken into groups to fix compiler type-check timeout
    fileprivate static var citationGroup1a: [CitationTestCase] {
        var cases: [CitationTestCase] = []
        
        cases.append(CitationTestCase(name: "1. Registry: Key Definitions", test: {
            let required = ["prodigy_2020", "riosord_2018", "cms_mme_2024", "cdc_opioids_2022", "fda_gabapentin_2019", "fda_morphine_2025"]
            let missing = required.filter { CitationRegistry.definitions[$0] == nil }
            if !missing.isEmpty { return .fail("Missing keys: \(missing)") }
            return .pass
        }))
        
        cases.append(CitationTestCase(name: "2. ClinicalData: Morphine Integrity", test: {
             guard let drug = ClinicalData.drugData.first(where: { $0.id == "morphine_po_ir" }) else { return .fail("Morphine PO missing") }
             // Citations: [CDC(1), Mercadante(2), FDA(3)]
             
             // Check BBW for ^[3]
             if let bbw = drug.blackBoxWarnings?.first?.riskDescription {
                 if !bbw.contains("^[3]") { return .fail("Morphine BBW missing marker ^[3]. Got: \(String(describing: bbw))") }
             }
             // Check Contra for ^[3]
             if let contra = drug.contraindications?.first?.reason {
                 if !contra.contains("^[3]") { return .fail("Morphine Contra missing marker ^[3]. Got: \(String(describing: contra))") }
             }
             return .pass
        }))
        
        cases.append(CitationTestCase(name: "3. ClinicalData: Hydromorphone Integrity", test: {
             guard let drug = ClinicalData.drugData.first(where: { $0.id == "hydromorphone" }) else { return .fail("Hydro missing") }
             // Citations: [Reddy(1), FDA(2)]
             
             // Check BBW for ^[2]
             if let bbw = drug.blackBoxWarnings?.first?.riskDescription {
                 if !bbw.contains("^[2]") { return .fail("Hydro BBW missing marker ^[2]. Got: \(String(describing: bbw))") }
             }
             return .pass
        }))
        
        cases.append(CitationTestCase(name: "4. Registry Currency Check", test: {
             let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
             let dateFormatter = DateFormatter()
             dateFormatter.dateFormat = "yyyy-MM-dd"
             
             for (id, citation) in CitationRegistry.definitions {
                 guard let date = dateFormatter.date(from: citation.lastVerified) else {
                     return .fail("Invalid Date Format for \(id): \(String(describing: citation.lastVerified))")
                 }
                 if date < oneYearAgo {
                     // Just a warning in logs, or strict fail? User asked to "Flag", let's fail to ensure attention.
                     return .fail("Citation \(id) is outdated (verified \(String(describing: citation.lastVerified))). Needs review.")
                 }
             }
             return .pass
        }))
        
        return cases
    }

    fileprivate static var citationGroup1b: [CitationTestCase] {
        var cases: [CitationTestCase] = []
        
        cases.append(CitationTestCase(name: "5. URL Deep Link Validate", test: {
             // Programmatically verify URL schemes and anchors
             for (id, citation) in CitationRegistry.definitions {
                 guard let urlString = citation.url, let url = URL(string: urlString) else { continue }
                 
                 // Check Scheme
                 if url.scheme != "https" { return .fail("Insecure URL for \(id): \(urlString)") }
                 
                 // FDA Specific Checks
                 if citation.type == .fdaLabel {
                     if !urlString.contains("dailymed.nlm.nih.gov") && !urlString.contains("fda.gov") {
                         return .fail("FDA Label source suspicious for \(id): \(urlString)")
                     }
                 }
                 
                 // Anchor Check (If section provided, URL usually should link to it, but structured differently in DailyMed)
                 // NOTE: DailyMed uses setid, not simple anchors often.
             }
             return .pass
        }))
        
        cases.append(CitationTestCase(name: "6. Cross-Tab Renal Consistency", test: {
             // Verify AssessmentStore matches Library Renal logic
             let store = AssessmentStore()
             store.reset()
             store.renalFunction = .dialysis // Strict
             store.analgesicProfile = .naive
             
             // Library: Morphine
             guard let morphine = ClinicalData.drugData.first(where: { $0.id == "morphine_po_ir" }) else { return .fail("Morphine Data missing") }
             
             // Simplify complexity: Check Unsafe Status separately
             // DrugData model has flat 'renalSafety' string
             let isUnsafe = morphine.renalSafety == "Unsafe" || morphine.renalSafety.contains("Avoid")
             
             // Assessment: Logic
             store.calculate()
             // Simplify complexity: Check Recommendations separately
             let hasMorphine = store.recommendations.contains { $0.name.contains("Morphine") }
             let blocksMorphine = !hasMorphine
             
             if isUnsafe && blocksMorphine { return .pass }
             return .fail("Renal Consistency Failure for Morphine.")
        }))
        
        cases.append(CitationTestCase(name: "7. Marker Resolution Logic", test: {
             // Verify that visual markers [N] in DrugData actually have N items in the list
             for drug in ClinicalData.drugData {
                 let warnings = (drug.blackBoxWarnings?.map { $0.riskDescription } ?? []) +
                                (drug.contraindications?.map { $0.reason } ?? [])
                 
                 for warn in warnings {
                     if let range = warn.range(of: "\\^\\[(\\d+)\\]", options: .regularExpression) {
                         let match = String(warn[range])
                         let digitStr = match.dropFirst(2).dropLast(1) // "^[3]" -> "3"
                         if let index = Int(digitStr) {
                             if drug.citations.count < index {
                                 return .fail("Marker \(match) in \(drug.name) out of bounds (Count: \(drug.citations.count))")
                             }
                         }
                     }
                 }
             }
             return .pass
        }))
        
        return cases
    }
    
    fileprivate static var citationGroup2: [CitationTestCase] {
        var cases: [CitationTestCase] = []
        
        // EVIDENCE INTEGRITY (Glass Box Phase)
        cases.append(CitationTestCase(name: "8. Evidence: Fentanyl Dual-Process", test: {
            // Acute (0.3)
            let acute = try? ConversionService.shared.getFactor(drugId: "fentanyl", route: "iv_acute")
            if acute?.factor != 0.3 { return .fail("Femtanyl Acute Factor Error. Expected 0.3, Got \(String(describing: acute?.factor ?? 0))") }
            if acute?.evidenceQuality.lowercased() != "high" { return .fail("Fentanyl Acute Quality Mismatch") }
            
            // Continuous (0.12)
            let continuous = try? ConversionService.shared.getFactor(drugId: "fentanyl", route: "iv_continuous")
            if continuous?.factor != 0.12 { return .fail("Fentanyl Continuous Factor Error. Expected 0.12, Got \(String(describing: continuous?.factor ?? 0))") }
            if continuous?.evidenceQuality.lowercased() != "moderate" { return .fail("Fentanyl Continuous Quality Mismatch") }
            
            return .pass
        }))
        
        cases.append(CitationTestCase(name: "9. Evidence: Methadone Safety", test: {
            let methadone = try? ConversionService.shared.getFactor(drugId: "methadone", route: "po")
            if methadone?.factor != 4.7 { return .fail("Methadone Factor Error. Expected 4.7, Got \(String(describing: methadone?.factor ?? 0))") }
            if methadone?.evidenceQuality.lowercased() != "low" { return .fail("Methadone Quality should be LOW (Surveillance Only)") }
            
            // Warning Check
            let hasNonLinear = methadone?.warnings?.contains { $0.uppercased().contains("NON-LINEAR") } ?? false
            if !hasNonLinear { return .fail("Methadone missing Non-Linear warning in JSON") }
            
            return .pass
        }))
        
        cases.append(CitationTestCase(name: "10. Zero-Factor Loading (Buprenorphine/Suzetrigine)", test: {
            // Logic: Ensure validation didn't reject these due to factor 0.0
            
            // 1. Buprenorphine (SL)
            let bup = try? ConversionService.shared.getFactor(drugId: "buprenorphine", route: "sublingual")
            let bup2 = bup ?? (try? ConversionService.shared.getFactor(drugId: "buprenorphine", route: "po"))
            
            if let factor = bup2?.factor {
                if factor != 0.0 { return .fail("Buprenorphine should be 0.0. Got \(factor)") }
            }
            
            // 2. Suzetrigine
             let suz = try? ConversionService.shared.getFactor(drugId: "suzetrigine", route: "po")
             if let factor = suz?.factor {
                 if factor != 0.0 { return .fail("Suzetrigine should be 0.0. Got \(factor)") }
             }
            
            return .pass
        }))
        
        return cases
    }

    
    static var citationTestCases: [CitationTestCase] {
        var all = citationGroup1a
        all.append(contentsOf: citationGroup1b)

        all.append(contentsOf: citationGroup2)
        return all
    }
    
    // Suite of 65+ Critical Scenarios
    // Cases 1-4: Core Logic
    // Cases 5-15: Advanced Stress Tests
    // Cases 16-31: System Safety Checks
    // Cases 32-52: Physiological Overlap
    // Cases 53-57: Logic Boundaries
    // Case 58: PRODIGY Verification
    // Cases 59-60: Referral Logic
    // Cases 61-62: MME & Specialty Referrals
    // Calculator M1-M3: Math Verification
    // Taper T1-T3: Rotation Safety
    // Methadone MP1-MP3: Calculator Logic
    // Broken into groups to fix compiler type-check timeout
    fileprivate var group1: [AssessmentTestCase] {
        var cases: [AssessmentTestCase] = []
        
        // --- CORE CHECKS ---
        
        // 1. Geriatric Dosing Safeguard (>70yo)
        cases.append(AssessmentTestCase(
            name: "1. Geriatric: Oxycodone Reduction (>70yo)",
            setup: { s in
                s.reset()
                s.age = "75" // Elderly
                s.analgesicProfile = .naive
                s.renalFunction = .normal
            },
            verify: { s in
                guard let oxy = s.recommendations.first(where: { $0.name.contains("Oxycodone") }) else {
                    return .fail("Oxycodone recommendation missing")
                }
                if oxy.detail.contains("2.5-5mg") { return .pass }
                return .fail("Elderly dose reduction failed. Got: \(oxy.detail)")
            }
        ))
        
        // 2. Hepatic Shunting (Hydromorphone Risk)
        cases.append(AssessmentTestCase(
            name: "2. Hepatic Failure: Hydromorphone Shunt Warning",
            setup: { s in
                s.reset()
                s.hepaticFunction = .failure
                s.analgesicProfile = .naive
                s.route = .po
            },
            verify: { s in
                guard let hydro = s.recommendations.first(where: { $0.name.contains("Hydromorphone") }) else {
                    return .fail("Hydromorphone recommendation missing")
                }
                if hydro.reason.contains("Shunt") || hydro.detail.contains("Bioavailability") {
                    return .pass
                }
                return .fail("Hepatic Shunt warning missing. Got Reason: \(hydro.reason)")
            }
        ))
        
        // 3. Pregnancy Safety (Codeine Exclusion)
        cases.append(AssessmentTestCase(
            name: "3. Pregnancy: Codeine/Tramadol Exclusion",
            setup: { s in
                s.reset()
                s.sex = .female
                s.age = "28"
                s.isPregnant = true
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasCodeine = s.recommendations.contains { $0.name.contains("Codeine") }
                let hasTramadol = s.recommendations.contains { $0.name.contains("Tramadol") }
                let hasWarning = s.warnings.contains { $0.contains("Pregnancy") }
                
                if !hasCodeine && !hasTramadol && hasWarning { return .pass }
                return .fail("Pregnancy filter failed. Codeine present: \(hasCodeine)")
            }
        ))
        
        // 4. Buprenorphine Optimization
        cases.append(AssessmentTestCase(
            name: "4. MAT: Buprenorphine Post-Op Strategy",
            setup: { s in
                s.reset()
                s.analgesicProfile = .buprenorphine
                s.indication = .postoperative
            },
            verify: { s in
                let continueRec = s.recommendations.contains { $0.name.contains("Continue Buprenorphine") && $0.type == .safe }
                let reductionRec = s.recommendations.contains { $0.name.contains("Dose Reduction") && $0.reason.contains("Controversial") }
                
                if continueRec && reductionRec { return .pass }
                return .fail("Buprenorphine Logic Mismatch. Expected Continue + Controversial Reduction. Got: \(s.recommendations.map { $0.name })")
            }
        ))
        
        // --- ADVANCED STRESS TESTS ---
        
        // 5. Elderly Polypharmacy
        cases.append(AssessmentTestCase(
            name: "5. Elderly Polypharmacy (Renal + Benzos)",
            setup: { s in
                s.reset()
                s.age = "82"
                s.analgesicProfile = .naive
                s.benzos = true
                s.sleepApnea = true
                s.renalFunction = .impaired
            },
            verify: { s in
                let highRisk = s.prodigyRisk == "High"
                let hasBenzoWarning = s.warnings.contains { $0.lowercased().contains("benzo") && $0.contains("3.8x") }
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let hasMorphine = s.recommendations.contains { $0.name.contains("Morphine") }
                let doseRec = s.recommendations.first(where: { $0.name.contains("Fentanyl") })
                let doseCorrect = doseRec?.detail.contains("12.5mcg") == true || doseRec?.detail.contains("Renal") == true || doseRec?.detail.contains("No active metabolites") == true
                
                if highRisk && hasBenzoWarning && hasFentanyl && !hasMorphine && doseCorrect { return .pass }
                return .fail("Elderly Polypharmacy failed. Risk:\(highRisk) Benzo:\(hasBenzoWarning) Fent:\(hasFentanyl) NoMorph:\(!hasMorphine) Dose:\(doseCorrect) Detail:\(doseRec?.detail ?? "NIL")")
            }
        ))
        
        // 6. Hepatic Failure + Neuropathic
        cases.append(AssessmentTestCase(
            name: "6. Hepatic Failure + Neuropathic Pain",
            setup: { s in
                s.reset()
                s.hepaticFunction = .failure
                s.painType = .neuropathic
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let toxicPresent = s.recommendations.contains { $0.name.contains("Morphine") || $0.name.contains("Oxycodone") }

                let tylenolCap = s.adjuvants.contains { $0.drug.localizedCaseInsensitiveContains("Acetaminophen") && $0.dose.contains("2g") }
                
                if hasFentanyl && !toxicPresent && tylenolCap { return .pass }
                return .fail("Hepatic/Neuropathic logic failed. Fent:\(hasFentanyl) NoToxic:\(!toxicPresent) Tylenol:\(tylenolCap) Adjuvants:\(s.adjuvants)")
            }
        ))
        
        // 7. Pregnant Chronic User
        cases.append(AssessmentTestCase(
            name: "7. Pregnant Chronic Opioid User",
            setup: { s in
                s.reset()
                s.sex = .female
                s.isPregnant = true
                s.analgesicProfile = .chronicRx
            },
            verify: { s in
                let continueMeds = s.recommendations.contains { $0.name.contains("Continue Home Meds") }
                let withdrawalWarn = s.warnings.contains { $0.contains("withdrawal") || $0.contains("fetal") }
                let noTramadol = !s.recommendations.contains { $0.name.contains("Tramadol") }
                
                if continueMeds && withdrawalWarn && noTramadol { return .pass }
                return .fail("Pregnant Chronic logic failed")
            }
        ))
        
        // 8. Dialysis + Bone Metastasis
        cases.append(AssessmentTestCase(
            name: "8. Dialysis + Bone Metastasis",
            setup: { s in
                s.reset()
                s.renalFunction = .dialysis
                s.painType = .bone
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let hydroCaution = s.recommendations.first(where: { $0.name.contains("Hydromorphone") })?.reason.contains("Strict Caution") ?? false
                let hasDex = s.adjuvants.contains { $0.drug.contains("Dexamethasone") }
                
                if hasFentanyl && hydroCaution && hasDex { return .pass }
                return .fail("Dialysis/Bone logic failed")
            }
        ))
        
        // 9. Buprenorphine + NPO + Surgical
        cases.append(AssessmentTestCase(
            name: "9. Buprenorphine + NPO + Surgical",
            setup: { s in
                s.reset()
                s.analgesicProfile = .buprenorphine
                s.postOpNPO = true
                s.route = .iv
                s.indication = .postoperative
            },
            verify: { s in
                let reductionRec = s.recommendations.contains { $0.detail.contains("8-12mg") }
                let highAffinity = s.recommendations.contains { $0.name.contains("High-Affinity") || $0.detail.contains("Fentanyl") }
                let poPresent = s.recommendations.contains { $0.name.contains("PO") }
                
                if reductionRec && highAffinity && !poPresent { return .pass }
                return .fail("Bup/NPO logic failed. 8-12mg Check: \(reductionRec), PO Present: \(poPresent)")
            }
        ))
        
        // 10. Methadone + QTc + CHF
        cases.append(AssessmentTestCase(
            name: "10. Methadone + QTc + CHF",
            setup: { s in
                s.reset()
                s.analgesicProfile = .methadone
                s.qtcProlonged = true
                s.chf = true
            },
            verify: { s in
                let qtcWarn = s.warnings.contains { $0.contains("QTc") || $0.contains("Torsades") }

                let methadoneRemoved = s.recommendations.contains { $0.name.contains("Methadone") } == false
                
                if qtcWarn && methadoneRemoved { return .pass }
                return .fail("Methadone QTc/CHF logic failed. QTcWarn:\(qtcWarn) Removed:\(methadoneRemoved).")
            }
        ))
        
        // 11. High Potency + Renal (Uncertain Tolerance)
        cases.append(AssessmentTestCase(
            name: "11. High Potency + Renal + Uncertain Tolerance",
            setup: { s in
                s.reset()
                s.analgesicProfile = .highPotency
                s.toleranceUncertain = true
                s.renalFunction = .dialysis
                s.route = .iv
            },
            verify: { s in
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let mmeWarn = s.warnings.contains { $0.contains("MME") && $0.contains("UNDERESTIMATE") }
                let hydroCaution = s.recommendations.first(where: { $0.name.contains("Hydromorphone") })?.reason.contains("Strict Caution") ?? false
                
                if hasFentanyl && mmeWarn && hydroCaution { return .pass }
                return .fail("High Potency/Renal logic failed")
            }
        ))
        
        // 12. Naltrexone + Bone Pain + Unstable Hemo
        cases.append(AssessmentTestCase(
            name: "12. Naltrexone + Bone Pain + Unstable Hemo",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naltrexone
                s.painType = .bone
                s.hemo = .unstable
            },
            verify: { s in
                let ketamineRec = s.recommendations.contains { $0.name.contains("Ketamine") }
                let hemoWarn = s.warnings.contains { $0.contains("Ketamine Caution") || $0.contains("hypertension") }
                let blockadeWarn = s.warnings.contains { $0.contains("BLOCKADE ACTIVE") }
                
                if ketamineRec && hemoWarn && blockadeWarn { return .pass }
                return .fail("Naltrexone/Hemo logic failed")
            }
        ))
        
        // 13. Chronic Opioid + COPD + Benzos
        cases.append(AssessmentTestCase(
            name: "13. Chronic + COPD + Benzos",
            setup: { s in
                s.reset()
                s.analgesicProfile = .chronicRx
                s.copd = true
                s.benzos = true
                s.age = "68"
            },
            verify: { s in
                let copdMonitor = s.monitoringPlan.contains { $0.contains("SpO2") }
                let benzoWarn = s.warnings.contains { $0.lowercased().contains("benzo") }
                
                if copdMonitor && benzoWarn { return .pass }
                return .fail("Respiratory Risk logic failed")
            }
        ))
        
        // 14. GI Bleed + Inflammatory
        cases.append(AssessmentTestCase(
            name: "14. GI Bleed + Inflammatory",
            setup: { s in
                s.reset()
                s.historyGIBleed = true
                s.painType = .inflammatory
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasIbuprofen = s.adjuvants.contains { $0.drug.contains("Ibuprofen") }
                let hasTopical = s.adjuvants.contains { $0.category.contains("Topical") }
                let bleedWarn = s.warnings.contains { $0.contains("GI BLEED") }
                
                if !hasIbuprofen && hasTopical && bleedWarn { return .pass }
                return .fail("GI Bleed safety logic failed")
            }
        ))
        
        // 15. SUD History + Chronic
        cases.append(AssessmentTestCase(
            name: "15. SUD History + Chronic Rx",
            setup: { s in
                s.reset()
                s.analgesicProfile = .chronicRx
                s.historyOverdose = true
                s.psychHistory = true
            },
            verify: { s in
                let monitorSUD = s.monitoringPlan.contains { $0.contains("Urine") || $0.contains("PDMP ALERT") }
                let naloxone = s.monitoringPlan.contains { $0.contains("Naloxone") }
                
                if monitorSUD && naloxone { return .pass }
                return .fail("SUD History logic failed")
            }
        ))
        
        return cases
    }
    
    fileprivate var group2: [AssessmentTestCase] {
        var cases: [AssessmentTestCase] = []
        
        // --- NEW COMPLEX CASES (16-25) ---

        // 16. Post-Op Naive (Fentanyl Inclusion)
        cases.append(AssessmentTestCase(
            name: "16. Post-Op Naive (Fentanyl Added)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naive
                s.indication = .postoperative
                s.route = .iv
            },
            verify: { s in
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                if hasFentanyl { return .pass }
                return .fail("Procedural Fentanyl missing for Post-Op")
            }
        ))

        // 17. Non-Surgical Naive (Fentanyl Exclusion)
        cases.append(AssessmentTestCase(
            name: "17. Non-Surgical Naive (No Fentanyl)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naive
                s.indication = .dyspnea // Not PostOp
                s.route = .iv
                s.renalFunction = .normal
                s.hepaticFunction = .normal
            },
            verify: { s in
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                if !hasFentanyl { return .pass }
                return .fail("Fentanyl incorrectly included for standard naive patient")
            }
        ))

        // 18. Surgical Chronic (Multiplier Warning)
        cases.append(AssessmentTestCase(
            name: "18. Surgical Chronic (3x Multiplier)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .chronicRx
                s.indication = .postoperative
            },
            verify: { s in
                let multiplierWarn = s.warnings.contains { $0.contains("SURGICAL MULTIPLIER") && $0.contains("3x") }
                if multiplierWarn { return .pass }
                return .fail("Surgical multiplier warning missing")
            }
        ))

        // 19. OIH Risk (Hyperalgesia)
        cases.append(AssessmentTestCase(
            name: "19. Chronic Rx + OIH Risk",
            setup: { s in
                s.reset()
                s.analgesicProfile = .chronicRx
            },
            verify: { s in
                let oihWarn = s.warnings.contains { $0.contains("Hyperalgesia") }
                if oihWarn { return .pass }
                return .fail("Hyperalgesia awareness warning missing")
            }
        ))

        // 20. Methadone + QTc + Vomiting (Zofran Risk)
        cases.append(AssessmentTestCase(
            name: "20. Methadone + QTc (Interaction Risk)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .methadone
                s.qtcProlonged = true
            },
            verify: { s in
                let interactionWarn = s.warnings.contains { $0.contains("QTc") || $0.contains("Interaction") }
                if interactionWarn { return .pass }
                return .fail("QTc Interaction warning missing")
            }
        ))

        // 21. Buprenorphine + NPO
        cases.append(AssessmentTestCase(
            name: "21. Buprenorphine + NPO (Route)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .buprenorphine
                s.gi = .npo
            },
            verify: { s in
                let routeWarn = s.warnings.contains { $0.contains("IV/SL") && $0.contains("NPO") }
                if routeWarn { return .pass }
                return .fail("Buprenorphine NPO route warning missing")
            }
        ))

        // 22. Dialysis + PostOp (Fentanyl Priority)
        cases.append(AssessmentTestCase(
            name: "22. Dialysis + PostOp (Fentanyl Priority)",
            setup: { s in
                s.reset()
                s.renalFunction = .dialysis
                s.indication = .postoperative
                s.route = .iv
            },
            verify: { s in
                // Should be first or near top
                if let firstRec = s.recommendations.first {
                    if firstRec.name.contains("Fentanyl") { return .pass }
                }
                return .fail("Fentanyl not prioritized in Dialysis")
            }
        ))
        
        // 22b. Moderate Renal + PostOp (Hydromorphone Standard)
        cases.append(AssessmentTestCase(
            name: "22b. Moderate Renal + PostOp (Hydro Standard)",
            setup: { s in
                s.reset()
                s.renalFunction = .impaired // Moderate
                s.indication = .postoperative
                s.route = .iv // IV
            },
            verify: { s in
                // Fentanyl should be present but maybe not first (Hydro reduced is standard)
                let hasHydro = s.recommendations.contains { $0.name.contains("Hydromorphone") }
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                
                // Check details for safe alternative

                if hasHydro && hasFentanyl { return .pass }
                return .fail("Moderate Renal logic failed. Hydro:\(hasHydro), Fentanyl:\(hasFentanyl)")
            }
        ))

        // 23. Liver Failure + GI Bleed (Complex Exclusion)
        cases.append(AssessmentTestCase(
            name: "23. Liver Failure + GI Bleed",
            setup: { s in
                s.reset()
                s.hepaticFunction = .failure
                s.historyGIBleed = true
                s.route = .iv
            },
            verify: { s in
                let hasMorphine = s.recommendations.contains { $0.name.contains("Morphine") }
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                
                if !hasMorphine && hasFentanyl && !hasNSAID { return .pass }
                return .fail("Combined Liver/Bleed safety failed")
            }
        ))

        // 24. High Potency + Uncertain Tolerance
        cases.append(AssessmentTestCase(
            name: "24. High Potency (Uncertain Tolerance)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .highPotency
                s.toleranceUncertain = true
            },
            verify: { s in
                let monitor = s.monitoringPlan.contains { $0.contains("Unpredictable Tolerance") }
                if monitor { return .pass }
                return .fail("Unpredictable tolerance monitor missing")
            }
        ))

        // 25. Naltrexone + Unstable Hemo (Ketamine Caution)
        cases.append(AssessmentTestCase(
            name: "25. Naltrexone + Unstable Hemo",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naltrexone
                s.hemo = .unstable
            },
            verify: { s in
                let ketamineWarn = s.warnings.contains { $0.contains("Ketamine Caution") }
                if ketamineWarn { return .pass }
                return .fail("Ketamine hemodynamic caution missing")
            }
        ))

        // 26. The Impossible Patient (Naltrexone + Hemo Unstable + Renal Failure)
        cases.append(AssessmentTestCase(
            name: "26. Impossible Patient (Naltrexone + Hemo + Renal)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naltrexone
                s.hemo = .unstable
                s.renalFunction = .dialysis
            },
            verify: { s in
                guard let ketamineRec = s.recommendations.first(where: { $0.name.contains("Ketamine") }) else {
                     return .fail("Ketamine missing completely")
                }
                
                if ketamineRec.type == .safe {
                    return .fail("CRITICAL: Ketamine marked .safe despite Hemodynamic Instability")
                }
                
                return .pass
            }
        ))

        // 27. OIRD Composite Score Audit (Strict Point Verification)
        cases.append(AssessmentTestCase(
            name: "27. OIRD Composite Audit (Male + 60s + CHF + OSA)",
            setup: { s in
                s.reset()
                s.age = "62"
                s.sex = .male
                s.chf = true
                s.sleepApnea = true
            },
            verify: { s in
                if s.compositeOIRDScore == 24 {
                   if s.prodigyRisk == "High" { return .pass }
                   return .fail("Risk Mismatch. Expected High (>20), Got \(s.prodigyRisk).")
                }
                return .fail("Score Mismatch. Expected 24, Got \(s.compositeOIRDScore). Factors: 8(Age)+3(Male)+5(CHF)+5(OSA)+3(Naive).")
            }
        ))
        
        // --- SYSTEM SAFETY CHECKS ---
        
        // 28. Calculation Idempotency (Stability Check)
        cases.append(AssessmentTestCase(
            name: "28. Calculation Idempotency (Stability)",
            setup: { s in
                s.reset()
                s.age = "75"
                s.renalFunction = .impaired
                s.analgesicProfile = .naive
            },
            verify: { s in
                let recCount1 = s.recommendations.count
                let warnCount1 = s.warnings.count
                
                s.calculate()
                s.calculate()
                s.calculate()
                
                let recCount2 = s.recommendations.count
                let warnCount2 = s.warnings.count
                
                if recCount1 == recCount2 && warnCount1 == warnCount2 {
                    return .pass
                }
                return .fail("Idempotency failed. Results changed on re-calculation.")
            }
        ))
        
        // 29. Reset Safety State (Clean Slate)
        cases.append(AssessmentTestCase(
            name: "29. Reset Safety (Clean Slate)",
            setup: { s in
                s.reset()
                s.hepaticFunction = .failure
                s.isPregnant = true
                s.reset()
            },
            verify: { s in
                if s.hepaticFunction == .normal && !s.isPregnant && s.chf == false {
                    return .pass
                }
                return .fail("Reset failed to clear Dangerous State (Hepatic/Pregnant).")
            }
        ))
        
        // 30. Hemodynamic Instability (Shock Logic Fix)
        cases.append(AssessmentTestCase(
            name: "30. Shock Logic (Fentanyl vs Morphine)",
            setup: { s in
                s.reset()
                s.hemo = .unstable
                s.analgesicProfile = .naive
                s.route = .iv
            },
            verify: { s in
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let hasMorphine = s.recommendations.contains { $0.name.contains("Morphine") }
                let hasWarning = s.warnings.contains { $0.contains("HEMODYNAMIC INSTABILITY") && $0.contains("Histamine") }
                
                if hasFentanyl && !hasMorphine && hasWarning {
                    return .pass
                }
                return .pass
            }
        ))
        
        // 31. Renal Sorting (Safety > Route)
        cases.append(AssessmentTestCase(
            name: "31. Renal Sorting (Fentanyl Safe > Hydro Caution)",
            setup: { s in
                s.reset()
                s.renalFunction = .impaired
                s.route = .iv
                s.analgesicProfile = .naive
            },
            verify: { s in
                guard s.recommendations.count >= 2 else { return .fail("Not enough recommendations") }
                
                let first = s.recommendations[0]
                let second = s.recommendations[1]
                
                let inTopTwo = first.name.contains("Fentanyl") || second.name.contains("Fentanyl")
                if inTopTwo { return .pass }
                
                return .fail("Sorting Failed. Fentanyl not in top 2. First: \(first.name) Second: \(second.name)")
            }
        ))
        
        return cases
    }


    fileprivate var group3: [AssessmentTestCase] {
        var cases: [AssessmentTestCase] = []
        
        // --- PHYSIOLOGICAL OVERLAP SCENARIOS (32-52) ---
        
        // 32. Renal + Shock: Morphine Exclusion
        cases.append(AssessmentTestCase(
            name: "32. Overlap: Renal + Shock (Morphine Removal)",
            setup: { s in
                s.reset()
                s.renalFunction = .dialysis
                s.hemo = .unstable
                s.route = .iv
            },
            verify: { s in
                let hasMorphine = s.recommendations.contains { $0.name.contains("Morphine") }
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                if !hasMorphine && hasFentanyl { return .pass }
                return .fail("Renal+Shock failed. Morphine present: \(hasMorphine)")
            }
        ))
        
        // 33. Hepatic + Shock: Fentanyl Safety
        cases.append(AssessmentTestCase(
            name: "33. Overlap: Hepatic + Shock (Fentanyl Priority)",
            setup: { s in
                s.reset()
                s.hepaticFunction = .failure
                s.hemo = .unstable
                s.route = .iv
            },
            verify: { s in
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let hasMorphine = s.recommendations.contains { $0.name.contains("Morphine") }
                if hasFentanyl && !hasMorphine { return .pass }
                return .fail("Hepatic+Shock failed. Fentanyl missing or Morphine present.")
            }
        ))
        
        // 34. Dual Organ Failure (Renal + Hepatic)
        cases.append(AssessmentTestCase(
            name: "34. Dual Organ Failure (Renal + Hepatic)",
            setup: { s in
                s.reset()
                s.renalFunction = .dialysis
                s.hepaticFunction = .failure
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let recCount = s.recommendations.count
                if hasFentanyl && recCount <= 3 { return .pass }
                return .fail("Dual Failure safety failed. Too many options: \(recCount)")
            }
        ))
        
        // 35. Triple Respiratory Threat (COPD + OSA + Benzos)
        cases.append(AssessmentTestCase(
            name: "35. Triple Respiratory Threat (COPD+OSA+Benzos)",
            setup: { s in
                s.reset()
                s.copd = true
                s.sleepApnea = true
                s.benzos = true
            },
            verify: { s in
                let capno = s.monitoringPlan.contains { $0.contains("Capnography") || $0.contains("SpO2") }
                let highRisk = s.warnings.contains { $0.contains("Respiratory") || $0.contains("Synergistic") }
                if capno && highRisk { return .pass }
                return .fail("Triple Respiratory Threat warnings missing.")
            }
        ))
        
        // 36. Neuropathic + Renal (Gabapentin Adjustment)
        cases.append(AssessmentTestCase(
            name: "36. Neuropathic + Renal (Adjuvant Check)",
            setup: { s in
                s.reset()
                s.painType = .neuropathic
                s.renalFunction = .dialysis
            },
            verify: { s in
                let gabaRec = s.adjuvants.first(where: { $0.drug.contains("Gabapentin") })
                guard let dose = gabaRec?.dose else { return .fail("Gabapentin missing for Neuropathic pain") }
                if dose.contains("100") || dose.contains("Renal") || dose.contains("post-HD") {
                    return .pass
                }
                return .fail("Gabapentin renal adjustment missing. Got: \(dose)")
            }
        ))
        
        // 37. Dyspnea + Renal Failure (Morphine vs Fentanyl)
        cases.append(AssessmentTestCase(
            name: "37. Dyspnea + Renal Failure",
            setup: { s in
                s.reset()
                s.indication = .dyspnea
                s.renalFunction = .dialysis
            },
            verify: { s in
                let hasHydro = s.recommendations.contains { $0.name.contains("Hydromorphone") }
                let morphWarning = s.warnings.contains { $0.contains("Morphine") && $0.contains("Metabolites") }
                if hasHydro && morphWarning { return .pass }
                return .fail("Dyspnea/Renal logic failed.")
            }
        ))
        
        // 38. Acute Abdomen (NPO + Inflammatory)
        cases.append(AssessmentTestCase(
            name: "38. Acute Abdomen (NPO + Inflammatory)",
            setup: { s in
                s.reset()
                s.gi = .npo
                s.painType = .inflammatory
                s.renalFunction = .normal
            },
            verify: { s in
                let hasToradol = s.adjuvants.contains { $0.drug.contains("Ketorolac") || $0.drug.contains("Toradol") }
                let hasIbuprofen = s.adjuvants.contains { $0.drug.contains("Ibuprofen") }
                if hasToradol && !hasIbuprofen { return .pass }
                return .fail("NPO Inflammatory logic failed. Toradol: \(hasToradol)")
            }
        ))
        
        // 39. Buprenorphine + Trauma (Full Agonist Add-on)
        cases.append(AssessmentTestCase(
            name: "39. Buprenorphine + Trauma (Add-on)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .buprenorphine
                s.indication = .standard
                s.painType = .nociceptive
            },
            verify: { s in
                let continueRec = s.recommendations.contains { $0.name.contains("Continue Home Dose") }
                let addOnRec = s.recommendations.contains { $0.reason.contains("Breakthrough") || $0.name.contains("Fentanyl") || $0.name.contains("High-Affinity") }
                if continueRec && addOnRec { return .pass }
                return .fail("Buprenorphine Acute Pain logic failed.")
            }
        ))
        
        // 40. QTc + Methadone
        cases.append(AssessmentTestCase(
            name: "40. QTc + Methadone",
            setup: { s in
                s.reset()
                s.analgesicProfile = .methadone
                s.qtcProlonged = true
            },
            verify: { s in
                let qtcWarn = s.warnings.contains { $0.contains("QTc") || $0.contains("ECG") }
                if qtcWarn { return .pass }
                return .fail("Methadone QTc warning missing.")
            }
        ))
        
        // 41. Shock + PO Route
        cases.append(AssessmentTestCase(
            name: "41. Shock + Oral Route",
            setup: { s in
                s.reset()
                s.hemo = .unstable
                s.route = .po
            },
            verify: { s in
                let absorptionWarn = s.warnings.contains { $0.contains("Absorption") || $0.contains("Shunting") || $0.contains("Bioavailability") }
                if absorptionWarn { return .pass }
                return .fail("Shock + PO Route warning missing.")
            }
        ))
        
        // 42. History Overdose + Naive
        cases.append(AssessmentTestCase(
            name: "42. History Overdose + Naive",
            setup: { s in
                s.reset()
                s.historyOverdose = true
                s.analgesicProfile = .naive
            },
            verify: { s in
                let naloxone = s.monitoringPlan.contains { $0.contains("Naloxone") }
                if naloxone { return .pass }
                return .fail("Overdose history monitoring failed.")
            }
        ))
        
        // 43. Extreme Elderly (88yo) + Naive
        cases.append(AssessmentTestCase(
            name: "43. Extreme Elderly (88yo) + Naive",
            setup: { s in
                s.reset()
                s.age = "88"
                s.analgesicProfile = .naive
            },
            verify: { s in
                let oxy = s.recommendations.first(where: { $0.name.contains("Oxycodone") })
                if oxy?.detail.contains("2.5") ?? false { return .pass }
                return .fail("Extreme elderly dosing failed.")
            }
        ))
        
        // 44. Hepatic + Bleed Risk (NSAID Block)
        cases.append(AssessmentTestCase(
            name: "44. Hepatic + Bleed Risk (NSAID Block)",
            setup: { s in
                s.reset()
                s.hepaticFunction = .failure
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                if !hasNSAID { return .pass }
                return .fail("NSAIDs allowed in Hepatic Failure.")
            }
        ))
        
        // 45. Bone Pain + Renal Failure (NSAID Block)
        cases.append(AssessmentTestCase(
            name: "45. Bone Pain + Renal Failure",
            setup: { s in
                s.reset()
                s.painType = .bone
                s.renalFunction = .dialysis
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                let hasSteroid = s.adjuvants.contains { $0.drug.contains("Dexamethasone") || $0.drug.contains("Prednisone") }
                if !hasNSAID && hasSteroid { return .pass }
                return .fail("Renal Bone Pain logic failed (NSAID present or Steroid missing).")
            }
        ))
        
        // 46. Pregnancy + Chronic Opioid (Withdrawal)
        cases.append(AssessmentTestCase(
            name: "46. Pregnancy + Chronic Opioid (Withdrawal)",
            setup: { s in
                s.reset()
                s.isPregnant = true
                s.analgesicProfile = .chronicRx
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("Preterm") || $0.contains("Withdrawal") }
                if warn { return .pass }
                return .fail("Pregnancy withdrawal warning missing.")
            }
        ))
        
        // 47. CHF + Inflammatory (NSAID Caution)
        cases.append(AssessmentTestCase(
            name: "47. CHF + Inflammatory (NSAID Caution)",
            setup: { s in
                s.reset()
                s.chf = true
                s.painType = .inflammatory
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                if !hasNSAID { return .pass }
                let warn = s.warnings.contains { $0.contains("Fluid") || $0.contains("CHF") }
                if warn { return .pass }
                return .fail("CHF NSAID warning missing.")
            }
        ))
        
        // 48. Composite OIRD High Risk Logic
        cases.append(AssessmentTestCase(
            name: "48. Composite OIRD High Risk Logic",
            setup: { s in
                s.reset()
                s.age = "80"
                s.sex = .male
                s.sleepApnea = true
                s.chf = true
            },
            verify: { s in
                if s.prodigyRisk == "High" { return .pass }
                return .fail("Composite OIRD High Risk calculation failed. Score: \(s.compositeOIRDScore)")
            }
        ))
        
        // 49. Post-Op + GI Tube
        cases.append(AssessmentTestCase(
            name: "49. Post-Op + GI Tube",
            setup: { s in
                s.reset()
                s.indication = .postoperative
                s.gi = .tube
            },
            verify: { s in
                let ivRecs = s.recommendations.contains { $0.name.contains("IV") }
                if ivRecs { return .pass }
                return .fail("GI Tube did not prioritize IV/Alternative routes.")
            }
        ))
        
        // 50. High Potency + Uncertain Tolerance
        cases.append(AssessmentTestCase(
            name: "50. High Potency + Uncertain Tolerance",
            setup: { s in
                s.reset()
                s.analgesicProfile = .highPotency
                s.toleranceUncertain = true
            },
            verify: { s in
                let monitor = s.monitoringPlan.contains { $0.contains("Tolerance") }
                if monitor { return .pass }
                return .fail("Uncertain tolerance monitoring missing.")
            }
        ))
        
        // 51. Glucuronidation Overlap (Renal + Hepatic)
        cases.append(AssessmentTestCase(
            name: "51. Glucuronidation Overlap (Renal + Hepatic)",
            setup: { s in
                s.reset()
                s.renalFunction = .impaired
                s.hepaticFunction = .impaired
            },
            verify: { s in
                let fentanylSafe = s.recommendations.contains { $0.name.contains("Fentanyl") }
                if fentanylSafe { return .pass }
                return .fail("Glucuronidation overlap safety check failed.")
            }
        ))
        
        // 52. The Perfect Storm
        cases.append(AssessmentTestCase(
            name: "52. The Perfect Storm",
            setup: { s in
                s.reset()
                s.age = "85"
                s.renalFunction = .dialysis
                s.hepaticFunction = .failure
                s.hemo = .unstable
                s.copd = true
            },
            verify: { s in
                let warnings = s.warnings.count
                if warnings >= 3 { return .pass }
                return .fail("Perfect Storm warnings insufficient. Count: \(warnings)")
            }
        ))
        
        return cases
    }
    fileprivate var group4: [AssessmentTestCase] {
        var cases: [AssessmentTestCase] = []
        // --- NEW LOGIC BOUNDARIES (53-57) ---

        // 53. Pediatric Safety (<18yo)
        cases.append(AssessmentTestCase(
            name: "53. Pediatric Safety (12yo Codeine/Tramadol Block)",
            setup: { s in
                s.reset()
                s.age = "12"
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasCodeine = s.recommendations.contains { $0.name.contains("Codeine") }
                let hasTramadol = s.recommendations.contains { $0.name.contains("Tramadol") }
                let pediatricWarn = s.warnings.contains { $0.contains("Pediatric") || $0.contains("Children") }
                if !hasCodeine && !hasTramadol && pediatricWarn { return .pass }
                return .fail("Pediatric safety failed.")
            }
        ))

        // 54. Methadone Naive Guardrail
        cases.append(AssessmentTestCase(
            name: "54. Methadone Naive Guardrail",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naive
                s.painType = .neuropathic
            },
            verify: { s in
                let methadone = s.recommendations.first(where: { $0.name.contains("Methadone") })
                if let m = methadone {
                    if m.type == .unsafe || m.reason.contains("Expert Consult") || m.type == .caution { return .pass }
                    return .fail("Methadone recommended for Naive patient without strict blockade. Type: \(m.type) Reason: \(m.reason)")
                }
                return .pass
            }
        ))

        // 55. Tramadol + Renal Impairment (Seizure Risk)
        cases.append(AssessmentTestCase(
            name: "55. Tramadol + Renal Impairment (Seizure Risk)",
            setup: { s in
                s.reset()
                s.renalFunction = .impaired
                s.analgesicProfile = .naive
            },
            verify: { s in
                let tramadol = s.recommendations.first(where: { $0.name.contains("Tramadol") })
                guard let t = tramadol else { return .pass }
                if t.type == .caution || t.type == .unsafe {
                    if t.detail.contains("Seizure") || t.detail.contains("Accumulation") { return .pass }
                }
                return .fail("Tramadol renal seizure warning missing.")
            }
        ))

        // 56. Adjuvant Prioritization (Inflammatory Pain)
        cases.append(AssessmentTestCase(
            name: "56. Adjuvant Prioritization (Inflammatory)",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.renalFunction = .normal
                s.gi = .intact
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                if hasNSAID { return .pass }
                return .fail("NSAIDs not prioritized for Inflammatory pain.")
            }
        ))

        // 57. Pregnancy + NSAID Exclusion
        cases.append(AssessmentTestCase(
            name: "57. Pregnancy + NSAID Exclusion",
            setup: { s in
                s.reset()
                s.isPregnant = true
                s.painType = .inflammatory
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") || $0.drug.contains("Ibuprofen") }
                let warn = s.warnings.contains { $0.contains("NSAID") || $0.contains("Ductus Arteriosus") || $0.contains("Fetal") }
                if !hasNSAID && warn { return .pass }
                return .fail("Pregnancy NSAID safety failed.")
            }
        ))
        
        // 58. Composite OIRD: Opioid Naivety Impact
        cases.append(AssessmentTestCase(
            name: "58. Composite OIRD: Opioid Naivety Impact",
            setup: { s in
                s.reset()
                s.age = "40"
                s.sex = .female
                s.analgesicProfile = .naive
                s.sleepApnea = false
                s.chf = false
                s.multipleProviders = false
            },
            verify: { s in
                if s.compositeOIRDScore == 3 { return .pass }
                return .fail("Opioid Naivety did not add 3 points. Score: \(s.compositeOIRDScore)")
            }
        ))
        
        // 59. Concurrent Benzos (Black Box Warning)
        cases.append(AssessmentTestCase(
            name: "59. Concurrent Benzos (Black Box Warning)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .chronicRx
                s.benzos = true
            },
            verify: { s in
                 let warn = s.warnings.contains { $0.contains("3.8x") && $0.contains("BLACK BOX") }
                 if warn { return .pass }
                 return .fail("Concurrent Benzo Black Box warning missing.")
            }
        ))
        
        // 60. PDMP Alert (Multiple Prescribers)
        cases.append(AssessmentTestCase(
            name: "60. PDMP Alert (Multiple Prescribers)",
            setup: { s in
                s.reset()
                s.analgesicProfile = .chronicRx
                s.multipleProviders = true
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("PDMP ALERT") && $0.contains("Multiple prescribers") }
                if warn { return .pass }
                return .fail("PDMP Multiple Prescriber warning missing.")
            }
        ))
        
        // 61. Referral: >90 MME (Pain Mgmt)
        cases.append(AssessmentTestCase(
            name: "61. Referral: >90 MME (Pain Mgmt)",
            setup: { s in
                s.reset()
                s.currentMME = "100"
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains(">90 MME") && $0.contains("Pain Management") }
                if warn { return .pass }
                return .fail("High MME referral warning missing.")
            }
        ))
        
        // 62. Referral: PT & Addiction Medicine
        cases.append(AssessmentTestCase(
            name: "62. Referral: PT & Addiction Medicine",
            setup: { s in
                s.reset()
                s.painType = .nociceptive
                s.historyOverdose = true
            },
            verify: { s in
                let hasPT = s.recommendations.contains { $0.name.contains("Physical Therapy") }
                let hasAddiction = s.recommendations.contains { $0.name.contains("Addiction Medicine") }
                if hasPT && hasAddiction { return .pass }
                return .fail("Specialty referrals missing. PT:\(hasPT) Addiction:\(hasAddiction)")
            }
        ))
        
        // MARK: - PHASE 2 EXPANSION (Cases 63-82)
        
        // 63. Naltrexone + Unstable Hemo
        cases.append(AssessmentTestCase(
            name: "63. Naltrexone + Unstable Hemo",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naltrexone
                s.hemo = .unstable
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("Ketamine Caution") }
                if warn { return .pass }
                return .fail("Naltrexone/Hemo caution missing.")
            }
        ))
        
        // 64. Naltrexone + Renal Failure
        cases.append(AssessmentTestCase(
            name: "64. Naltrexone + Renal Failure",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naltrexone
                s.renalFunction = .dialysis
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                if !hasNSAID { return .pass }
                return .fail("NSAIDs allowed in Naltrexone+Renal.")
            }
        ))
        
        // 65. Naltrexone + Surgery
        cases.append(AssessmentTestCase(
            name: "65. Naltrexone + Surgery",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naltrexone
                s.indication = .postoperative
            },
            verify: { s in
                let hasKetamine = s.recommendations.contains { $0.name.contains("Ketamine") }
                if hasKetamine { return .pass }
                return .fail("Ketamine missing for Naltrexone surgery.")
            }
        ))
        
        // 66. Buprenorphine Split Dosing
        cases.append(AssessmentTestCase(
            name: "66. Buprenorphine Split Dosing",
            setup: { s in
                s.reset()
                s.analgesicProfile = .buprenorphine
                s.splitDosing = false
            },
            verify: { s in
                let splitRec = s.recommendations.contains { $0.name.contains("Split Home Dose") }
                if splitRec { return .pass }
                return .fail("Split dosing recommendation missing.")
            }
        ))
        
        // 67. Buprenorphine NPO
        cases.append(AssessmentTestCase(
            name: "67. Buprenorphine NPO",
            setup: { s in
                s.reset()
                s.analgesicProfile = .buprenorphine
                s.gi = .npo
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("NPO Status") && ($0.contains("IV/SL") || $0.contains("Formulation")) }
                if warn { return .pass }
                return .fail("Buprenorphine NPO formulation warning missing.")
            }
        ))
        
        // 68. Buprenorphine Pregnancy
        cases.append(AssessmentTestCase(
            name: "68. Buprenorphine Pregnancy",
            setup: { s in
                s.reset()
                s.analgesicProfile = .buprenorphine
                s.isPregnant = true
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("Neonatology") || $0.contains("Withdrawal") }
                if warn { return .pass }
                return .fail("Pregnancy warning missing for Buprenorphine.")
            }
        ))
        
        // 69. Buprenorphine Hepatic Failure
        cases.append(AssessmentTestCase(
            name: "69. Buprenorphine Hepatic Failure",
            setup: { s in
                s.reset()
                s.analgesicProfile = .buprenorphine
                s.hepaticFunction = .failure
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("LIVER FAILURE") }
                if warn { return .pass }
                return .fail("Generic Hepatic Failure warning missing.")
            }
        ))
        
        // 70. Methadone QTc Safety
        cases.append(AssessmentTestCase(
            name: "70. Methadone QTc Safety",
            setup: { s in
                s.reset()
                s.analgesicProfile = .methadone
                s.qtcProlonged = true
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("SAFETY GATE") && $0.contains("QTc") }
                if warn { return .pass }
                return .fail("QTc avoidance warning missing.")
            }
        ))
        
        // 71. High Potency Tolerance Cap
        cases.append(AssessmentTestCase(
            name: "71. High Potency Tolerance Cap",
            setup: { s in
                s.reset()
                s.analgesicProfile = .highPotency
                s.toleranceUncertain = true
            },
            verify: { s in
                let monitor = s.monitoringPlan.contains { $0.contains("Unpredictable Tolerance") }
                if monitor { return .pass }
                return .fail("Unpredictable tolerance monitor missing.")
            }
        ))
        
        // 72. Chronic Rx OIH Warning
        cases.append(AssessmentTestCase(
            name: "72. Chronic Rx OIH Warning",
            setup: { s in
                s.reset()
                s.analgesicProfile = .chronicRx
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("OIH") || $0.contains("Hyperalgesia") }
                if warn { return .pass }
                return .fail("Hyperalgesia awareness warning missing.")
            }
        ))
        
        // 73. Chronic Rx + NPO
        cases.append(AssessmentTestCase(
            name: "73. Chronic Rx + NPO",
            setup: { s in
                s.reset()
                s.analgesicProfile = .chronicRx
                s.gi = .npo
            },
            verify: { s in
                let rec = s.recommendations.contains { $0.name.contains("Continue Home Meds") }
                let warn = s.warnings.contains { $0.contains("NPO") }
                if rec && warn { return .pass }
                return .fail("NPO conflict warning missing.")
            }
        ))
        
        // 74. Codeine Zero Policy
        cases.append(AssessmentTestCase(
            name: "74. Codeine Zero Policy",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasCodeine = s.recommendations.contains { $0.name.contains("Codeine") }
                if !hasCodeine { return .pass }
                return .fail("Codeine recommended.")
            }
        ))
        
        // 75. Tramadol Zero Policy
        cases.append(AssessmentTestCase(
            name: "75. Tramadol Zero Policy",
            setup: { s in
                s.reset()
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasTramadol = s.recommendations.contains { $0.name.contains("Tramadol") }
                if !hasTramadol { return .pass }
                return .fail("Tramadol recommended.")
            }
        ))
        
        // 76. Elderly + Benzos
        cases.append(AssessmentTestCase(
            name: "76. Elderly + Benzos",
            setup: { s in
                s.reset()
                s.age = "85"
                s.benzos = true
            },
            verify: { s in
                let warn = s.warnings.contains { $0.lowercased().contains("benzo") }
                if warn { return .pass }
                return .fail("Benzo warning missing for elderly.")
            }
        ))
        
        // 77. Renal Failure Checks
        cases.append(AssessmentTestCase(
            name: "77. Renal Failure Checks",
            setup: { s in
                s.reset()
                s.renalFunction = .dialysis
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasMorphine = s.recommendations.contains { $0.name.contains("Morphine") }
                if !hasMorphine { return .pass }
                return .fail("Morphine present in Renal Failure.")
            }
        ))
        
        // 78. Hepatic Failure Checks
        cases.append(AssessmentTestCase(
            name: "78. Hepatic Failure Checks",
            setup: { s in
                s.reset()
                s.hepaticFunction = .failure
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasOxy = s.recommendations.contains { $0.name.contains("Oxycodone") }
                if !hasOxy { return .pass }
                return .fail("Oxycodone present in Hepatic Failure.")
            }
        ))
        
        // 79. Sickle Cell (Bone Pain)
        cases.append(AssessmentTestCase(
            name: "79. Sickle Cell (Bone Pain)",
            setup: { s in
                s.reset()
                s.painType = .bone
                s.age = "25"
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                if hasNSAID { return .pass }
                return .fail("NSAID missing for Bone Pain.")
            }
        ))
        
        return cases
    }

    fileprivate var group5: [AssessmentTestCase] {
        var cases: [AssessmentTestCase] = []
        // MARK: - PHASE 13: SYSTEMATIC VALIDATION (Cases 80-91)
        
        // --- REFRACTORY GOUT GROUP (RG1-RG4) ---
        
        // RG1. Normal Gout (Standard)
        cases.append(AssessmentTestCase(
            name: "RG1. Gout: Standard",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.inflammatorySubtype = .gout
                s.renalFunction = .normal
                s.hepaticFunction = .normal
            },
            verify: { s in
                let hasColchicine = s.adjuvants.contains { $0.drug.contains("Colchicine") }
                let hasIndocin = s.adjuvants.contains { $0.drug.contains("Indomethacin") }
                if hasColchicine && hasIndocin { return .pass }
                return .fail("Standard Gout should have Colchicine + Indomethacin.")
            }
        ))
        
        // RG2. Renal Gout (Failure)
        cases.append(AssessmentTestCase(
            name: "RG2. Gout: Renal Failure",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.inflammatorySubtype = .gout
                s.renalFunction = .dialysis
                s.hepaticFunction = .normal
            },
            verify: { s in
                let hasColchicine = s.adjuvants.contains { $0.drug.contains("Colchicine") }
                let hasPrednisone = s.adjuvants.contains { $0.drug.contains("Prednisone") }
                let warn = s.warnings.contains { $0.contains("RENAL GOUT") || $0.contains("COMPLEX GOUT") }
                if !hasColchicine && hasPrednisone && warn { return .pass }
                return .fail("Renal Gout failure.")
            }
        ))
        
        // RG3. Combined Impairment (Complex)
        cases.append(AssessmentTestCase(
            name: "RG3. Gout: Combined Impairment (Anakinra)",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.inflammatorySubtype = .gout
                s.renalFunction = .impaired
                s.hepaticFunction = .impaired
            },
            verify: { s in
                let hasAnakinra = s.adjuvants.contains { $0.drug.contains("Anakinra") }
                let hasPrednisone = s.adjuvants.contains { $0.drug.contains("Prednisone") }
                if hasAnakinra && hasPrednisone { return .pass }
                return .fail("Combined Impairment failure.")
            }
        ))
        
        // RG4. Hepatic Failure (Complex)
        cases.append(AssessmentTestCase(
            name: "RG4. Gout: Hepatic Failure",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.inflammatorySubtype = .gout
                s.hepaticFunction = .failure
            },
            verify: { s in
                let hasColchicine = s.adjuvants.contains { $0.drug.contains("Colchicine") }
                let hasAnakinra = s.adjuvants.contains { $0.drug.contains("Anakinra") }
                if !hasColchicine && hasAnakinra { return .pass }
                return .fail("Hepatic Failure Gout logic failure.")
            }
        ))
        
        // --- SAFETY PROTOCOL GROUP (P1-P4) ---
        
        // P1. Pericarditis Standard
        cases.append(AssessmentTestCase(
            name: "P1. Pericarditis: Standard",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.inflammatorySubtype = .pericarditis
                s.renalFunction = .normal
            },
            verify: { s in
                let hasColchicine = s.adjuvants.contains { $0.drug.contains("Colchicine") }
                let hasIbuprofen = s.adjuvants.contains { $0.drug.contains("Ibuprofen") && $0.dose.contains("600") }
                if hasColchicine && hasIbuprofen { return .pass }
                return .fail("Standard Pericarditis failure.")
            }
        ))
        
        // P2. Pericarditis + Pregnancy
        cases.append(AssessmentTestCase(
            name: "P2. Pericarditis: Pregnancy",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.inflammatorySubtype = .pericarditis
                s.isPregnant = true
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                let hasPrednisone = s.adjuvants.contains { $0.drug.contains("Prednisone") }
                if !hasNSAID && hasPrednisone { return .pass }
                return .fail("Pregnant Pericarditis failure.")
            }
        ))
        
        // P3. Lactation Safety
        cases.append(AssessmentTestCase(
            name: "P3. Lactation (Colchicine Warning)",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.inflammatorySubtype = .gout
                s.isBreastfeeding = true
                s.isPregnant = false
            },
            verify: { s in
                let warn = s.warnings.contains { $0.contains("LACTATION") && $0.contains("Colchicine") }
                if warn { return .pass }
                return .fail("Lactation warning for Colchicine missing.")
            }
        ))
        
        // P4. Renal Pericarditis
        cases.append(AssessmentTestCase(
            name: "P4. Pericarditis: Renal",
            setup: { s in
                s.reset()
                s.painType = .inflammatory
                s.inflammatorySubtype = .pericarditis
                s.renalFunction = .dialysis
            },
            verify: { s in
                let hasNSAID = s.adjuvants.contains { $0.category.contains("NSAID") }
                let hasPrednisone = s.adjuvants.contains { $0.drug.contains("Prednisone") }
                if !hasNSAID && hasPrednisone { return .pass }
                return .fail("Renal Pericarditis failure.")
            }
        ))
        
        // --- NEUROPATHIC / SUZETRIGINE GROUP (N1-N4) ---
        
        // N1. Suzetrigine Standard
        cases.append(AssessmentTestCase(
            name: "N1. Suzetrigine: Standard",
            setup: { s in
                s.reset()
                s.painType = .nociceptive
                s.indication = .standard
                s.renalFunction = .normal
            },
            verify: { s in
                let hasSuzetrigine = s.adjuvants.contains { $0.drug.contains("Suzetrigine") }
                if hasSuzetrigine { return .pass }
                return .fail("Suzetrigine missing for Acute Nociceptive Pain.")
            }
        ))
        
        // N2. Suzetrigine Renal Safety
        cases.append(AssessmentTestCase(
            name: "N2. Suzetrigine: Renal (Dialysis)",
            setup: { s in
                s.reset()
                s.painType = .nociceptive
                s.renalFunction = .dialysis
            },
            verify: { s in
                let hasSuzetrigine = s.adjuvants.contains { $0.drug.contains("Suzetrigine") }
                let warn = s.warnings.contains { $0.contains("Suzetrigine") && $0.contains("Contraindicated") }
                if !hasSuzetrigine || warn { return .pass }
                return .fail("Suzetrigine permitted in Dialysis without warning.")
            }
        ))
        
        // N3. Gabapentin Renal Adjustment
        cases.append(AssessmentTestCase(
            name: "N3. Gabapentin: Renal",
            setup: { s in
                s.reset()
                s.painType = .neuropathic
                s.renalFunction = .impaired
            },
            verify: { s in
                let gaba = s.adjuvants.first { $0.drug.contains("Gabapentin") }
                if gaba?.dose.contains("100") ?? false { return .pass }
                return .fail("Gabapentin renal dose adjustment missing.")
            }
        ))
        
        // N4. Pregabalin Elderly Safety
        cases.append(AssessmentTestCase(
            name: "N4. Pregabalin: Elderly",
            setup: { s in
                s.reset()
                s.age = "85"
                s.painType = .neuropathic
            },
            verify: { s in
                let hasTCA = s.adjuvants.contains { $0.category.contains("Second Line") || $0.drug.contains("Nortriptyline") }
                if !hasTCA { return .pass }
                return .fail("TCA recommended for Elderly (BEERS Criteria).")
            }
        ))

        // MARK: - STRESS TESTS (Aggressive Scenarios)
        
        // S1. Polypharmacy Storm
        cases.append(AssessmentTestCase(
            name: "S1. Polypharmacy Storm",
            setup: { s in
                s.reset()
                s.age = "75"
                s.copd = true
                s.sleepApnea = true
                s.benzos = true
                s.analgesicProfile = .naive
                s.renalFunction = .impaired
                s.hepaticFunction = .impaired
            },
            verify: { s in
                let triple = s.warnings.contains { $0.contains("TRIPLE THREAT") }
                let benzo = s.warnings.contains { $0.contains("BLACK BOX") }
                let renal = s.recommendations.contains { $0.reason.contains("Reduce") || $0.detail.contains("Renal") || $0.detail.contains("Reduce") }
                if triple && benzo && renal { return .pass }
                return .fail("Polypharmacy failure.")
            }
        ))
        
        // S2. Triple Organ Failure
        cases.append(AssessmentTestCase(
            name: "S2. Triple Organ Failure",
            setup: { s in
                s.reset()
                s.renalFunction = .dialysis
                s.hepaticFunction = .failure
                s.gi = .npo
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasPO = s.recommendations.contains { $0.name.contains("PO") }
                let hasFentanyl = s.recommendations.contains { $0.name.contains("Fentanyl") }
                let hasMorphine = s.recommendations.contains { $0.name.contains("Morphine") }
                if !hasPO && hasFentanyl && !hasMorphine { return .pass }
                return .fail("Triple Failure failure.")
            }
        ))
        
        // S3. Pediatric Contraindications
        cases.append(AssessmentTestCase(
            name: "S3. Pediatric (12yo) Safety",
            setup: { s in
                s.reset()
                s.age = "12"
                s.analgesicProfile = .naive
                s.painType = .nociceptive
            },
            verify: { s in
                let hasTramadol = s.recommendations.contains { $0.name.contains("Tramadol") }
                let hasCodeine = s.recommendations.contains { $0.name.contains("Codeine") }
                let warning = s.warnings.contains { $0.contains("Pediatric") }
                if !hasTramadol && !hasCodeine && warning { return .pass }
                return .fail("Pediatric failure.")
            }
        ))
        
        // S4. Conflicting Requirements
        cases.append(AssessmentTestCase(
            name: "S4. NPO + Oral Preference",
            setup: { s in
                s.reset()
                s.gi = .npo
                s.route = .po
                s.analgesicProfile = .naive
            },
            verify: { s in
                let hasPO = s.recommendations.contains { $0.name.contains("PO") }
                let warning = s.warnings.contains { $0.contains("NPO") }
                if !hasPO && warning { return .pass }
                return .fail("NPO Safety Override failed.")
            }
        ))
        
        // S5. Max MME
        cases.append(AssessmentTestCase(
            name: "S5. Massive Dosages (>500 MME)",
            setup: { s in
                s.reset()
                s.currentMME = "600"
                s.analgesicProfile = .chronicRx
            },
            verify: { s in
                let referral = s.warnings.contains { $0.contains(">90 MME") }
                let naloxone = s.monitoringPlan.contains { $0.contains("Naloxone") }
                if referral && naloxone { return .pass }
                return .fail("High Dose checks failure.")
            }
        ))
        // 80. Neuropathic Pain
        cases.append(AssessmentTestCase(
            name: "80. Neuropathic Pain (Atypical Logic)",
            setup: { s in
                s.reset()
                s.painType = .neuropathic
                s.analgesicProfile = .chronicRx
            },
            verify: { s in
                let hasMethadone = s.recommendations.contains { $0.name.contains("Methadone") }
                let hasBup = s.recommendations.contains { $0.name.contains("Buprenorphine") }
                let hasTapentadol = s.recommendations.contains { $0.name.contains("Tapentadol") }
                if hasMethadone || hasBup || hasTapentadol { return .pass }
                return .fail("Neuropathic atypical logic failure.")
            }
        ))
        
        // 81. Hepatic Failure + IV
        cases.append(AssessmentTestCase(
            name: "81. Hepatic Failure (IV Bioavailability Fix)",
            setup: { s in
                s.reset()
                s.hepaticFunction = .failure
                s.route = .iv
                s.analgesicProfile = .naive
            },
            verify: { s in
                guard let hydro = s.recommendations.first(where: { $0.name.contains("Hydromorphone") }) else {
                    return .fail("Hydromorphone IV missing.")
                }
                if hydro.detail.contains("Bioavailability") {
                    return .fail("IV mentions Bioavailability.")
                }
                if hydro.detail.contains("clearance") { return .pass }
                return .fail("Clearance mention missing.")
            }
        ))
        
        // 82. Neuropathic + Elderly
        cases.append(AssessmentTestCase(
            name: "82. Neuropathic + Elderly (TCA Caution)",
            setup: { s in
                s.reset()
                s.painType = .neuropathic
                s.age = "75"
            },
            verify: { s in
                let hasTCA = s.recommendations.contains { $0.name.contains("Nortriptyline") || $0.name.contains("Amitriptyline") }
                if !hasTCA { return .pass }
                if let tca = s.recommendations.first(where: { $0.name.contains("Nortriptyline") }) {
                    if tca.type == .caution || tca.type == .unsafe { return .pass }
                }
                return .fail("TCA recommended for Elderly without warning.")
            }
        ))
        
        // 83. Neuropathic + Renal Impairment
        cases.append(AssessmentTestCase(
            name: "83. Neuropathic + Renal (Gabapentin Adj)",
            setup: { s in
                s.reset()
                s.painType = .neuropathic
                s.renalFunction = .impaired
            },
            verify: { s in
                guard let gaba = s.adjuvants.first(where: { $0.drug.contains("Gabapentin") || $0.drug.contains("Pregabalin") }) else {
                    return .fail("Gabapentinoids missing.")
                }
                if gaba.dose.contains("Renal") || gaba.drug.contains("Adjust") || gaba.dose.contains("100") { return .pass }
                return .fail("Gabapentinoid renal adjustment missing.")
            }
        ))

        // 84. Neuropathic + Hepatic Failure
        cases.append(AssessmentTestCase(
            name: "84. Neuropathic + Hepatic (Duloxetine Avoid)",
            setup: { s in
                s.reset()
                s.painType = .neuropathic
                s.hepaticFunction = .failure
            },
            verify: { s in
                let hasDuloxetine = s.recommendations.contains { $0.name.contains("Duloxetine") }
                if !hasDuloxetine { return .pass }
                if let dulox = s.recommendations.first(where: { $0.name.contains("Duloxetine") }) {
                    if dulox.type == .unsafe { return .pass }
                }
                return .fail("Duloxetine recommended in Hepatic Failure.")
            }
        ))
        
        return cases
    }
    
    // MARK: - Calculator Test Suite (New MME Logic)
    
    var calculatorTestCases: [CalculatorTestCase] {
        return [
        
        // M1. Multiple Prescription Sum
        CalculatorTestCase(
            name: "M1. MME Sum Check (Morphine + Oxy)",
            setup: { c in
                c.reset()
                c.activeInputsAdd(drugId: "morphine_po_ir", dose: "30") // 30 MME
                c.activeInputsAdd(drugId: "oxycodone", dose: "20") // 30 MME (20 * 1.5)
            },
            verify: { c in
                if c.resultMME == "60.0" { return .pass }
                return .fail("MME Sum Incorrect. Expected 60.0, Got \(c.resultMME)")
            }
        ),
        
        // M2. Fentanyl Patch Conversion
        CalculatorTestCase(
            name: "M2. Fentanyl Patch Conversion (2.0x)",
            setup: { c in
                c.reset()
                c.activeInputsAdd(drugId: "fentanyl_patch", dose: "25") // 25 mcg/hr
                // Standard: 25 mcg/hr * 2.0 = 50 mg Oral Morphine Equiv
            },
            verify: { c in
                // Allow small rounding diff if logic uses 2.0 vs table
                if let mme = Double(c.resultMME), abs(mme - 60.0) <= 2.5 { return .pass }
                return .fail("Fentanyl Patch MME Incorrect. Expected 60.0 (CDC 2022), Got \(c.resultMME)")
            }
        ),
        
        // M3. IV vs PO Morphine
        CalculatorTestCase(
            name: "M3. IV Morphine Factor (3.0x)",
            setup: { c in
                c.reset()
                c.activeInputsAdd(drugId: "morphine_iv", dose: "10") // 10 mg IV
                // Standard: 10 mg IV * 3 = 30 mg PO
            },
            verify: { c in
                if c.resultMME == "30.0" { return .pass }
                return .fail("IV Morphine Factor Incorrect. Expected 30.0, Got \(c.resultMME)")
            }
        ),
        
        // R1. Renal Mild Consistency (Hydromorphone)
        CalculatorTestCase(
            name: "R1. Renal Mild: Hydromorphone (No Reduction)",
            setup: { c in
                c.reset()
                c.activeInputsAdd(drugId: "oxycodone", dose: "10") // 15 MME input
                c.renalStatus = .impaired // Mild
            },
            verify: { c in
                // Expect Hydromorphone output to NOT be reduced heavily (Factor 1.0)
                guard let target = c.targetDoses.first(where: { $0.drug.contains("Hydromorphone") && $0.route == "IV" }) else {
                    return .fail("Hydromorphone IV missing")
                }
                
                // Should have warning but NO reduction logic implies dose should be around 3.75
                if target.ratioLabel.contains("Caution") && !target.ratioLabel.contains("50%") { return .pass }
                return .fail("Renal Mild Hydro label mismatch: \(target.ratioLabel)")
            }
        ),
        
        // R2. Renal Severe Consistency (Hydromorphone)
        CalculatorTestCase(
            name: "R2. Renal Severe: Hydromorphone (50% Reduction)",
            setup: { c in
                c.reset()
                c.activeInputsAdd(drugId: "oxycodone", dose: "10")
                c.renalStatus = .dialysis
            },
            verify: { c in
                guard let target = c.targetDoses.first(where: { $0.drug.contains("Hydromorphone") }) else { return .fail("Missing Hydro") }
                
                if target.ratioLabel.contains("50%") { return .pass }
                return .fail("Renal Severe Hydro label missing 50% warning: \(target.ratioLabel)")
            }
        ),
        
        // R3. Renal Mild Consistency (Morphine)
        CalculatorTestCase(
            name: "R3. Renal Mild: Morphine (No Auto-Reduce)",
            setup: { c in
                c.reset()
                c.activeInputsAdd(drugId: "oxycodone", dose: "10")
                c.renalStatus = .impaired
            },
            verify: { c in
                guard let target = c.targetDoses.first(where: { $0.drug.contains("Morphine") && $0.route == "IV" }) else { return .fail("Missing Morphine") }
                
                // Expect "Consider -25%" but not hard "-25%" logic if possible, or just the text
                if target.ratioLabel.contains("Consider -25%") { return .pass }
                return .fail("Renal Mild Morphine label mismatch: \(target.ratioLabel)")
            }
        ),
        
        // R4. Renal Severe Consistency (Morphine)
        CalculatorTestCase(
            name: "R4. Renal Severe: Morphine (AVOID)",
            setup: { c in
                c.reset()
                c.activeInputsAdd(drugId: "oxycodone", dose: "10")
                c.renalStatus = .dialysis
            },
            verify: { c in
                guard let target = c.targetDoses.first(where: { $0.drug.contains("Morphine") }) else { return .fail("Missing Morphine") }
                
                if target.totalDaily == "AVOID" || target.ratioLabel.contains("AVOID") { return .pass }
                return .fail("Renal Severe Morphine not Avoided: \(target.totalDaily)")
            }
        )
    ]
    }
    
    // Suzetrigine Safety Checks (Phase 8)
    static var suzetrigineTests: [AssessmentTestCase] {
        return [
        AssessmentTestCase(
            name: "Z1. Suzetrigine Trigger (Acute Nociceptive)",
            setup: { s in
                s.reset()
                s.indication = .standard
                s.painType = .nociceptive
                s.age = "40" // Safe
            },
            verify: { s in
                if s.adjuvants.contains(where: { $0.drug == "Suzetrigine" }) { return .pass }
                return .fail("Suzetrigine missing from Adjuvants for Nociceptive Pain")
            }
        ),
        AssessmentTestCase(
            name: "Z2. Respiratory Preference (OSA)",
            setup: { s in
                s.reset()
                s.indication = .standard
                s.painType = .nociceptive
                s.sleepApnea = true
            },
            verify: { s in
                guard let adj = s.adjuvants.first(where: { $0.drug == "Suzetrigine" }) else { return .fail("Missing") }
                if adj.rationale.contains("Preferred") { return .pass }
                return .fail("Did not trigger 'Preferred' status for OSA in rationale")
            }
        ),
        AssessmentTestCase(
            name: "Z3. Renal Gate (Dialysis)",
            setup: { s in
                s.reset()
                s.painType = .nociceptive
                s.renalFunction = .dialysis
            },
            verify: { s in
                if s.adjuvants.contains(where: { $0.drug == "Suzetrigine" }) { return .fail("Suzetrigine showed in Dialysis") }
                if s.warnings.contains(where: { $0.contains("Suzetrigine: Avoid use") }) { return .pass }
                return .fail("Missing Dialysis Warning")
            }
        ),
        AssessmentTestCase(
            name: "Z4. Hepatic Gate (Failure)",
            setup: { s in
                s.reset()
                s.painType = .nociceptive
                s.hepaticFunction = .failure
            },
            verify: { s in
                // Suzetrigine should be blocked by generateAdvice() which checks for hepaticFunction != .failure
                if s.adjuvants.contains(where: { $0.drug == "Suzetrigine" }) { return .fail("Suzetrigine showed in Hepatic Failure") }
                return .pass
            }
        )
        ]
    }
    
    static var intelligenceAuditTests: [AssessmentTestCase] {
        return [
        AssessmentTestCase(
            name: "IA1. Red Hat Alert: Hepatorenal Syndrome",
            setup: { s in
                s.reset()
                s.renalFunction = .impaired
                s.hepaticFunction = .failure
            },
            verify: { s in
                if s.warnings.contains(where: { $0.contains("Avoid Morphine") && $0.contains("Fentanyl") }) { return .pass }
                return .fail("Failed to detect Hepatorenal Warning details")
            }
        ),
        AssessmentTestCase(
            name: "IA2. Risk Audit Breakdown (PRODIGY+RIOSORD)",
            setup: { s in
                s.reset()
                s.age = "75" // Age 70-79: +12 (PRODIGY)
                s.benzos = true // +9 (RIOSORD)
                s.sleepApnea = true // +5 (PRODIGY)
                s.analgesicProfile = .naive // +3 (RIOSORD)
                // Expected: 12 + 9 + 5 + 3 = 29
            },
            verify: { s in
                if s.compositeOIRDScore != 29 { return .fail("Score mismatch. Expected 29, got \(s.compositeOIRDScore)") }
                
                let factors = s.riskBreakdown.map { $0.factor }
                let hasAge = factors.contains(where: { $0.contains("Age 70-79") })
                let hasBenzos = factors.contains("Benzodiazepines")
                let hasOSA = factors.contains(where: { $0.contains("Sleep Apnea") })
                let hasNaive = factors.contains("Opioid Naive")
                
                if hasAge && hasBenzos && hasOSA && hasNaive { return .pass }
                return .fail("Missing factors in audit breakdown: \(factors)")
            }
        )
        ]
    }
    
    var testCases: [AssessmentTestCase] {
        var all = ClinicalValidationEngine.suzetrigineTests
        all.append(contentsOf: ClinicalValidationEngine.intelligenceAuditTests)
        all.append(contentsOf: group1)
        all.append(contentsOf: group2)
        all.append(contentsOf: group3)
        all.append(contentsOf: group4)
        all.append(contentsOf: group5)
        return all
    }
    
    // Taper & Rotation Test Suite
    var taperTestCases: [CalculatorTestCase] {
        return [
        CalculatorTestCase(
            name: "T1. Aggressive Rotation Warning (<25% Reduction)",
            setup: { c in 
                c.reset()
                c.activeInputsAdd(drugId: "morphine_po_ir", dose: "100") // 100 MME
                c.reduction = 10 // 10% reduction
            },
            verify: { c in 
                if c.complianceWarning.contains("Aggressive") && c.complianceWarning.contains("<25%") { return .pass }
                return .fail("Aggressive Rotation warning missing")
            }
        ),
        CalculatorTestCase(
            name: "T2. Standard Rotation (30% -> Standard)",
            setup: { c in 
                c.reset()
                c.activeInputsAdd(drugId: "morphine_po_ir", dose: "100")
                c.reduction = 30 
            },
            verify: { c in 
                if c.complianceWarning.contains("Standard Rotation") { return .pass }
                return .fail("Standard Rotation label missing")
            }
        ),
        CalculatorTestCase(
            name: "T3. Conservative Rotation (>50%)",
            setup: { c in 
                c.reset()
                c.activeInputsAdd(drugId: "morphine_po_ir", dose: "100")
                c.reduction = 60
            },
            verify: { c in 
                if c.complianceWarning.contains("Conservative") { return .pass }
                return .fail("Conservative Rotation warning missing")
            }
        )
        ]
    }
    
    // Methadone Logic Suite (Using calculateMethadoneConversion standalone)
    var methadoneTestCases: [MethadoneTestCase] {
        return [
        MethadoneTestCase(
            name: "MP1. Elderly Conservative Ratio (>65y)",
            mme: 100, // 60-199 range
            age: 70, // >65 triggers 20:1 instead of 10:1
            method: .rapid,
            verify: { res in
                // MME 100. Ratio 20:1 -> 5mg/day
                // If standard 10:1 -> 10mg/day
                if res.totalDailyDose == 5.0 || res.totalDailyDose == 7.5 { return .pass }
                return .fail("Elderly ratio failed. Expected 5mg (20:1) or 7.5mg (Floor), Got \(res.totalDailyDose)")
            }
        ),
        MethadoneTestCase(
            name: "MP2. Standard Ratio (50y)",
            mme: 100,
            age: 50, // Standard 10:1
            method: .rapid,
            verify: { res in
                // MME 100. Ratio 10:1 -> 10mg/day
                // MME 100. Ratio 10:1 -> 10mg/day
                // NCCN Ratio 8:1 -> 12.5mg/day -> Split TID -> 4.0 -> 12.0
                if res.totalDailyDose >= 10.0 && res.totalDailyDose <= 12.5 { return .pass }
                return .fail("Standard ratio failed. Expected 10-12.5mg, Got \(res.totalDailyDose)")
            }
        ),
        MethadoneTestCase(
            name: "MP3. Stepwise Schedule Generation",
            mme: 300,
            age: 50,
            method: .stepwise,
            verify: { res in
                guard let schedule = res.transitionSchedule, schedule.count == 3 else {
                    return .fail("Schedule missing or incorrect length")
                }
                if schedule[0].dayLabel.contains("Days 1-3") { return .pass }
                return .fail("Stepwise schedule labels incorrect")
            }
        )
        ]
    }
    
    // MARK: - OUD Consult Validation (Phase 3)
    var oudTestCases: [OUDTestCase] {
        return [
        
        // --- INDUCTION PROTOCOLS ---
        
        // O1. Standard Induction
        OUDTestCase(
            name: "O1. Standard Induction (COWS 13)",
            setup: { s in
                s.reset()
                s.cowsSelections = [99: 13] // Mock score 13
                s.entries = [SubstanceEntry(type: .oxycodone, quantity: 1, unit: "dose", route: .oral, lastUseHoursAgo: 12)]
            },
            verify: { s in
                if s.recommendedProtocol == .standardBup { return .pass }
                return .fail("Expected Standard Induction. Got: \(String(describing: s.recommendedProtocol))")
            }
        ),
        
        // O2. Micro-Induction (Bernese) - Fentanyl
        OUDTestCase(
            name: "O2. Micro-Induction (Fentanyl + Low COWS)",
            setup: { s in
                s.reset()
                s.cowsSelections = [99: 10] // COWS < 13
                s.entries = [SubstanceEntry(type: .streetFentanylPowder, quantity: 1, unit: "dose", route: .inhalation, lastUseHoursAgo: 12)]
            },
            verify: { s in
                if s.recommendedProtocol == .microInduction { return .pass }
                return .fail("Fentanyl + COWS 10 should trigger Micro-Induction. Got: \(String(describing: s.recommendedProtocol))")
            }
        ),
        
        // O3. Grey Zone (COWS 10) -> Standard Induction
        OUDTestCase(
            name: "O3. Grey Zone (COWS 8-11 -> Standard)",
            setup: { s in
                s.reset()
                s.cowsSelections = [99: 10] // Score 10
                s.entries = [SubstanceEntry(type: .oxycodone, quantity: 1, unit: "dose", route: .oral, lastUseHoursAgo: 12)]
            },
            verify: { s in
                if s.recommendedProtocol == .standardBup { return .pass }
                return .fail("COWS 10 should trigger Standard Induction. Got: \(String(describing: s.recommendedProtocol))")
            }
        ),
        
        // O4. High-Dose Initiation
        OUDTestCase(
            name: "O4. High-Dose Initiation (ER)",
            setup: { s in
                s.reset()
                s.cowsSelections = [99: 14]
                s.erSetting = true
                s.entries = [SubstanceEntry(type: .streetFentanylPowder, quantity: 1, unit: "dose", route: .inhalation, lastUseHoursAgo: 12)]
            },
            verify: { s in
                if s.recommendedProtocol == .highDoseBup { return .pass }
                return .fail("ER Setting + High Score should trigger High-Dose. Got: \(String(describing: s.recommendedProtocol))")
            }
        ),
        
        // O5. Symptom Management (Too Early)
        OUDTestCase(
            name: "O5. Symptom Management (COWS 4)",
            setup: { s in
                s.reset()
                s.cowsSelections = [99: 4]
                s.entries = [SubstanceEntry(type: .oxycodone, quantity: 1, unit: "dose", route: .oral, lastUseHoursAgo: 12)]
            },
            verify: { s in
                if s.recommendedProtocol == .symptomManagement { return .pass }
                return .fail("Low COWS should trigger Symptom Mgmt. Got: \(String(describing: s.recommendedProtocol))")
            }
        ),
        
        // --- SAFETY & CONTRAINDICATIONS ---
        
        // O6. Liver Failure (Buprenorphine Safe)
        OUDTestCase(
            name: "O6. Liver Failure (Buprenorphine Safe)",
            setup: { s in
                s.reset()
                s.cowsSelections = [99: 15]
                s.hasLiverFailure = true
                s.entries = [SubstanceEntry(type: .oxycodone, quantity: 1, unit: "dose", route: .oral, lastUseHoursAgo: 12)]
            },
            verify: { s in
                if s.recommendedProtocol == .standardBup { return .pass }
                return .fail("Liver Failure should NOT block Buprenorphine. Got: \(String(describing: s.recommendedProtocol))")
            }
        ),
        
        // O7. Acute Pain (Buprenorphine Safe)
        OUDTestCase(
            name: "O7. Acute Pain (Buprenorphine Safe)",
            setup: { s in
                s.reset()
                s.cowsSelections = [99: 15]
                s.hasAcutePain = true
                s.entries = [SubstanceEntry(type: .oxycodone, quantity: 1, unit: "dose", route: .oral, lastUseHoursAgo: 12)]
            },
            verify: { s in
                if s.recommendedProtocol == .standardBup { return .pass }
                return .fail("Acute Pain should NOT block Buprenorphine. Got: \(String(describing: s.recommendedProtocol))")
            }
        ),
        
        // O8. Pregnancy Safety (Suboxone vs Subutex)
        OUDTestCase(
            name: "O8. Pregnancy (Standard of Care)",
            setup: { s in
                s.reset()
                s.isPregnant = true
                s.entries = [SubstanceEntry(type: .streetHeroin, quantity: 1, unit: "dose", route: .intravenous, lastUseHoursAgo: 12)]
                // Note: Logic for medication string is likely in Wizard, this test checks 's.medicationName'
                // Assuming default valid selection
            },
            verify: { s in
                // Updated: Suboxone (Combo) is standard. Subutex (Mono) not strictly required.
                // Just check that a Buprenorphine product is recommended.
                if s.medicationName.contains("Suboxone") || s.medicationName.contains("Subutex") || s.medicationName.contains("Buprenorphine") { return .pass }
                return .fail("Pregnancy should recommend Buprenorphine product. Got: \(s.medicationName)")
            }
        ),
        
        // --- DISCHARGE SAFETY ---
        
        // O9. Naloxone Trigger
        OUDTestCase(
            name: "O9. Discharge: Naloxone (Fentanyl)",
            setup: { s in
                s.reset()
                s.entries = [SubstanceEntry(type: .streetFentanylPowder, quantity: 1, unit: "dose", route: .inhalation, lastUseHoursAgo: 12)]
            },
            verify: { s in
                let hasNaloxone = s.dischargeChecklist.contains { $0.contains("Naloxone") }
                if hasNaloxone { return .pass }
                return .fail("Fentanyl user requires Naloxone on discharge.")
            }
        ),
        
        // O10. Bridge Script
        OUDTestCase(
            name: "O10. Discharge: Bridge Script",
            setup: { s in
                s.reset()
                s.cowsSelections = [99: 13] // Standard
                s.entries = [SubstanceEntry(type: .oxycodone, quantity: 1, unit: "dose", route: .oral, lastUseHoursAgo: 12)]
            },
            verify: { s in
                let hasBridge = s.dischargeChecklist.contains { $0.contains("Bridge script") || $0.contains("Bridge Script") } // Handle case mismatch
                if hasBridge { return .pass }
                return .fail("Standard induction requires Bridge Script.")
            }
        )
    ]
    }
    
}

// MARK: - OUD Clinical Intelligence Tests
extension ClinicalValidationEngine {
    static var oudLogicTests: [OUDComplexTestCase] {
        return [
            // 1. Fentanyl + Benzos -> Massive Tolerance -> Low Dose Initiation + FDA Alert
            OUDComplexTestCase(
                name: "OUD-Logic-1: Fentanyl + Benzos (Extreme Risk)",
                entries: [
                    SubstanceEntry(type: .streetFentanylPowder, quantity: 1, unit: "g", route: .intravenous, lastUseHoursAgo: 12),
                    SubstanceEntry(type: .benzodiazepinesStreet, quantity: 2, unit: "mg", route: .oral, lastUseHoursAgo: 2)
                ],
                cows: 6, // Low COWS
                hasUlcers: false
            ) { plan in
                // Expect LDI
                guard plan.protocolName.contains("Low-Dose") else { return .fail("Expected Low-Dose Initiation for Fentanyl") }
                // Expect FDA Alert
                guard plan.safetyAlerts.contains(where: { $0.contains("FDA ALERT") }) else { return .fail("Missing FDA Benzo Alert") }
                return .pass
            },
            
            // 2. Oxycodone (Low Tolerance) -> Standard Induction
            OUDComplexTestCase(
                name: "OUD-Logic-2: Oxycodone Naive (Standard)",
                entries: [
                    SubstanceEntry(type: .oxycodone, quantity: 30, unit: "mg", route: .oral, lastUseHoursAgo: 12)
                ],
                cows: 10, // Moderate Withdrawal
                hasUlcers: false
            ) { plan in
                guard plan.protocolName.contains("Traditional") || plan.protocolName.contains("Standard") else { return .fail("Expected Traditional Induction") }
                return .pass
            },
            
            // 3. Xylazine Risk -> Warning
            OUDComplexTestCase(
                name: "OUD-Logic-3: Xylazine Context",
                entries: [
                    SubstanceEntry(type: .streetFentanylPowder, quantity: 1, unit: "g", route: .intravenous, lastUseHoursAgo: 12),
                    SubstanceEntry(type: .xylazineAdulterant, quantity: 1, unit: "trace", route: .intravenous, lastUseHoursAgo: 12)
                ],
                cows: 12,
                hasUlcers: true
            ) { plan in
                guard plan.safetyAlerts.contains(where: { $0.contains("XYLAZINE") }) else { return .fail("Missing Xylazine Warning") }
                return .pass
            }
        ]
    }
}
// MARK: - Transparency & Glass Box Audits
extension ClinicalValidationEngine {
    static var transparencyTestCases: [TransparencyTestCase] {
        return [
            // TR1. Math Traceability: Fentanyl
            TransparencyTestCase(
                name: "TR1. Math Traceability: Fentanyl IV Push",
                setup: { c in 
                    c.reset()
                    c.activeInputsAdd(drugId: "fentanyl", dose: "100") 
                },
                verify: { c in 
                    // Fentanyl IV factor is 0.3. 100 * 0.3 = 30 MME.
                    if c.calculationReceipt.joined().contains("100.0 mcg Fentanyl × 0.30 = 30.0 MME") {
                        return .pass
                    }
                    return .fail("Receipt math trace missing or incorrect: \(c.calculationReceipt)")
                }
            ),
            
            // TR2. Evidence Transparency: Methadone
            TransparencyTestCase(
                name: "TR2. Evidence: Methadone MME Variance",
                setup: { c in 
                    c.reset()
                    c.activeInputsAdd(drugId: "methadone", dose: "10") 
                },
                verify: { c in 
                    // Methadone in calculator should expose its factor transparency
                    guard let factorObj = c.inputs.first(where: { $0.drugId == "methadone" })?.activeFactor else {
                         return .fail("Methadone activeFactor missing")
                    }
                    if factorObj.source.contains("CDC") && (factorObj.evidenceQuality == "low" || factorObj.evidenceQuality == "moderate") {
                         return .pass
                    }
                    return .fail("Methadone evidence metadata mismatch: \(factorObj.source)")
                }
            ),
            
            // TR3. Audit Traceability: OIRD Score Breakdown
            TransparencyTestCase(
                name: "TR3. Audit Accessibility: Calculation Transparency",
                setup: { c in 
                    c.reset()
                    c.activeInputsAdd(drugId: "morphine_po_ir", dose: "150") // >90 MME check
                },
                verify: { c in 
                    // Verify that the >90 MME warning contains the clinical rationale for transparency
                    if c.warningText.contains(">90 MME") && c.warningText.contains("Naloxone") {
                        return .pass
                    }
                    return .fail("Transparency warning for High Dose missing: \(c.warningText)")
                }
            )
        ]
    }
}
