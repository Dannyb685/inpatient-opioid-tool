import React, { useState } from 'react';
import {
    ClipboardCheck,
    Thermometer,
    Activity,
    Brain,
    AlertTriangle,
    FileText,
    Copy,
    ChevronRight,
    Stethoscope,
    ShieldCheck,
    Pill
} from 'lucide-react';
import { ClinicalCard, Badge } from './Shared';

type ScaleItem = {
    id: string;
    label: string;
    options: { score: number; text: string }[];
};

const COWS_DATA: ScaleItem[] = [
    { id: 'pulse', label: 'Resting Pulse Rate', options: [{ score: 0, text: '≤80' }, { score: 1, text: '81-100' }, { score: 2, text: '101-120' }, { score: 4, text: '>120' }] },
    { id: 'sweat', label: 'Sweating', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Chills/Moist' }, { score: 2, text: 'Beads of sweat' }, { score: 3, text: 'Drenching' }] },
    { id: 'restless', label: 'Restlessness', options: [{ score: 0, text: 'Able to sit still' }, { score: 1, text: 'Difficulty sitting' }, { score: 3, text: 'Frequent shifting' }, { score: 5, text: 'Unable to sit' }] },
    { id: 'pupil', label: 'Pupil Size', options: [{ score: 0, text: 'Normal' }, { score: 1, text: 'Pinned' }, { score: 2, text: 'Mod Dilation' }, { score: 5, text: 'Dilated Only' }] },
    { id: 'ache', label: 'Bone/Joint Aches', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Mild' }, { score: 2, text: 'Severe/Rubbing' }, { score: 4, text: 'Unbearable' }] },
    { id: 'nose', label: 'Runny Nose / Tearing', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Stuffiness' }, { score: 2, text: 'Running/Tearing' }, { score: 4, text: 'Profuse' }] },
    { id: 'gi', label: 'GI Upset', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Loose Stools' }, { score: 2, text: 'Nausea/Cramps' }, { score: 3, text: 'Vomiting/Diarrhea' }] },
    { id: 'tremor', label: 'Tremor', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Fine (felt)' }, { score: 2, text: 'Gross (seen)' }, { score: 4, text: 'Coarse' }] },
    { id: 'yawn', label: 'Yawning', options: [{ score: 0, text: 'None' }, { score: 1, text: '1-2 times' }, { score: 2, text: 'Frequent' }, { score: 4, text: 'Constant' }] },
    { id: 'anxiety', label: 'Anxiety / Irritability', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Increasing' }, { score: 2, text: 'Obvious' }, { score: 4, text: 'Severe' }] },
    { id: 'skin', label: 'Gooseflesh', options: [{ score: 0, text: 'None' }, { score: 3, text: 'Piloerection (skin only)' }, { score: 5, text: 'Prominent' }] }
];

const AssessmentModule = () => {
    return (
        <div className="space-y-6 animate-in fade-in">
            <ClinicalCard title="Initial OUD Assessment">
                <div className="space-y-4">
                    <div className="bg-teal-50 dark:bg-teal-900/20 p-4 rounded-lg border border-teal-100 dark:border-teal-800/50">
                        <h4 className="text-xs font-bold text-teal-800 dark:text-teal-200 uppercase mb-2">Single Question Screener</h4>
                        <p className="text-sm font-medium text-teal-900 dark:text-teal-100 italic">
                            "How many times in the past year have you used an illegal drug or prescription medication for nonmedical reasons?"
                        </p>
                        <div className="mt-2 text-[10px] text-teal-600 dark:text-teal-400 font-bold">
                            POSITIVE SCREEN: At least once (Note: Does not equate to OUD)
                        </div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-widest">DSM-V 6Cs Criteria</h4>
                            <ul className="text-xs text-slate-600 dark:text-slate-400 space-y-1">
                                <li>• <strong>Control</strong>: Lost control / unable to cut back</li>
                                <li>• <strong>Cravings</strong>: Strong desire to use</li>
                                <li>• <strong>Consequences</strong>: Health/Physical issues</li>
                                <li>• <strong>Consequences</strong>: Relationship/Social strain</li>
                                <li>• <strong>C</strong>ommunity: Significant time obtaining/using</li>
                                <li>• <strong>C</strong>areer: Interfere with work/school/home</li>
                            </ul>
                        </div>
                        <div className="space-y-2">
                            <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Severity & Other Factors</h4>
                            <div className="flex flex-wrap gap-2 mb-3">
                                <Badge text="Mild: 2-3" type="safe" />
                                <Badge text="Mod: 4-5" type="caution" />
                                <Badge text="Severe: 6+" type="unsafe" />
                            </div>
                            <ul className="text-xs text-slate-600 dark:text-slate-400 space-y-1">
                                <li>• Pattern of use & overdose history</li>
                                <li>• Syringe access & injection practices</li>
                                <li>• Treatment history & patient goals</li>
                            </ul>
                        </div>
                    </div>

                    <div className="bg-slate-50 dark:bg-slate-900/50 p-3 rounded-lg border border-slate-200 dark:border-slate-800">
                        <h4 className="text-xs font-bold mb-2">Recommended Workup</h4>
                        <div className="flex flex-wrap gap-2">
                            {['UTox', 'Pregnancy', 'LFTs', 'HIV', 'Hep Panel', 'PDMP Check'].map(test => (
                                <span key={test} className="px-2 py-1 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded text-[10px] font-bold text-slate-500">{test}</span>
                            ))}
                        </div>
                    </div>
                </div>
            </ClinicalCard>
        </div>
    );
};

const ProtocolsModule = () => {
    const [view, setView] = useState<'bernese' | 'temple'>('temple');
    return (
        <div className="space-y-6 animate-in fade-in">
            <div className="flex bg-slate-100 dark:bg-slate-900 rounded-lg p-1 w-fit">
                <button onClick={() => setView('temple')} className={`px-3 py-1.5 rounded-md text-[10px] font-bold transition-all ${view === 'temple' ? 'bg-white dark:bg-slate-800 text-teal-600 shadow-sm' : 'text-slate-400'}`}>Temple Protocol</button>
                <button onClick={() => setView('bernese')} className={`px-3 py-1.5 rounded-md text-[10px] font-bold transition-all ${view === 'bernese' ? 'bg-white dark:bg-slate-800 text-purple-600 shadow-sm' : 'text-slate-400'}`}>Bernese Method</button>
            </div>

            {view === 'temple' ? (
                <ClinicalCard title="Temple Protocol (Aggressive MOUD)">
                    <div className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div className="bg-teal-50/50 dark:bg-teal-900/10 p-4 rounded-lg border border-teal-100 dark:border-teal-900/30">
                                <h5 className="text-xs font-bold text-teal-800 dark:text-teal-400 uppercase mb-3">Oral Regimen</h5>
                                <div className="space-y-2">
                                    <div className="flex justify-between items-center text-xs">
                                        <span className="font-bold">Oxycodone ER</span>
                                        <span className="text-teal-600 font-black">30-60mg TID</span>
                                    </div>
                                    <div className="text-[10px] text-slate-500 italic ml-2">• Up by 20mg q8h as needed</div>
                                    <div className="flex justify-between items-center text-xs mt-2">
                                        <span className="font-bold">Oxycodone IR</span>
                                        <span className="text-teal-600 font-black">15-30mg q4h PRN</span>
                                    </div>
                                </div>
                            </div>
                            <div className="bg-slate-50 dark:bg-slate-900/50 p-4 rounded-lg border border-slate-200 dark:border-slate-700">
                                <h5 className="text-xs font-bold text-slate-800 dark:text-slate-200 uppercase mb-3 text-center">Breakthrough / PCA</h5>
                                <div className="space-y-3">
                                    <div className="p-2 bg-white dark:bg-slate-800 rounded border border-slate-100 dark:border-slate-700">
                                        <div className="text-xs font-bold">Standard PRN</div>
                                        <div className="text-[11px] text-slate-600 mt-1">Dilaudid 2mg IV</div>
                                    </div>
                                    <div className="p-2 bg-white dark:bg-slate-800 rounded border border-slate-100 dark:border-slate-700">
                                        <div className="text-xs font-bold">Patient Controlled (PCA)</div>
                                        <div className="text-[11px] text-slate-600 mt-1">Dilaudid 1mg/hr basal</div>
                                        <div className="text-[10px] text-slate-400 mt-0.5">• Up by 0.5mg/hr every 2h</div>
                                        <div className="text-[10px] text-slate-400">• 0.5-1mg demand q10min</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </ClinicalCard>
            ) : (
                <ClinicalCard title="Bernese Method (Micro-Induction)">
                    <div className="space-y-3">
                        {[
                            { day: 1, dose: '0.5 mg once', note: 'Continue full agonist.' },
                            { day: 2, dose: '0.5 mg BID', note: 'Continue full agonist.' },
                            { day: 3, dose: '1 mg BID', note: 'Continue full agonist.' },
                            { day: 4, dose: '2 mg BID', note: 'Continue full agonist.' },
                            { day: 5, dose: '4 mg BID', note: 'Continue full agonist.' },
                            { day: 6, dose: '8 mg daily', note: 'STOP full agonist.' },
                        ].map((step) => (
                            <div key={step.day} className="flex items-center gap-4 bg-slate-50 dark:bg-slate-900/50 p-3 rounded-lg border border-slate-100 dark:border-slate-800">
                                <div className="w-10 h-10 flex-none rounded-full bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400 flex items-center justify-center font-bold text-sm">D{step.day}</div>
                                <div>
                                    <div className="text-xs font-bold text-slate-900 dark:text-slate-100">{step.dose}</div>
                                    <div className="text-[10px] text-slate-500 font-medium">{step.note}</div>
                                </div>
                            </div>
                        ))}
                    </div>
                </ClinicalCard>
            )}
        </div>
    );
};

const AdjunctsModule = () => {
    return (
        <div className="space-y-4 animate-in fade-in">
            <ClinicalCard title="Adjunctive Support (Non-Opioid)">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {[
                        { symptoms: "Sweating, restlessness, anxiety", med: "Clonidine 0.1-0.3 mg PO q6-8h PRN", max: "1.2 mg/day" },
                        { symptoms: "Loose stools / Diarrhea", med: "Loperamide 4 mg x1, then 2 mg PRN", max: "16 mg/day" },
                        { symptoms: "Nausea / Vomiting", med: "Zofran 4 mg PO q6h PRN", max: "Max 16-24 mg" },
                        { symptoms: "Insomnia", med: "Trazodone 50-100 mg PO qHS PRN", note: "or Melatonin 3-9 mg" },
                        { symptoms: "Anxiety & Insomnia", med: "Diphenhydramine 25-50 mg PO q8h PRN", max: "Benadryl" },
                        { symptoms: "Bone/Joint Pain", med: "Tylenol 650mg q6h / Ibuprofen 800mg q8h", max: "NSAID limit" }
                    ].map((item, i) => (
                        <div key={i} className="p-3 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-100 dark:border-slate-800">
                            <div className="text-[10px] font-black text-teal-600 dark:text-teal-400 uppercase">{item.symptoms}</div>
                            <div className="text-xs font-bold text-slate-800 dark:text-slate-200 mt-1">{item.med}</div>
                            {item.max && <div className="text-[10px] text-slate-400 font-medium mt-0.5">• {item.max}</div>}
                        </div>
                    ))}
                </div>
            </ClinicalCard>

            <div className="bg-indigo-50/50 dark:bg-indigo-900/10 p-4 rounded-xl border border-indigo-100 dark:border-indigo-900/30 flex items-start gap-4">
                <Brain className="w-6 h-6 text-indigo-500 mt-1" />
                <div>
                    <h4 className="text-sm font-bold text-indigo-900 dark:text-indigo-200">Pharmacology Note: Methadone</h4>
                    <p className="text-xs text-indigo-800 dark:text-indigo-300 mt-1 leading-relaxed">
                        Methadone is a long-acting full opioid agonist; requires EKG monitoring for QT-prolongation.
                    </p>
                    <div className="mt-2 flex items-center gap-3">
                        <div className="px-2 py-1 bg-white dark:bg-slate-900 border border-indigo-200 dark:border-indigo-800 rounded font-black text-indigo-600 text-[10px]">
                            METHADONE 30mg/day ≈ OXYCODONE 175mg/day
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

const ScaleCalculator = ({ title, data }: { title: string, data: ScaleItem[] }) => {
    const [scores, setScores] = useState<{ [key: string]: number }>({});
    const totalScore = Object.values(scores).reduce((a, b) => a + b, 0);

    const getInterpretation = (score: number) => {
        if (score < 5) return { text: 'Mild / No Withdrawal', color: 'text-slate-500', bg: 'bg-slate-100 dark:bg-slate-800' };
        if (score < 13) return { text: 'Mild Withdrawal (5-12)', color: 'text-amber-600', bg: 'bg-amber-50 dark:bg-amber-900/20' };
        if (score < 25) return { text: 'Moderate Withdrawal (13-24)', color: 'text-orange-600', bg: 'bg-orange-50 dark:bg-orange-900/20' };
        if (score < 36) return { text: 'Moderately Severe (25-36)', color: 'text-rose-600', bg: 'bg-rose-50 dark:bg-rose-900/20' };
        return { text: 'Severe Withdrawal (>36)', color: 'text-rose-700', bg: 'bg-rose-100 dark:bg-rose-900/20' };
    };

    const interp = getInterpretation(totalScore);

    const handleCopy = () => {
        const txt = `${title} Score: ${totalScore}\ninterpretation: ${interp.text}\n\nBreakdown:\n${data.map(i => `- ${i.label}: ${scores[i.id] || 0}`).join('\n')}`;
        navigator.clipboard.writeText(txt);
    };

    return (
        <div className="space-y-6 animate-in fade-in">
            <div className="sticky top-0 z-10 bg-white/95 dark:bg-slate-900/95 backdrop-blur border-b border-slate-200 dark:border-slate-800 pb-4 pt-2 mb-4">
                <div className="flex items-center justify-between">
                    <div>
                        <h2 className="text-lg font-bold text-slate-800 dark:text-slate-200 flex items-center gap-2">
                            <Activity className="w-5 h-5 text-teal-600" /> {title} Calculator
                        </h2>
                        <div className={`mt-1 inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold ${interp.bg} ${interp.color}`}>
                            Score: {totalScore} • {interp.text}
                        </div>
                    </div>
                    <button onClick={handleCopy} className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full text-slate-400 hover:text-slate-600 transition-colors">
                        <Copy className="w-5 h-5" />
                    </button>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {data.map(item => (
                    <div key={item.id} className="bg-white dark:bg-slate-800/50 p-3 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm">
                        <div className="flex justify-between items-center mb-2">
                            <span className="font-bold text-slate-700 dark:text-slate-300 text-xs">{item.label}</span>
                            <span className="text-[10px] font-black text-teal-600 bg-teal-50 dark:bg-teal-900/20 px-2 py-0.5 rounded">
                                {scores[item.id] || 0}
                            </span>
                        </div>
                        <div className="flex flex-wrap gap-1.5">
                            {item.options.map(opt => (
                                <button
                                    key={opt.score}
                                    onClick={() => setScores(p => ({ ...p, [item.id]: opt.score }))}
                                    className={`flex-1 min-w-[50px] text-[10px] py-1.5 px-1 rounded border transition-all font-medium ${(scores[item.id] === opt.score)
                                        ? 'bg-teal-600 text-white border-teal-600 shadow-teal-900/10 shadow-sm'
                                        : 'bg-white dark:bg-slate-900 text-slate-500 border-slate-200 dark:border-slate-700 hover:border-teal-300'
                                        }`}
                                >
                                    {opt.text}
                                </button>
                            ))}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};

export const ToolkitView = () => {
    const [tab, setTab] = useState<'assess' | 'cows' | 'induct' | 'adjunct'>('assess');

    return (
        <div className="h-full flex flex-col gap-4">
            <div className="flex bg-white dark:bg-slate-900 p-1 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm shrink-0 overflow-x-auto no-scrollbar">
                {[
                    { id: 'assess', label: 'Assessment', icon: ClipboardCheck },
                    { id: 'cows', label: 'COWS Scale', icon: Activity },
                    { id: 'induct', label: 'Protocols', icon: ShieldCheck },
                    { id: 'adjunct', label: 'Adjuncts', icon: Pill }
                ].map(item => (
                    <button
                        key={item.id}
                        onClick={() => setTab(item.id as any)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all whitespace-nowrap ${tab === item.id
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
                {tab === 'assess' && <AssessmentModule />}
                {tab === 'cows' && <ScaleCalculator title="COWS (Opiate Withdrawal)" data={COWS_DATA} />}
                {tab === 'induct' && <ProtocolsModule />}
                {tab === 'adjunct' && <AdjunctsModule />}
            </div>
        </div>
    );
};
