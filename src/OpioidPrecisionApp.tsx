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
    Zap,
    Home,
    Menu,
    X,
    User,
    Settings,
    Beaker
} from 'lucide-react';

import { DRUG_DATA, WARNING_DATA } from './data';

// --- Components ---

const ClinicalCard = ({ children, className = "", title, action }: { children: React.ReactNode, className?: string, title?: string, action?: React.ReactNode }) => (
    <div className={`bg-white rounded-lg border border-slate-200 shadow-sm overflow-hidden ${className}`}>
        {title && (
            <div className="px-4 py-3 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">{title}</h3>
                {action}
            </div>
        )}
        <div className="p-4">
            {children}
        </div>
    </div>
);

const Badge = ({ type, text }: { type?: string, text: string }) => {
    const styles: { [key: string]: string } = {
        safe: "bg-emerald-100 text-emerald-700 border-emerald-200",
        caution: "bg-amber-100 text-amber-700 border-amber-200",
        unsafe: "bg-rose-100 text-rose-700 border-rose-200",
        neutral: "bg-slate-100 text-slate-600 border-slate-200",
        purple: "bg-purple-100 text-purple-700 border-purple-200"
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
    const [hepatic, setHepatic] = useState<string | null>(null);
    const [painType, setPainType] = useState<string | null>(null);
    const [route, setRoute] = useState<string | null>(null);
    const [gi, setGi] = useState<string | null>(null);
    const [recs, setRecs] = useState<any[]>([]);
    const [warnings, setWarnings] = useState<string[]>([]);

    useEffect(() => {
        if (!renal || !hemo || !route || !gi || !hepatic || !painType) {
            setRecs([]);
            setWarnings([]);
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

        // GI / Swallowing Logic
        if (gi === 'npo') {
            if (route === 'po') {
                r = [];
                w.push('PO Contraindicated: Patient is NPO / Malabsorption. Switch to IV or Patch.');
            }
        } else if (gi === 'tube') {
            if (route === 'po') {
                w.push('DO NOT CRUSH Extended Release (ER/LA) formulations (OxyContin, MS Contin). Fatal dose dumping risk.');
                r = r.map(x => ({ ...x, detail: x.detail + ' Use liquid formulation.' }));
            }
        }

        // Hepatic Logic
        if (hepatic === 'impaired' || hepatic === 'failure') {
            r = r.map(x => ({ ...x, detail: x.detail + ' Reduce initial dose 50% and extend interval.' }));

            if (hepatic === 'failure') {
                w.push('Liver Failure (Child-Pugh C): Avoid Methadone (accumulation) and Morphine/Codeine (prodrug failure / precipitous coma).');
                r = r.filter(x => x.name !== 'Methadone');
                if (!r.find(x => x.name === 'Fentanyl')) {
                    r.unshift({ name: 'Fentanyl', reason: 'Preferred.', detail: 'Safest option in failures (no active metabolites), but clearance is still reduced.', type: 'safe' });
                }
            }
        }

        // Pain Pathophysiology Logic
        if (painType === 'neuropathic') {
            // If Methadone is present (and safe), upgrade it to Preferred
            const methadone = r.find(x => x.name === 'Methadone');
            if (methadone) {
                // Move Methadone to top and mark preferred
                r = r.filter(x => x.name !== 'Methadone');
                r.unshift({ ...methadone, type: 'safe', reason: 'Preferred.', detail: 'NMDA antagonism treats neuropathic component. Monitor QTc.' });
            }

            // Warn about others
            r = r.map(x => {
                if (x.name !== 'Methadone') {
                    return { ...x, detail: x.detail + ' Less effective for nerve pain. Consider adjuvants.' };
                }
                return x;
            });
        }

        setRecs(r);
        setWarnings(w);
    }, [renal, hemo, route, gi, hepatic, painType]);

    const ParameterBtn = ({ active, onClick, label, sub }: { active: boolean, onClick: () => void, label: string, sub?: string }) => (
        <button
            onClick={onClick}
            className={`w-full text-left p-3 rounded-md border text-sm transition-all ${active
                ? 'bg-teal-50 border-teal-600 text-teal-900 ring-1 ring-teal-600'
                : 'bg-white border-slate-200 text-slate-600 hover:border-teal-400 hover:bg-slate-50'
                }`}
        >
            <div className="font-medium">{label}</div>
            {sub && <div className="text-[10px] opacity-70 mt-0.5">{sub}</div>}
        </button>
    );

    return (
        <div className="flex flex-col lg:flex-row gap-6 h-full">
            {/* Left Pane: Patient Profile */}
            <div className="lg:w-1/3 flex-none space-y-6">
                <div>
                    <h2 className="text-lg font-bold text-slate-800 mb-4 px-1">Case Parameters</h2>
                    <div className="space-y-5">
                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase ml-1">Pain Pathophysiology</label>
                            <div className="space-y-1.5">
                                <ParameterBtn active={painType === 'nociceptive'} onClick={() => setPainType('nociceptive')} label="Nociceptive" sub="Somatic / Visceral" />
                                <ParameterBtn active={painType === 'neuropathic'} onClick={() => setPainType('neuropathic')} label="Neuropathic" sub="Nerve Injury / Radiculopathy" />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase ml-1">Renal Function</label>
                            <div className="space-y-1.5">
                                <ParameterBtn active={renal === 'normal'} onClick={() => setRenal('normal')} label="Normal Function" sub="eGFR > 60" />
                                <ParameterBtn active={renal === 'impaired'} onClick={() => setRenal('impaired')} label="Impaired / CKD" sub="eGFR < 30" />
                                <ParameterBtn active={renal === 'dialysis'} onClick={() => setRenal('dialysis')} label="Dialysis Dependent" sub="HD / PD / CRRT" />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase ml-1">Hemodynamics</label>
                            <div className="space-y-1.5">
                                <ParameterBtn active={hemo === 'stable'} onClick={() => setHemo('stable')} label="Hemodynamically Stable" />
                                <ParameterBtn active={hemo === 'unstable'} onClick={() => setHemo('unstable')} label="Shock / Hypotensive" sub="MAP < 65 or Pressors" />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase ml-1">Hepatic Function</label>
                            <div className="space-y-1.5">
                                <ParameterBtn active={hepatic === 'normal'} onClick={() => setHepatic('normal')} label="Normal Function" />
                                <ParameterBtn active={hepatic === 'impaired'} onClick={() => setHepatic('impaired')} label="Impaired / Cirrhosis" sub="Child-Pugh A/B" />
                                <ParameterBtn active={hepatic === 'failure'} onClick={() => setHepatic('failure')} label="Liver Failure" sub="Child-Pugh C" />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase ml-1">GI / Swallowing</label>
                            <div className="space-y-1.5">
                                <ParameterBtn active={gi === 'intact'} onClick={() => setGi('intact')} label="Intact / Swallow" />
                                <ParameterBtn active={gi === 'tube'} onClick={() => setGi('tube')} label="Tube / Dysphagia" sub="NGT / OGT / PEG" />
                                <ParameterBtn active={gi === 'npo'} onClick={() => setGi('npo')} label="NPO / GI Failure" sub="Ileus / Obstruction" />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <label className="text-xs font-bold text-slate-400 uppercase ml-1">Route of Admin</label>
                            <div className="grid grid-cols-2 gap-2">
                                <ParameterBtn active={route === 'iv'} onClick={() => setRoute('iv')} label="IV / SQ" />
                                <ParameterBtn active={route === 'po'} onClick={() => setRoute('po')} label="Oral (PO)" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Right Pane: Guidance */}
            <div className="lg:flex-1 h-full min-h-[400px] bg-slate-50 rounded-xl border border-slate-200 p-6">
                {recs.length > 0 ? (
                    <div className="space-y-5 animate-in fade-in slide-in-from-bottom-2">
                        <div className="flex items-center justify-between">
                            <h3 className="text-sm font-bold text-slate-500 uppercase tracking-wider flex items-center gap-2">
                                <Beaker className="w-4 h-4" /> Recommended Agents
                            </h3>
                            <span className="text-xs font-medium text-slate-400">{recs.length} options found</span>
                        </div>

                        <div className="space-y-3">
                            {recs.map((rec, i) => (
                                <div key={i} className="bg-white p-4 rounded-lg shadow-sm border border-slate-100 hover:shadow-md transition-shadow">
                                    <div className="flex justify-between items-start mb-2">
                                        <div className="flex items-center gap-2">
                                            {rec.type === 'safe'
                                                ? <div className="p-1 rounded-full bg-emerald-100 text-emerald-600"><Activity className="w-4 h-4" /></div>
                                                : <div className="p-1 rounded-full bg-amber-100 text-amber-600"><AlertTriangle className="w-4 h-4" /></div>
                                            }
                                            <span className="font-bold text-slate-800 text-lg">{rec.name}</span>
                                        </div>
                                        <Badge type={rec.type} text={rec.type === 'safe' ? 'Preferred' : 'Monitor'} />
                                    </div>
                                    <p className="text-slate-600 text-sm font-medium mb-1">{rec.reason}</p>
                                    <p className="text-xs text-slate-400 bg-slate-50 p-2 rounded border border-slate-100 inline-block">{rec.detail}</p>
                                </div>
                            ))}
                        </div>

                        {warnings.length > 0 && (
                            <div className="mt-6">
                                <h3 className="text-xs font-bold text-rose-500 uppercase tracking-wider mb-3 flex items-center gap-2">
                                    <ShieldAlert className="w-4 h-4" /> Contraindications
                                </h3>
                                <div className="bg-rose-50 border border-rose-100 rounded-lg p-4">
                                    <ul className="space-y-2">
                                        {warnings.map((w, i) => (
                                            <li key={i} className="flex items-start gap-2 text-sm text-rose-800">
                                                <span className="block w-1.5 h-1.5 mt-1.5 rounded-full bg-rose-400 flex-none" />
                                                {w}
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            </div>
                        )}
                    </div>
                ) : (
                    <div className="h-full flex flex-col items-center justify-center text-slate-300">
                        <Microscope className="w-12 h-12 mb-4 opacity-50" />
                        <span className="text-sm font-medium">Select parameters to view guidance</span>
                    </div>
                )}
            </div>
        </div>
    );
};

const CalculatorView = () => {
    const [ivMorphine, setIvMorphine] = useState(10);
    const [reduction, setReduction] = useState(30);

    const convert = (factor: number) => {
        const raw = ivMorphine * factor;
        const reduced = raw * (1 - (reduction / 100));
        return { raw: raw.toFixed(1), reduced: reduced.toFixed(1) };
    };

    return (
        <div className="grid lg:grid-cols-2 gap-8 max-w-4xl mx-auto">
            <div className="lg:col-span-2 bg-blue-50 border border-blue-100 rounded-xl p-4 flex gap-4 items-start shadow-sm">
                <div className="p-2 bg-blue-100 text-blue-600 rounded-lg flex-none">
                    <Info className="w-5 h-5" />
                </div>
                <div>
                    <h3 className="text-sm font-bold text-blue-900 mb-1">When to use this Calculator?</h3>
                    <p className="text-sm text-blue-800 leading-relaxed">
                        Use this tool to calculate a safe starting dose when <strong>switching</strong> a patient from one opioid to another (Opioid Rotation).
                        <span className="block mt-1.5 font-bold text-rose-600">
                            ⚠️ Do NOT use this for patients who are not currently taking opioids (opioid-naive).
                        </span>
                    </p>
                </div>
            </div>
            {/* Input Side */}
            <div className="space-y-6">
                <ClinicalCard title="Input Dose">
                    <div className="flex items-center justify-between mb-8">
                        <div>
                            <span className="block text-2xl font-bold text-slate-900">Morphine IV</span>
                            <span className="text-xs text-slate-500 font-medium uppercase tracking-wide">Reference Standard</span>
                        </div>
                        <div className="flex items-baseline gap-1 relative">
                            <input
                                type="number"
                                value={ivMorphine}
                                onChange={(e) => setIvMorphine(Math.max(0, parseFloat(e.target.value)))}
                                className="w-28 text-4xl font-bold text-right text-teal-600 border-b-2 border-slate-100 focus:border-teal-500 focus:outline-none bg-transparent pb-1"
                            />
                            <span className="text-sm font-bold text-slate-400 absolute -right-6 bottom-2">mg</span>
                        </div>
                    </div>

                    <div className="bg-slate-50 p-4 rounded-lg border border-slate-100">
                        <div className="flex justify-between items-center mb-3">
                            <span className="text-xs font-bold text-slate-500 uppercase">Cross-Tolerance Reduction</span>
                            <div className="min-w-[3.5rem] text-center px-2 py-0.5 rounded bg-white border border-slate-200 shadow-sm">
                                <span className={`text-xs font-extrabold ${reduction < 30 ? 'text-rose-500' : reduction > 40 ? 'text-blue-600' : 'text-teal-600'}`}>
                                    -{reduction}%
                                </span>
                            </div>
                        </div>

                        {/* Presets */}
                        <div className="flex justify-between gap-2 mb-3">
                            {[
                                { val: 0, label: '0%', color: 'rose' },
                                { val: 30, label: '30%', color: 'teal' },
                                { val: 50, label: '50%', color: 'blue' }
                            ].map((opt) => (
                                <button
                                    key={opt.val}
                                    onClick={() => setReduction(opt.val)}
                                    className={`flex-1 py-1.5 px-2 rounded text-[10px] font-bold uppercase tracking-wider border transition-all ${reduction === opt.val
                                        ? `bg-white border-${opt.color}-500 text-${opt.color}-600 shadow-sm ring-1 ring-${opt.color}-500`
                                        : 'bg-slate-100 border-slate-200 text-slate-400 hover:bg-white hover:border-slate-300'
                                        }`}
                                >
                                    {opt.label}
                                </button>
                            ))}
                        </div>

                        {/* Range Slider */}
                        <div className="mb-4 px-1">
                            <input
                                type="range"
                                min="0"
                                max="75"
                                step="5"
                                value={reduction}
                                onChange={(e) => setReduction(parseInt(e.target.value))}
                                className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-teal-600"
                            />
                            <div className="flex justify-between mt-1 text-[9px] font-bold text-slate-400 uppercase tracking-wide">
                                <span>Aggressive</span>
                                <span>Conservative</span>
                            </div>
                        </div>

                        <div className="text-[11px] leading-relaxed text-slate-500 bg-white p-3 rounded border border-slate-200 flex gap-2">
                            <div className="mt-0.5 min-w-[14px]">
                                {reduction < 25 ? <Zap className="w-3.5 h-3.5 text-rose-500" /> :
                                    reduction > 40 ? <ShieldAlert className="w-3.5 h-3.5 text-blue-500" /> :
                                        <Activity className="w-3.5 h-3.5 text-teal-500" />}
                            </div>
                            <span>
                                {reduction === 0 && <strong>Aggressive (0%):</strong>}
                                {reduction === 30 && <strong>Standard (30%):</strong>}
                                {reduction === 50 && <strong>Conservative (50%):</strong>}
                                {reduction !== 0 && reduction !== 30 && reduction !== 50 && <strong>Custom (-{reduction}%):</strong>}
                                {' '}
                                {reduction < 25 && "Use ONLY if pain is severe/uncontrolled OR switching route of same drug. High risk of incomplete cross-tolerance."}
                                {(reduction >= 25 && reduction <= 40) && "Standard starting point. Balances pain control with safety margin."}
                                {reduction > 40 && "Recommended for elderly, frail, or renal/hepatic impairment. Prioritizes safety."}
                            </span>
                        </div>
                    </div>
                </ClinicalCard>

                <div className="bg-blue-50 p-4 rounded-lg border border-blue-100 flex gap-3 text-blue-900">
                    <Info className="w-5 h-5 flex-none text-blue-500" />
                    <p className="text-xs leading-relaxed">
                        <strong>Clinical Note:</strong> Calculator uses equianalgesic ratios from NCCN Guidelines.
                        Always use clinical judgment and start lower in elderly/frail patients.
                    </p>
                </div>
            </div>

            {/* Output Side */}
            <div className="space-y-6">
                <div>
                    <h3 className="text-xs font-bold text-slate-400 uppercase mb-3 ml-1">Parenteral Targets (IV/SQ)</h3>
                    <div className="space-y-2">
                        <ClinicalCard className="flex justify-between items-center p-4">
                            <div>
                                <div className="font-bold text-slate-800">Hydromorphone IV</div>
                                <div className="text-[10px] text-slate-400">Ratio 1:6.7</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-teal-600">{convert(0.15).reduced}<small className="text-xs text-slate-400 ml-1">mg</small></div>
                                <div className="text-[10px] text-slate-400 strikethrough decoration-slate-300 opacity-60">{convert(0.15).raw} raw</div>
                            </div>
                        </ClinicalCard>
                        <ClinicalCard className="flex justify-between items-center p-4">
                            <div>
                                <div className="font-bold text-slate-800">Fentanyl IV</div>
                                <div className="text-[10px] text-slate-400">Ratio 1:100 (mcg)</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-teal-600">{convert(10).reduced}<small className="text-xs text-slate-400 ml-1">mcg</small></div>
                            </div>
                        </ClinicalCard>
                    </div>
                </div>

                <div>
                    <h3 className="text-xs font-bold text-slate-400 uppercase mb-3 ml-1">Enteral Targets (PO)</h3>
                    <div className="space-y-2">
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-emerald-400">
                            <div>
                                <div className="font-bold text-slate-800">Oxycodone PO</div>
                                <div className="text-[10px] text-emerald-600 font-medium">High Bioavailability</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-slate-800">{convert(2.0).reduced}<small className="text-xs text-slate-400 ml-1">mg</small></div>
                            </div>
                        </ClinicalCard>
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-amber-400 bg-amber-50/30">
                            <div>
                                <div className="font-bold text-slate-800">Hydromorphone PO</div>
                                <div className="text-[10px] text-amber-600 font-medium">Erratic Absorption</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-slate-800">{convert(0.75).reduced}<small className="text-xs text-slate-400 ml-1">mg</small></div>
                            </div>
                        </ClinicalCard>
                    </div>
                </div>

                <div>
                    <h3 className="text-xs font-bold text-slate-400 uppercase mb-3 ml-1">Transdermal Targets (Patches)</h3>
                    <div className="space-y-2">
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-purple-400 bg-purple-50/20">
                            <div>
                                <div className="font-bold text-slate-800">Fentanyl Patch</div>
                                <div className="text-[10px] text-purple-600 font-medium">72hr Delivery</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-purple-700">{convert(1.5).reduced}<small className="text-xs text-slate-400 ml-1">mcg/h</small></div>
                                <div className="text-[9px] text-slate-400">Ratio 1:2 (OME)</div>
                            </div>
                        </ClinicalCard>
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-indigo-400 bg-indigo-50/20">
                            <div>
                                <div className="font-bold text-slate-800">Butrans Patch</div>
                                <div className="text-[10px] text-indigo-600 font-medium">7-Day Partial Agonist</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-indigo-700">{convert(1.5).reduced}<small className="text-xs text-slate-400 ml-1">mcg/h</small></div>
                                <div className="text-[9px] text-slate-400">Max 20mcg/h</div>
                            </div>
                        </ClinicalCard>
                    </div>
                    <div className="mt-2 p-2 bg-purple-50 rounded border border-purple-100 text-[10px] text-purple-700 italic leading-tight">
                        Note: Patches take 12-24h for initial effect. Maintain bridge dose if transitioning from short-acting opioids.
                    </div>
                </div>

                <div>
                    <h3 className="text-xs font-bold text-slate-400 uppercase mb-3 ml-1">Transmucosal Targets (SL/Buccal)</h3>
                    <div className="space-y-2">
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-rose-400 bg-rose-50/10">
                            <div>
                                <div className="font-bold text-slate-800">Fentanyl SL</div>
                                <div className="text-[10px] text-rose-600 font-medium">Rapid Breakthrough</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-rose-700">{convert(10).reduced}<small className="text-xs text-slate-400 ml-1">mcg</small></div>
                                <div className="text-[9px] text-slate-400">Not for Naive</div>
                            </div>
                        </ClinicalCard>
                    </div>
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
        <div className="max-w-4xl mx-auto space-y-6">
            <div className="relative">
                <Search className="absolute left-3 top-3.5 h-4 w-4 text-slate-400" />
                <input
                    type="text"
                    placeholder="Search by drug, metabolite, or mechanism..."
                    className="w-full pl-9 pr-4 py-3 rounded-xl border border-slate-200 outline-none focus:ring-2 focus:ring-teal-100 focus:border-teal-500 text-sm shadow-sm"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                />
            </div>

            <div className="space-y-3">
                {filtered.map(drug => (
                    <div key={drug.id} className="bg-white rounded-lg border border-slate-200 overflow-hidden shadow-sm hover:shadow-md transition-all">
                        <div
                            onClick={() => setExpanded(expanded === drug.id ? null : drug.id)}
                            className="p-4 cursor-pointer flex justify-between items-center group"
                        >
                            <div>
                                <div className="flex items-center gap-3">
                                    <h3 className="font-bold text-slate-800">{drug.name}</h3>
                                    <Badge type={drug.type} text={drug.renal_safety === 'Safe' ? 'Renal Safe' : 'Renal Caution'} />
                                </div>
                                <div className="text-xs text-slate-500 mt-1">{drug.type}</div>
                            </div>
                            <div className={`p-1 rounded-full transition-colors ${expanded === drug.id ? 'bg-slate-100 text-slate-600' : 'text-slate-300 group-hover:text-slate-500'}`}>
                                {expanded === drug.id ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                            </div>
                        </div>

                        {expanded === drug.id && (
                            <div className="bg-slate-50 px-4 pb-4 pt-4 border-t border-slate-100 text-sm">
                                <div className="grid md:grid-cols-2 gap-4 mb-4">
                                    <div className="bg-white p-3 rounded border border-slate-200">
                                        <span className="block text-[10px] font-bold text-slate-400 uppercase tracking-wide mb-1">IV Profile</span>
                                        <span className="text-slate-700 font-medium">{drug.iv_onset} onset / {drug.iv_duration} duration</span>
                                    </div>
                                    <div className="bg-white p-3 rounded border border-slate-200">
                                        <span className="block text-[10px] font-bold text-slate-400 uppercase tracking-wide mb-1">Bioavailability</span>
                                        <div className="flex items-center gap-2">
                                            <div className="flex-1 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                                                <div className="h-full bg-teal-500" style={{ width: `${drug.bioavailability}%` }}></div>
                                            </div>
                                            <span className="text-xs font-bold text-slate-600 w-8">{drug.bioavailability > 0 ? `${drug.bioavailability}%` : '-'}</span>
                                        </div>
                                    </div>
                                </div>

                                <div className="space-y-3">
                                    <div className="flex gap-3">
                                        <Zap className="w-4 h-4 text-purple-500 flex-none mt-0.5" />
                                        <div>
                                            <h4 className="text-xs font-bold text-slate-900 uppercase mb-1">Clinical Nuance</h4>
                                            <p className="text-slate-600 leading-relaxed">{drug.clinical_nuance}</p>
                                        </div>
                                    </div>
                                    <div className="flex gap-3">
                                        <Activity className="w-4 h-4 text-slate-400 flex-none mt-0.5" />
                                        <div>
                                            <h4 className="text-xs font-bold text-slate-900 uppercase mb-1">Pharmacokinetics</h4>
                                            <p className="text-slate-500 leading-relaxed text-xs">{drug.pharmacokinetics}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                ))}
            </div>
        </div>
    );
};

// --- Shell ---

const SidebarItem = ({ active, icon: Icon, label, onClick }: { active: boolean, icon: any, label: string, onClick: () => void }) => (
    <button
        onClick={onClick}
        className={`w-full flex flex-col items-center justify-center p-3 rounded-xl transition-all mb-2 ${active
            ? 'bg-teal-50 text-teal-700 shadow-sm'
            : 'text-slate-400 hover:text-slate-600 hover:bg-slate-50'
            }`}
    >
        <Icon className={`w-6 h-6 mb-1 ${active ? 'stroke-2' : 'stroke-1.5'}`} />
        <span className="text-[10px] font-bold tracking-wide">{label}</span>
    </button>
);

const OpioidPrecisionApp = () => {
    const [activeTab, setActiveTab] = useState('decision');

    return (
        <div className="flex h-screen bg-white text-slate-900 font-sans overflow-hidden">
            {/* Sidebar Navigation */}
            <nav className="w-20 bg-white border-r border-slate-200 flex flex-col items-center py-6 z-20 flex-none">
                <div className="mb-8">
                    <div className="w-10 h-10 bg-teal-600 rounded-xl flex items-center justify-center text-white shadow-teal-200 shadow-lg">
                        <Activity className="w-6 h-6" />
                    </div>
                </div>

                <div className="flex-1 w-full px-2">
                    <SidebarItem active={activeTab === 'decision'} onClick={() => setActiveTab('decision')} icon={Home} label="Guide" />
                    <SidebarItem active={activeTab === 'calc'} onClick={() => setActiveTab('calc')} icon={Calculator} label="Dose" />
                    <SidebarItem active={activeTab === 'ref'} onClick={() => setActiveTab('ref')} icon={Database} label="Drugs" />
                </div>

                <div className="mt-auto px-2 space-y-2">
                    <button className="w-full text-slate-300 hover:text-slate-500 p-2"><Settings className="w-5 h-5 mx-auto" /></button>
                    <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 text-xs font-bold mx-auto">
                        DB
                    </div>
                </div>
            </nav>

            {/* Main Content Area */}
            <div className="flex-1 flex flex-col h-full bg-white overflow-hidden relative">
                {/* Top Bar */}
                <header className="h-16 border-b border-slate-100 flex items-center justify-between px-8 bg-white/80 backdrop-blur-sm z-10 flex-none">
                    <div>
                        <h1 className="text-xl font-bold text-slate-800">
                            {activeTab === 'decision' && 'Clinical Decision Support'}
                            {activeTab === 'calc' && 'Conversion Calculator'}
                            {activeTab === 'ref' && 'Pharmacology Reference'}
                        </h1>
                        <p className="text-xs text-slate-400 font-medium">Inpatient Opioid Management Tool</p>
                    </div>
                    <div className="flex items-center gap-4">
                        <div className="hidden md:flex items-center gap-2 px-3 py-1.5 bg-slate-50 rounded-lg text-xs font-medium text-slate-500 border border-slate-100">
                            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                            System Active
                        </div>
                    </div>
                </header>

                {/* View Container */}
                <main className="flex-1 overflow-y-auto p-8 relative">
                    {activeTab === 'decision' && <DecisionSupportView />}
                    {activeTab === 'calc' && <CalculatorView />}
                    {activeTab === 'ref' && <ReferenceView />}
                </main>
            </div>
        </div>
    );
};

export default OpioidPrecisionApp;
