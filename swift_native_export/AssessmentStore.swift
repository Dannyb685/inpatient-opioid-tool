import Foundation
import Combine


class AssessmentStore: ObservableObject {
    // --- INPUTS ---
    // Demographics
    @Published var age: String = "" { didSet { calculate() } }
    @Published var sex: Sex = .male { didSet { calculate() } }
    @Published var naive: Bool = false { 
        didSet { 
            if naive { mat = false } // Contradiction check
            calculate() 
        } 
    }
    @Published var mat: Bool = false { 
        didSet { 
            if mat { naive = false } // Contradiction check
            calculate() 
        } 
    } // Home Buprenorphine
    
    // Clinical Parameters
    // --- STATE MEMORY ---
    private var lastHepaticState: HepaticStatus = .impaired // Memory for Toggle Logic

    // Clinical Parameters
    @Published var renalFunction: RenalStatus = .normal { didSet { calculate() } }
    @Published var hepaticFunction: HepaticStatus = .normal { 
        didSet { 
            // VECTOR 1 FIX: State Preservation
            if oldValue == .failure && hepaticFunction == .normal {
                lastHepaticState = .failure // Remember we were in failure
            }
            // If toggling ON (Normal -> Impaired), check if we should restore Failure
            if oldValue == .normal && hepaticFunction == .impaired && lastHepaticState == .failure {
                hepaticFunction = .failure
            }
            
            calculate() 
        } 
    }
    @Published var hemo: Hemodynamics = .stable { didSet { calculate() } }
    @Published var gi: GIStatus = .intact { didSet { calculate() } }
    @Published var route: OpioidRoute = .both { didSet { calculate() } }
    @Published var indication: ClinicalIndication = .standard { didSet { calculate() } }
    @Published var painType: PainType = .nociceptive { didSet { calculate() } }
    
    // ... (rest of vars)

    // ... (down to line 278) ...
    
        if painType == .neuropathic {
            if !isNPO {
                // VECTOR 3 FIX: Specific Dialysis Dosing
                if renalFunction == .dialysis {
                    adj.append("Gabapentin: Max 100mg post-dialysis ONLY.")
                } else {
                    adj.append("Gabapentin (Renal adjust).")
                }
                
                if !isHepaticBad && !isRenalBad { adj.append("Duloxetine (Cymbalta).") }
                else { warns.append("Avoid Duloxetine in Renal/Hepatic impairment.") }
            }
            adj.append("Lidocaine 5% patch.")
        } else if painType == .inflammatory || painType == .bone {
    
    // Risk Factors
    @Published var sleepApnea: Bool = false { didSet { calculate() } }
    @Published var chf: Bool = false { didSet { calculate() } }
    @Published var benzos: Bool = false { didSet { calculate() } }
    @Published var copd: Bool = false { didSet { calculate() } }
    @Published var psychHistory: Bool = false { didSet { calculate() } }

    @Published var historyOverdose: Bool = false { didSet { calculate() } } // SUD / OD History
    @Published var isPregnant: Bool = false { didSet { calculate() } }

    var isPediatric: Bool {
        if let ageInt = Int(age), ageInt < 18 { return true }
        return false
    }

    var isRenalImpaired: Bool {
        get { renalFunction != .normal }
        set { renalFunction = newValue ? .impaired : .normal }
    }
    
    var isHepaticImpaired: Bool {
        get { hepaticFunction != .normal }
        set { hepaticFunction = newValue ? .impaired : .normal }
    }

    
    // --- OUTPUTS ---
    @Published var recommendations: [DrugRecommendation] = []
    @Published var adjuvants: [String] = []
    @Published var warnings: [String] = []
    
    @Published var prodigyScore: Int = 0
    @Published var prodigyRisk: String = "Low"
    @Published var monitoringPlan: [String] = []
    
    // No more Combine pipeline needed
    
    init() {
        calculate() // Initial calculation
    }
    
    func calculate() {
        var recs: [DrugRecommendation] = []
        var adj: [String] = []
        var warns: [String] = []

        
        // --- 1. PRODIGY SCORING ---
        var pScore = 0
        if let ageInt = Int(age) {
            if ageInt >= 80 { pScore += 16 }
            else if ageInt >= 70 { pScore += 12 }
            else if ageInt >= 60 { pScore += 8 }
        }
        if sex == .male { pScore += 8 }
        // LOGIC: Naive adds +3 only if NOT on MAT
        if naive && !mat { pScore += 3 }
        if sleepApnea { pScore += 5 }
        if chf { pScore += 7 }
        
        self.prodigyScore = pScore
        self.prodigyRisk = pScore >= 15 ? "High" : (pScore >= 8 ? "Intermediate" : "Low")
        
        var monitors: [String] = []
        if pScore >= 15 { monitors.append("⚠️ PRODIGY High Risk: Continuous Capnography + Pulse Oximetry.") }
        else if pScore >= 8 { monitors.append("PRODIGY Intermediate: Consider Capnography.") }
        else { monitors.append("Standard monitoring.") }
        
        if benzos { monitors.append("⚠️ WARNING: Concurrent Benzos increase overdose risk 3.8x (Black Box).") }
        if copd { monitors.append("COPD: Target SpO2 88-92% (Risk of CO2 retention).") }
        
        self.monitoringPlan = monitors
        
        // --- 2. CLINICAL LOGIC ---
        let isRenalBad = (renalFunction == .impaired || renalFunction == .dialysis)
        let isHepaticFailure = (hepaticFunction == .failure)
        let isHepaticBad = (hepaticFunction == .impaired || hepaticFunction == .failure)
        let isNPO = (gi == .npo)
        
        // --- HELPERS ---
        func getStartingDose(drug: String, route: String) -> String {
            guard naive else { return "Titrate to effect" }
            let isElderly = (Int(age) ?? 0) >= 70
            
            // Standard Naive Starting Doses
            switch (drug, route) {
            case ("Morphine", "IV"): return isElderly ? "Start 1-2mg" : "Start 2-4mg"
            case ("Hydromorphone", "IV"): return isElderly ? "Start 0.2-0.4mg" : "Start 0.2-0.5mg"
            case ("Fentanyl", "IV"): return isElderly ? "Start 12.5-25mcg" : "Start 25-50mcg"
            case ("Oxycodone", "PO"): return isElderly ? "Start 2.5-5mg" : "Start 5-10mg"
            case ("Morphine", "PO"): return isElderly ? "Start 7.5-15mg" : "Start 15-30mg"
            case ("Hydromorphone", "PO"): return isElderly ? "Start 1-2mg" : "Start 2-4mg"
            default: return "Titrate to effect"
            }
        }

        func addIVRecs() {
            let fentDose = getStartingDose(drug: "Fentanyl", route: "IV")
            let dilDose = getStartingDose(drug: "Hydromorphone", route: "IV")
            let morDose = getStartingDose(drug: "Morphine", route: "IV")

            if isRenalBad {
                recs.append(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred.", detail: "Safest renal option (No metabolites). \(fentDose)", type: .safe))
                if renalFunction == .dialysis {
                     recs.append(DrugRecommendation(name: "Hydromorphone IV", reason: "Strict Caution.", detail: "Accumulates between sessions. Reduce dose 50%. \(dilDose)", type: .caution))
                } else {
                     recs.append(DrugRecommendation(name: "Hydromorphone IV", reason: "Caution.", detail: "Reduce dose 50%. Watch for H3G. \(dilDose)", type: .caution))
                }
            } else {
                recs.append(DrugRecommendation(name: "Morphine IV", reason: "Standard.", detail: "Ideal first-line. \(morDose)", type: .safe))
                
                // HEPATIC SAFETY: Hydromorphone IV requires reduction in Failure
                if isHepaticFailure {
                    recs.append(DrugRecommendation(name: "Hydromorphone IV", reason: "Caution.", detail: "Reduce dose 50%. Watch for sedation. \(dilDose)", type: .caution))
                } else {
                    recs.append(DrugRecommendation(name: "Hydromorphone IV", reason: "Standard.", detail: "Preferred in high tolerance. \(dilDose)", type: .safe))
                }
            }
        }
        
        func addPORecs() {
            if isNPO { 
                // SAFETY: NPO Paradox Fix
                recs.append(DrugRecommendation(name: "NPO Status", reason: "Route Conflict.", detail: "Patient is NPO. Avoid Oral Route. Consider IV or Transdermal.", type: .unsafe))
                return 
            }
            
            let oxyDose = getStartingDose(drug: "Oxycodone", route: "PO")
            let morDose = getStartingDose(drug: "Morphine", route: "PO")
            let dilaudidPODose = getStartingDose(drug: "Hydromorphone", route: "PO")
            
            if isRenalBad {
                // SAFETY FIX: Do NOT suggest Methadone for Naive patients
                if !naive {
                    // METHADONE TRAP FIX
                    if painType == .neuropathic {
                         recs.append(DrugRecommendation(name: "Methadone PO (Expert Consult Required)", reason: "Safe Option.", detail: "No renal metabolites. Consult Specialist.", type: .safe))
                    }
                }
                
                if !isHepaticFailure {
                    recs.append(DrugRecommendation(name: "Oxycodone PO", reason: "Caution.", detail: "Reduce frequency. Monitor sedation. \(oxyDose)", type: .caution))
                }
                // TRIPLE WHAMMY FIX: Include reference dose for calculation
                recs.append(DrugRecommendation(name: "Hydromorphone PO", reason: "Caution.", detail: "Reduce dose 50%. \(dilaudidPODose)", type: .caution))
            } else {
                recs.append(DrugRecommendation(name: "Oxycodone PO", reason: "Preferred.", detail: "Superior bioavailability. \(oxyDose)", type: .safe))
                recs.append(DrugRecommendation(name: "Morphine PO", reason: "Standard.", detail: "Reliable option. \(morDose)", type: .safe))
            }
        }
        
        // --- 3. BRANCHING LOGIC ---
        if hemo == .unstable {
            let fentDose = getStartingDose(drug: "Fentanyl", route: "IV")
            recs.append(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred.", detail: "Cardiostable. \(fentDose)", type: .safe))
            warns.append("Morphine: Histamine release precipitates hypotension.")
        }
        else if mat {
            recs.append(DrugRecommendation(name: "Home Buprenorphine", reason: "Maintenance.", detail: "Continue basal to prevent withdrawal.", type: .safe))
            recs.append(DrugRecommendation(name: "Breakthrough Agonist", reason: "Acute Pain.", detail: "High-affinity agonist (Fentanyl/Dilaudid) required.", type: .safe))
            if route == .po || route == .both { 
                addPORecs() 
                // FIX: Remove Morphine PO
                let blockedDrugs = ["Morphine", "Oxycodone", "Codeine", "Hydrocodone", "Tramadol"]
                recs.removeAll { rec in 
                    blockedDrugs.contains { blocked in rec.name.contains(blocked) }
                }
            }
            if route == .iv || route == .both { 
                addIVRecs()
                // FIX: Remove Morphine as it is blocked by Buprenorphine
                // NEW (Stricter Blockade Logic):
                let blockedDrugs = ["Morphine", "Oxycodone", "Codeine", "Hydrocodone", "Tramadol"]
                recs.removeAll { rec in 
                    blockedDrugs.contains { blocked in rec.name.contains(blocked) }
                }
            }
        }
        // PERINATAL MODE
        else if isPregnant {
             warns.append("Perinatal Mode: Consult OB/High-Risk Specialist.")
             warns.append("Avoid Codeine/Tramadol: Ultra-rapid metabolism risk to fetus/infant.")
             
             // 1. Prioritize Buprenorphine / Methadone
             recs.append(DrugRecommendation(name: "Buprenorphine", reason: "Preferred.", detail: "Standard of care. Fewer neonatal withdrawal symptoms.", type: .safe))
             recs.append(DrugRecommendation(name: "Methadone", reason: "Specialist Only.", detail: "Standard of care. Requires dose titration due to metabolism.", type: .caution))
             
             if route == .iv { addIVRecs() }
             else if route == .po { addPORecs() }
             else { addPORecs(); addIVRecs() }
             
             // 2. Filter Contraindications (Codeine/Tramadol)
             recs.removeAll { $0.name.contains("Codeine") || $0.name.contains("Tramadol") }
             
             // 3. Mark others as Caution
             recs = recs.map { r in
                 if r.name.contains("Buprenorphine") || r.name.contains("Methadone") { return r }
                 return DrugRecommendation(name: r.name, reason: "Caution", detail: "Shortest duration possible. Monitor neonate.", type: .caution)
             }
        }
        else {
            if isRenalBad { warns.append("Avoid: Morphine, Codeine, Tramadol, Meperidine.") }
            if route == .iv { addIVRecs() }
            else if route == .po { addPORecs() }
            else { addPORecs(); addIVRecs(); adj.append("Route Preference: Determine based on GI tolerance.") }
        }
        
        // --- 4. HEPATIC SAFETY GATES (CRITICAL FIXES) ---
        if isHepaticFailure { // Child-Pugh C
            warns.append("Liver Failure: Avoid Morphine, Oxycodone, Methadone, Tramadol, Tapentadol.")
            
            // FIX: Expanded Toxic List (Oxymorphone, Tapentadol, Tramadol)
            let toxic = ["Morphine", "Codeine", "Methadone", "Oxycodone", "Oxymorphone", "Tapentadol", "Tramadol"]
            recs = recs.filter { r in !toxic.contains { t in r.name.contains(t) } }
            
            // Ensure Fentanyl if not present
            if !recs.contains(where: { $0.name.contains("Fentanyl") }) {
                let fentDose = getStartingDose(drug: "Fentanyl", route: "IV")
                recs.insert(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred.", detail: "Safest choice in liver failure. \(fentDose)", type: .safe), at: 0)
            }
            
            // FIX: Hydromorphone Shunt Warning
             recs = recs.map { r in
                 if r.name.contains("Hydromorphone") && r.name.contains("PO") {
                    return DrugRecommendation(name: r.name, reason: "EXTREME CAUTION", detail: "AVOID PREFERRED. Danger: Shunt Effect (400% Bioavailability). If used, reduce 75%.", type: .caution)
                }
                 if !r.detail.contains("Reduce") {
                     return DrugRecommendation(name: r.name, reason: r.reason, detail: r.detail + " Reduce dose 50%.", type: r.type)
                 }
                 return r
             }
        } else if hepaticFunction == .impaired {
             recs = recs.map { r in
                 if !r.detail.contains("Reduce") {
                     return DrugRecommendation(name: r.name, reason: r.reason, detail: r.detail + " Reduce initial dose 50%.", type: r.type)
                 }
                 return r
             }
        }
        
        // --- 5. NPO & ADJUVANTS ---
        if isNPO {
            recs = recs.filter { !$0.name.contains("PO") && !$0.name.contains("Oral") }
            if route == .po || route == .both { warns.append("PO Contraindicated: Patient is NPO.") }
        }
        
        if painType == .neuropathic {
            if !isNPO {
                adj.append("Gabapentin (Renal adjust).")
                if !isHepaticBad && !isRenalBad { adj.append("Duloxetine (Cymbalta).") }
                else { warns.append("Avoid Duloxetine in Renal/Hepatic impairment.") }
            }
            adj.append("Lidocaine 5% patch.")
        } else if painType == .inflammatory || painType == .bone {
            if !isRenalBad && !isHepaticBad && !chf {
                adj.append(isNPO ? "Ketorolac IV (Limit 5d)." : "NSAIDs: Naproxen/Celecoxib.")
            } else {
                warns.append("Avoid NSAIDs: Renal, Hepatic, or CHF risk.")
            }
            if painType == .bone { adj.append("Dexamethasone.") }
            
            if isHepaticFailure { adj.append("Acetaminophen: CAUTION. Max 2g/day.") }
            else if isHepaticBad { adj.append("Acetaminophen: Monitor LFTs. Max 3g/day.") }
            else { adj.append("Acetaminophen: Max 4g/day.") }
        }
        
        // FIX: Fentanyl Patch Gate
        if naive {
            if indication == .cancer {
                 warns.append("Fentanyl Patch: Contraindicated in Opioid Naive.")
            }
        }
        
        // NPO Filter for Adjuvants
        if isNPO {
             adj = adj.filter { $0.contains("Patch") || $0.contains("IV") }
        }

        self.recommendations = recs
        self.adjuvants = adj
        self.warnings = warns
    }
    
    func reset() {
        age = ""; sex = .male; naive = false; mat = false; isPregnant = false
        renalFunction = .normal; hepaticFunction = .normal; hemo = .stable
        gi = .intact; route = .both; indication = .standard; painType = .nociceptive
        sleepApnea = false; chf = false; benzos = false; copd = false
        psychHistory = false; historyOverdose = false
        calculate()
    }
    
    // Perinatal Helper
    func shouldShowPregnancyToggle() -> Bool {
        guard sex == .female else { return false }
        guard let ageInt = Int(age), ageInt >= 12, ageInt <= 55 else { return false }
        return true
    }
}
