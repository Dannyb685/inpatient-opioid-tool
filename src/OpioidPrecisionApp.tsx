import React, { useState, useEffect } from 'react';
import {
    Activity,
    AlertTriangle,
    Calculator,
    ChevronDown,
    ChevronUp,
    Database,
    FileText,
    Info,
    Search,
    ShieldAlert,
    Microscope,
    Sliders,
    Zap
} from 'lucide-react';

// --- Clinical Data ---

const DRUG_DATA = [
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
        bioavailability: 40 // Low and variable
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

const WARNING_DATA = [
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

// --- Components ---

const Card = ({ children, className = "", onClick }: { children: React.ReactNode, className?: string, onClick?: () => void }) => (
    <div onClick={onClick} className={`bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden ${className} ${onClick ? 'cursor-pointer hover:border-blue-400 transition-colors' : ''}`}>
        {children}
    </div>
);

const Badge = ({ type, text }: { type?: string, text: string }) => {
    const styles: { [key: string]: string } = {
        safe: "bg-emerald-50 text-emerald-700 border-emerald-200",
        caution: "bg-amber-50 text-amber-700 border-amber-200",
        unsafe: "bg-rose-50 text-rose-700 border-rose-200",
        neutral: "bg-slate-50 text-slate-700 border-slate-200",
        purple: "bg-purple-50 text-purple-700 border-purple-200"
    };

    let styleKey = type || 'neutral';
    if (!type) {
        if (text.includes('Safe') || text.includes('Preferred')) styleKey = 'safe';
        if (text.includes('Caution') || text.includes('Monitor')) styleKey = 'caution';
        if (text.includes('Unsafe') || text.includes('Avoid')) styleKey = 'unsafe';
        if (text.includes('Interaction') || text.includes('Affinity')) styleKey = 'purple';
    }

    return (
        <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wide border ${styles[styleKey] || styles.neutral}`}>
            {text}
        </span>
    );
};

// --- Views ---

const DecisionSupportView = () => {
    const [renal, setRenal] = useState<string | null>(null);
    const [hemo, setHemo] = useState<string | null>(null);
    const [route, setRoute] = useState<string | null>(null);
    const [recs, setRecs] = useState<any[]>([]);
    const [warnings, setWarnings] = useState<string[]>([]);

    useEffect(() => {
        if (!renal || !hemo || !route) {
            setRecs([]);
            return;
        }

        let r: any[] = [];
        let w: string[] = [];

        // Detailed Algorithm
        if (renal === 'dialysis' || renal === 'impaired') {
            r.push({ name: 'Fentanyl', reason: 'Safe (no active metabolites).', detail: 'Watch context-sensitive t1/2 in ICU infusions.', type: 'safe' });
            r.push({ name: 'Methadone', reason: 'Safe (fecal excretion).', detail: 'Use low dose; monitor QTc and day 3-5 accumulation.', type: 'safe' });

            if (route === 'po') {
                r.push({ name: 'Hydromorphone PO', reason: 'Use with caution.', detail: 'Reduce dose 50%. Monitor for allodynia (H3G).', type: 'caution' });
                r.push({ name: 'Oxycodone', reason: 'Use with caution.', detail: 'Reduce frequency. Monitor sedation.', type: 'caution' });
            } else {
                r.push({ name: 'Hydromorphone IV', reason: 'Caution.', detail: 'Reduce dose. Dialyzable, but H3G neurotoxicity is real.', type: 'caution' });
            }
            w.push('Morphine Contraindicated: M6G/M3G accumulation causes coma and myoclonus.');
        } else {
            if (route === 'po') {
                r.push({ name: 'Oxycodone', reason: 'Preferred.', detail: 'Superior bioavailability to Morphine/Dilaudid PO.', type: 'safe' });
            } else {
                r.push({ name: 'Morphine', reason: 'Standard.', detail: 'Ideal unless hypotension present.', type: 'safe' });
                r.push({ name: 'Hydromorphone', reason: 'Standard.', detail: 'Preferred in high tolerance.', type: 'safe' });
            }
        }

        if (hemo === 'unstable') {
            r = r.filter(x => x.name !== 'Morphine');
            if (!r.find(x => x.name === 'Fentanyl')) {
                r.unshift({ name: 'Fentanyl', reason: 'Preferred.', detail: 'Cardiostable; no histamine release.', type: 'safe' });
            }
            w.push('Morphine: Histamine release precipitates vasodilation/hypotension.');
        }

        setRecs(r);
        setWarnings(w);
    }, [renal, hemo, route]);

    return (
        <div className="space-y-6">
            {/* Input Matrix */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                <div className="space-y-2">
                    <label className="text-xs font-bold text-slate-500 uppercase">Renal Status</label>
                    <div className="flex flex-col gap-1">
                        {[{ id: 'normal', l: 'GFR > 60' }, { id: 'impaired', l: 'GFR < 30' }, { id: 'dialysis', l: 'Dialysis' }].map(o => (
                            <button key={o.id} onClick={() => setRenal(o.id)}
                                className={`px-3 py-2 text-sm rounded-lg border text-left ${renal === o.id ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-slate-600 hover:bg-slate-50'}`}>
                                {o.l}
                            </button>
                        ))}
                    </div>
                </div>
                <div className="space-y-2">
                    <label className="text-xs font-bold text-slate-500 uppercase">Hemodynamics</label>
                    <div className="flex flex-col gap-1">
                        {[{ id: 'stable', l: 'Stable BP' }, { id: 'unstable', l: 'Shock / Hypotensive' }].map(o => (
                            <button key={o.id} onClick={() => setHemo(o.id)}
                                className={`px-3 py-2 text-sm rounded-lg border text-left ${hemo === o.id ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-slate-600 hover:bg-slate-50'}`}>
                                {o.l}
                            </button>
                        ))}
                    </div>
                </div>
                <div className="space-y-2">
                    <label className="text-xs font-bold text-slate-500 uppercase">Route</label>
                    <div className="flex flex-col gap-1">
                        {[{ id: 'iv', l: 'Intravenous' }, { id: 'po', l: 'Oral' }].map(o => (
                            <button key={o.id} onClick={() => setRoute(o.id)}
                                className={`px-3 py-2 text-sm rounded-lg border text-left ${route === o.id ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-slate-600 hover:bg-slate-50'}`}>
                                {o.l}
                            </button>
                        ))}
                    </div>
                </div>
            </div>

            {/* Output Stream */}
            <div className="min-h-[200px]">
                {recs.length > 0 ? (
                    <div className="space-y-3 animate-in fade-in slide-in-from-bottom-2">
                        <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wider flex items-center gap-2">
                            <Microscope className="w-4 h-4" /> Clinical Recommendations
                        </h3>
                        {recs.map((rec, i) => (
                            <Card key={i} className={`p-4 border-l-4 ${rec.type === 'safe' ? 'border-l-emerald-500' : 'border-l-amber-500'}`}>
                                <div className="flex justify-between items-center mb-1">
                                    <span className="font-bold text-slate-800">{rec.name}</span>
                                    <Badge type={rec.type} text={rec.type === 'safe' ? 'Preferred' : 'Proceed with Caution'} />
                                </div>
                                <div className="text-sm text-slate-600 font-medium">{rec.reason}</div>
                                <div className="text-xs text-slate-500 mt-1 italic border-t pt-1 border-slate-100">{rec.detail}</div>
                            </Card>
                        ))}
                        {warnings.length > 0 && (
                            <div className="bg-rose-50 p-4 rounded-xl border border-rose-100">
                                <div className="flex items-center gap-2 text-rose-800 font-bold text-sm mb-2">
                                    <ShieldAlert className="w-4 h-4" /> Contraindications
                                </div>
                                <ul className="text-xs text-rose-700 space-y-1 list-disc pl-4">
                                    {warnings.map((w, i) => <li key={i}>{w}</li>)}
                                </ul>
                            </div>
                        )}
                    </div>
                ) : (
                    <div className="h-full flex flex-col items-center justify-center text-slate-300 border-2 border-dashed border-slate-200 rounded-xl p-8">
                        <Activity className="w-8 h-8 mb-2" />
                        <span className="text-sm">Awaiting Clinical Parameters</span>
                    </div>
                )}
            </div>
        </div>
    );
};

const CalculatorView = () => {
    const [ivMorphine, setIvMorphine] = useState(10);
    const [reduction, setReduction] = useState(30); // Default 30% reduction

    const convert = (factor: number) => {
        const raw = ivMorphine * factor;
        const reduced = raw * (1 - (reduction / 100));
        return { raw: raw.toFixed(1), reduced: reduced.toFixed(1) };
    };

    return (
        <div className="space-y-6 max-w-2xl mx-auto">
            {/* Input */}
            <div className="bg-slate-900 text-white p-6 rounded-2xl shadow-lg">
                <div className="flex justify-between items-start mb-6">
                    <div>
                        <label className="text-xs font-bold text-slate-400 uppercase tracking-wider">Input Dose</label>
                        <div className="text-2xl font-bold">IV Morphine Equivalent</div>
                    </div>
                    <div className="flex items-baseline gap-2">
                        <input
                            type="number"
                            value={ivMorphine}
                            onChange={(e) => setIvMorphine(Math.max(0, parseFloat(e.target.value)))}
                            className="bg-transparent text-4xl font-mono text-right w-24 border-b border-slate-600 focus:border-blue-500 outline-none"
                        />
                        <span className="text-slate-400">mg</span>
                    </div>
                </div>

                <div className="space-y-2">
                    <div className="flex justify-between text-xs font-medium text-slate-300">
                        <span className="flex items-center gap-1"><Sliders className="w-3 h-3" /> Cross-Tolerance Reduction</span>
                        <span className={reduction < 25 ? "text-rose-400" : "text-emerald-400"}>-{reduction}%</span>
                    </div>
                    <input
                        type="range"
                        min="0"
                        max="75"
                        value={reduction}
                        onChange={(e) => setReduction(parseInt(e.target.value))}
                        className="w-full h-1 bg-slate-700 rounded-lg appearance-none cursor-pointer accent-blue-500"
                    />
                    <p className="text-[10px] text-slate-500">
                        *Clinical Standard: Reduce calculated dose by 25-50% when rotating agents to account for incomplete cross-tolerance.
                    </p>
                </div>
            </div>

            {/* Results Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-3">
                    <h4 className="text-xs font-bold text-slate-400 uppercase ml-1">Parenteral (IV) Targets</h4>
                    <Card className="p-4">
                        <div className="flex justify-between items-baseline mb-1">
                            <span className="font-bold text-slate-700">Hydromorphone IV</span>
                            <span className="text-2xl font-bold text-blue-600">{convert(0.15).reduced} <span className="text-sm text-slate-400">mg</span></span>
                        </div>
                        <div className="text-xs text-slate-400">Raw calc: {convert(0.15).raw} mg (Ratio 1:6.7)</div>
                    </Card>
                    <Card className="p-4">
                        <div className="flex justify-between items-baseline mb-1">
                            <span className="font-bold text-slate-700">Fentanyl IV</span>
                            <span className="text-2xl font-bold text-blue-600">{convert(10).reduced} <span className="text-sm text-slate-400">mcg</span></span>
                        </div>
                        <div className="text-xs text-slate-400">Raw calc: {convert(10).raw} mcg (Ratio 1:100)</div>
                    </Card>
                </div>

                <div className="space-y-3">
                    <h4 className="text-xs font-bold text-slate-400 uppercase ml-1">Enteral (PO) Targets</h4>
                    <Card className="p-4 border-l-4 border-l-emerald-400">
                        <div className="flex justify-between items-baseline mb-1">
                            <span className="font-bold text-slate-700">Oxycodone PO</span>
                            <span className="text-2xl font-bold text-emerald-600">{convert(2.0).reduced} <span className="text-sm text-slate-400">mg</span></span>
                        </div>
                        <div className="text-xs text-slate-400">High Bioavailability. Ratio 1:2</div>
                    </Card>
                    <Card className="p-4 border-l-4 border-l-amber-400">
                        <div className="flex justify-between items-baseline mb-1">
                            <span className="font-bold text-slate-700">Hydromorphone PO</span>
                            <span className="text-2xl font-bold text-amber-600">{convert(0.75).reduced} <span className="text-sm text-slate-400">mg</span></span>
                        </div>
                        <div className="text-xs text-slate-500 font-medium">Warning: Poor Bioavailability.</div>
                        <div className="text-xs text-slate-400">Often underdosed if 1:1 conversion used.</div>
                    </Card>
                </div>
            </div>
        </div>
    );
};

const ReferenceView = () => {
    const [searchTerm, setSearchTerm] = useState('');
    const [expanded, setExpanded] = useState<string | null>(null);

    const filtered = DRUG_DATA.filter(d =>
        d.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        d.clinical_nuance.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="space-y-4">
            <div className="relative">
                <Search className="absolute left-3 top-3.5 h-4 w-4 text-slate-400" />
                <input
                    type="text"
                    placeholder="Search by drug, metabolite, or mechanism..."
                    className="w-full pl-9 pr-4 py-3 rounded-xl border border-slate-200 focus:ring-2 focus:ring-blue-100 focus:border-blue-500 outline-none text-sm"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                />
            </div>

            <div className="space-y-3">
                {filtered.map(drug => (
                    <div key={drug.id} className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
                        <div
                            onClick={() => setExpanded(expanded === drug.id ? null : drug.id)}
                            className="p-4 cursor-pointer hover:bg-slate-50 transition-colors flex justify-between items-center"
                        >
                            <div>
                                <div className="flex items-center gap-2 mb-1">
                                    <h3 className="font-bold text-slate-900">{drug.name}</h3>
                                    <Badge type={drug.type} text={drug.renal_safety === 'Safe' ? 'Renal Safe' : 'Renal Caution'} />
                                </div>
                                <div className="text-xs text-slate-500">{drug.type}</div>
                            </div>
                            {expanded === drug.id ? <ChevronUp className="h-4 w-4 text-slate-400" /> : <ChevronDown className="h-4 w-4 text-slate-400" />}
                        </div>

                        {expanded === drug.id && (
                            <div className="bg-slate-50 px-4 pb-4 pt-2 border-t border-slate-100 text-sm">
                                <div className="grid grid-cols-2 gap-4 mb-3">
                                    <div className="bg-white p-2 rounded border border-slate-200">
                                        <span className="block text-[10px] font-bold text-slate-400 uppercase">IV Onset/Duration</span>
                                        <span className="text-slate-700">{drug.iv_onset} / {drug.iv_duration}</span>
                                    </div>
                                    <div className="bg-white p-2 rounded border border-slate-200">
                                        <span className="block text-[10px] font-bold text-slate-400 uppercase">Bioavailability</span>
                                        <div className="flex items-center gap-2">
                                            <div className="flex-1 h-1 bg-slate-100 rounded-full overflow-hidden">
                                                <div className="h-full bg-blue-500" style={{ width: `${drug.bioavailability}%` }}></div>
                                            </div>
                                            <span className="text-slate-700">{drug.bioavailability > 0 ? `${drug.bioavailability}%` : 'N/A'}</span>
                                        </div>
                                    </div>
                                </div>

                                <div className="space-y-2">
                                    <div>
                                        <span className="flex items-center gap-1 text-xs font-bold text-purple-700 uppercase mb-1">
                                            <Zap className="w-3 h-3" /> Clinical Context
                                        </span>
                                        <p className="text-slate-700 leading-relaxed">{drug.clinical_nuance}</p>
                                    </div>
                                    <div>
                                        <span className="flex items-center gap-1 text-xs font-bold text-slate-500 uppercase mb-1">
                                            <Activity className="w-3 h-3" /> Pharmacokinetics
                                        </span>
                                        <p className="text-slate-600">{drug.pharmacokinetics}</p>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                ))}
            </div>

            <div className="mt-8 pt-6 border-t border-dashed border-slate-300">
                <h3 className="text-xs font-bold text-rose-500 uppercase mb-3 flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4" /> High-Risk Agents
                </h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {WARNING_DATA.map(w => (
                        <div key={w.id} className="bg-rose-50 p-3 rounded-lg border border-rose-100">
                            <div className="font-bold text-rose-900 text-sm mb-1">{w.name}</div>
                            <div className="text-[10px] font-bold text-rose-800 uppercase mb-1">{w.risk}</div>
                            <p className="text-xs text-rose-800/80 leading-relaxed">{w.desc}</p>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};

// --- Shell ---

const OpioidPrecisionApp = () => {
    const [activeTab, setActiveTab] = useState('decision');

    return (
        <div className="min-h-screen bg-slate-50 text-slate-900 font-sans selection:bg-blue-100">
            <header className="sticky top-0 z-20 bg-white/80 backdrop-blur-md border-b border-slate-200">
                <div className="max-w-3xl mx-auto px-4 h-14 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <div className="bg-slate-900 text-white p-1.5 rounded-lg">
                            <Activity className="w-4 h-4" />
                        </div>
                        <div>
                            <h1 className="text-sm font-bold text-slate-900">Precision Analgesia</h1>
                            <p className="text-[10px] text-slate-500 font-medium">Inpatient Guide 2025</p>
                        </div>
                    </div>
                </div>
                <div className="max-w-3xl mx-auto px-2 flex space-x-1">
                    {[{ id: 'decision', icon: Database, l: 'Algo' }, { id: 'calc', icon: Calculator, l: 'Calc' }, { id: 'ref', icon: FileText, l: 'Data' }].map(t => (
                        <button key={t.id} onClick={() => setActiveTab(t.id)}
                            className={`flex-1 py-2 text-xs font-medium border-b-2 transition-colors flex justify-center items-center gap-2 ${activeTab === t.id ? 'border-blue-600 text-blue-700 bg-blue-50/50' : 'border-transparent text-slate-500'}`}>
                            <t.icon className="w-3 h-3" /> {t.l}
                        </button>
                    ))}
                </div>
            </header>

            <main className="max-w-3xl mx-auto px-4 py-6 pb-20">
                {activeTab === 'decision' && <DecisionSupportView />}
                {activeTab === 'calc' && <CalculatorView />}
                {activeTab === 'ref' && <ReferenceView />}
            </main>
        </div>
    );
};

export default OpioidPrecisionApp;
