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

import { DRUG_DATA, WARNING_DATA } from './data';

// --- Components ---

const Card = ({ children, className = "", onClick }: { children: React.ReactNode, className?: string, onClick?: () => void }) => (
    <div onClick={onClick} className={`bg-[var(--background-secondary)] rounded-xl shadow-sm border border-[var(--background-modifier-border)] overflow-hidden ${className} ${onClick ? 'cursor-pointer hover:border-[var(--interactive-accent)] transition-colors' : ''}`}>
        {children}
    </div>
);

const Badge = ({ type, text }: { type?: string, text: string }) => {
    const styles: { [key: string]: string } = {
        safe: "bg-[var(--background-modifier-success)] text-white border-transparent",
        caution: "bg-[var(--background-modifier-warning)] text-black border-transparent",
        unsafe: "bg-[var(--status-error)] text-white border-transparent",
        neutral: "bg-[var(--background-modifier-border)] text-[var(--text-muted)] border-transparent",
        purple: "bg-[var(--interactive-accent)] text-white border-transparent"
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
                    <label className="text-xs font-bold text-[var(--text-muted)] uppercase">Renal Status</label>
                    <div className="flex flex-col gap-1">
                        {[{ id: 'normal', l: 'GFR > 60' }, { id: 'impaired', l: 'GFR < 30' }, { id: 'dialysis', l: 'Dialysis' }].map(o => (
                            <button key={o.id} onClick={() => setRenal(o.id)}
                                className={`px-3 py-2 text-sm rounded-lg border text-left ${renal === o.id ? 'bg-[var(--interactive-accent)] text-[var(--text-on-accent)] border-[var(--interactive-accent)]' : 'bg-[var(--background-primary)] text-[var(--text-normal)] border-[var(--background-modifier-border)] hover:bg-[var(--background-modifier-hover)]'}`}>
                                {o.l}
                            </button>
                        ))}
                    </div>
                </div>
                <div className="space-y-2">
                    <label className="text-xs font-bold text-[var(--text-muted)] uppercase">Hemodynamics</label>
                    <div className="flex flex-col gap-1">
                        {[{ id: 'stable', l: 'Stable BP' }, { id: 'unstable', l: 'Shock / Hypotensive' }].map(o => (
                            <button key={o.id} onClick={() => setHemo(o.id)}
                                className={`px-3 py-2 text-sm rounded-lg border text-left ${hemo === o.id ? 'bg-[var(--interactive-accent)] text-[var(--text-on-accent)] border-[var(--interactive-accent)]' : 'bg-[var(--background-primary)] text-[var(--text-normal)] border-[var(--background-modifier-border)] hover:bg-[var(--background-modifier-hover)]'}`}>
                                {o.l}
                            </button>
                        ))}
                    </div>
                </div>
                <div className="space-y-2">
                    <label className="text-xs font-bold text-[var(--text-muted)] uppercase">Route</label>
                    <div className="flex flex-col gap-1">
                        {[{ id: 'iv', l: 'Intravenous' }, { id: 'po', l: 'Oral' }].map(o => (
                            <button key={o.id} onClick={() => setRoute(o.id)}
                                className={`px-3 py-2 text-sm rounded-lg border text-left ${route === o.id ? 'bg-[var(--interactive-accent)] text-[var(--text-on-accent)] border-[var(--interactive-accent)]' : 'bg-[var(--background-primary)] text-[var(--text-normal)] border-[var(--background-modifier-border)] hover:bg-[var(--background-modifier-hover)]'}`}>
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
                        <h3 className="text-sm font-bold text-[var(--text-muted)] uppercase tracking-wider flex items-center gap-2">
                            <Microscope className="w-4 h-4" /> Clinical Recommendations
                        </h3>
                        {recs.map((rec, i) => (
                            <Card key={i} className={`p-4 border-l-4 ${rec.type === 'safe' ? 'border-l-[var(--background-modifier-success)]' : 'border-l-[var(--background-modifier-warning)]'}`}>
                                <div className="flex justify-between items-center mb-1">
                                    <span className="font-bold text-[var(--text-normal)]">{rec.name}</span>
                                    <Badge type={rec.type} text={rec.type === 'safe' ? 'Preferred' : 'Proceed with Caution'} />
                                </div>
                                <div className="text-sm text-[var(--text-muted)] font-medium">{rec.reason}</div>
                                <div className="text-xs text-[var(--text-faint)] mt-1 italic border-t pt-1 border-[var(--background-modifier-border)]">{rec.detail}</div>
                            </Card>
                        ))}
                        {warnings.length > 0 && (
                            <div className="bg-[var(--background-modifier-error)] p-4 rounded-xl border border-[var(--background-modifier-border)]">
                                <div className="flex items-center gap-2 text-white font-bold text-sm mb-2">
                                    <ShieldAlert className="w-4 h-4" /> Contraindications
                                </div>
                                <ul className="text-xs text-white/90 space-y-1 list-disc pl-4">
                                    {warnings.map((w, i) => <li key={i}>{w}</li>)}
                                </ul>
                            </div>
                        )}
                    </div>
                ) : (
                    <div className="h-full flex flex-col items-center justify-center text-[var(--text-faint)] border-2 border-dashed border-[var(--background-modifier-border)] rounded-xl p-8">
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
            <div className="bg-[var(--background-secondary-alt)] text-[var(--text-normal)] p-6 rounded-2xl shadow-lg border border-[var(--background-modifier-border)]">
                <div className="flex justify-between items-start mb-6">
                    <div>
                        <label className="text-xs font-bold text-[var(--text-muted)] uppercase tracking-wider">Input Dose</label>
                        <div className="text-2xl font-bold">IV Morphine Equivalent</div>
                    </div>
                    <div className="flex items-baseline gap-2">
                        <input
                            type="number"
                            value={ivMorphine}
                            onChange={(e) => setIvMorphine(Math.max(0, parseFloat(e.target.value)))}
                            className="bg-transparent text-4xl font-mono text-right w-24 border-b border-[var(--background-modifier-border)] focus:border-[var(--interactive-accent)] outline-none text-[var(--text-normal)]"
                        />
                        <span className="text-[var(--text-muted)]">mg</span>
                    </div>
                </div>

                <div className="space-y-2">
                    <div className="flex justify-between text-xs font-medium text-[var(--text-muted)]">
                        <span className="flex items-center gap-1"><Sliders className="w-3 h-3" /> Cross-Tolerance Reduction</span>
                        <span className={reduction < 25 ? "text-[var(--text-error)]" : "text-[var(--text-success)]"}>-{reduction}%</span>
                    </div>
                    <input
                        type="range"
                        min="0"
                        max="75"
                        value={reduction}
                        onChange={(e) => setReduction(parseInt(e.target.value))}
                        className="w-full h-1 bg-[var(--background-modifier-border)] rounded-lg appearance-none cursor-pointer accent-[var(--interactive-accent)]"
                    />
                    <p className="text-[10px] text-[var(--text-faint)]">
                        *Clinical Standard: Reduce calculated dose by 25-50% when rotating agents to account for incomplete cross-tolerance.
                    </p>
                </div>
            </div>

            {/* Results Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-3">
                    <h4 className="text-xs font-bold text-[var(--text-muted)] uppercase ml-1">Parenteral (IV) Targets</h4>
                    <Card className="p-4">
                        <div className="flex justify-between items-baseline mb-1">
                            <span className="font-bold text-[var(--text-normal)]">Hydromorphone IV</span>
                            <span className="text-2xl font-bold text-[var(--interactive-accent)]">{convert(0.15).reduced} <span className="text-sm text-[var(--text-faint)]">mg</span></span>
                        </div>
                        <div className="text-xs text-[var(--text-faint)]">Raw calc: {convert(0.15).raw} mg (Ratio 1:6.7)</div>
                    </Card>
                    <Card className="p-4">
                        <div className="flex justify-between items-baseline mb-1">
                            <span className="font-bold text-[var(--text-normal)]">Fentanyl IV</span>
                            <span className="text-2xl font-bold text-[var(--interactive-accent)]">{convert(10).reduced} <span className="text-sm text-[var(--text-faint)]">mcg</span></span>
                        </div>
                        <div className="text-xs text-[var(--text-faint)]">Raw calc: {convert(10).raw} mcg (Ratio 1:100)</div>
                    </Card>
                </div>

                <div className="space-y-3">
                    <h4 className="text-xs font-bold text-[var(--text-muted)] uppercase ml-1">Enteral (PO) Targets</h4>
                    <Card className="p-4 border-l-4 border-l-[var(--background-modifier-success)]">
                        <div className="flex justify-between items-baseline mb-1">
                            <span className="font-bold text-[var(--text-normal)]">Oxycodone PO</span>
                            <span className="text-2xl font-bold text-[var(--text-success)]">{convert(2.0).reduced} <span className="text-sm text-[var(--text-faint)]">mg</span></span>
                        </div>
                        <div className="text-xs text-[var(--text-faint)]">High Bioavailability. Ratio 1:2</div>
                    </Card>
                    <Card className="p-4 border-l-4 border-l-[var(--background-modifier-warning)]">
                        <div className="flex justify-between items-baseline mb-1">
                            <span className="font-bold text-[var(--text-normal)]">Hydromorphone PO</span>
                            <span className="text-2xl font-bold text-[var(--text-warning)]">{convert(0.75).reduced} <span className="text-sm text-[var(--text-faint)]">mg</span></span>
                        </div>
                        <div className="text-xs text-[var(--text-muted)] font-medium">Warning: Poor Bioavailability.</div>
                        <div className="text-xs text-[var(--text-faint)]">Often underdosed if 1:1 conversion used.</div>
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
        <div className="min-h-full bg-[var(--background-primary)] text-[var(--text-normal)] font-sans selection:bg-[var(--text-selection)]">
            <header className="sticky top-0 z-20 bg-[var(--background-primary-alt)] border-b border-[var(--background-modifier-border)]">
                <div className="max-w-3xl mx-auto px-4 h-14 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                        <div className="bg-[var(--interactive-accent)] text-white p-1.5 rounded-lg">
                            <Activity className="w-4 h-4" />
                        </div>
                        <div>
                            <h1 className="text-sm font-bold text-[var(--text-normal)]">Precision Analgesia</h1>
                            <p className="text-[10px] text-[var(--text-muted)] font-medium">Inpatient Guide 2025</p>
                        </div>
                    </div>
                </div>
                <div className="max-w-3xl mx-auto px-2 flex space-x-1">
                    {[{ id: 'decision', icon: Database, l: 'Algo' }, { id: 'calc', icon: Calculator, l: 'Calc' }].map(t => (
                        <button key={t.id} onClick={() => setActiveTab(t.id)}
                            className={`flex-1 py-2 text-xs font-medium border-b-2 transition-colors flex justify-center items-center gap-2 ${activeTab === t.id ? 'border-[var(--interactive-accent)] text-[var(--text-accent)] bg-[var(--background-modifier-hover)]' : 'border-transparent text-[var(--text-muted)]'}`}>
                            <t.icon className="w-3 h-3" /> {t.l}
                        </button>
                    ))}
                </div>
            </header>

            <main className="max-w-3xl mx-auto px-4 py-6 pb-20">
                {activeTab === 'decision' && <DecisionSupportView />}
                {activeTab === 'calc' && <CalculatorView />}
            </main>
        </div>
    );
};

export default OpioidPrecisionApp;
