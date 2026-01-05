import Foundation
import Combine
import SwiftUI

// MARK: - Enums
// AnalgesicProfile is NOT in ClinicalData.swift, so we define it here.
enum AnalgesicProfile: String, CaseIterable, Identifiable, Codable {
    case naive = "Opioid Naive"
    case chronicRx = "Chronic Rx Opioids (Pain)"
    case highPotency = "High-Potency / Fentanyl"
    case buprenorphine = "Buprenorphine (MAT)"
    case methadone = "Methadone (MAT)"
    case naltrexone = "Naltrexone / Vivitrol"
    
    var id: String { self.rawValue }
}

// MARK: - Store
class AssessmentStore: ObservableObject, CalculatorInputs {
    
    // --- INPUTS ---
    @Published var age: String = "" { didSet { calculate() } }
    @Published var currentMME: String = "" { didSet { calculate() } } // Referral Logic Input
    @Published var sex: Sex = .female { didSet { calculate() } }
    
    // Analgesic Profile
    @Published var analgesicProfile: AnalgesicProfile = .naive { didSet { calculate() } }
    
    // Modifiers
    @Published var qtcProlonged: Bool = false { didSet { calculate() } }
    @Published var splitDosing: Bool = false { didSet { calculate() } }
    @Published var toleranceUncertain: Bool = true { didSet { calculate() } }
    @Published var postOpNPO: Bool = false { didSet { calculate() } }

    // Clinical Parameters
    @Published var renalFunction: RenalStatus = .normal { didSet { calculate() } }
    @Published var hepaticFunction: HepaticStatus = .normal { didSet { calculate() } }
    @Published var hemo: Hemodynamics = .stable { didSet { calculate() } }
    @Published var gi: GIStatus = .intact { didSet { calculate() } }
    @Published var route: OpioidRoute = .both { didSet { calculate() } }
    @Published var indication: ClinicalIndication = .standard { didSet { calculate() } }
    @Published var painType: PainType = .nociceptive { didSet { calculate() } }

    // Risk Factors
    @Published var sleepApnea: Bool = false { didSet { calculate() } }
    @Published var chf: Bool = false { didSet { calculate() } }
    @Published var benzos: Bool = false { didSet { calculate() } }
    @Published var copd: Bool = false { didSet { calculate() } }
    @Published var psychHistory: Bool = false { didSet { calculate() } }
    @Published var historyOverdose: Bool = false { didSet { calculate() } }
    @Published var multipleProviders: Bool = false { didSet { calculate() } } // PDMP Integration
    @Published var historyGIBleed: Bool = false { didSet { calculate() } } // Question 6
    @Published var isPregnant: Bool = false { didSet { calculate() } }

    // Computed Properties
    var isRenalImpaired: Bool { renalFunction == .impaired || renalFunction == .dialysis }
    var isHepaticFailure: Bool { hepaticFunction == .failure }
    var isElderly: Bool { (Int(age) ?? 0) >= 70 }
    var isPediatric: Bool { (Int(age) ?? 20) < 18 }
    
    var generatedSummary: String {
        let ageStr = age.isEmpty ? "??" : age
        let sexStr = sex == .male ? "M" : "F"
        
        // Sentence 1: Presentation
        // "**62M** presenting with **acute nociceptive pain**."
        
        let painDesc: String
        switch painType {
        case .nociceptive: painDesc = "nociceptive pain"
        case .neuropathic: painDesc = "neuropathic pain"
        case .inflammatory: painDesc = "inflammatory pain"
        case .bone: painDesc = "bone pain"
        }
        
        // Setting
        // "presenting with" covers the acute setting implicitly, OR we add "in the perioperative setting"
        var settingPhrase = "presenting with"
        switch indication {
        case .postoperative: settingPhrase = "presenting (perioperative) with"
        case .dyspnea: settingPhrase = "presenting with palliative dyspnea and"
        case .cancer: settingPhrase = "presenting with cancer-related"
        default: break 
        }
        
        let sentence1 = "**\(ageStr)\(sexStr)** \(settingPhrase) **\(painDesc)**."
        
        // Sentence 2: Patient Context
        // "Patient is **opioid naive** with **reduced renal function**."
        
        // Analgesic Status
        let status: String
        switch analgesicProfile {
        case .naive: status = "opioid naive"
        case .chronicRx: status = "on home chronic opioids"
        case .highPotency: status = "using high-potency opioids"
        case .buprenorphine: status = "on Buprenorphine"
        case .methadone: status = "on Methadone"
        case .naltrexone: status = "on Naltrexone blockade"
        }
        
        var conditions: [String] = []
        
        // Comorbidities that matter for summary
        if renalFunction != .normal { conditions.append(renalFunction == .dialysis ? "ESRD" : "reduced renal function") }
        if hepaticFunction != .normal { conditions.append(hepaticFunction == .failure ? "hepatic failure" : "hepatic impairment") }
        if hemo == .unstable { conditions.append("hemodynamic instability") }
        if chf { conditions.append("CHF") }
        if copd { conditions.append("COPD") }
        if gi == .npo || postOpNPO { conditions.append("NPO status") }
        if historyGIBleed { conditions.append("active/recent GI bleed") }
        if isPregnant { conditions.append("active pregnancy") }
        if sleepApnea { conditions.append("OSA") }
        if benzos { conditions.append("concurrent benzodiazepine use") }
        if historyOverdose { conditions.append("history of overdose") }
        
        let conditionString: String
        if conditions.isEmpty {
            conditionString = "."
        } else {
            // Join with commas and "and" for the last one
            if conditions.count == 1 {
                conditionString = " with **\(conditions[0])**."
            } else {
                let last = conditions.last!
                let rest = conditions.dropLast().joined(separator: ", ")
                conditionString = " with **\(rest)** and **\(last)**."
            }
        }
        
        let sentence2 = "Patient is **\(status)**\(conditionString)"
        
        return "\(sentence1) \(sentence2)"
    }

    // --- OUTPUTS ---
    @Published var recommendations: [DrugRecommendation] = []
    @Published var adjuvants: [AdjuvantRecommendation] = []
    @Published var warnings: [String] = []
    @Published var monitoringPlan: [String] = []
    
    @Published var prodigyScore: Int = 0
    @Published var prodigyRisk: String = "Low"
    
    let didUpdate = PassthroughSubject<Void, Never>()
    
    init() { calculate() }

    // MARK: - MAIN CALCULATION ENGINE
    func calculate() {
        // Reset Outputs
        var recs: [DrugRecommendation] = []
        var warns: [String] = []
        var monitors: [String] = []
        var adjs: [AdjuvantRecommendation] = []

        // 1. PRODIGY SCORING
        var pScore = 0
        if let ageInt = Int(age) {
            if ageInt >= 80 { pScore += 16 }
            else if ageInt >= 70 { pScore += 12 }
            else if ageInt >= 60 { pScore += 8 }
        }
        if sex == .male { pScore += 3 } // Corrected: 3 points (Khanna et al.)
        if analgesicProfile == .naive { pScore += 3 }
        if sleepApnea { pScore += 5 }
        if chf { pScore += 5 } // Corrected: 5 points (Khanna et al.)
        
        // Benzo Warning
        if benzos {
            warns.append("⚠️ POLYPHARMACY: Concurrent Benzos increase overdose risk 3.8x (Black Box). STOP or Taper.")
            // Standard PRODIGY does not include Benzos in the score itself, though it's a risk factor.
        }
        
        // PDMP Warning
        if multipleProviders {
            warns.append("⚠️ PDMP ALERT: Multiple prescribers detected. Verify total MME. Risk scores do not replace judgment.")
        }
        
        self.prodigyScore = pScore
        self.prodigyRisk = pScore >= 15 ? "High" : (pScore >= 8 ? "Intermediate" : "Low")
        
        if pScore >= 15 { monitors.append("⚠️ PRODIGY High Risk: Continuous Capnography + Pulse Oximetry recommended.") }
        else if pScore >= 8 { monitors.append("PRODIGY Intermediate: Consider Capnography.") }
        
        if copd { monitors.append("COPD: Target SpO2 88-92% to prevent CO2 retention.") }
        
        // 1.1 TRIPLE RESPIRATORY THREAT (Case 35)
        if copd && sleepApnea && benzos {
            warns.append("⚠️ TRIPLE THREAT: Synergistic CNS Depression (COPD + OSA + Benzos). Risk of rapid desaturation.")
        }
        
        // 1.2 PEDIATRIC SAFETY (Case 53)
        if isPediatric {
            warns.append("⚠️ Pediatric Patient: Codeine and Tramadol are CONTRAINDICATED (FDA Black Box).") // Case 57 Safety
        }

        // 2. HELPERS
        func getStartingDose(drug: String, route: String) -> String {
            guard analgesicProfile == .naive else { return "Titrate to effect" }
            
            switch (drug, route) {
            case ("Fentanyl", "IV"): return isElderly ? "Start 12.5mcg" : "Start 25-50mcg"
            case ("Hydromorphone", "IV"): return isElderly ? "Start 0.2mg" : "Start 0.2-0.5mg"
            case ("Morphine", "IV"): return isElderly ? "Start 1-2mg" : "Start 2-4mg"
            case ("Oxycodone", "PO"): return isElderly ? "Start 2.5-5mg" : "Start 5-10mg"
            default: return "Standard starting dose"
            }
        }

        func addRec(_ name: String, _ type: RecommendationType, _ reason: String, _ detail: String) {
            recs.append(DrugRecommendation(name: name, reason: reason, detail: detail, type: type))
        }

        // 3. ANALGESIC PROFILE LOGIC
        switch analgesicProfile {
        case .naive:
            if route == .iv || route == .both {
                addRec("Hydromorphone IV", .safe, "Standard", "Potent. \(getStartingDose(drug: "Hydromorphone", route: "IV"))")
                addRec("Morphine IV", .safe, "Standard", "First line. \(getStartingDose(drug: "Morphine", route: "IV"))")
            }
            // Add Fentanyl IV only for specific indications (Renal/Hepatic Logic below handles this)
            if indication == .postoperative && (route == .iv || route == .both) {
                 addRec("Fentanyl IV", .safe, "Procedural", "Short duration. \(getStartingDose(drug: "Fentanyl", route: "IV"))")
            }
            
            if (route == .po || route == .both) && gi != .npo {
                addRec("Morphine PO", .safe, "Preferred", "15mg PO. Assess efficacy relative to baseline.")
                addRec("Oxycodone PO", .safe, "Preferred", "Bioavailable. \(getStartingDose(drug: "Oxycodone", route: "PO"))")
            }
            
            // Fentanyl Patch Warning removed from here per user request (Block recs, warn in library instead).

        case .chronicRx:
            warns.append("Tolerant Patient: Baseline dose + 20% for acute pain.")
            addRec("Continue Home Meds", .safe, "Prevent Withdrawal", "Maintain baseline. Add short-acting agonist (10-20% daily dose) q3h.")
            
            if isPregnant {
                warns.append("⚠️ PREGNANCY: Acute Withdrawal causes fetal distress. Maintain baseline.") // Case 46 Cap Fix
            }
            
            // Escalation Math (Uncontrolled Pain)
            addRec("Escalation Strategy", .caution, "If Pain Uncontrolled", "Calculate total 24h breakthrough used. Add sum + 20-30% to new daily baseline.")
            
            // Surgical Multiplier
            if indication == .postoperative {
                warns.append("⚠️ SURGICAL MULTIPLIER (Expert Consensus): Chronic Rx patients need ~3x higher MME than naive controls.")
            }
            
            // Hyperalgesia Distinction
            warns.append("OIH Awareness: If pain worsens despite dose escalation, suspect Hyperalgesia. Consider Opioid Rotation or Ketamine.")
            
        case .highPotency:
            warns.append("⚠️ HIGH POTENCY: MME Calculators will UNDERESTIMATE tolerance.")
            if toleranceUncertain { monitors.append("Unpredictable Tolerance: Titrate by effect. Start High, but monitor closely.") }
            addRec("Fentanyl IV", .safe, "Preferred", "Titratable. Start 50-100mcg IV if tolerance high.")
            // High Potency often requires rotation options. Adding Hydromorphone allows Renal logic to apply 'Strict Caution' adjustment if needed (Case 11).
            addRec("Hydromorphone IV", .caution, "Alternative", "Potent. Start 0.5-1mg IV. Monitor closely.")

        case .buprenorphine:
            if indication == .postoperative {
                 addRec("Buprenorphine Strategy", .caution, "Modulate Blockade", "Reduce baseline to 8-12mg daily to allow full agonist efficacy (ASAM Guidelines).")
                 addRec("Continue Buprenorphine", .safe, "Do Not Taper Completely", "Maintenance prevents relapse.")
            } else {
                 addRec("Continue Home Dose (Buprenorphine)", .safe, "Do Not Taper", "Maintenance prevents relapse.") // Case 39 Name Fix
            }
            
            // Split Dosing Optimization for Analgesia
            if !splitDosing {
                addRec("Split Home Dose", .safe, "Analgesic Efficacy", "Divide daily dose q6-8h to maximize duration of analgesia (Duration 6-8h).")
            }
            
            addRec("High-Affinity Agonist", .caution, "Breakthrough", "Use Hydromorphone/Fentanyl to overcome blockade.")
            if gi == .npo { warns.append("NPO Status: Use IV/SL Buprenorphine formulations.") }

        case .methadone:
            addRec("Continue Methadone", .safe, "Baseline", "Split dose q8h for analgesia.")
            if qtcProlonged {
                warns.append("⚠️ QTc PROLONGED: Avoid Zofran/Haldol. AVOID METHADONE if QTc > 500ms. Check K+/Mg++.")
                monitors.append("Daily ECG recommended. Hold if QTc > 500.")
            }

        case .naltrexone:
            warns.append("⚠️ BLOCKADE ACTIVE: Opioids ineffective.")
            
            // Ketamine Safety Check
            let ketamineSafety: RecommendationType = (hemo == .unstable) ? .caution : .safe
            let ketamineInfo = (hemo == .unstable) ? "CAUTION: May worsen HTN/Tachycardia. Monitor closely." : "0.1-0.3 mg/kg/hr. Bypasses Mu-receptor."
            
            addRec("Ketamine Infusion", ketamineSafety, "Primary Analgesic", ketamineInfo)
            
            if hemo == .unstable {
                warns.append("Hemodynamic Instability: Ketamine Caution high.")
                addRec("Lidocaine Infusion", .safe, "Alternative", "Consider if Ketamine contraindicated. Cardiac monitoring required.")
                addRec("Regional Anesthesia", .safe, "Sparing Option", "Consult Anesthesia for nerve blocks.")
            }
        }
        
        // 4. RENAL FILTERS
        if isRenalImpaired {
            recs.removeAll { $0.name.contains("Morphine") }
            
            if let idx = recs.firstIndex(where: { $0.name.contains("Hydromorphone") }) {
                let d = recs[idx]
                let warning = renalFunction == .dialysis ? "Strict Caution (Dialysis)." : "Renal Caution."
                let detail = renalFunction == .dialysis ? "Accumulates between sessions. Reduce dose 50%." : "Reduce dose 50%."
                // Since d is a let constant in the struct, we must create a new one.
                recs[idx] = DrugRecommendation(name: d.name, reason: warning, detail: detail, type: .caution)
            }
            
            if !recs.contains(where: { $0.name.contains("Fentanyl") }) && (route == .iv || route == .both) {
                 if renalFunction == .dialysis {
                     recs.insert(DrugRecommendation(name: "Fentanyl IV", reason: "Renal Safe", detail: "No active metabolites. \(getStartingDose(drug: "Fentanyl", route: "IV"))", type: .safe), at: 0)
                 } else {
                     addRec("Fentanyl IV", .safe, "Renal Safe", "No active metabolites. \(getStartingDose(drug: "Fentanyl", route: "IV"))")
                     }
        }
        
        // Dyspnea + Renal Specific Warning (Case 37)
        if indication == .dyspnea && isRenalImpaired {
            warns.append("Dyspnea/Renal: Avoid Morphine due to Metabolites. Consider Hydromorphone or Fentanyl (off-label).")
            if !recs.contains(where: { $0.name.contains("Hydromorphone") }) {
                 // Ensure alternative exists
                 addRec("Hydromorphone IV", .caution, "Alternative", "Renal adjusted. 0.2mg IV.")
            }
        }
        }

        // 5. HEPATIC FILTERS
        if isHepaticFailure {
            warns.append("⚠️ LIVER FAILURE: Avoid Morphine, Codeine, Tramadol, Oxycodone.")
            let toxic = ["Morphine", "Codeine", "Tramadol", "Oxycodone", "Methadone", "Meperidine"]
            recs.removeAll { r in toxic.contains { t in r.name.contains(t) } }
            
            warns.append("Acetaminophen: Max 2g/day.")

            if !recs.contains(where: { $0.name.contains("Fentanyl") }) && (route == .iv || route == .both) {
                addRec("Fentanyl IV", .safe, "Preferred", "Safest hepatic profile.")
            }
            
            if let idx = recs.firstIndex(where: { $0.name.contains("Hydromorphone") }) {
                 recs[idx] = DrugRecommendation(name: recs[idx].name, reason: "Caution (Shunting)", detail: "Bioavailability increases 4x. Start 1mg PO / 0.2mg IV.", type: .caution)
            } else if (route == .po || route == .both) && gi != .npo {
                 // Fallback: If Naive, Hydromorphone PO wasn't added initially, but it is the preferred oral option here (vs Morphine/Oxy).
                 addRec("Hydromorphone PO", .caution, "Caution (Shunting)", "Preferred over Morphine. Bioavailability increases 4x. Start 1mg PO.")
            }
        }

        // 6. GI / NPO LOGIC
        if gi == .npo || postOpNPO {
            recs.removeAll { $0.name.contains("PO") }
            warns.append("NPO: Enteral route contraindicated.")
        }
        
        // 7. HEMODYNAMIC FILTERS (NEW)
        if hemo == .unstable {
            warns.append("⚠️ HEMODYNAMIC INSTABILITY: Avoid Morphine (Histamine Release). Fentanyl preferred.")
            
            // Remove Morphine/Codeine (Histamine release)
            recs.removeAll { $0.name.contains("Morphine") || $0.name.contains("Codeine") }
            
            // Prioritize Fentanyl
            if !recs.contains(where: { $0.name.contains("Fentanyl") }) && (route == .iv || route == .both) {
                recs.insert(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred", detail: "Cardiostable. Start 25-50mcg. Titrate carefully.", type: .safe), at: 0)
            } else if let idx = recs.firstIndex(where: { $0.name.contains("Fentanyl") }) {
                // Ensure it's marked SAFE/PREFERRED
                let old = recs[idx]
                recs[idx] = DrugRecommendation(name: old.name, reason: "Preferred (Stable)", detail: old.detail, type: .safe)
            }
        }
        
        // Shock + PO (Case 41)
        if hemo == .unstable && (route == .po || route == .both) {
            warns.append("⚠️ SHOCK: Oral Absorption unreliable due to gut shunting. Use IV.")
        }
        
        // GI Bleed Specific Logic (Question 6)
        if historyGIBleed {
            warns.append("⚠️ GI BLEED: Avoid systemic NSAIDs. Use topical patches/gels if indicated.")
            // Redundant logic in Adjuvant section will also catch this, but top-level warning is good.
        }

        // 7. PREGNANCY LOGIC
        if isPregnant {
            warns.append("Pregnancy: Avoid Codeine/Tramadol. Neonatology consult recommended.")
            recs.removeAll { $0.name.contains("Codeine") || $0.name.contains("Tramadol") }
        }
        
        // Pediatric Block (Case 53)
        if isPediatric {
             recs.removeAll { $0.name.contains("Codeine") || $0.name.contains("Tramadol") }
        }

        // 8. ADJUVANT LOGIC
        switch painType {
        case .neuropathic:
            // Custom initializer for AdjuvantRecommendation is required based on ClinicalData definition?
            // User provided init in their snippet. ClinicalData has init.
            adjs.append(AdjuvantRecommendation(category: "First Line", drug: "Gabapentin", dose: isRenalImpaired ? "100mg daily (Renal)" : "300mg TID", rationale: "Neuropathic standard."))
            if !isElderly && !chf {
                adjs.append(AdjuvantRecommendation(category: "Second Line", drug: "Nortriptyline", dose: "10-25mg QHS", rationale: "TCA."))
            }

        case .bone:
            // "Steroids have limited, if any, use in chronic cancer pain."
            adjs.append(AdjuvantRecommendation(category: "Anti-Inflammatory", drug: "Dexamethasone", dose: "4-8mg IV/PO", rationale: "Acute flares/Compression only. Limited chronic utility."))
            if !isRenalImpaired && !historyGIBleed {
                 adjs.append(AdjuvantRecommendation(category: "NSAID", drug: "Naproxen", dose: "500mg BID", rationale: "Bone pain."))
            }

        case .inflammatory, .nociceptive:
            if isRenalImpaired || isHepaticFailure || chf || historyGIBleed {
                 adjs.append(AdjuvantRecommendation(category: "Topical", drug: "Diclofenac Gel 1%", dose: "4g QID", rationale: "Lower systemic absorption."))
            } else {
                 if gi == .npo && painType == .inflammatory {
                     // Case 38: NPO Inflammatory -> Toradol (IV NSAID)
                     // Check Renal first (Toradol is unsafe in renal failure)
                     if isRenalImpaired {
                         // No NSAIDs
                     } else {
                         adjs.append(AdjuvantRecommendation(category: "IV NSAID", drug: "Ketorolac (Toradol)", dose: "15-30mg IV q6h", rationale: "NPO Anti-inflammatory."))
                     }
                 } else {
                     adjs.append(AdjuvantRecommendation(category: "NSAID", drug: "Ibuprofen", dose: "400mg QID", rationale: "Standard anti-inflammatory."))
                 }
            }
            
            // Case 57: Pregnancy NSAID Exclusion
            if isPregnant && (painType == .inflammatory || painType == .nociceptive || painType == .bone) {
                // Remove NSAIDs created above
                adjs.removeAll { $0.category.contains("NSAID") || $0.drug.contains("Ibuprofen") || $0.drug.contains("Ketorolac") || $0.drug.contains("Naproxen") }
                warns.append("⚠️ PREGNANCY: NSAIDs contraindicated (Ductus Arteriosus closure).")
            }
            
            if isHepaticFailure {
                 adjs.append(AdjuvantRecommendation(category: "Analgesic", drug: "Acetaminophen", dose: "Max 2g/day", rationale: "Hepatic Limit."))
            } else {
                 adjs.append(AdjuvantRecommendation(category: "Analgesic", drug: "Acetaminophen", dose: "650mg q6h", rationale: "Multimodal sparing."))
            }
            
            
            // Note: Visceral pain case not currently in PainType enum.

        }
        
        if historyOverdose || psychHistory {
            monitors.append("SUD History: Urine Drug Screen + Naloxone prescription at discharge.")
            warns.append("High Risk: Limit quantity. Review PDMP.")
        }
        
        // 9. REFERRAL TRIGGERS
        // Pain Management (>90 MME)
        if let mme = Int(currentMME), mme > 90 {
            warns.append("⚠️ >90 MME: High Overdose Risk (CDC). Pain Management Consult Required.")
            monitors.append("MME > 90: Co-prescribe Naloxone.")
        }
        
        // Addiction Medicine (OUD Context)
        if historyOverdose || (analgesicProfile == .buprenorphine && indication != .postoperative) {
            // If they are on Buprenorphine for OUD (implied by not post-op? or just strictly OUD history)
            // Or if history of overdose.
            // Requirement: "Addiction medicine for suspected opioid use disorder"
            // We use historyOverdose as proxy for risk here.
            addRec("Addiction Medicine Consult", .safe, "Suspected OUD", "Assess for MAT optimization.")
        }
        
        // Physical Therapy (Musculoskeletal)
        // Nociceptive pain implies musculoskeletal often, or inflammatory.
        if painType == .nociceptive || painType == .inflammatory {
            addRec("Physical Therapy Consult", .safe, "Multimodal", "Functional restoration for musculoskeletal pain.")
        }

        // 9. FINAL SORTING: Safety > Route > Stability
        recs.sort { (a, b) -> Bool in
            // Helper: Rank Safety (Safe=0, Caution=1, Unsafe=2)
            func rank(_ type: RecommendationType) -> Int {
                switch type {
                case .safe: return 0
                case .caution: return 1
                case .unsafe: return 2
                }
            }
            
            // 1. Safety Priority
            let rankA = rank(a.type)
            let rankB = rank(b.type)
            if rankA != rankB { return rankA < rankB }
            
            // 2. Route Priority (PO > IV)
            // (Only relevant if we aren't enforcing IV only)
            let aPO = a.name.contains("PO")
            let bPO = b.name.contains("PO")
            if aPO != bPO { return aPO } // True (PO) comes before False (IV)
            
            return false // Maintain original relative order
        }

        self.recommendations = recs
        self.adjuvants = adjs
        self.warnings = warns
        self.monitoringPlan = monitors
        
        didUpdate.send()
    }
    
    // MARK: - HELPERS
    func reset() {
        self.age = ""
        self.sex = .female
        self.analgesicProfile = .naive
        self.qtcProlonged = false
        self.splitDosing = false
        self.toleranceUncertain = true
        self.postOpNPO = false
        self.renalFunction = .normal
        self.hepaticFunction = .normal
        self.hemo = .stable
        self.gi = .intact
        self.route = .both
        self.indication = .standard
        self.painType = .nociceptive
        self.sleepApnea = false
        self.chf = false
        self.benzos = false
        self.copd = false
        self.psychHistory = false
        self.multipleProviders = false
        self.multipleProviders = false
        self.historyOverdose = false
        self.historyGIBleed = false
        self.isPregnant = false
        self.currentMME = ""
        calculate()
    }
    
    func shouldShowPregnancyToggle() -> Bool {
        guard sex == .female else { return false }
        if let ageInt = Int(age), ageInt > 60 { return false }
        return true
    }
}
