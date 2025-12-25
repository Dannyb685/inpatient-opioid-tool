import Foundation

// MARK: - Models

struct DecisionNode {
    let id: String
    let text: String
    let options: [DecisionOption]
}

struct DecisionOption: Identifiable {
    let id = UUID()
    let label: String
    let nextId: String?
    let outcome: String?
}

struct ConditionGuide: Identifiable {
    let id = UUID()
    let title: String
    let recommendations: [String]
}

struct AntiEmetic: Identifiable {
    let id = UUID()
    let drug: String
    let site: String
    let dose: String
    let effects: String
}

// --- Induction Models ---
struct TempleRegimen {
    let title: String
    let oral: [String] // "Oxycodone ER 30-60mg TID"
    let breakthrough: [String] // "Dilaudid 2mg IV"
}

struct BerneseStep: Identifiable {
    let id = UUID()
    let day: Int
    let dose: String
    let note: String
}


// MARK: - Data Store

struct ProtocolData {
    
    // --- Flowcharts ---
    static let flowcharts: [String: DecisionNode] = [
        "root": DecisionNode(id: "root", text: "Select the primary clinical scenario:", options: [
            DecisionOption(label: "Cancer Pain Management", nextId: "cancer_start", outcome: nil),
            DecisionOption(label: "Neuropathic Pain", nextId: "neuro_start", outcome: nil),
            DecisionOption(label: "Inflammatory / Bone Pain", nextId: "inflam_start", outcome: nil),
            DecisionOption(label: "Acute Renal Failure", nextId: "renal_pain", outcome: nil)
        ]),
        "cancer_start": DecisionNode(id: "cancer_start", text: "Is the patient opioid-naive?", options: [
            DecisionOption(label: "Yes (Naive)", nextId: "cancer_naive", outcome: nil),
            DecisionOption(label: "No (Tolerant)", nextId: "cancer_tolerant", outcome: nil)
        ]),
        "cancer_naive": DecisionNode(id: "cancer_naive", text: "Are there renal or hepatic contraindications?", options: [
            DecisionOption(label: "No (Normal Organs)", nextId: nil, outcome: "Start Morphine IR 5-10mg PO q4h or Oxycodone 5mg PO q4h. Titrate to effect."),
            DecisionOption(label: "Yes (Renal/Hepatic)", nextId: "cancer_organ_failure", outcome: nil)
        ]),
        "cancer_organ_failure": DecisionNode(id: "cancer_organ_failure", text: "Select deficiency:", options: [
            DecisionOption(label: "Renal Failure", nextId: nil, outcome: "Avoid Morphine. Use Fentanyl (Patch/IV) or Methadone (consult). Hydromorphone with caution."),
            DecisionOption(label: "Hepatic Failure", nextId: nil, outcome: "Avoid Methadone & Codeine. Use Fentanyl. Reduce dose 50% and extend interval.")
        ]),
        "cancer_tolerant": DecisionNode(id: "cancer_tolerant", text: "Is pain controlled on current regimen?", options: [
            DecisionOption(label: "Yes", nextId: nil, outcome: "Continue current regimen. Ensure breakthrough dose is 10-20% of TDD."),
            DecisionOption(label: "No (Uncontrolled)", nextId: "rotate_check", outcome: nil)
        ]),
        "rotate_check": DecisionNode(id: "rotate_check", text: "Are side effects limiting dose escalation?", options: [
            DecisionOption(label: "Yes (Side Effects)", nextId: nil, outcome: "Opioid Rotation indicated. Reduce equianalgesic dose by 30-50% for cross-tolerance."),
            DecisionOption(label: "No (Just Pain)", nextId: nil, outcome: "Increase TDD by 25-50%. Re-evaluate in 24h.")
        ]),
        "neuro_start": DecisionNode(id: "neuro_start", text: "Is there a nociceptive (tissue damage) component?", options: [
            DecisionOption(label: "Pure Neuropathic", nextId: nil, outcome: "First line: Gabapentin/Pregabalin or TCA/SNRI. Opioids are second/third line."),
            DecisionOption(label: "Mixed Pain", nextId: "neuro_mixed", outcome: nil)
        ]),
        "neuro_mixed": DecisionNode(id: "neuro_mixed", text: "Consider Dual-Action Opioids. Are they candidate for Methadone?", options: [
            DecisionOption(label: "Yes (Qtc OK)", nextId: nil, outcome: "Methadone is Gold Standard (NMDA antagonist). Consult Pain for induction."),
            DecisionOption(label: "No", nextId: nil, outcome: "Consider Tapentadol (NRI + Mu) or add adjuvant (Gabapentin) to standard opioid.")
        ]),
        "inflam_start": DecisionNode(id: "inflam_start", text: "Is the pain localized or systemic?", options: [
            DecisionOption(label: "Localized (e.g. Bone Met)", nextId: nil, outcome: "Consider NSAIDs (Naproxen/Celecoxib) + Dexamethasone. Rule out fracture."),
            DecisionOption(label: "Systemic (e.g. Flare)", nextId: "inflam_systemic", outcome: nil)
        ]),
        "inflam_systemic": DecisionNode(id: "inflam_systemic", text: "Are there GI or Renal contraindications for NSAIDs?", options: [
            DecisionOption(label: "No (Safe for NSAID)", nextId: nil, outcome: "Start Naproxen 500mg BID or Ibuprofen 600mg q6h scheduled."),
            DecisionOption(label: "Yes (Avoid NSAID)", nextId: nil, outcome: "Use Tylenol 1g q6h + consider low-dose Steroids or Opioids if severe.")
        ]),
        "renal_pain": DecisionNode(id: "renal_pain", text: "Is the patient on Dialysis?", options: [
            DecisionOption(label: "Yes (Dialysis)", nextId: nil, outcome: "Fentanyl or Methadone preferred. Hydromorphone: Caution (dialyzable). Morphine: CONTRAINDICATED."),
            DecisionOption(label: "No (CKD)", nextId: nil, outcome: "GFR < 30: Avoid Morphine. Oxycodone/Hydromorphone: Caution (accumulate). Fentanyl: Safe.")
        ])
    ]
    
    // --- Condition Guides ---
    static let conditionGuides: [ConditionGuide] = [
        ConditionGuide(title: "Abdominal Pain (Non Traumatic)", recommendations: [
            "IV Ketorolac 10-15 mg OR IV Diclofenac 75 mg OR IV Metimazole",
            "IV Acetaminophen 1g over 15 minutes",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 minutes",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]),
        ConditionGuide(title: "Abdominal Pain (Traumatic)", recommendations: [
            "IV Acetaminophen 1g over 15 minutes",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]),
        ConditionGuide(title: "Back Pain (Nonradicular)", recommendations: [
            "IV Ketorolac 10-15 mg OR Ibuprofen 400 mg PO OR IV Diclofenac 75 mg OR IV Metimazole 1g",
            "Trigger point injection (10ml 0.5% Bupivacaine or 20ml 1% Lidocaine)",
            "IV Acetaminophen 1g over 15 minutes",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 minutes",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]),
        ConditionGuide(title: "Burns", recommendations: [
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 min, then infusion @ 1.5-2.5 mg/kg/hr",
            "IV Dexmedetomidine 0.2-0.7 mcg/kg/hour drip",
            "IV Clonidine 0.3-2 mcg/kg/hour drip"
        ]),
        ConditionGuide(title: "Headache / Migraine", recommendations: [
            "IV Metoclopramide 10 mg (slow drip) OR IV Prochlorperazine 10 mg (slow infusion)",
            "Combine w/ IV Diphenhydramine 25-50 mg or IV Chlorpromazine 12.5 mg",
            "SQ Sumatriptan 6 mg (within 1h of onset, repeat in 1h if needed)",
            "IV Ketorolac 10-15 mg OR IV Diclofenac 75 mg OR IV Metimazole 1g",
            "US Guided nerve block / Paracervical trigger point (Lidocaine/Bupivacaine)",
            "IV Haloperidol 2.5 mg OR IV Droperidol 2-5 mg (slow 10 min infusion)",
            "IV Propofol 10 mg IVP q5 min (Intractable migraine)",
            "Refractory: Ketamine 0.2-0.3 mg/kg short infusion"
        ]),
        ConditionGuide(title: "MSK (Musculoskeletal)", recommendations: [
            "US guided nerve block",
            "IV Ketorolac 10-15 mg OR IV Diclofenac 75 mg OR IV Metimazole 1g",
            "IV Acetaminophen 1g over 15 minutes",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]),
        ConditionGuide(title: "Neuropathic Pain", recommendations: [
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 min, then infusion @ 1.5-2.5 mg/kg/hr",
            "IV Dexmedetomidine 0.2-0.3 mcg/kg/hour infusion",
            "Gabapentin: D1: 300mg QD, D2: 300mg BID, D3: 300mg TID"
        ]),
        ConditionGuide(title: "Renal Colic", recommendations: [
            "IV Ketorolac 10-15 mg OR IV Diclofenac 75 mg OR IV Metimazole 1g",
            "IV Acetaminophen 1g over 15 minutes",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 minutes",
            "IN Desmopressin 40 mcg once (adjunct to NSAIDs)",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]),
        ConditionGuide(title: "Sickle Cell Crisis", recommendations: [
            "IN Ketamine 1 mg/kg (max 1 ml per nostril)",
            "IV Ketamine 0.3 mg/kg (min) + drip @ 0.15 mg/kg/hr + SQ infusion @ 0.15-0.25 mg/kg/hr",
            "IV/IM Haloperidol or Droperidol 5-10 mg",
            "IV Dexmedetomidine 0.2-0.3 mcg/kg/hour infusion"
        ])
    ]
    
    // --- Anti-Emetics ---
    static let antiEmetics: [AntiEmetic] = [
        AntiEmetic(drug: "Metoclopramide", site: "D2 (gut), 5HT3 (high dose)", dose: "5-20 mg PO/IV before meals/QHS", effects: "Dystonia, akathisia"),
        AntiEmetic(drug: "Haloperidol", site: "D2 (CTZ)", dose: "0.5-4 mg PO/SQ/IV q6h", effects: "Dystonia, sedation, QTc"),
        AntiEmetic(drug: "Prochlorperazine", site: "D2 (CTZ)", dose: "5-10 mg PO/IV q6h or 25 mg PR", effects: "Dystonia, akathisia, QTc"),
        AntiEmetic(drug: "Olanzapine", site: "D2, 5HT2A", dose: "2.5-10 mg daily", effects: "Metabolic, sedation, orthostasis"),
        AntiEmetic(drug: "Promethazine", site: "H1, ACh, D2", dose: "12.5-25 mg PO/IV/IM q6h", effects: "Anticholinergic, sedation"),
        AntiEmetic(drug: "Ondansetron", site: "5HT3", dose: "4-8 mg PO/IV q4-8h", effects: "Headache, constipation, QTc"),
        AntiEmetic(drug: "Scopolamine", site: "ACh, H1", dose: "1.5 mg Patch q72h", effects: "Dry mouth, blurred vision"),
        AntiEmetic(drug: "Dexamethasone", site: "Steroid", dose: "4-8 mg PO q4-6h", effects: "Psychosis, insomnia, fluid")
    ]
    
    // --- Induction Protocols ---
    static let templeData = TempleRegimen(
        title: "Temple Protocol (Aggressive MOUD)",
        oral: ["Oxycodone ER: 30-60mg TID (Up by 20mg q8h PRN)", "Oxycodone IR: 15-30mg q4h PRN"],
        breakthrough: ["Standard: Dilaudid 2mg IV PRN", "PCA: Dilaudid 1mg/hr basal + 0.5-1mg demand q10min"]
    )
    
    static let berneseData: [BerneseStep] = [
        BerneseStep(day: 1, dose: "0.5 mg once", note: "Continue full agonist."),
        BerneseStep(day: 2, dose: "0.5 mg BID", note: "Continue full agonist."),
        BerneseStep(day: 3, dose: "1 mg BID", note: "Continue full agonist."),
        BerneseStep(day: 4, dose: "2 mg BID", note: "Continue full agonist."),
        BerneseStep(day: 5, dose: "4 mg BID", note: "Continue full agonist."),
        BerneseStep(day: 6, dose: "8 mg daily", note: "STOP full agonist.")
    ]
}
