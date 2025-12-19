export const DRUG_DATA = [
    {
        id: 'morphine',
        name: 'Morphine',
        type: 'Full Agonist',
        iv_onset: '5-10 min',
        iv_duration: '3-4 hrs',
        renal_safety: 'Unsafe',
        hepatic_safety: 'Caution',
        clinical_nuance: 'M6G (analgesic) accumulates in renal failure = prolonged sedation. M3G (neuroexcitatory) accumulates = myoclonus/seizures. Histamine release is dose-dependent; avoid in hemodynamic instability.',
        pharmacokinetics: 'Glucuronidation (UGT2B7). High first-pass metabolism (PO Bioavail ~30%).',
        tags: ['Standard', 'Histamine Release', 'Vasodilation'],
        bioavailability: 30
    },
    {
        id: 'hydromorphone',
        name: 'Hydromorphone',
        type: 'Full Agonist',
        iv_onset: '5 min',
        iv_duration: '2-3 hrs',
        renal_safety: 'Caution',
        hepatic_safety: 'Safe',
        clinical_nuance: 'H3G metabolite is solely neuroexcitatory. In renal failure, accumulation causes allodynia and agitation (often mistaken for pain, leading to dangerous dose escalation). 5-7x potency of morphine.',
        pharmacokinetics: 'Glucuronidation. No CYP interactions. Cleaner than morphine but not risk-free.',
        tags: ['Potent', 'Low Volume', 'Neuroexcitation Risk'],
        bioavailability: 40
    },
    {
        id: 'fentanyl',
        name: 'Fentanyl',
        type: 'Phenylpiperidine',
        iv_onset: '1-2 min',
        iv_duration: '30-60 min',
        renal_safety: 'Safe',
        hepatic_safety: 'Safe',
        clinical_nuance: 'Context-Sensitive Half-Life: With continuous infusion >24h, lipid saturation occurs, prolonging elimination (t1/2 rises from 4h to >12h). Rigid chest wall syndrome possible with rapid high-dose push.',
        pharmacokinetics: 'CYP3A4 substrate. Highly lipophilic. No active metabolites.',
        tags: ['Renal Safe', 'Cardio Stable', 'Lipid Storage'],
        bioavailability: 0
    },
    {
        id: 'oxycodone',
        name: 'Oxycodone',
        type: 'Full Agonist',
        iv_onset: 'N/A',
        iv_duration: '3-4 hrs',
        renal_safety: 'Caution',
        hepatic_safety: 'Caution',
        clinical_nuance: 'Interaction Alert: Strong CYP3A4 inhibitors (Voriconazole, Posaconazole, Ritonavir) significantly increase AUC. Active metabolite Oxymorphone (via CYP2D6) is minor but relevant in ultra-metabolizers.',
        pharmacokinetics: 'High oral bioavailability (60-87%). Dual metabolism (3A4 > 2D6).',
        tags: ['Oral Standard', 'CYP3A4 Interaction'],
        bioavailability: 75
    },
    {
        id: 'methadone',
        name: 'Methadone',
        type: 'Complex Agonist',
        iv_onset: 'Variable',
        iv_duration: '6-8 hrs (Analgesia)',
        renal_safety: 'Safe',
        hepatic_safety: 'Caution',
        clinical_nuance: 'The Dissociation Trap: Analgesia lasts 6-8h, but elimination t1/2 is 15-60h. "Stacking" toxicity typically occurs on Day 3-5. EKG mandatory (hERG blockade). NMDA antagonism reverses tolerance.',
        pharmacokinetics: 'CYP3A4/2B6/2D6. Auto-induction occurs. Fecal excretion protects kidneys.',
        tags: ['Neuropathic', 'Stacking Risk', 'QT Prolongation'],
        bioavailability: 80
    },
    {
        id: 'buprenorphine',
        name: 'Buprenorphine',
        type: 'Partial Agonist',
        iv_onset: '10-15 min',
        iv_duration: '6-8 hrs',
        renal_safety: 'Safe',
        hepatic_safety: 'Safe',
        clinical_nuance: 'Binding Affinity (Ki ~0.22 nM) is stronger than Fentanyl (~1.35 nM). To treat acute pain, you must maintain baseline occupancy and use high-affinity full agonists to cover remaining receptors. Do not stop maintenance.',
        pharmacokinetics: 'CYP3A4. Ceiling effect on respiratory depression, but NOT on sedation if combined with benzos.',
        tags: ['High Affinity', 'Split Dosing', 'Ceiling Effect'],
        bioavailability: 30
    }
];

export const WARNING_DATA = [
    {
        id: 'tramadol',
        name: 'Tramadol',
        risk: 'Serotonin Syndrome / Seizure',
        desc: 'Low efficacy but high toxicity. Risk increases 5x with Linezolid (MAOI activity) or SSRIs. Hypoglycemia risk in elderly. 30% of analgesia is non-opioid (SNRI).'
    },
    {
        id: 'combo',
        name: 'Combination (APAP)',
        risk: 'Hepatotoxicity Masking',
        desc: 'Inpatients often receive IV Acetaminophen (Ofirmev). Adding Percocet/Norco creates invisible APAP overdose. Always uncouple.'
    },
    {
        id: 'codeine',
        name: 'Codeine',
        risk: 'Genetic Lottery',
        desc: '10% of Caucasians lack CYP2D6 (no effect). 30% of Ethiopians/Saudis are Ultra-Rapid Metabolizers (morphine overdose). Clinically indefensible to use.'
    }
];
