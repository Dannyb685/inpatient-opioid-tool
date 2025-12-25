import Foundation
import SwiftUI

// MARK: - Enums (Replicating React State Options)

enum RenalStatus: String, CaseIterable, Identifiable {
    case normal = "Normal (>30)"
    case impaired = "Impaired (<30)"
    case dialysis = "Dialysis"
    var id: String { self.rawValue }
}

enum HepaticStatus: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case impaired = "Impaired (A/B)"
    case failure = "Failure (C)"
    var id: String { self.rawValue }
}

enum Hemodynamics: String, CaseIterable, Identifiable {
    case stable = "Stable"
    case unstable = "Unstable / Shock"
    var id: String { self.rawValue }
}

enum GIStatus: String, CaseIterable, Identifiable {
    case intact = "Intact / Alert"
    case tube = "Tube / Dysphagia"
    case npo = "NPO / GI Failure / AMS"
    var id: String { self.rawValue }
}

enum OpioidRoute: String, CaseIterable, Identifiable {
    case iv = "IV / SQ"
    case po = "Oral (PO)"
    case both = "Both / Either"
    var id: String { self.rawValue }
}

enum ClinicalIndication: String, CaseIterable, Identifiable {
    case standard = "General / Acute"
    case dyspnea = "Palliative Dyspnea"
    case cancer = "Cancer Pain"
    var id: String { self.rawValue }
}

enum PainType: String, CaseIterable, Identifiable {
    case nociceptive = "Nociceptive (Tissue)"
    case neuropathic = "Neuropathic (Nerve)"
    case inflammatory = "Inflammatory"
    case bone = "Bone Pain"
    var id: String { self.rawValue }
}

enum Sex: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    var id: String { self.rawValue }
}

// MARK: - Data Models

enum RecommendationType {
    case safe
    case caution
    case unsafe
}

struct DrugRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let reason: String
    let detail: String
    let type: RecommendationType
}

// MARK: - Data Models

struct DrugData: Identifiable {
    let id: String
    let name: String
    let type: String
    let ivOnset: String
    let ivDuration: String
    let renalSafety: String // Safe, Caution, Unsafe
    let hepaticSafety: String // Safe, Caution, Unsafe
    let clinicalNuance: String
    let pharmacokinetics: String
    let tags: [String]
    let bioavailability: Int
}

struct WarningData: Identifiable {
    let id: String
    let name: String
    let risk: String
    let desc: String
}

// MARK: - Clinical Data Store

struct ClinicalData {
    
    static let drugData: [DrugData] = [
        DrugData(id: "morphine", name: "Morphine", type: "Full Agonist", ivOnset: "5-10 min", ivDuration: "3-4 hrs", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "M6G (potent analgesic) accumulates in renal failure = prolonged sedation. M3G (neuroexcitatory) accumulation contributes to myoclonus/seizures. Histamine release is dose-dependent.", pharmacokinetics: "Glucuronidation (UGT2B7). High first-pass metabolism (PO Bioavail ~30%).", tags: ["Standard", "Histamine Release", "Vasodilation"], bioavailability: 30),
        
        DrugData(id: "hydromorphone", name: "Hydromorphone", type: "Full Agonist", ivOnset: "5 min", ivDuration: "2-3 hrs", renalSafety: "Caution", hepaticSafety: "Safe", clinicalNuance: "H3G metabolite is solely neuroexcitatory. In renal failure, accumulation causes allodynia and agitation (often mistaken for pain, leading to dangerous dose escalation). 5-7x potency of morphine.", pharmacokinetics: "Glucuronidation. No CYP interactions. Cleaner than morphine but not risk-free.", tags: ["Potent", "Low Volume", "Neuroexcitation Risk"], bioavailability: 24),
        
        DrugData(id: "fentanyl", name: "Fentanyl", type: "Phenylpiperidine", ivOnset: "1-2 min", ivDuration: "30-60 min", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "Context-Sensitive Half-Life: Lipid saturation prolongs elimination (t1/2 ~3.6h terminal, but increases effectively with continuous infusion). Chest wall rigidity with rapid push.", pharmacokinetics: "CYP3A4 substrate. Highly lipophilic. No active metabolites.", tags: ["Renal Safe", "Cardio Stable", "Lipid Storage"], bioavailability: 100),
        
        DrugData(id: "oxycodone", name: "Oxycodone", type: "Full Agonist", ivOnset: "N/A", ivDuration: "3-4 hrs", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "Interaction Alert: Strong CYP3A4 inhibitors (Voriconazole, Posaconazole, Ritonavir) significantly increase AUC. Active metabolite Oxymorphone (via CYP2D6) is minor but relevant in ultra-metabolizers.", pharmacokinetics: "High oral bioavailability (60-87%). Dual metabolism (3A4 > 2D6).", tags: ["Oral Standard", "CYP3A4 Interaction"], bioavailability: 75),
        
        DrugData(id: "methadone", name: "Methadone", type: "Complex Agonist", ivOnset: "Variable", ivDuration: "6-8 hrs (Analgesia)", renalSafety: "Safe", hepaticSafety: "Caution", clinicalNuance: "Non-Linear Kinetics: Ratios vary from 2:1 (<30mg Mor) to 20:1 (>1000mg). 'Stacking' toxicity on Day 3-5 due to long variable t1/2 (15-120h). Respiratory depression peaks later than analgesia.", pharmacokinetics: "CYP3A4/2B6/2D6. Auto-induction occurs. Fecal excretion protects kidneys.", tags: ["Neuropathic", "Stacking Risk", "QT Prolongation"], bioavailability: 80),
        
        DrugData(id: "buprenorphine", name: "Buprenorphine", type: "Partial Agonist", ivOnset: "10-15 min", ivDuration: "6-8 hrs", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "High Affinity (Ki ~0.22nM). Perioperative: Continue basal dose; do NOT taper (prevents destabilization). Add full agonist for acute pain. Ceiling effect on respiratory depression.", pharmacokinetics: "CYP3A4. Dissociates slowly from receptors (long duration).", tags: ["High Affinity", "Split Dosing", "Ceiling Effect"], bioavailability: 30),
        
        DrugData(id: "fentanyl_patch", name: "Fentanyl (Transdermal)", type: "Phenylpiperidine", ivOnset: "12-24 hrs", ivDuration: "72 hrs", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "Heat Sensitivity: Fever or heating pads increase absorption by 30%+, risking overdose. 12-24h 'lag time' when starting/stopping. Do not use in opioid-naive patients. Requirement: >60mg OME baseline.", pharmacokinetics: "Absorbed into skin depot. Steady state takes 3 patches to achieve fully.", tags: ["Chronic Pain Only", "Heat Sensitive", "Depot Effect"], bioavailability: 0),
        
        DrugData(id: "butrans", name: "Buprenorphine (Butrans)", type: "Partial Agonist", ivOnset: "24-48 hrs", ivDuration: "7 days", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "7-Day Patch. Ceiling effect on respiratory depression. Stronger binding affinity than full agonists; can precipitate withdrawal if started too soon after high-dose full agonists.", pharmacokinetics: "Transdermal. Long half-life (~26h after removal).", tags: ["7-Day Patch", "Partial Agonist", "Ceiling Effect"], bioavailability: 15),
        
        DrugData(id: "sublingual_fentanyl", name: "Fentanyl (SL/Buccal)", type: "Phenylpiperidine", ivOnset: "5-15 min", ivDuration: "2-3 hrs", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "TIKOS (TIRF) Drugs. High potency for breakthrough pain. Dose is NOT directly proportional to oral/IV counterparts due to transmucosal bypass of first-pass metabolism.", pharmacokinetics: "Bypasses liver first-pass. Highly lipophilic.", tags: ["TIKOS", "Breakthrough Only", "Rapid Onset"], bioavailability: 50),
        
        DrugData(id: "hydrocodone", name: "Hydrocodone", type: "Full Agonist", ivOnset: "N/A", ivDuration: "4-6 hrs", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "Often combined with Acetaminophen. Watch daily APAP limit. Not primarily a prodrug (intrinsic activity), but CYP2D6 metabolizes it to Hydromorphone (minor pathway).", pharmacokinetics: "CYP3A4 -> Norhydrocodone (Major). CYP2D6 -> Hydromorphone (Minor).", tags: ["Oral Only", "APAP Combo", "Prodrug"], bioavailability: 70),
        
        DrugData(id: "codeine", name: "Codeine", type: "Weak Agonist", ivOnset: "15-30 min", ivDuration: "3-4 hrs", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "Prodrug -> Morphine (CYP2D6). Genetic variability causes failure (poor metabolizers) or overdose (ultra-rapid). Avoid in children/BF/Renal Failure.", pharmacokinetics: "Hepatic metabolism. 10% converted to Morphine.", tags: ["Prodrug", "Genetic Variance", "Weak"], bioavailability: 90),
        
        DrugData(id: "tramadol", name: "Tramadol", type: "Weak Agonist / SNRI", ivOnset: "N/A", ivDuration: "4-6 hrs", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "Lowers seizure threshold. Risk of Serotonin Syndrome. Dual mechanism: Mu-agonist + SNRI. Adjustment required in CKD (Max 200mg).", pharmacokinetics: "CYP2D6/3A4. Active metabolite (O-desmethyltramadol) is more potent.", tags: ["Seizure Risk", "Serotonin Syndrome", "Dual Action"], bioavailability: 75),
        
        DrugData(id: "oxymorphone", name: "Oxymorphone", type: "Full Agonist", ivOnset: "5-10 min", ivDuration: "3-6 hrs", renalSafety: "Caution", hepaticSafety: "Unsafe", clinicalNuance: "Present as major drug form (Opana). As an Oxycodone metabolite, it is minor and clinically insignificant. High potency. Food significantly increases absorption (do not take with high fat meals).", pharmacokinetics: "Direct Glucuronidation. No CYP interactions (cleaner logic than Oxycodone).", tags: ["Potent", "Food Effect"], bioavailability: 10),
        
        DrugData(id: "tapentadol", name: "Tapentadol", type: "Dual Action", ivOnset: "N/A", ivDuration: "4-6 hrs", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "Mu-agonist + NRI (Norepinephrine Reuptake Inhibitor). Less GI side effects than pure agonists. Limited data in severe renal impairment.", pharmacokinetics: "Glucuronidation. No active metabolites.", tags: ["Dual Action", "Less Constipation"], bioavailability: 32),
        
        DrugData(id: "meperidine", name: "Meperidine", type: "Phenylpiperidine", ivOnset: "5 min", ivDuration: "2-3 hrs", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "CONTRAINDICATED in Renal Failure/Elderly. Toxic metabolite (Normeperidine) causes tremors/seizures. High interaction risk (MAOIs). Historic use only.", pharmacokinetics: "Hepatic -> Normeperidine (Neurotoxic, long T1/2).", tags: ["Neurotoxic", "Do Not Use", "Seizure Risk"], bioavailability: 50),
        
        DrugData(id: "sufentanil", name: "Sufentanil", type: "Phenylpiperidine", ivOnset: "1-3 min", ivDuration: "20-45 min", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "ICU/Anesthesia Only. 5-10x potency of Fentanyl. Rapid equilibration.", pharmacokinetics: "High lipid solubility. High protein binding.", tags: ["ICU Only", "Ultra Potent"], bioavailability: 100),
        
        DrugData(id: "alfentanil", name: "Alfentanil", type: "Phenylpiperidine", ivOnset: "<1 min", ivDuration: "10-15 min", renalSafety: "Safe", hepaticSafety: "Var", clinicalNuance: "Fastest onset (low pKa allows rapid BBB crossing). Very short duration. Context-sensitive half-life is favorable.", pharmacokinetics: "CYP3A4. Lower lipid solubility than Fentanyl = less distribution volume.", tags: ["ICU Only", "Rapid Onset"], bioavailability: 100)
    ]
    
    static let warningData: [WarningData] = [
        WarningData(id: "tramadol", name: "Tramadol", risk: "Serotonin Syndrome / Seizure", desc: "Low efficacy but high toxicity. Significant risk with Linezolid (MAOI activity) or SSRIs. Hypoglycemia risk in elderly. 30% of analgesia is non-opioid (SNRI)."),
        WarningData(id: "combo", name: "Combination (APAP)", risk: "Hepatotoxicity Masking", desc: "Inpatients often receive IV Acetaminophen (Ofirmev). Adding Percocet/Norco creates invisible APAP overdose. Always uncouple."),
        WarningData(id: "codeine", name: "Codeine", risk: "Genetic Lottery", desc: "10% of Caucasians lack CYP2D6 (no effect). 30% of Ethiopians/Saudis are Ultra-Rapid Metabolizers (morphine overdose). Clinically indefensible to use.")
    ]
    
    // Legacy support (still used in AssessmentStore for quick lookups)
    static let generalWarnings: [String] = [
        "Avoid NSAIDs in patients with Renal Impairment (CrCl < 30), GI Bleed history, or decompensated Heart Failure.",
        "Avoid Acetaminophen > 2g/day in Hepatic Failure or active alcohol use.",
        "Concurrent use of Benzodiazepines and Opioids increases risk of fatal overdose by 3.8x (Black Box Warning)."
    ]
    
    static let methadoneWarning = "DO NOT ESTIMATE: Methadone conversion varies by total MME (4:1 to 20:1). Accumulates over 5 days (t1/2 8-59h). Risk of QTc prolongation and overdose."
    static let fentanylPatchWarning = "WARNING: Patches take 12-24h to onset. Cover with short-acting. Package insert recommends stricter conversion than standard equianalgesic tables."
    
    static var drugNuances: [String: String] {
        var dict: [String: String] = [:]
        for drug in drugData {
            dict[drug.name] = drug.clinicalNuance
        }
        return dict
    }
}
