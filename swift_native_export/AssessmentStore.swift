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
    @Published var renalFunction: RenalStatus = .normal { didSet { calculate() } }
    @Published var hepaticFunction: HepaticStatus = .normal { didSet { calculate() } }
    @Published var hemo: Hemodynamics = .stable { didSet { calculate() } }
    @Published var gi: GIStatus = .intact { didSet { calculate() } }
    @Published var route: OpioidRoute = .iv { didSet { calculate() } }
    @Published var indication: ClinicalIndication = .standard { didSet { calculate() } }
    @Published var painType: PainType = .nociceptive { didSet { calculate() } }
    
    // Risk Factors
    @Published var sleepApnea: Bool = false { didSet { calculate() } }
    @Published var chf: Bool = false { didSet { calculate() } }
    @Published var benzos: Bool = false { didSet { calculate() } }
    @Published var copd: Bool = false { didSet { calculate() } }
    @Published var psychHistory: Bool = false { didSet { calculate() } }
    
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
        var riskReasons: [String] = [] // Internal tracking for 'High' risk overrides
        var generalRiskScore: String = "Low" // 'Low' | 'Moderate' | 'High'
        
        // --- 1. PRODIGY SCORING (Validated Tool - 5 Factors Only) ---
        // Factors: Age >= 60, Male Sex, Opioid Naive, Sleep Disordered Breathing, CHF.
        var pScore = 0
        var pRisk = "Low"
        var monitors: [String] = []
        
        if let ageInt = Int(age) {
            if ageInt >= 80 { pScore += 16 }
            else if ageInt >= 70 { pScore += 12 }
            else if ageInt >= 60 { pScore += 8 }
        }
        if sex == .male { pScore += 8 }
        if naive { pScore += 3 }
        if sleepApnea { pScore += 5 }
        if chf { pScore += 7 }
        
        // PRODIGY Risk Stratification
        if pScore >= 15 {
            pRisk = "High"
            monitors.append("PRODIGY High Risk: Continuous Capnography + Pulse Oximetry Recommended.")
        } else if pScore >= 8 {
            pRisk = "Intermediate"
            monitors.append("PRODIGY Intermediate Risk: Consider Continuous Capnography.")
        } else {
            pRisk = "Low"
            monitors.append("PRODIGY Low Risk: Standard monitoring.")
        }
        
        self.prodigyScore = pScore
        self.prodigyRisk = pRisk
        
        // --- 2. EXPANDED RISK ASSESSMENT (Evidence Based) ---
        // Additional factors not in PRODIGY but clinically relevant for respiratory depression
        var expandedMonitors: [String] = monitors
        
        if benzos {
            riskReasons.append("Concurrent Benzodiazepines")
            expandedMonitors.append("⚠️ WARNING: Concurrent Benzos increase overdose risk 3.8x (Black Box).")
            if pRisk == "Low" && pScore < 8 {
                expandedMonitors.append("Risk elevated to High/Caution due to sedatives despite low PRODIGY score.")
            }
        }
        
        if copd {
             riskReasons.append("COPD / Lung Disease")
             expandedMonitors.append("COPD: Carbon dioxide retention risk. Target SpO2 88-92%.")
        }
        
        self.monitoringPlan = expandedMonitors
        
        // --- 2. CLINICAL LOGIC ---
        let isRenalBad = (renalFunction == .impaired || renalFunction == .dialysis)
        // Dialysis vs Impaired distinction might be needed for specific details, but logic generally groups them
        let isHepaticBad = (hepaticFunction == .impaired || hepaticFunction == .failure)
        let isHepaticFailure = (hepaticFunction == .failure)
        
        // Helpers (Closure to capture context)
        func getStartingDose(drug: String, route: String) -> String {
            // Basic conservative starting dose logic
            let isElderly = (Int(age) ?? 0) >= 70
            
            if drug == "Morphine" && route == "IV" {
                if naive {
                    return isElderly ? "Start 1-2mg" : "Start 2-4mg"
                } else {
                    return "Titrate to effect"
                }
            }
            if drug == "Hydromorphone" && route == "IV" {
                if naive {
                    return isElderly ? "Start 0.2-0.4mg" : "Start 0.2-0.5mg"
                } else {
                     return "Titrate to effect"
                }
            }
            if drug == "Fentanyl" && route == "IV" {
                 if naive {
                    return isElderly ? "Start 12.5-25mcg" : "Start 25-50mcg"
                } else {
                     return "Titrate to effect"
                }
            }
            if drug == "Oxycodone" && route == "PO" {
                 if naive {
                    return isElderly ? "Start 2.5-5mg" : "Start 5-10mg"
                } else {
                     return "Titrate to effect"
                }
            }
             if drug == "Morphine" && route == "PO" {
                 if naive {
                    return isElderly ? "Start 7.5-15mg" : "Start 15-30mg"
                } else {
                     return "Titrate to effect"
                }
            }
            return ""
        }

        func addIVRecs() {
            if isRenalBad {
                let fentDose = getStartingDose(drug: "Fentanyl", route: "IV")
                recs.append(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred.", detail: "Safest renal option (No metabolites). \(fentDose)", type: .safe))
                
                let dilaudidDose = getStartingDose(drug: "Hydromorphone", route: "IV")
                recs.append(DrugRecommendation(name: "Hydromorphone IV", reason: "Caution.", detail: "Reduce dose 50%. Watch for H3G accumulation. \(dilaudidDose)", type: .caution))
            } else {
                let morphDose = getStartingDose(drug: "Morphine", route: "IV")
                recs.append(DrugRecommendation(name: "Morphine IV", reason: "Standard.", detail: "Ideal first-line. \(morphDose)", type: .safe))
                
                let dilaudidDose = getStartingDose(drug: "Hydromorphone", route: "IV")
                recs.append(DrugRecommendation(name: "Hydromorphone IV", reason: "Standard.", detail: "Preferred in high tolerance. \(dilaudidDose)", type: .safe))
            }
        }
        
        func addPORecs() {
            if isRenalBad {
                if !isHepaticFailure {
                    let oxyDose = getStartingDose(drug: "Oxycodone", route: "PO")
                    recs.append(DrugRecommendation(name: "Oxycodone PO", reason: "Caution.", detail: "Reduce frequency. Monitor sedation. \(oxyDose)", type: .caution))
                }
                recs.append(DrugRecommendation(name: "Hydromorphone PO", reason: "Caution.", detail: "Reduce dose 50%.", type: .caution))
            } else {
                let oxyDose = getStartingDose(drug: "Oxycodone", route: "PO")
                recs.append(DrugRecommendation(name: "Oxycodone PO", reason: "Preferred.", detail: "Superior bioavailability. \(oxyDose)", type: .safe))
                
                let morphDose = getStartingDose(drug: "Morphine", route: "PO")
                recs.append(DrugRecommendation(name: "Morphine PO", reason: "Standard.", detail: "Reliable if renal function normal. \(morphDose)", type: .safe))
            }
        }
        
        // Step 1: HEMODYNAMICS OVERRIDE
        if hemo == .unstable {
            riskReasons.append("Hemodynamic Instability")
            generalRiskScore = "High"
            let fentDose = getStartingDose(drug: "Fentanyl", route: "IV")
            recs.append(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred.", detail: "Cardiostable; no histamine release. \(fentDose)", type: .safe))
            warns.append("Morphine: Histamine release precipitates vasodilation/hypotension.")
        }
        // Step 2: MAT
        else if mat {
            riskReasons.append("Home MAT")
            recs.append(DrugRecommendation(name: "Home Buprenorphine (SL/Patch)", reason: "Maintenance.", detail: "Continue basal to prevent withdrawal.", type: .safe))
            recs.append(DrugRecommendation(name: "Breakthrough Agonist", reason: "Acute Pain.", detail: "Add high-affinity agonist (Fentanyl/Dilaudid) on top of MAT.", type: .safe))
            
            if isRenalBad {
                 recs.append(DrugRecommendation(name: "Buprenorphine (Safety)", reason: "Renal Safe.", detail: "No dose adjustment needed in dialysis.", type: .safe))
            }
            
            // Simplified route logic for MAT breakthrough
            if route == .iv || route == .both || route == .either { addIVRecs() }
            if route == .po || route == .both || route == .either { addPORecs() }
        }
        // Step 3: STANDARD LOGIC
        else {
            if isRenalBad {
                riskReasons.append("Renal Insufficiency")
                generalRiskScore = "High"
                warns.append("Avoid: Morphine, Codeine, Tramadol, Meperidine (Active metabolites/Seizure risk).")
                // Methadone logic: "Safe" in terms of metabolites, but complex
                recs.append(DrugRecommendation(name: "Methadone PO", reason: "Safe.", detail: "Fecal excretion. Consult Specialist.", type: .safe))
            } else {
                 // Explicit Meperidine Warning for General Population too
                 warns.append("Avoid Meperidine (Neurotoxic metabolites, Seizure risk).")
            }
            
            if route == .iv { addIVRecs() }
            else if route == .po { addPORecs() }
            else if route == .both || route == .either {
                addIVRecs()
                addPORecs()
                if route == .either {
                    adj.append("Route Preference: Determine based on GI tolerance.")
                }
            } else {
                addIVRecs() // Default fallback
            }
        }
        
        // Step 4: HEPATIC SAFETY GATES
        if isHepaticFailure { // Child-Pugh C
            riskReasons.append("Hepatic Failure")
            generalRiskScore = "High"
            warns.append("Liver Failure (Child-Pugh C): Avoid Methadone, Morphine, Codeine, and Oxycodone.")
            
            // Filter Toxic
            let toxic = ["Morphine", "Codeine", "Methadone", "Oxycodone"]
            recs = recs.filter { r in !toxic.contains { t in r.name.contains(t) } }
            
            // Ensure Fentanyl if not present
            if !recs.contains(where: { $0.name.contains("Fentanyl") }) {
                recs.insert(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred.", detail: "Safest choice in liver failure.", type: .safe), at: 0)
            }
            
            // Add reduction note
             recs = recs.map { DrugRecommendation(name: $0.name, reason: $0.reason, detail: $0.detail + " Reduce dose 50%.", type: $0.type) }
            
        } else if hepaticFunction == .impaired { // Child-Pugh A/B
             riskReasons.append("Hepatic Impairment")
             if generalRiskScore != "High" { generalRiskScore = "Moderate" }
             recs = recs.map { DrugRecommendation(name: $0.name, reason: $0.reason, detail: $0.detail + " Reduce initial dose 50%.", type: $0.type) }
        }
        
        // Step 5: GI / NPO Logic
        if gi == .npo {
            // UNIVERSAL SAFETY FILTER: Remove all PO/Oral meds regardless of route selection
            // This prevents "Methadone PO" or other auto-added PO meds from leaking through even if Route=IV
            recs = recs.filter { !$0.name.contains("PO") && !$0.name.contains("Oral") }
            
            // Context-aware warnings
            if route == .po || route == .both || route == .either {
                 if route == .po {
                     recs = [] // Clear if ONLY PO requested
                 }
                 warns.append("PO Contraindicated: Patient is NPO/AMS. Switch to IV.")
            }
        }
        
        // Step 6: PAIN TYPE & ADJUVANTS
        if painType == .neuropathic {
            adj.append("Gabapentinoids: Gabapentin or Pregabalin.")
            if !isHepaticBad {
                adj.append("SNRIs: Duloxetine (Cymbalta).")
            } else {
                warns.append("Avoid Duloxetine in Hepatic Impairment.")
            }
            adj.append("Topicals: Lidocaine 5% patch.")
        } else if painType == .inflammatory || painType == .bone {
            if !isRenalBad && !isHepaticBad {
                adj.append("NSAIDs: Naproxen or Celecoxib.")
            } else {
                warns.append("Avoid NSAIDs: Renal/Hepatic Impairment risk.")
            }
            
            if painType == .bone {
                adj.append("Corticosteroids: Dexamethasone (Periosteal pain).")
                warns.append("Bone Pain: Consider Radiation Oncology.")
            }
            // Acetaminophen Check
            if isHepaticFailure {
                adj.append("Acetaminophen: CAUTION. Max 2g/day strictly.")
            } else if isHepaticBad {
                adj.append("Acetaminophen: Monitor LFTs. Max 3g/day.")
            } else {
                adj.append("Acetaminophen: Scheduled foundation (Max 4g).")
            }
        } else if painType == .nociceptive {
            adj.append("Acetaminophen / NSAIDs (if renal/liver safe).")
        }
        
        // Step 7: CLINICAL INDICATIONS
        if indication == .dyspnea {
            if !recs.contains(where: { $0.name.contains("Morphine") }) && !isRenalBad && !isHepaticFailure {
                recs.insert(DrugRecommendation(name: "Morphine IV", reason: "Gold Standard.", detail: "Air hunger.", type: .safe), at: 0)
            }
            adj.append("Anxiety: Low-dose Lorazepam (0.5mg).")
        }
        
        // Step 8: General Risk
        if sleepApnea {
            riskReasons.append("Sleep Apnea (OSA)")
            warns.append("OSA: Avoid basal infusions. Monitor SpO2/EtCO2.")
        }
        
        self.recommendations = recs
        self.adjuvants = adj
        self.warnings = warns
    }
}
