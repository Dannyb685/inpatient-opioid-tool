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
struct SymptomItem: Identifiable, Hashable {
    let id = UUID()
    let drug: String
    let dose: String
    let note: String
}

struct SymptomCategory: Identifiable {
    let id = UUID()
    let title: String
    let items: [SymptomItem]
}

struct BerneseStep: Identifiable {
    let id = UUID()
    let day: Int
    let dose: String
    let note: String
}


// MARK: - Data Store

struct ProtocolData {
    
    // --- Flowcharts (Clinical Decision Support) ---
    static let flowcharts: [String: DecisionNode] = [
        
        // MARK: - Root (Phenotype Selector)
        "root": DecisionNode(id: "root", text: "Select the Pain Phenotype:", options: [
            DecisionOption(label: "Acute Nociceptive (Tissue Injury)", nextId: "noci_start", outcome: nil),
            DecisionOption(label: "Neuropathic (Nerve Lesion)", nextId: "neuro_start", outcome: nil),
            DecisionOption(label: "Nociplastic (Central Sensitization)", nextId: "plastic_start", outcome: nil),
            DecisionOption(label: "Acute-on-Chronic Flare", nextId: "flare_start", outcome: nil),
            DecisionOption(label: "Palliative / Malignant", nextId: "palliative_start", outcome: nil),
            DecisionOption(label: "Opioid Tolerant / SUD", nextId: "sud_start", outcome: nil)
        ]),
        
        // MARK: - 1. Acute Nociceptive (Trauma, Post-op)
        "noci_start": DecisionNode(id: "noci_start", text: "Severity of Tissue Injury:", options: [
            DecisionOption(label: "Mild-Moderate (e.g., Sprain)", nextId: nil, outcome: "**First Line:** Multimodal: Acetaminophen 1g + NSAID (Ibuprofen 400-600mg).\n\n**Escalation:** Add weak opioid (e.g., Oxycodone 5mg) only for breakthrough. Max 3 days."),
            DecisionOption(label: "Severe (e.g., Fracture, Burn)", nextId: nil, outcome: "**Immediate Analgesia:** Start IV Opioid (Morphine 0.1mg/kg or Fentanyl). Transition to PO when able.\n\n**Opioid Sparing:** MANDATORY: Add Regional Block, IV Tylenol, or Ketamine (0.1-0.3 mg/kg) to reduce opioid requirement.")
        ]),

        // MARK: - 2. Neuropathic (Peripheral/Central)
        "neuro_start": DecisionNode(id: "neuro_start", text: "Select Neuropathic Presentation:", options: [
            DecisionOption(label: "Localized (e.g., PHN)", nextId: nil, outcome: "**First Line:** Topical Lidocaine 5% Patch (12h on/off) OR Capsaicin.\n\n**Second Line:** Add Gabapentin/Pregabalin."),
            DecisionOption(label: "Diffuse (e.g., Diabetic Poly)", nextId: nil, outcome: "**First Line (NeuPSIG):** Gabapentinoids (Gabapentin/Pregabalin) OR SNRIs (Duloxetine/Venlafaxine).\n\n**Avoid:** Opioids are 3rd line. Low efficacy, high risk. Use only as last resort (e.g., Tapentadol).")
        ]),

        // MARK: - 3. Nociplastic (Fibro, Central Sensitization)
        "plastic_start": DecisionNode(id: "plastic_start", text: "Nociplastic Strategy (Fibromyalgia/IBS):", options: [
            DecisionOption(label: "Primary Goal", nextId: nil, outcome: "**Pharmacologic:** SNRIs (Duloxetine/Milnacipran) or TCA (Amitriptyline). Gabapentinoids are 2nd line.\n\n**Non-Pharm (Crucial):** Aerobic Exercise, CBT, Sleep Hygiene. Passive therapies (massage) are less effective."),
            DecisionOption(label: "Opioid Question", nextId: nil, outcome: "STOP. Opioids worsen nociplastic pain (Hyperalgesia). Do not initiate.")
        ]),

        // MARK: - 4. Acute-on-Chronic Flare
        "flare_start": DecisionNode(id: "flare_start", text: "Verify Baseline Status:", options: [
            DecisionOption(label: "Baseline Verifiable?", nextId: "flare_verify", outcome: nil)
        ]),
        
        "flare_verify": DecisionNode(id: "flare_verify", text: "Can you confirm home dose (PDMP/Pharmacy)?", options: [
            DecisionOption(label: "Yes (Verified)", nextId: nil, outcome: "**Step 1 (Baseline):** Continue verified home basal opioids (prevent withdrawal).\n\n**Step 2 (Acute):** Treat new injury with standard acute doses (10-20% > baseline). Do not increase baseline long-term."),
            DecisionOption(label: "No (Unverified)", nextId: nil, outcome: "SAFETY: Do not restart full home dose. Start 50-70% to prevent overdose. Treat acute pain independently.")
        ]),

        // MARK: - 5. Palliative / Malignant
        "palliative_start": DecisionNode(id: "palliative_start", text: "Goal of Care:", options: [
            DecisionOption(label: "Quality of Life / Comfort", nextId: nil, outcome: "**Uncontrolled Pain:** Titrate by 25-50% q24h. Use IR breakthrough (10-20% of TDD) q1h prn.\n\n**Bone Metastasis:** Add NSAID (if safe) or Dexamethasone 4-8mg. Consider Radiation.")
        ]),

        // MARK: - 6. Opioid Tolerant / SUD
        "sud_start": DecisionNode(id: "sud_start", text: "Patient Profile:", options: [
            DecisionOption(label: "Active SUD / High Risk", nextId: "sud_active", outcome: nil),
            DecisionOption(label: "Physiologic Tolerance Only", nextId: "flare_start", outcome: nil) // Route to Acute-on-Chronic
        ]),
        
        "sud_active": DecisionNode(id: "sud_active", text: "Active SUD Management:", options: [
            DecisionOption(label: "On Buprenorphine (MAT)?", nextId: nil, outcome: "**Perioperative/Acute:** CONTINUE Buprenorphine (prevents relapse). Add high-affinity agonist (Fentanyl/Dilaudid) on top for acute pain.\n\n**Severe Pain:** Split Buprenorphine dose q6-8h for better analgesia."),
            DecisionOption(label: "Not on MAT", nextId: nil, outcome: "**Strategy:** Opioid Sparing (Ketamine/Blocks) is priority. If opioids needed, avoid IV Push (reduces euphoria). Use Oral or PCA.\n\n**Discharge:** Do not prescribe long-course opioids. Limit <3 days. Coordinate with Addiction Medicine.")
        ]),
    ]
    
    // --- Condition Guides ---
    static let generalPrinciples: [ConditionGuide] = [
        ConditionGuide(title: "Opioids Likely Required", recommendations: [
            "Major trauma",
            "Crush injuries",
            "Burns",
            "Major surgery",
            "Severe pain PLUS Contraindications to NSAIDs OR NSAIDs unlikely to be effective"
        ]),
        ConditionGuide(title: "Non-Opioids Likely Effective", recommendations: [
            "Lower back pain",
            "Neck pain",
            "Soft tissue injuries (e.g., sprain, bursitis)",
            "Minor surgery",
            "Odontalgia",
            "Renal colic",
            "Headaches (including migraine)"
        ])
    ]

    static let conditionGuides: [ConditionGuide] = [
        
        ConditionGuide(title: "Abdominal Pain (Non-Traumatic)", recommendations: [
            "First-Line: IV Acetaminophen 1g over 15 min OR Oral NSAIDs",
            "Refractory: Low-dose Ketamine 0.1–0.3 mg/kg IV (selected cases)",
            "Management: Etiology-specific treatment; Consider nerve blocks (e.g., ESP for pancreatitis)",
            "Contraindications: NSAIDs only after excluding GI bleed, perforation, and bowel obstruction."
        ]),
        
        ConditionGuide(title: "Abdominal Pain (Traumatic)", recommendations: [
            "First-Line: IV Acetaminophen 1g over 15 min",
            "Analgesia: Low-dose Ketamine 0.1–0.3 mg/kg IV OR Fentanyl 0.5–1 mcg/kg IV (unstable)",
            "Adjunct: Regional anesthesia if appropriate",
            "Safety: Avoid NSAIDs until hemorrhage excluded; Ketamine preferred for hemodynamic stability."
        ]),
        
        ConditionGuide(title: "Back Pain (Acute, Non-Radicular)", recommendations: [
            "First-Line: Ibuprofen 400–600mg OR Naproxen 500mg OR IV Ketorolac 15–30mg",
            "Adjuncts: Muscle relaxants (Cyclobenzaprine 5–10mg) - Note: Increased risk of sedation/adverse events",
            "Note: Acetaminophen monotherapy shows no difference from placebo for pain/disability.",
            "Contraindications: Avoid benzodiazepines (guidelines recommend against use)."
        ]),
        
        ConditionGuide(title: "Chest Wall Pain / Costochondritis", recommendations: [
            "First-Line: Topical NSAIDs (Diclofenac gel) OR Oral NSAIDs",
            "Adjuncts: Lidocaine 5% patch OR Oral Acetaminophen 1g",
            "Procedural: Serratus Anterior or Erector Spinae Plane block (Highly effective for rib fractures)",
            "Note: Nerve blocks provide superior pain control with minimal systemic side effects."
        ]),
        
        ConditionGuide(title: "Fractures (Extremity)", recommendations: [
            "First-Line: Topical NSAIDs OR Oral Ibuprofen 400–600mg",
            "Adjunct: Oral Acetaminophen 1g",
            "Severe Pain: Regional nerve block (Brachial plexus, Femoral, Sciatic)",
            "Refractory: Low-dose Ketamine 0.1–0.3 mg/kg",
            "Evidence: Short-term NSAID use is considered safe for fracture healing."
        ]),
        
        ConditionGuide(title: "Headache / Migraine (Acute)", recommendations: [
            "First-Line: IV Prochlorperazine/Metoclopramide 10mg + IV Diphenhydramine 25–50mg",
            "Second-Line: SC Sumatriptan 6mg OR IV Ketorolac 15–30mg OR Occipital Nerve Block",
            "Cardio-Safe Alternative: Ubrogepant 50-100mg OR Rimegepant 75mg (Gepants)",
            "Refractory: IV Valproate 500–1000mg OR IV Haloperidol 2.5–5mg",
            "Contraindications: Avoid Triptans in CAD, Stroke, or uncontrolled HTN."
        ]),
        
        ConditionGuide(title: "MSK Trauma (Acute)", recommendations: [
            "First-Line: Topical NSAIDs (Diclofenac) OR Oral Ibuprofen 400–600mg",
            "Second-Line: IV Acetaminophen 1g (if NPO) OR Oral Acetaminophen 1g",
            "Severe Pain: US-guided nerve block OR Low-dose Ketamine 0.1–0.3 mg/kg",
            "Safety: Check renal function before systemic NSAIDs."
        ]),
        
        ConditionGuide(title: "Neuropathic Pain (Acute)", recommendations: [
            "First-Line: Gabapentin load (300mg D1 → 300mg BID D2 → 300mg TID D3)",
            "Exacerbation: Low-dose Ketamine 0.1–0.3 mg/kg IV",
            "Selected Indication ONLY: IV Lidocaine 1.5 mg/kg (Radicular pain / Zoster / Renal Colic)",
            "CRITICAL SAFETY: IV Lidocaine requires continuous cardiac monitoring. High adverse event risk.",
            "Contraindications: IV Lidocaine absolute contraindication in structural heart disease/arrhythmia."
        ]),
        
        ConditionGuide(title: "Renal Colic", recommendations: [
            "First-Line: IV/IM Ketorolac 15–30mg OR IV Diclofenac 75mg",
            "Second-Line: IV Acetaminophen 1g over 15 min",
            "Investigational Adjunct: IN Desmopressin 40mcg (Mixed evidence; inferior to NSAIDs)",
            "Contraindications: NSAIDs in renal impairment (GFR <60), GI bleed, or anticoagulation."
        ]),
        
        ConditionGuide(title: "Sickle Cell Crisis", recommendations: [
            "First-Line: IV Morphine 0.1 mg/kg OR Hydromorphone 0.5–1mg (Start within 60 min)",
            "Adjunct: IV Ketorolac 15–30mg (if no contraindications)",
            "Refractory: Low-dose Ketamine 0.1–0.3 mg/kg IV",
            "Dosing Principle: Individualize to patient's home baseline requirement. Do NOT delay opioids."
        ])
    ]
    
    // --- Symptom Management ---
    static let symptomManagement: [SymptomCategory] = [
        SymptomCategory(title: "Pain", items: [
            SymptomItem(drug: "Acetaminophen", dose: "650 mg PO q6h PRN", note: "Mild pain, headache, myalgias (5 days)")
        ]),
        SymptomCategory(title: "Anxiety", items: [
            SymptomItem(drug: "Hydroxyzine", dose: "25 mg PO q6h PRN", note: "Anxiety (5 days)"),
            SymptomItem(drug: "Clonidine", dose: "0.1 mg PO q6h PRN", note: "Restlessness or anxiety"),
            SymptomItem(drug: "Gabapentin", dose: "100-300 mg PO TID PRN", note: "Anxiety (5 days)")
        ]),
        SymptomCategory(title: "GI Symptoms", items: [
            SymptomItem(drug: "Hyoscyamine", dose: "125 mcg PO q6h PRN", note: "Cramping or abdominal pain (5 days)"),
            SymptomItem(drug: "Loperamide", dose: "2 mg PO q6h PRN", note: "Diarrhea (5 days)"),
            SymptomItem(drug: "Ondansetron ODT", dose: "4 mg PO q6h PRN", note: "Nausea or vomiting (5 days)")
        ]),
        SymptomCategory(title: "Sleep", items: [
            SymptomItem(drug: "Trazodone", dose: "50 mg PO QHS PRN", note: "Sleep (5 days)"),
            SymptomItem(drug: "Gabapentin", dose: "100-300 mg PO QHS PRN", note: "Sleep (5 days)")
        ]),
        SymptomCategory(title: "Harm Reduction", items: [
            SymptomItem(drug: "Naloxone", dose: "Distribution", note: "Referral to IDEA Exchange")
        ])
    ]
    
    struct InductionStep: Identifiable {
        let id = UUID()
        let step: String
        let action: String
        let note: String
    }
    
    static let standardInduction: [InductionStep] = [
        InductionStep(step: "Assessment", action: "Wait for COWS ≥ 8", note: "Mild-moderate withdrawal; 12-24h since last short-acting opioid."),
        InductionStep(step: "Initial Dose", action: "2 mg - 4 mg Sublingual", note: "Dissolve fully under tongue. Observe for 60 minutes."),
        InductionStep(step: "Re-Assessment", action: "Repeated COWS Score", note: "If symptoms persist and no precipitated withdrawal, repeat 4mg dose."),
        InductionStep(step: "Titration", action: "Max 12-16 mg Day 1", note: "Aim for symptom relief. Establish maintenance dose on Day 2.")
    ]
    
    // --- Induction Protocols ---
    
    static let berneseData: [BerneseStep] = [
        BerneseStep(day: 1, dose: "0.5 mg once", note: "Continue full agonist."),
        BerneseStep(day: 2, dose: "0.5 mg BID", note: "Continue full agonist."),
        BerneseStep(day: 3, dose: "1 mg BID", note: "Continue full agonist."),
        BerneseStep(day: 4, dose: "2 mg BID", note: "Continue full agonist."),
        BerneseStep(day: 5, dose: "4 mg BID", note: "Continue full agonist."),
        BerneseStep(day: 6, dose: "8 mg daily", note: "STOP full agonist.")
    ]
}
    
