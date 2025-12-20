import React, { useState } from 'react';
import {
    GitBranch,
    ArrowRight,
    CheckCircle,
    RotateCcw,
    CornerDownRight,
    Copy
} from 'lucide-react';

type DecisionNode = {
    id: string;
    text: string;
    options: { label: string; nextId?: string; outcome?: string }[];
};

const PROTOCOLS: { [key: string]: DecisionNode } = {
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
    // Cancer Branch
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
    // Neuropathic Branch
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
    // Inflammatory Branch
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
    // Renal Branch
    'renal_pain': {
        id: 'renal_pain',
        text: 'Is the patient on Dialysis?',
        options: [
            { label: 'Yes (Dialysis)', outcome: 'Fentanyl or Methadone preferred. Hydromorphone: Caution (dialyzable). Morphine: CONTRAINDICATED.' },
            { label: 'No (CKD)', outcome: 'GFR < 30: Avoid Morphine. Oxycodone/Hydromorphone: Caution (accumulate). Fentanyl: Safe.' }
        ]
    }
};

export const ProtocolsView = () => {
    const [history, setHistory] = useState<string[]>(['root']);
    const [outcome, setOutcome] = useState<string | null>(null);

    const currentNodeId = history[history.length - 1];
    const currentNode = PROTOCOLS[currentNodeId];

    const handleSelect = (nextId?: string, outcomeText?: string) => {
        if (outcomeText) {
            setOutcome(outcomeText);
        } else if (nextId) {
            setHistory([...history, nextId]);
        }
    };

    const handleReset = () => {
        setHistory(['root']);
        setOutcome(null);
    };

    const handleBack = () => {
        if (history.length > 1) {
            setHistory(history.slice(0, -1));
            setOutcome(null);
        }
    };

    const handleCopy = () => {
        // Generate summary of path
        const path = history.map(id => {
            const node = PROTOCOLS[id];
            // Find option that led to next node... complex to reverse engineer without storing choices.
            // Let's just copy the Outcome.
            return node.text;
        }).join(' -> ');

        const text = `Clinical Protocol Decision:\nOutcome: ${outcome}\nContext: ${currentNode.text}`;
        navigator.clipboard.writeText(text);
    };

    return (
        <div className="h-full flex flex-col items-center justify-center p-6 max-w-2xl mx-auto">
            <div className="w-full bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden flex flex-col min-h-[400px]">
                {/* Header */}
                <div className="bg-slate-50 p-4 border-b border-slate-100 flex justify-between items-center">
                    <div className="flex items-center gap-2">
                        <GitBranch className="w-5 h-5 text-teal-600" />
                        <span className="font-bold text-slate-700">Clinical Pathways</span>
                    </div>
                    <div className="flex gap-2">
                        {history.length > 1 && (
                            <button onClick={handleBack} className="text-xs text-slate-500 hover:text-slate-800 font-medium px-2 py-1">
                                Back
                            </button>
                        )}
                        <button onClick={handleReset} className="text-xs text-slate-500 hover:text-slate-800 font-medium px-2 py-1 flex items-center gap-1">
                            <RotateCcw className="w-3 h-3" /> Reset
                        </button>
                    </div>
                </div>

                {/* Content */}
                <div className="flex-1 p-8 flex flex-col items-center justify-center text-center animate-in fade-in slide-in-from-right-4">
                    {outcome ? (
                        <div className="space-y-6">
                            <div className="w-16 h-16 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4">
                                <CheckCircle className="w-8 h-8" />
                            </div>
                            <h3 className="text-xl font-bold text-slate-800">Recommendation</h3>
                            <p className="text-lg text-slate-600 leading-relaxed font-medium">
                                {outcome}
                            </p>
                            <button
                                onClick={handleCopy}
                                className="mt-8 flex items-center gap-2 mx-auto px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-lg transition-colors font-bold text-sm"
                            >
                                <Copy className="w-4 h-4" /> Copy Recommendation
                            </button>
                        </div>
                    ) : (
                        <div className="w-full space-y-8">
                            <h3 className="text-xl font-bold text-slate-800">
                                {currentNode.text}
                            </h3>
                            <div className="grid gap-3 w-full max-w-md mx-auto">
                                {currentNode.options.map((opt, i) => (
                                    <button
                                        key={i}
                                        onClick={() => handleSelect(opt.nextId, opt.outcome)}
                                        className="flex items-center justify-between p-4 rounded-xl border border-slate-200 hover:border-teal-500 hover:bg-teal-50 hover:text-teal-900 transition-all group text-left"
                                    >
                                        <span className="font-medium text-slate-700 group-hover:text-teal-900">{opt.label}</span>
                                        <ArrowRight className="w-4 h-4 text-slate-300 group-hover:text-teal-600" />
                                    </button>
                                ))}
                            </div>
                        </div>
                    )}
                </div>

                {/* Footer Breadcrumbs */}
                <div className="bg-slate-50 p-3 border-t border-slate-100 text-[10px] text-slate-400 flex items-center gap-2 overflow-hidden">
                    {history.map((id, i) => (
                        <React.Fragment key={id}>
                            {i > 0 && <ArrowRight className="w-3 h-3 flex-none opacity-50" />}
                            <span className="whitespace-nowrap">{id === 'root' ? 'Start' : id.replace(/_/g, ' ')}</span>
                        </React.Fragment>
                    ))}
                </div>
            </div>
        </div>
    );
};
