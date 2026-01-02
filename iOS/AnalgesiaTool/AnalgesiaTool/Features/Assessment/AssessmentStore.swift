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
    @Published var adjuvants: [AdjuvantRecommendation] = []
    @Published var warnings: [String] = []
    
    @Published var prodigyScore: Int = 0
    @Published var prodigyRisk: String = "Low"
    @Published var monitoringPlan: [String] = []
    
    let didUpdate = PassthroughSubject<Void, Never>()
    
    // No more Combine pipeline needed
    
    // --- PERSISTENCE ---
    private var persistenceURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("assessment_state.json")
    }
    
    // Flag to prevent save cycles during load
    private var isLoading = false

    private struct AssessmentState: Codable {
        let age: String
        let sex: Sex
        let naive: Bool
        let mat: Bool
        let renalFunction: RenalStatus
        let hepaticFunction: HepaticStatus
        let hemo: Hemodynamics
        let gi: GIStatus
        let route: OpioidRoute
        let indication: ClinicalIndication
        let painType: PainType
        let sleepApnea: Bool
        let chf: Bool
        let benzos: Bool
        let copd: Bool
        let psychHistory: Bool
        let historyOverdose: Bool
        let isPregnant: Bool
        let lastHepaticState: HepaticStatus
    }

    private func save() {
        guard !isLoading else { return }
        
        let state = AssessmentState(
            age: age, sex: sex, naive: naive, mat: mat, 
            renalFunction: renalFunction, hepaticFunction: hepaticFunction, 
            hemo: hemo, gi: gi, route: route, indication: indication, 
            painType: painType, sleepApnea: sleepApnea, chf: chf, 
            benzos: benzos, copd: copd, psychHistory: psychHistory, 
            historyOverdose: historyOverdose, isPregnant: isPregnant,
            lastHepaticState: lastHepaticState
        )
        
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: persistenceURL, options: .completeFileProtection)
            // print("Saved state to \(persistenceURL)")
        } catch {
            print("Failed to save state: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else { return }
        
        isLoading = true // Suspend save trigger
        do {
            let data = try Data(contentsOf: persistenceURL)
            let state = try JSONDecoder().decode(AssessmentState.self, from: data)
            
            self.age = state.age
            self.sex = state.sex
            self.naive = state.naive
            self.mat = state.mat
            self.renalFunction = state.renalFunction
            self.hepaticFunction = state.hepaticFunction
            self.hemo = state.hemo
            self.gi = state.gi
            self.route = state.route
            self.indication = state.indication
            self.painType = state.painType
            self.sleepApnea = state.sleepApnea
            self.chf = state.chf
            self.benzos = state.benzos
            self.copd = state.copd
            self.psychHistory = state.psychHistory
            self.historyOverdose = state.historyOverdose
            self.isPregnant = state.isPregnant
            self.lastHepaticState = state.lastHepaticState
            
        } catch {
            print("Failed to load state: \(error)")
        }
        isLoading = false
    }

    init() {
        load() // Restore state
        calculate() // Update outputs
    }
    
    func calculate() {
        // Trigger save on every calculation (state change)
        defer { save() }
        
        var recs: [DrugRecommendation] = []
        var adj: [AdjuvantRecommendation] = [] // Unused but kept for type compat if needed locally
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
            else { addPORecs(); addIVRecs(); adj.append(AdjuvantRecommendation(category: "Guidance", drug: "Route Selection", dose: "See Clinical Context", rationale: "Determine based on GI tolerance")) }
        }
        
        // --- 4. HEPATIC SAFETY GATES (CRITICAL FIXES) ---
        if isHepaticFailure { // Child-Pugh C
            warns.append("Liver Failure: Avoid Morphine, Codeine, Methadone, Tramadol, Meperidine.")
            
            // FIX: Toxic List - Removed Oxycodone (Is First Line), Added Meperidine
            let toxic = ["Morphine", "Codeine", "Methadone", "Oxymorphone", "Tapentadol", "Tramadol", "Meperidine"]
            recs = recs.filter { r in !toxic.contains { t in r.name.contains(t) } }
            
            // Ensure Fentanyl if not present
            if !recs.contains(where: { $0.name.contains("Fentanyl") }) {
                let fentDose = getStartingDose(drug: "Fentanyl", route: "IV")
                recs.insert(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred.", detail: "Safest choice (No hepatic metabolism). \(fentDose)", type: .safe), at: 0)
            }
            
            // FIX: Hydromorphone & Oxycodone Adjustments
             recs = recs.map { r in
                 if r.name.contains("Hydromorphone") && r.name.contains("PO") {
                    return DrugRecommendation(name: r.name, reason: "Caution (Shunt Risk)", detail: "Bioavailability increases 4x. Start 1mg PO. Extended interval.", type: .caution)
                }
                 if r.name.contains("Oxycodone") {
                     return DrugRecommendation(name: r.name, reason: "Caution", detail: "Start 2.5mg PO. Extended interval. Monitor sedation.", type: .caution)
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
        
        // Ported Adjuvants Logic (v1.6)
        var newAdjuvants: [AdjuvantRecommendation] = []
        
        switch painType {
        case .neuropathic:
            // NeuPSIG Guidelines
            warns.append("Neuropathic Pain: Opioids are 3rd-line (High risk/Low efficacy). Prioritize TCAs, SNRIs, Gabapentinoids.")
            
            // 1. Gabapentinoids (First Line)
            let gabapentinDose = isRenalBad ? "100mg PO QD (Renal Dose)" : "300mg PO TID (Titrate)"
            let gabapentinRationale = isRenalBad ? "Accumulates in CKD. Start low." : "First-line. Target calcium channels."
            
            newAdjuvants.append(AdjuvantRecommendation(
                category: "First Line (Neuropathic)",
                drug: "Gabapentin",
                dose: gabapentinDose,
                rationale: gabapentinRationale
            ))
            
            // 2. SNRIs (First Line)
            if !isHepaticBad && renalFunction != .dialysis && (Int(age) ?? 0) < 80 {
                newAdjuvants.append(AdjuvantRecommendation(
                   category: "First Line (Neuropathic)",
                   drug: "Duloxetine (Cymbalta)",
                   dose: "30mg PO daily",
                   rationale: "First-line SNRI. Avoid if eGFR<30."
                ))
            }

            // 3. TCAs (First Line) - Age limit logic (Beers Criteria)
            let isElderly = (Int(age) ?? 0) >= 65
            if !chf && !isElderly {
                newAdjuvants.append(AdjuvantRecommendation(
                   category: "First Line (Neuropathic)",
                   drug: "Nortriptyline",
                   dose: "10-25mg PO QHS",
                   rationale: "First-line TCA. Monitor QTc/Anticholinergic effects."
                ))
            } else if isElderly {
                 warns.append("Avoid TCAs (Amitriptyline) in Elderly (Beers List): Anticholinergic risk.")
            }
            
            // 4. Topicals (Second Line)
            if !isNPO {
                 newAdjuvants.append(AdjuvantRecommendation(
                     category: "Second Line (Localized)",
                     drug: "Lidocaine 5% Patch",
                     dose: "Apply 12h ON / 12h OFF",
                     rationale: "Safe peripheral analgesia."
                 ))
                 newAdjuvants.append(AdjuvantRecommendation(
                     category: "Second Line (Localized)",
                     drug: "Capsaicin 8% Patch",
                     dose: "Apply to area",
                     rationale: "High-concentration topical."
                 ))
            }
            
        case .bone, .inflammatory:
            let isElderly = (Int(age) ?? 0) >= 65
            
            // NSAIDs Logic (ASCO/ASPN & Beers)
            if !isRenalBad && !isHepaticBad && !chf && gi == .intact {
                if isElderly {
                    // AGS Beers: Prefer Topical or COX-2 in Elderly
                    newAdjuvants.append(AdjuvantRecommendation(
                        category: "First Line (Inflammatory)",
                        drug: "Diclofenac Gel 1%",
                        dose: "4g QID to affected area",
                        rationale: "Topical NSAID preferred in elderly (Systemic safety)."
                    ))
                    newAdjuvants.append(AdjuvantRecommendation(
                        category: "First Line (Inflammatory)",
                        drug: "Celecoxib",
                        dose: "100-200mg PO BID",
                        rationale: "COX-2 Selective. GI protection recommended."
                    ))
                } else {
                    // Standard First Line
                    newAdjuvants.append(AdjuvantRecommendation(
                        category: "First Line (Inflammatory)",
                        drug: "Naproxen",
                        dose: "500mg PO BID",
                        rationale: "Non-selective NSAID. Take with food."
                    ))
                    newAdjuvants.append(AdjuvantRecommendation(
                        category: "First Line (Inflammatory)",
                        drug: "Ibuprofen",
                        dose: "400-600mg PO QID",
                        rationale: "First-line anti-inflammatory."
                    ))
                }
            } else {
                warns.append("Avoid NSAIDs: Contraindicated due to Renal/Hepatic/GI/CHF risk.")
            }
            
            if painType == .bone {
                 newAdjuvants.append(AdjuvantRecommendation(
                    category: "Steroid",
                    drug: "Dexamethasone",
                    dose: "4-8mg PO/IV daily",
                    rationale: "Effective for bone metastasis capsular pain."
                ))
            }
            
            // Acetaminophen Alternative
             if isHepaticFailure {
                 newAdjuvants.append(AdjuvantRecommendation(
                    category: "Alternative",
                    drug: "Acetaminophen",
                    dose: "Max 2g/day",
                    rationale: "CAUTION in Liver Failure. Strict limit."
                ))
             } else {
                 newAdjuvants.append(AdjuvantRecommendation(
                    category: "Alternative",
                    drug: "Acetaminophen",
                    dose: isHepaticBad ? "Max 3g/day" : "650mg q6h (Max 4g)",
                    rationale: isHepaticBad ? "Monitor LFTs." : "First-line alternative to NSAIDs."
                ))
             }
            
        case .nociceptive:
            // Tylenol Standard
            if isHepaticFailure {
                 newAdjuvants.append(AdjuvantRecommendation(
                    category: "Multimodal Sparing",
                    drug: "Acetaminophen",
                    dose: "Max 2g/day",
                    rationale: "CAUTION in Liver Failure."
                ))
            } else if isHepaticBad {
                newAdjuvants.append(AdjuvantRecommendation(
                    category: "Multimodal Sparing",
                    drug: "Acetaminophen",
                    dose: "Max 3g/day",
                    rationale: "Caution in mild impairment."
                ))
            } else {
                newAdjuvants.append(AdjuvantRecommendation(
                    category: "Multimodal Sparing",
                    drug: "Acetaminophen",
                    dose: "650mg PO q6h",
                    rationale: "Reduces opioid consumption by 20%."
                ))
            }
        }
        
        // NPO Filter for Adjuvants
        if isNPO {
             newAdjuvants = newAdjuvants.filter { $0.drug.contains("Patch") || $0.drug.contains("IV") || $0.drug.contains("Rectal") }
        }

        self.recommendations = recs
        self.adjuvants = newAdjuvants
        self.warnings = warns
        
        didUpdate.send()
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
