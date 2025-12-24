import React, { useState, useEffect } from 'react';
import {
    Activity,
    AlertTriangle,
    ShieldAlert,
    Microscope,
    Beaker,
    Copy,
    CheckCircle2,
    Users,
    Timer,
    HeartPulse,
    Wind
} from 'lucide-react';
import { Badge, ClinicalCard, ParameterBtn } from './Shared';

export const AssessmentView = () => {
    // Clinical Parameters
    const [renal, setRenal] = useState<string | null>(null);
    const [hemo, setHemo] = useState<string | null>(null);
    const [hepatic, setHepatic] = useState<string | null>(null);
    const [painType, setPainType] = useState<string | null>(null);
    const [indication, setIndication] = useState<string | null>(null);
    const [route, setRoute] = useState<string | null>(null);
    const [gi, setGi] = useState<string | null>(null);
    const [organSupport, setOrganSupport] = useState(false); // New: Pressors/Vent?

    // Demographics & PRODIGY Inputs
    const [age, setAge] = useState<string>('');
    const [sex, setSex] = useState<'male' | 'female' | null>(null);
    const [naive, setNaive] = useState(false);

    // Comorbidities / Risk Factors
    const [sleepApnea, setSleepApnea] = useState(false);
    const [chf, setChf] = useState(false);
    const [copd, setCopd] = useState(false);
    const [benzos, setBenzos] = useState(false);
    const [psychHistory, setPsychHistory] = useState(false);

    // Outputs
    const [recs, setRecs] = useState<any[]>([]);
    const [adjuvants, setAdjuvants] = useState<string[]>([]);
    const [warnings, setWarnings] = useState<string[]>([]);

    // PRODIGY State
    const [prodigyScore, setProdigyScore] = useState(0);
    const [prodigyRisk, setProdigyRisk] = useState<'Low' | 'Intermediate' | 'High'>('Low');
    const [monitoringRecs, setMonitoringRecs] = useState<string[]>([]);

    // Legacy Risk State (still useful for general stratification)
    const [riskScore, setRiskScore] = useState<'Low' | 'Moderate' | 'High'>('Low');
    const [riskReasons, setRiskReasons] = useState<string[]>([]);

    useEffect(() => {
        // --- RESET OUTPUTS ---
        let r: any[] = [];
        let adj: string[] = [];
        let w: string[] = [];
        let rReasons: string[] = [];
        let score: 'Low' | 'Moderate' | 'High' = 'Low';

        // --- PRODIGY SCORING LOGIC (Always Runs) ---
        let pScore = 0;
        let pRisk: 'Low' | 'Intermediate' | 'High' = 'Low';
        let monitors: string[] = [];

        // 1. Age Decades >= 60
        const ageNum = parseInt(age);
        if (!isNaN(ageNum) && ageNum >= 60) {
            if (ageNum >= 80) pScore += 6;
            else if (ageNum >= 70) pScore += 4;
            else pScore += 2;
        }

        // 2. Male Sex
        if (sex === 'male') pScore += 3;

        // 3. Opioid Naivety (Strongest Predictor)
        if (naive) pScore += 5;

        // 4. Sleep Disorders
        if (sleepApnea) pScore += 4;

        // 5. CHF
        if (chf) pScore += 3;

        // Determine Risk Tier
        if (pScore >= 21) {
            pRisk = 'High';
            monitors.push('⚠️ CONTINUOUS CAPNOGRAPHY + Pulse Oximetry REQUIRED.');
            monitors.push('Nursing assessment q1h x 12h, then q2h.');
            monitors.push('POSS Sedation Scale before every dose.');
            monitors.push('Consider 10-25% dose reduction. Naloxone at bedside.');
        } else if (pScore >= 10) {
            pRisk = 'Intermediate';
            monitors.push('Consider Continuous Capnography.');
            monitors.push('Nursing assessment q2h x 24h.');
            monitors.push('POSS Sedation Scale with vitals.');
        } else {
            pRisk = 'Low';
            monitors.push('Standard monitoring per protocol.');
        }

        // Additional High Risk Modifiers (Non-scored but critical)
        if (benzos) {
            monitors.push('Warning: Concurrent Benzos increase overdose risk 3.8x.');
            if (pRisk === 'Low') {
                pRisk = 'Intermediate'; // Upgrade risk manually
                monitors.push('Risk Upgraded due to Sedatives.');
            }
        }
        if (copd) {
            monitors.push('COPD: Increased retention risk. Target SpO2 88-92%?');
        }

        setProdigyScore(pScore);
        setProdigyRisk(pRisk);
        setMonitoringRecs(monitors);

        // --- CLINICAL LOGIC (Progressive) ---

        // Helpers to avoid duplication for IV/PO choices
        const addIVRecs = (isRenalBad: boolean) => {
            if (isRenalBad) {
                r.push({ name: 'Fentanyl IV', reason: 'Preferred (No metabolites).', detail: 'Safest renal option.', type: 'safe' });
                r.push({ name: 'Hydromorphone IV', reason: 'Caution.', detail: 'Reduce dose 50%. Watch for H3G accumulation.', type: 'caution' });
            } else {
                r.push({ name: 'Morphine IV', reason: 'Standard.', detail: 'Ideal first-line unless hypotensive.', type: 'safe' });
                r.push({ name: 'Hydromorphone IV', reason: 'Standard.', detail: 'Preferred in high tolerance.', type: 'safe' });
            }
        };

        const addPORecs = (isRenalBad: boolean) => {
            if (isRenalBad) {
                r.push({ name: 'Oxycodone PO', reason: 'Caution.', detail: 'Reduce frequency. Monitor for sedation.', type: 'caution' });
                r.push({ name: 'Hydromorphone PO', reason: 'Caution.', detail: 'Reduce dose 50%. Monitor carefully.', type: 'caution' });
            } else {
                r.push({ name: 'Oxycodone PO', reason: 'Preferred.', detail: 'Superior bioavailability to PO Morphine.', type: 'safe' });
                r.push({ name: 'Morphine PO', reason: 'Standard.', detail: 'Reliable if renal function is normal.', type: 'safe' });
            }
        };

        // 1. HEMODYNAMICS (Immediate Override)
        if (hemo === 'unstable') {
            rReasons.push('Hemodynamic Instability');
            score = 'High';
            r.push({ name: 'Fentanyl', reason: 'Preferred.', detail: 'Cardiostable; no histamine release.', type: 'safe' });
            w.push('Morphine: Histamine release precipitates vasodilation/hypotension.');
        }

        // 2. STANDARD OPIOID SELECTION
        if (renal && hemo !== 'unstable') {
            const isRenalBad = renal === 'dialysis' || renal === 'impaired';
            if (isRenalBad) {
                rReasons.push('Renal Insufficiency');
                score = 'High';
                w.push('Morphine Contraindicated: M6G/M3G accumulation causes coma and myoclonus.');
            }

            // Apply Route Logic
            if (route === 'iv') {
                addIVRecs(isRenalBad);
            } else if (route === 'po') {
                addPORecs(isRenalBad);
            } else if (route === 'both' || route === 'either') {
                addIVRecs(isRenalBad);
                addPORecs(isRenalBad);
                if (route === 'either') {
                    adj.push('Route Preference: Determine based on GI tolerance and required speed of onset.');
                }
            } else {
                // Default if route unknown
                addIVRecs(isRenalBad);
            }
        }

        // 3. HEPATIC SAFETY GATES
        if (hepatic) {
            if (hepatic === 'failure') {
                rReasons.push('Hepatic Failure');
                score = 'High';
                w.push('Liver Failure (Child-Pugh C): Avoid Methadone and Morphine/Codeine.');
                r = r.filter(x => x.name !== 'Methadone' && !x.name.includes('Morphine'));
                if (!r.find(x => x.name === 'Fentanyl' || x.name === 'Fentanyl IV')) {
                    r.unshift({ name: 'Fentanyl', reason: 'Preferred.', detail: 'Safest in failure.', type: 'safe' });
                }
                r = r.map(x => ({ ...x, detail: x.detail + ' Reduce dose 50%.' }));
            } else if (hepatic === 'impaired') {
                rReasons.push('Hepatic Impairment');
                if (score !== 'High') score = 'Moderate';
                r = r.map(x => ({ ...x, detail: x.detail + ' Reduce initial dose 50%.' }));
            }
        }

        // 4. GI / NPO Logic
        if (gi === 'npo') {
            if (route === 'po' || route === 'both' || route === 'either') {
                const poNames = ['Oxycodone PO', 'Hydromorphone PO', 'Morphine PO', 'Oxycodone'];
                if (route === 'po') r = [];
                else r = r.filter(x => !poNames.includes(x.name));
                w.push('PO Contraindicated: Patient is NPO / AMS. Switch to IV.');
            }
        } else if (gi === 'tube') {
            const poIndicators = ['PO', 'Oxycodone', 'Hydromorphone PO'];
            if (r.some(x => poIndicators.some(ind => x.name.includes(ind)))) {
                w.push('Tube Access: Use liquid formulations. Do not crush ER/LA meds.');
            }
        }

        // 5. PAIN TYPE ADJUVANTS
        if (painType) {
            if (painType === 'neuropathic') {
                adj.push('Gabapentinoids: Gabapentin or Pregabalin (Lyrica).');
                adj.push('Antidepressants: Duloxetine (Cymbalta) or Nortriptyline.');
                adj.push('Topicals: Lidocaine 5% patch.');
            } else if (painType === 'inflammatory') {
                adj.push('NSAIDs: Naproxen or Celecoxib.');
                adj.push('Acetaminophen: 650-1000mg q6h.');
            } else if (painType === 'bone') {
                adj.push('NSAIDs / Corticosteroids: Dexamethasone is superior for periosteal stretch.');
                w.push('Bone Pain: Consider radiation oncology consult.');
            } else if (painType === 'nociceptive') {
                adj.push('Acetaminophen / NSAIDs: Scheduled multimodal foundation.');
            }
        }

        // 6. CLINICAL SCENARIO CONTEXT
        if (indication) {
            if (indication === 'cancer_pain') {
                w.push('Cancer Pain: Utilize short-acting opioids for titration.');
            } else if (indication === 'dyspnea') {
                if (renal === 'normal' && (route === 'iv' || route === 'either' || route === 'both' || !route)) {
                    if (!r.find(x => x.name === 'Morphine IV')) {
                        r.unshift({ name: 'Morphine IV', reason: 'Gold Standard.', detail: 'Strong evidence for air hunger.', type: 'safe' });
                    }
                }
                adj.push('Anxiety: Consider Low-dose Lorazepam (0.5mg).');
            }
        }

        // 7. General Risk Factors
        if (sleepApnea) {
            rReasons.push('Sleep Apnea (OSA)');
            score = score === 'High' ? 'High' : 'Moderate';
            w.push('OSA: Avoid basal infusions. Monitoring is critical.');
        }

        setRecs(r);
        setAdjuvants(adj);
        setWarnings(w);
        setRiskScore(score);
        setRiskReasons(rReasons);

    }, [renal, hemo, route, gi, hepatic, painType, indication, sleepApnea, psychHistory, age, sex, naive, chf, copd, benzos]);

    const handleCopy = () => {
        const note = `
Opioid Risk Assessment
----------------------
PRODIGY Score: ${prodigyScore} (${prodigyRisk.toUpperCase()} RISK)
Monitoring Plan:
${monitoringRecs.map(m => `- ${m}`).join('\n')}

Risk Factors:
${sleepApnea ? '- Sleep Apnea (+4)' : ''}
${naive ? '- Opioid Naive (+5)' : ''}
${chf ? '- Chronic Heart Failure (+3)' : ''}
${sex === 'male' ? '- Male Sex (+3)' : ''}

Clinical Recommendations:
${recs.map(r => `- ${r.name}: ${r.reason} (${r.detail})`).join('\n')}
${adjuvants.length > 0 ? '\nAdjuvants:\n' + adjuvants.map(a => `- ${a}`).join('\n') : ''}
${warnings.length > 0 ? '\nWarnings:\n' + warnings.map(w => `- ${w}`).join('\n') : ''}
    `.trim();
        navigator.clipboard.writeText(note);
    };

    return (
        <div className="flex flex-col lg:flex-row gap-4 h-auto lg:h-full p-4 md:p-0">
            {/* Left Pane: Patient Profile */}
            <div className="lg:w-1/3 flex-none space-y-3 lg:overflow-y-auto pr-2 custom-scrollbar">
                <h2 className="text-lg font-bold text-text-primary mb-2 px-1">Selection & Risk</h2>
                <div className="space-y-3">

                    {/* Demographics & PRODIGY */}
                    <div className="bg-surface-highlight p-3 rounded-2xl border border-border space-y-3">
                        <h3 className="text-xs font-bold text-text-secondary uppercase tracking-wider flex items-center gap-2">
                            <Users className="w-4 h-4" /> Patient Demographics
                        </h3>

                        <div className="flex gap-3">
                            <div className="flex-1">
                                <label className="block text-xs font-bold text-text-tertiary uppercase mb-1">Age</label>
                                <input
                                    type="number"
                                    placeholder="Yrs"
                                    value={age}
                                    onChange={(e) => setAge(e.target.value)}
                                    className="w-full px-3 py-1.5 rounded-xl border border-border text-sm font-bold text-text-primary outline-none focus:border-action bg-surface-card transition-all"
                                />
                            </div>
                            <div className="flex-1">
                                <label className="block text-xs font-bold text-text-tertiary uppercase mb-1">Sex</label>
                                <div className="flex bg-surface-card rounded-xl border border-border overflow-hidden">
                                    <button onClick={() => setSex('male')} className={`flex-1 py-1.5 text-xs font-bold transition-all ${sex === 'male' ? 'bg-action-bg text-action' : 'text-text-tertiary hover:bg-surface-highlight'}`}>M</button>
                                    <div className="w-px bg-border"></div>
                                    <button onClick={() => setSex('female')} className={`flex-1 py-1.5 text-xs font-bold transition-all ${sex === 'female' ? 'bg-action-bg text-action' : 'text-text-tertiary hover:bg-surface-highlight'}`}>F</button>
                                </div>
                            </div>
                        </div>

                        <label className={`flex items-center justify-between p-3 rounded-xl border cursor-pointer transition-all ${naive ? 'bg-action-bg border-action-border/30' : 'bg-surface-card border-border'}`}>
                            <div>
                                <span className="text-xs font-bold text-text-primary block">Opioid Naive</span>
                                <span className="text-[10px] text-text-tertiary font-medium">No exposure last 7 days</span>
                            </div>
                            <input type="checkbox" checked={naive} onChange={e => setNaive(e.target.checked)} className="w-4 h-4 accent-action rounded" />
                        </label>
                    </div>

                    {/* Risk Factors Section */}
                    <div className="bg-danger-bg/50 p-3 rounded-2xl border border-danger/20 space-y-2">
                        <h3 className="text-xs font-bold text-danger uppercase tracking-wider flex items-center gap-2">
                            <ShieldAlert className="w-4 h-4" /> PRODIGY & Safety
                        </h3>

                        <div className="grid grid-cols-1 gap-1.5">
                            <label className="flex items-center gap-2 p-2 bg-surface-card rounded-xl border border-border cursor-pointer hover:border-danger/30 transition-all">
                                <input type="checkbox" checked={sleepApnea} onChange={e => setSleepApnea(e.target.checked)} className="w-3.5 h-3.5 accent-danger" />
                                <span className="text-[11px] font-bold text-text-secondary">Sleep Apnea (OSA/CSA)</span>
                            </label>
                            <label className="flex items-center gap-2 p-2 bg-surface-card rounded-xl border border-border cursor-pointer hover:border-danger/30 transition-all">
                                <input type="checkbox" checked={chf} onChange={e => setChf(e.target.checked)} className="w-3.5 h-3.5 accent-danger" />
                                <span className="text-[11px] font-bold text-text-secondary">Chronic Heart Failure</span>
                            </label>
                            <label className="flex items-center gap-2 p-2 bg-surface-card rounded-xl border border-border cursor-pointer hover:border-danger/30 transition-all">
                                <input type="checkbox" checked={benzos} onChange={e => setBenzos(e.target.checked)} className="w-3.5 h-3.5 accent-danger" />
                                <span className="text-[11px] font-bold text-text-secondary">Benzos / Sedatives</span>
                            </label>
                            <label className="flex items-center gap-2 p-2 bg-surface-card rounded-xl border border-border cursor-pointer hover:border-danger/30 transition-all">
                                <input type="checkbox" checked={copd} onChange={e => setCopd(e.target.checked)} className="w-3.5 h-3.5 accent-danger" />
                                <span className="text-[11px] font-bold text-text-secondary">COPD / Lung Disease</span>
                            </label>
                            <label className="flex items-center gap-2 p-2 bg-surface-card rounded-xl border border-border cursor-pointer hover:border-danger/30 transition-all">
                                <input type="checkbox" checked={psychHistory} onChange={e => setPsychHistory(e.target.checked)} className="w-3.5 h-3.5 accent-danger" />
                                <span className="text-[11px] font-bold text-text-secondary">Substance / Psych Hx</span>
                            </label>
                        </div>
                    </div>

                    <div className="space-y-3 pt-1">
                        {/* 1. Hemodynamics */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">1. Hemodynamics</label>
                            <div className="space-y-1">
                                <ParameterBtn active={hemo === 'stable'} onClick={() => setHemo('stable')} label="Hemodynamically Stable" />
                                <ParameterBtn active={hemo === 'unstable'} onClick={() => setHemo('unstable')} label="Shock / Hypotensive" sub="MAP < 65 or Pressors" />
                            </div>
                        </div>

                        {/* 2. Renal Function */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">2. Renal Function</label>
                            <div className="space-y-1">
                                <ParameterBtn active={renal === 'normal'} onClick={() => setRenal('normal')} label="Normal Function" sub="eGFR > 60" />
                                <ParameterBtn active={renal === 'impaired'} onClick={() => setRenal('impaired')} label="Impaired / CKD" sub="eGFR < 30" />
                                <ParameterBtn active={renal === 'dialysis'} onClick={() => setRenal('dialysis')} label="Dialysis Dependent" sub="HD / PD / CRRT" />
                            </div>
                        </div>

                        {/* 3. GI / AMS / Swallowing */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">3. GI / Mental Status</label>
                            <div className="space-y-1">
                                <ParameterBtn active={gi === 'intact'} onClick={() => setGi('intact')} label="Intact / Alert" />
                                <ParameterBtn active={gi === 'tube'} onClick={() => setGi('tube')} label="Tube / Dysphagia" sub="NGT / OGT / PEG" />
                                <ParameterBtn active={gi === 'npo'} onClick={() => setGi('npo')} label="NPO / GI Failure / AMS" sub="Ileus / Unresponsive" />
                            </div>
                        </div>

                        {/* 4. Desired Route */}
                        <div className="space-y-1.5 bg-action-bg/5 px-2 py-3 rounded-xl border border-action-border/10">
                            <label className="text-[10px] font-bold text-action uppercase ml-1">4. Desired Route</label>
                            <div className="grid grid-cols-2 gap-2 mt-1">
                                <ParameterBtn active={route === 'iv'} onClick={() => setRoute('iv')} label="IV / SQ" />
                                <ParameterBtn active={route === 'po'} onClick={() => setRoute('po')} label="Oral (PO)" />
                                <ParameterBtn active={route === 'both'} onClick={() => setRoute('both')} label="Both" />
                                <ParameterBtn active={route === 'either'} onClick={() => setRoute('either')} label="Either" />
                            </div>
                        </div>

                        {/* 5. Hepatic Function */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">5. Hepatic Function</label>
                            <div className="space-y-1">
                                <ParameterBtn active={hepatic === 'normal'} onClick={() => setHepatic('normal')} label="Normal Function" />
                                <ParameterBtn active={hepatic === 'impaired'} onClick={() => setHepatic('impaired')} label="Impaired / Cirrhosis" sub="Child-Pugh A/B" />
                                <ParameterBtn active={hepatic === 'failure'} onClick={() => setHepatic('failure')} label="Liver Failure" sub="Child-Pugh C" />
                            </div>
                        </div>

                        {/* 6. Clinical Scenario */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">6. Clinical Scenario</label>
                            <div className="space-y-1">
                                <ParameterBtn active={indication === 'standard'} onClick={() => setIndication('standard')} label="General / Acute Pain" sub="Post-Op / Trauma / Medical" />
                                <ParameterBtn active={indication === 'dyspnea'} onClick={() => setIndication('dyspnea')} label="Palliative Dyspnea" sub="End of Life / Air Hunger" />
                                <ParameterBtn active={indication === 'cancer_pain'} onClick={() => setIndication('cancer_pain')} label="Cancer Pain" sub="Active Malignancy / Metastatic" />
                            </div>
                        </div>

                        {/* 7. Dominant Pathophysiology */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">7. Dominant Pathophysiology</label>
                            <div className="space-y-1">
                                <ParameterBtn active={painType === 'nociceptive'} onClick={() => setPainType('nociceptive')} label="Nociceptive (Tissue)" sub="Somatic / Visceral" />
                                <ParameterBtn active={painType === 'neuropathic'} onClick={() => setPainType('neuropathic')} label="Neuropathic (Nerve)" sub="Radiculopathy / Spinal Cord" />
                                <ParameterBtn active={painType === 'inflammatory'} onClick={() => setPainType('inflammatory')} label="Inflammatory" sub="Autoimmune / Infection / Abscess" />
                                <ParameterBtn active={painType === 'bone'} onClick={() => setPainType('bone')} label="Bone Pain" sub="Metastatic / Periosteal" />
                            </div>
                        </div>

                    </div>
                </div>
            </div>
            {/* Right Pane: Guidance */}
            <div className="lg:flex-1 h-auto lg:h-full min-h-[400px] bg-surface-highlight rounded-2xl border border-border p-4 flex flex-col shadow-inner">
                {recs.length > 0 ? (
                    <div className="space-y-4 animate-fade-in flex-1 flex flex-col h-auto lg:h-full lg:overflow-hidden">

                        {/* Static Advisory - Always Visible */}
                        <div className="bg-action-bg/30 border border-action-border/20 p-3 rounded-xl flex items-start gap-3 shrink-0">
                            <Activity className="w-4 h-4 text-action mt-0.5" />
                            <div className="text-xs text-text-primary leading-relaxed font-medium">
                                <strong>Non-Opioid Strategy:</strong>
                                {(hepatic === 'impaired' || hepatic === 'failure' || (hepatic === 'normal' && renal === 'normal')) && (
                                    <p className="mt-0.5">• Avoid Tylenol {'>'} 4g daily (2g if liver failure).</p>
                                )}
                                {(renal === 'impaired' || renal === 'dialysis' || hepatic === 'failure' || (hepatic === 'normal' && renal === 'normal')) && (
                                    <p className="mt-0.5">• Avoid NSAIDs in HTN/CAD, GI Bleed, Renal Disease, Cirrhosis.</p>
                                )}
                            </div>
                        </div>

                        {/* Scrollable Content Container */}
                        <div className="lg:overflow-y-auto custom-scrollbar flex-1 pr-2 space-y-4">

                            {/* PRODIGY Header */}
                            <div className="bg-surface-card rounded-2xl border border-border shadow-sm overflow-hidden mb-2">
                                <div className="p-3 border-b border-border flex justify-between items-center bg-surface-highlight/50">
                                    <div className="flex items-center gap-2">
                                        <Activity className="w-5 h-5 text-action" />
                                        <div>
                                            <h3 className="text-xs font-bold text-text-primary uppercase tracking-wide">PRODIGY Risk Score</h3>
                                            <p className="text-[10px] text-text-tertiary font-medium">Respiratory Depression Prediction</p>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <div className="text-2xl font-black text-action leading-none">{prodigyScore}</div>
                                        <div className={`text-[10px] font-bold uppercase px-1.5 py-0.5 rounded ${prodigyRisk === 'High' ? 'bg-danger-bg text-danger' :
                                            prodigyRisk === 'Intermediate' ? 'bg-warning-bg text-warning' :
                                                'bg-action-bg text-action'
                                            }`}>{prodigyRisk} Risk</div>
                                    </div>
                                </div>

                                {/* Monitoring Plan */}
                                <div className={`p-3 ${prodigyRisk === 'High' ? 'bg-danger-bg/20' : prodigyRisk === 'Intermediate' ? 'bg-warning-bg/20' : 'bg-surface-highlight/30'}`}>
                                    <h4 className={`text-xs font-bold uppercase mb-2 flex items-center gap-2 ${prodigyRisk === 'High' ? 'text-danger' :
                                        prodigyRisk === 'Intermediate' ? 'text-warning' :
                                            'text-text-secondary'
                                        }`}>
                                        <HeartPulse className="w-4 h-4" /> Monitoring Strategy
                                    </h4>
                                    <ul className="space-y-1 mb-2">
                                        {monitoringRecs.map((m, i) => (
                                            <li key={i} className="text-xs font-medium text-text-secondary flex items-start gap-2">
                                                <span className="mt-1.5 w-1 h-1 rounded-full bg-text-tertiary flex-none" />
                                                {m}
                                            </li>
                                        ))}
                                    </ul>

                                    {/* Temporal Alert */}
                                    <div className="bg-surface-card/60 rounded-xl border border-border p-2 flex gap-3 items-center">
                                        <Timer className="w-4 h-4 text-text-tertiary flex-none" />
                                        <div className="text-[10px] text-text-secondary leading-tight">
                                            <strong>Peak Risk:</strong> 14:00-20:00 (Day 0) & 02:00-06:00 (Night).
                                            Median onset 8.8h post-op. 46% of PRODIGY patients had an event.
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="flex items-center justify-between mt-2">
                                <h3 className="text-xs font-bold text-text-tertiary uppercase tracking-wider flex items-center gap-2">
                                    <Beaker className="w-4 h-4" /> Clinical Recommendations
                                </h3>
                                <button
                                    onClick={handleCopy}
                                    className="flex items-center gap-2 px-3 py-1.5 bg-surface-highlight hover:bg-surface-card text-text-secondary rounded-xl transition-all text-[10px] font-bold border border-border"
                                >
                                    <Copy className="w-3 h-3" />
                                    Smart Copy
                                </button>
                            </div>

                            <div className="space-y-3 lg:overflow-y-auto custom-scrollbar flex-1 pr-1">
                                {recs.map((rec, i) => (
                                    <div key={i} className="bg-surface-card p-4 rounded-2xl shadow-sm border border-border hover:shadow-md transition-all">
                                        <div className="flex justify-between items-start mb-2">
                                            <div className="flex items-center gap-2">
                                                {rec.type === 'safe'
                                                    ? <div className="p-1 rounded-full bg-action-bg text-action"><Activity className="w-4 h-4" /></div>
                                                    : <div className="p-1 rounded-full bg-warning-bg text-warning"><AlertTriangle className="w-4 h-4" /></div>
                                                }
                                                <span className="font-bold text-text-primary text-base">{rec.name}</span>
                                            </div>
                                            <Badge type={rec.type} text={rec.type === 'safe' ? 'Preferred' : 'Monitor'} />
                                        </div>
                                        <p className="text-text-secondary text-xs font-medium mb-2">{rec.reason}</p>
                                        <p className="text-[10px] text-text-tertiary bg-surface-highlight/50 p-2 rounded-xl border border-border inline-block leading-relaxed">{rec.detail}</p>
                                    </div>
                                ))}

                                {adjuvants.length > 0 && (
                                    <div className="mt-4 space-y-2">
                                        <h3 className="text-xs font-bold text-action uppercase tracking-wider flex items-center gap-2">
                                            <CheckCircle2 className="w-4 h-4" /> Suggested Adjuvants
                                        </h3>
                                        {adjuvants.map((adj, i) => (
                                            <div key={i} className="bg-action-bg/30 p-3 rounded-xl border border-action-border/20 text-xs text-text-primary leading-relaxed font-medium">
                                                {adj}
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>

                            {/* Close Scrollable Container */}
                        </div>

                        {warnings.length > 0 && (
                            <div className="mt-auto pt-4">
                                <h3 className="text-xs font-bold text-danger uppercase tracking-wider mb-2 flex items-center gap-2">
                                    <ShieldAlert className="w-4 h-4" /> Contraindications
                                </h3>
                                <div className="bg-danger-bg/30 border border-danger/20 rounded-xl p-3">
                                    <ul className="space-y-1.5">
                                        {warnings.map((w, i) => (
                                            <li key={i} className="flex items-start gap-2 text-xs text-text-primary font-medium">
                                                <span className="block w-1.5 h-1.5 mt-1.5 rounded-full bg-danger flex-none" />
                                                {w}
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            </div>
                        )}
                    </div>
                ) : (
                    <div className="h-full flex flex-col items-center justify-center text-text-tertiary">
                        <Microscope className="w-12 h-12 mb-4 opacity-50" />
                        <span className="text-sm font-medium">Select parameters to view guidance</span>
                    </div>
                )}
            </div>
        </div >
    );
};
