import React, { useState } from 'react';
import {
    GitBranch,
    ArrowRight,
    CheckCircle,
    RotateCcw,
    Copy,
    ChevronDown,
    ChevronUp,
    FileText,
    Brain,
    Wind,
    AlertCircle,
    Utensils,
    Thermometer,
    Zap,
    HeartPulse,
    ShieldAlert,
    Stethoscope,
    Terminal,
    Info
} from 'lucide-react';
import { ClinicalCard, Badge } from './Shared';

// --- Types ---

type DecisionNode = {
    id: string;
    text: string;
    options: { label: string; nextId?: string; outcome?: string }[];
};

// --- Data: Flowcharts ---

const FLOWCHARTS: { [key: string]: DecisionNode } = {
    'root': {
        id: 'root',
        text: 'Select the primary clinical scenario:',
        options: [
            { label: 'Cancer Pain Management', nextId: 'cancer_start' },
            { label: 'Neuropathic Pain', nextId: 'neuro_start' },
            { label: 'Inflammatory / Bone Pain', nextId: 'inflam_start' },
            { label: 'Acute Renal Failure', nextId: 'renal_pain' }
        ]
    },
    'cancer_start': {
        id: 'cancer_start',
        text: 'Is the patient opioid-naive?',
        options: [
            { label: 'Yes (Naive)', nextId: 'cancer_naive' },
            { label: 'No (Tolerant)', nextId: 'cancer_tolerant' }
        ]
    },
    'cancer_naive': {
        id: 'cancer_naive',
        text: 'Are there renal or hepatic contraindications?',
        options: [
            { label: 'No (Normal Organs)', outcome: 'Start Morphine IR 5-10mg PO q4h or Oxycodone 5mg PO q4h. Titrate to effect.' },
            { label: 'Yes (Renal/Hepatic)', nextId: 'cancer_organ_failure' }
        ]
    },
    'cancer_organ_failure': {
        id: 'cancer_organ_failure',
        text: 'Select deficiency:',
        options: [
            { label: 'Renal Failure', outcome: 'Avoid Morphine. Use Fentanyl (Patch/IV) or Methadone (consult). Hydromorphone with caution.' },
            { label: 'Hepatic Failure', outcome: 'Avoid Methadone & Codeine. Use Fentanyl. Reduce dose 50% and extend interval.' }
        ]
    },
    'cancer_tolerant': {
        id: 'cancer_tolerant',
        text: 'Is pain controlled on current regimen?',
        options: [
            { label: 'Yes', outcome: 'Continue current regimen. Ensure breakthrough dose is 10-20% of TDD.' },
            { label: 'No (Uncontrolled)', nextId: 'rotate_check' }
        ]
    },
    'rotate_check': {
        id: 'rotate_check',
        text: 'Are side effects limiting dose escalation?',
        options: [
            { label: 'Yes (Side Effects)', outcome: 'Opioid Rotation indicated. Reduce equianalgesic dose by 30-50% for cross-tolerance.' },
            { label: 'No (Just Pain)', outcome: 'Increase TDD by 25-50%. Re-evaluate in 24h.' }
        ]
    },
    'neuro_start': {
        id: 'neuro_start',
        text: 'Is there a nociceptive (tissue damage) component?',
        options: [
            { label: 'Pure Neuropathic', outcome: 'First line: Gabapentin/Pregabalin or TCA/SNRI. Opioids are second/third line.' },
            { label: 'Mixed Pain', nextId: 'neuro_mixed' }
        ]
    },
    'neuro_mixed': {
        id: 'neuro_mixed',
        text: 'Consider Dual-Action Opioids. Are they candidate for Methadone?',
        options: [
            { label: 'Yes (Qtc OK)', outcome: 'Methadone is Gold Standard (NMDA antagonist). Consult Pain for induction.' },
            { label: 'No', outcome: 'Consider Tapentadol (NRI + Mu) or add adjuvant (Gabapentin) to standard opioid.' }
        ]
    },
    'inflam_start': {
        id: 'inflam_start',
        text: 'Is the pain localized or systemic?',
        options: [
            { label: 'Localized (e.g. Bone Met)', outcome: 'Consider NSAIDs (Naproxen/Celecoxib) + Dexamethasone. Rule out fracture.' },
            { label: 'Systemic (e.g. Flare)', nextId: 'inflam_systemic' }
        ]
    },
    'inflam_systemic': {
        id: 'inflam_systemic',
        text: 'Are there GI or Renal contraindications for NSAIDs?',
        options: [
            { label: 'No (Safe for NSAID)', outcome: 'Start Naproxen 500mg BID or Ibuprofen 600mg q6h scheduled.' },
            { label: 'Yes (Avoid NSAID)', outcome: 'Use Tylenol 1g q6h + consider low-dose Steroids or Opioids if severe.' }
        ]
    },
    'renal_pain': {
        id: 'renal_pain',
        text: 'Is the patient on Dialysis?',
        options: [
            { label: 'Yes (Dialysis)', outcome: 'Fentanyl or Methadone preferred. Hydromorphone: Caution (dialyzable). Morphine: CONTRAINDICATED.' },
            { label: 'No (CKD)', outcome: 'GFR < 30: Avoid Morphine. Oxycodone/Hydromorphone: Caution (accumulate). Fentanyl: Safe.' }
        ]
    }
};

// --- Data: Condition Guides ---

const CONDITION_GUIDES = [
    {
        title: "Abdominal Pain (Non Traumatic)",
        recommendations: [
            "IV Ketorolac 10-15 mg OR IV Diclofenac 75 mg OR IV Metimazole",
            "IV Acetaminophen 1g over 15 minutes",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 minutes",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]
    },
    {
        title: "Abdominal Pain (Traumatic)",
        recommendations: [
            "IV Acetaminophen 1g over 15 minutes",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]
    },
    {
        title: "Back Pain (Nonradicular)",
        recommendations: [
            "IV Ketorolac 10-15 mg OR Ibuprofen 400 mg PO OR IV Diclofenac 75 mg OR IV Metimazole 1g",
            "Trigger point injection (10ml 0.5% Bupivacaine or 20ml 1% Lidocaine)",
            "IV Acetaminophen 1g over 15 minutes",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 minutes",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]
    },
    {
        title: "Burns",
        recommendations: [
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 min, then infusion @ 1.5-2.5 mg/kg/hr",
            "IV Dexmedetomidine 0.2-0.7 mcg/kg/hour drip",
            "IV Clonidine 0.3-2 mcg/kg/hour drip"
        ]
    },
    {
        title: "Headache / Migraine",
        recommendations: [
            "IV Metoclopramide 10 mg (slow drip) OR IV Prochlorperazine 10 mg (slow infusion)",
            "Combine w/ IV Diphenhydramine 25-50 mg or IV Chlorpromazine 12.5 mg",
            "SQ Sumatriptan 6 mg (within 1h of onset, repeat in 1h if needed)",
            "IV Ketorolac 10-15 mg OR IV Diclofenac 75 mg OR IV Metimazole 1g",
            "US Guided nerve block / Paracervical trigger point (Lidocaine/Bupivacaine)",
            "IV Haloperidol 2.5 mg OR IV Droperidol 2-5 mg (slow 10 min infusion)",
            "IV Propofol 10 mg IVP q5 min (Intractable migraine)",
            "Refractory: Ketamine 0.2-0.3 mg/kg short infusion"
        ]
    },
    {
        title: "MSK (Musculoskeletal)",
        recommendations: [
            "US guided nerve block",
            "IV Ketorolac 10-15 mg OR IV Diclofenac 75 mg OR IV Metimazole 1g",
            "IV Acetaminophen 1g over 15 minutes",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]
    },
    {
        title: "Neuropathic Pain",
        recommendations: [
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 min, then infusion @ 1.5-2.5 mg/kg/hr",
            "IV Dexmedetomidine 0.2-0.3 mcg/kg/hour infusion",
            "Gabapentin: D1: 300mg QD, D2: 300mg BID, D3: 300mg TID"
        ]
    },
    {
        title: "Renal Colic",
        recommendations: [
            "IV Ketorolac 10-15 mg OR IV Diclofenac 75 mg OR IV Metimazole 1g",
            "IV Acetaminophen 1g over 15 minutes",
            "IV Lidocaine 1.5 mg/kg of 2% over 10-15 minutes",
            "IN Desmopressin 40 mcg once (adjunct to NSAIDs)",
            "IV Ketamine 0.3 mg/kg over 10 min, then drip @ 0.15 mg/kg/hr"
        ]
    },
    {
        title: "Sickle Cell Crisis",
        recommendations: [
            "IN Ketamine 1 mg/kg (max 1 ml per nostril)",
            "IV Ketamine 0.3 mg/kg (min) + drip @ 0.15 mg/kg/hr + SQ infusion @ 0.15-0.25 mg/kg/hr",
            "IV/IM Haloperidol or Droperidol 5-10 mg",
            "IV Dexmedetomidine 0.2-0.3 mcg/kg/hour infusion"
        ]
    }
];

// --- Data: Best Practices ---

const ANTI_EMETICS = [
    { drug: "Metoclopramide", site: "D2 (gut), 5HT3 (high dose)", dose: "5-20 mg PO/IV before meals/QHS", effects: "Dystonia, akathisia" },
    { drug: "Haloperidol", site: "D2 (CTZ)", dose: "0.5-4 mg PO/SQ/IV q6h", effects: "Dystonia, sedation, QTc" },
    { drug: "Prochlorperazine", site: "D2 (CTZ)", dose: "5-10 mg PO/IV q6h or 25 mg PR", effects: "Dystonia, akathisia, QTc" },
    { drug: "Olanzapine", site: "D2, 5HT2A", dose: "2.5-10 mg daily", effects: "Metabolic, sedation, orthostasis" },
    { drug: "Promethazine", site: "H1, ACh, D2", dose: "12.5-25 mg PO/IV/IM q6h", effects: "Anticholinergic, sedation" },
    { drug: "Ondansetron", site: "5HT3", dose: "4-8 mg PO/IV q4-8h", effects: "Headache, constipation, QTc" },
    { drug: "Scopolamine", site: "ACh, H1", dose: "1.5 mg Patch q72h", effects: "Dry mouth, blurred vision" },
    { drug: "Dexamethasone", site: "Steroid", dose: "4-8 mg PO q4-6h", effects: "Psychosis, insomnia, fluid" }
];

// --- Components ---

const FlowchartView = () => {
    const [history, setHistory] = useState<string[]>(['root']);
    const [outcome, setOutcome] = useState<string | null>(null);

    const currentNodeId = history[history.length - 1];
    const currentNode = FLOWCHARTS[currentNodeId];

    const handleSelect = (nextId?: string, outcomeText?: string) => {
        if (outcomeText) setOutcome(outcomeText);
        else if (nextId) setHistory([...history, nextId]);
    };

    return (
        <div className="space-y-6 animate-in fade-in">
            <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 shadow-sm min-h-[300px] flex flex-col justify-center text-center">
                {outcome ? (
                    <div className="space-y-4">
                        <CheckCircle className="w-12 h-12 text-emerald-500 mx-auto" />
                        <h3 className="text-lg font-bold">Recommendation</h3>
                        <p className="text-slate-600 dark:text-slate-400 font-medium leading-relaxed">{outcome}</p>
                        <button onClick={() => { setHistory(['root']); setOutcome(null); }} className="mt-4 px-4 py-2 bg-slate-100 dark:bg-slate-800 rounded-lg text-xs font-bold">Reset Pathway</button>
                    </div>
                ) : (
                    <div className="space-y-6">
                        <h3 className="text-lg font-bold text-slate-800 dark:text-slate-200">{currentNode.text}</h3>
                        <div className="grid gap-2 max-w-md mx-auto">
                            {currentNode.options.map((opt, i) => (
                                <button
                                    key={i}
                                    onClick={() => handleSelect(opt.nextId, opt.outcome)}
                                    className="flex items-center justify-between p-4 rounded-xl border border-slate-200 dark:border-slate-800 hover:border-teal-500 hover:bg-teal-50 dark:hover:bg-teal-900/10 transition-all text-left group"
                                >
                                    <span className="text-sm font-medium">{opt.label}</span>
                                    <ArrowRight className="w-4 h-4 text-slate-300 group-hover:text-teal-500" />
                                </button>
                            ))}
                        </div>
                    </div>
                )}
            </div>
            {/* Breadcrumbs */}
            <div className="flex flex-wrap gap-2 items-center text-[10px] text-slate-400">
                {history.map((h, i) => (
                    <React.Fragment key={i}>
                        {i > 0 && <span>/</span>}
                        <span className="lowercase">{h.replace('_', ' ')}</span>
                    </React.Fragment>
                ))}
            </div>
        </div>
    );
};

const ConditionGuidesView = () => {
    const [activeIdx, setActiveIdx] = useState<number | null>(null);
    return (
        <div className="space-y-3 animate-in fade-in">
            {CONDITION_GUIDES.map((guide, i) => (
                <div key={i} className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 overflow-hidden">
                    <button
                        onClick={() => setActiveIdx(activeIdx === i ? null : i)}
                        className="w-full px-4 py-3 flex justify-between items-center hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                    >
                        <span className="font-bold text-sm text-slate-700 dark:text-slate-300">{guide.title}</span>
                        {activeIdx === i ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                    </button>
                    {activeIdx === i && (
                        <div className="px-4 pb-4 pt-1 space-y-2 border-t border-slate-100 dark:border-slate-800">
                            {guide.recommendations.map((rec, j) => (
                                <div key={j} className="flex gap-2 items-start text-xs text-slate-600 dark:text-slate-400">
                                    <div className="w-1.5 h-1.5 rounded-full bg-teal-500 mt-1.5 flex-none" />
                                    <span>{rec}</span>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            ))}
        </div>
    );
};

const BestPracticesView = () => {
    return (
        <div className="space-y-6 animate-in fade-in">
            <ClinicalCard title="Pain & Symptom Management">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="bg-emerald-50 dark:bg-emerald-900/10 p-4 rounded-lg border border-emerald-100 dark:border-emerald-800/30">
                        <h5 className="text-xs font-bold text-emerald-800 dark:text-emerald-400 uppercase mb-3">Clinician Best Practices</h5>
                        <ul className="text-[11px] text-slate-600 dark:text-slate-400 space-y-2">
                            <li>• Ask about pain/SOB/Nausea/Anxiety <strong>EVERY DAY</strong>.</li>
                            <li>• Never leave a patient in pain without a plan.</li>
                            <li>• Verify home opioid dose before hospital orders.</li>
                            <li>• Set expectations for <strong>OVERNIGHT</strong> care.</li>
                            <li>• Involve specialist (PharmD, Palliative) if initial attempts fail.</li>
                        </ul>
                    </div>
                    <div className="bg-amber-50 dark:bg-amber-900/10 p-4 rounded-lg border border-amber-100 dark:border-amber-800/30">
                        <h5 className="text-xs font-bold text-amber-800 dark:text-amber-400 uppercase mb-3">Caring Wisely</h5>
                        <div className="flex gap-3">
                            <ShieldAlert className="w-10 h-10 text-amber-500 flex-none" />
                            <p className="text-[10px] text-slate-600 dark:text-slate-400 leading-relaxed italic">
                                Avoid topical "ABH" (Ativan, Benadryl, Haldol) gel for nausea. Not proven effective; active ingredients not absorbed to systemic levels.
                            </p>
                        </div>
                    </div>
                </div>
            </ClinicalCard>

            <ClinicalCard title="Nausea & Vomiting Control">
                <div className="overflow-x-auto">
                    <table className="w-full text-[10px] text-left">
                        <thead className="bg-slate-50 dark:bg-slate-800 text-slate-500 uppercase">
                            <tr>
                                <th className="px-2 py-2">Drug</th>
                                <th className="px-2 py-2">Mechanism</th>
                                <th className="px-2 py-2">Standard Dose</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                            {ANTI_EMETICS.map((ae, i) => (
                                <tr key={i} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50">
                                    <td className="px-2 py-2 font-bold text-slate-800 dark:text-slate-200">{ae.drug}</td>
                                    <td className="px-2 py-2 text-slate-500 uppercase">{ae.site}</td>
                                    <td className="px-2 py-2 text-slate-600 dark:text-slate-400">{ae.dose}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </ClinicalCard>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <ClinicalCard title="Dyspnea (SOB)">
                    <div className="space-y-3">
                        <div className="p-3 bg-blue-50 dark:bg-blue-900/10 border border-blue-100 dark:border-blue-800/30 rounded text-[10px] text-blue-800 dark:text-blue-300">
                            <h6 className="font-bold underline mb-1">Non-Pharmacologic:</h6>
                            <p>• Fan or open window (trigeminal nerve stimulation)</p>
                            <p>• Reassurance & expectations for family</p>
                            <p>• O2 for hypoxia (normoxic cannula has no benefit)</p>
                        </div>
                        <div className="p-3 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800 rounded text-xs">
                            <span className="font-bold">Opioid Tx:</span> Morphine 2.5-5mg PO q4h or 1-2mg IV q2-3h. Reduces sensitivity to dyspnea.
                        </div>
                    </div>
                </ClinicalCard>
                <ClinicalCard title="Secretions (Death Rattle)">
                    <div className="space-y-3">
                        <div className="p-3 bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800 rounded">
                            <div className="text-[10px] uppercase font-black text-rose-500 mb-1">Warning</div>
                            <p className="text-[10px] text-slate-500 italic">Often more distressing to family than patient. Avoid deep suction.</p>
                        </div>
                        <div className="text-xs space-y-1">
                            <div>• Atropine 1% drops: 1-2 SL q1-2h (if not awake)</div>
                            <div>• Glycopyrrolate: 0.1-0.2mg IV/SQ q4h</div>
                        </div>
                    </div>
                </ClinicalCard>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <ClinicalCard title="Anxiety">
                    <div className="space-y-3">
                        <p className="text-[10px] text-slate-500 italic">Often exacerbated by untreated symptoms or meds (steroids).</p>
                        <div className="text-xs space-y-2">
                            <div>
                                <span className="font-bold">Acute:</span> Lorazepam 0.5-2 mg PO/IV q6h PRN
                            </div>
                            <div>
                                <span className="font-bold">Non-Pharm:</span> Aromatherapy, massage, SW support
                            </div>
                        </div>
                    </div>
                </ClinicalCard>
                <ClinicalCard title="Anorexia">
                    <div className="space-y-3">
                        <p className="text-[10px] text-slate-500 italic">Terminal anorexia is normal but distressing to caregivers.</p>
                        <div className="text-xs space-y-1">
                            <div>• Megace/Marinol: Inconsistent evidence</div>
                            <div>• Steroids: Short-term appetite boost</div>
                            <div>• Small, palatable meals &gt; large portions</div>
                        </div>
                    </div>
                </ClinicalCard>
            </div>

            <ClinicalCard title="Clinical References">
                <div className="text-[9px] text-slate-400 space-y-1 leading-tight">
                    <p>• Bickel K, Arnold R. Death Rattle and Oral Secretions. Fast Facts #109.</p>
                    <p>• Weissman DE. Dyspnea at End-of-Life. Fast Facts #27.</p>
                    <p>• Gordon WJ, et al. Management of Intractable Nausea... JAMA 2007.</p>
                </div>
            </ClinicalCard>
        </div>
    );
};

// --- Main Component ---

export const ProtocolsView = () => {
    const [activeTab, setActiveTab] = useState<'path' | 'cond' | 'best'>('cond');

    return (
        <div className="h-full flex flex-col gap-4">
            <div className="flex bg-white dark:bg-slate-900 p-1 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm shrink-0 overflow-x-auto no-scrollbar">
                {[
                    { id: 'cond', label: 'Condition Guides', icon: Stethoscope },
                    { id: 'path', label: 'Decision Trees', icon: GitBranch },
                    { id: 'best', label: 'Symptom Care', icon: HeartPulse }
                ].map(item => (
                    <button
                        key={item.id}
                        onClick={() => setActiveTab(item.id as any)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all whitespace-nowrap ${activeTab === item.id
                            ? 'bg-teal-600 text-white shadow-md'
                            : 'text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800'
                            }`}
                    >
                        <item.icon className="w-4 h-4" />
                        {item.label}
                    </button>
                ))}
            </div>

            <div className="flex-1 overflow-y-auto custom-scrollbar pr-2">
                {activeTab === 'path' && <FlowchartView />}
                {activeTab === 'cond' && <ConditionGuidesView />}
                {activeTab === 'best' && <BestPracticesView />}
            </div>
        </div>
    );
};
