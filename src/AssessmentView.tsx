import React, { useEffect, useState } from 'react';
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
    HeartPulse
} from 'lucide-react';
import { Badge, ParameterBtn } from './Shared';
import { useAssessmentStore } from './stores/AssessmentStore';

export const AssessmentView = () => {
    // Global Store
    const {
        age, setAge,
        sex, setSex,
        opioidNaive, setOpioidNaive,
        homeBuprenorphine, setHomeBuprenorphine,

        renalFunction, setRenalFunction,
        hepaticFunction, setHepaticFunction,
        hemoStatus, setHemoStatus,
        painType, setPainType,
        indication, setIndication,
        routePreference, setRoutePreference,
        giStatus, setGiStatus,
        organSupport,

        sleepApnea, setSleepApnea,
        chf, setChf,
        copd, setCopd,
        benzos, setBenzos,
        psychHistory, setPsychHistory,

        prodigyScore,
        prodigyRisk
    } = useAssessmentStore();

    // Local Computed Logic for Recommendations
    // (We keep this in the view for now as it's purely derivation for display)
    const [recs, setRecs] = useState<any[]>([]);
    const [adjuvants, setAdjuvants] = useState<string[]>([]);
    const [warnings, setWarnings] = useState<string[]>([]);
    const [monitoringRecs, setMonitoringRecs] = useState<string[]>([]);

    useEffect(() => {
        // --- RESET OUTPUTS ---
        let r: any[] = [];
        let adj: string[] = [];
        let w: string[] = [];
        let monitors: string[] = [];

        // --- PRODIGY MONITORING (from Store Score) ---
        if (prodigyRisk === 'High') {
            monitors.push('⚠️ CONTINUOUS CAPNOGRAPHY + Pulse Oximetry REQUIRED.');
            monitors.push('Nursing assessment q1h x 6h, then q2h.');
        } else if (prodigyRisk === 'Intermediate') {
            monitors.push('Consider Continuous Capnography.');
            monitors.push('Nursing assessment q4h.');
        } else {
            monitors.push('Standard monitoring per protocol.');
        }

        if (benzos) {
            monitors.push('Warning: Concurrent Benzos increase overdose risk 3.8x.');
            if (prodigyRisk === 'Low' && prodigyScore < 8) {
                monitors.push('Risk elevated due to sedatives.');
            }
        }
        if (copd) {
            monitors.push('COPD: Increased retention risk. Target SpO2 88-92%?');
        }

        setMonitoringRecs(monitors);

        // --- CLINICAL LOGIC (Refined) ---
        const isRenalBad = renalFunction === 'dialysis' || renalFunction === 'impaired';
        const isHepaticBad = hepaticFunction === 'failure' || hepaticFunction === 'impaired';
        const isHepaticFailure = hepaticFunction === 'failure';

        // Helpers
        const addIVRecs = () => {
            if (isRenalBad) {
                r.push({ name: 'Fentanyl IV', reason: 'Preferred.', detail: 'Safest renal option (No metabolites).', type: 'safe' });
                r.push({ name: 'Hydromorphone IV', reason: 'Caution.', detail: 'Reduce dose 50%. Watch for H3G accumulation.', type: 'caution' });
            } else {
                r.push({ name: 'Morphine IV', reason: 'Standard.', detail: 'Ideal first-line.', type: 'safe' });
                r.push({ name: 'Hydromorphone IV', reason: 'Standard.', detail: 'Preferred in high tolerance.', type: 'safe' });
            }
        };

        const addPORecs = () => {
            if (isRenalBad) {
                if (!isHepaticFailure) {
                    r.push({ name: 'Oxycodone PO', reason: 'Caution.', detail: 'Reduce frequency. Monitor sedation.', type: 'caution' });
                }
                r.push({ name: 'Hydromorphone PO', reason: 'Caution.', detail: 'Reduce dose 50%.', type: 'caution' });
            } else {
                r.push({ name: 'Oxycodone PO', reason: 'Preferred.', detail: 'Superior bioavailability.', type: 'safe' });
                r.push({ name: 'Morphine PO', reason: 'Standard.', detail: 'Reliable if renal function normal.', type: 'safe' });
            }
        };

        // 1. HEMODYNAMICS (Override)
        if (hemoStatus === 'unstable') {
            r.push({ name: 'Fentanyl', reason: 'Preferred.', detail: 'Cardiostable; no histamine release.', type: 'safe' });
            w.push('Morphine: Histamine release precipitates vasodilation/hypotension.');
        }
        // 2. MAT / BUPRENORPHINE
        else if (homeBuprenorphine) {
            r.push({ name: 'Home Buprenorphine', reason: 'Maintenance.', detail: 'Continue basal to prevent withdrawal.', type: 'safe' });
            r.push({ name: 'Breakthrough Agonist', reason: 'Acute Pain.', detail: 'Add high-affinity agonist (Fentanyl/Dilaudid) on top of MAT.', type: 'safe' });

            if (isRenalBad) {
                r.push({ name: 'Buprenorphine (Safety)', reason: 'Renal Safe.', detail: 'No dose adjustment needed in dialysis.', type: 'safe' });
            }

            // Route Logic (Simpler for MAT breakthrough)
            if (routePreference === 'iv' || routePreference === 'both' || routePreference === 'either') addIVRecs();
            if (routePreference === 'po' || routePreference === 'both' || routePreference === 'either') addPORecs();
        }
        // 3. STANDARD LOGIC
        else if (renalFunction) {
            if (isRenalBad) {
                w.push('Avoid: Morphine, Codeine, Tramadol, Meperidine (Active metabolites/Seizure risk).');
                r.push({ name: 'Methadone', reason: 'Safe.', detail: 'Fecal excretion. Consult Pain Svc.', type: 'safe' });
            }

            if (routePreference === 'iv') addIVRecs();
            else if (routePreference === 'po') addPORecs();
            else if (routePreference === 'both' || routePreference === 'either') {
                addIVRecs();
                addPORecs();
                if (routePreference === 'either') adj.push('Route Preference: Determine based on GI tolerance.');
            } else {
                addIVRecs(); // Default
            }
        }

        // 4. HEPATIC SAFETY GATES (Strict Filters)
        if (hepaticFunction) {
            if (isHepaticFailure) {
                w.push('Liver Failure (Child-Pugh C): Avoid Methadone, Morphine, Codeine, and Oxycodone.');

                // FILTER OUT TOXIC MEDS
                const toxic = ['Morphine', 'Codeine', 'Methadone', 'Oxycodone'];
                r = r.filter(x => !toxic.some(t => x.name.includes(t)));

                // Ensure Fentanyl is visible if not already
                if (!r.some(x => x.name.includes('Fentanyl'))) {
                    r.unshift({ name: 'Fentanyl', reason: 'Preferred.', detail: 'Safest choice in liver failure.', type: 'safe' });
                }
                r = r.map(x => ({ ...x, detail: x.detail + ' Reduce dose 50%.' }));
            } else if (hepaticFunction === 'impaired') {
                r = r.map(x => ({ ...x, detail: x.detail + ' Reduce initial dose 50%.' }));
            }
        }

        // 5. GI / NPO Logic
        if (giStatus === 'npo') {
            if (routePreference === 'po' || routePreference === 'both' || routePreference === 'either') {
                const poNames = ['Oxycodone', 'Hydromorphone PO', 'Morphine PO'];
                if (routePreference === 'po') r = [];
                else r = r.filter(x => !poNames.some(n => x.name.includes(n)));
                w.push('PO Contraindicated: Patient is NPO. Switch to IV.');
            }
        }

        // 6. PAIN TYPE & ADJUVANTS (Context Aware)
        if (painType) {
            if (painType === 'neuropathic') {
                adj.push('Gabapentinoids: Gabapentin or Pregabalin.');
                if (!isHepaticBad) {
                    adj.push('SNRIs: Duloxetine (Cymbalta).');
                } else {
                    w.push('Avoid Duloxetine in Hepatic Impairment.');
                }
                adj.push('Topicals: Lidocaine 5% patch.');
            } else if (painType === 'inflammatory' || painType === 'bone') {
                // Renal Gate for NSAIDs
                if (!isRenalBad && !isHepaticBad) {
                    adj.push('NSAIDs: Naproxen or Celecoxib.');
                } else {
                    w.push('Avoid NSAIDs: Renal/Hepatic Impairment risk.');
                }

                if (painType === 'bone') {
                    adj.push('Corticosteroids: Dexamethasone (Periosteal pain).');
                    w.push('Bone Pain: Consider Radiation Oncology.');
                }

                // Acetaminophen Safety Check
                if (isHepaticFailure) {
                    adj.push('Acetaminophen: CAUTION. Max 2g/day strictly.');
                } else if (isHepaticBad) {
                    adj.push('Acetaminophen: Monitor LFTs. Max 3g/day.');
                } else {
                    adj.push('Acetaminophen: Scheduled foundation (Max 4g).');
                }
            } else if (painType === 'nociceptive') {
                adj.push('Acetaminophen / NSAIDs (if renal/liver safe).');
            }
        }

        // 7. CLINICAL INDICATIONS
        if (indication === 'dyspnea') {
            if (!r.some(x => x.name.includes('Morphine')) && !isRenalBad && !isHepaticFailure) {
                r.unshift({ name: 'Morphine IV', reason: 'Gold Standard.', detail: 'Air hunger.', type: 'safe' });
            }
            adj.push('Anxiety: Low-dose Lorazepam (0.5mg).');
        }

        // 8. General Risk
        if (sleepApnea) {
            w.push('OSA: Avoid basal infusions. Monitor SpO2/EtCO2.');
        }

        setRecs(r);
        setAdjuvants(adj);
        setWarnings(w);

    }, [renalFunction, hemoStatus, routePreference, giStatus, hepaticFunction, painType, indication, sleepApnea, psychHistory, age, sex, opioidNaive, chf, copd, benzos, homeBuprenorphine, prodigyScore, prodigyRisk]);

    const handleCopy = () => {
        const note = `
Opioid Risk Assessment
----------------------
PRODIGY Score: ${prodigyScore} (${prodigyRisk.toUpperCase()} RISK)
Monitoring Plan:
${monitoringRecs.map(m => `- ${m}`).join('\n')}

Risk Factors:
${sleepApnea ? '- Sleep Apnea (+5)' : ''}
${opioidNaive ? '- Opioid Naive (+3)' : ''}
${chf ? '- Chronic Heart Failure (+7)' : ''}
${sex === 'male' ? '- Male Sex (+8)' : ''}

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

                        <label className={`flex items-center justify-between p-3 rounded-xl border cursor-pointer transition-all ${opioidNaive ? 'bg-action-bg border-action-border/30' : 'bg-surface-card border-border'}`}>
                            <div>
                                <span className="text-xs font-bold text-text-primary block">Opioid Naive</span>
                                <span className="text-[10px] text-text-tertiary font-medium">No exposure last 7 days</span>
                            </div>
                            <input type="checkbox" checked={opioidNaive} onChange={e => setOpioidNaive(e.target.checked)} className="w-4 h-4 accent-action rounded" />
                        </label>

                        <label className={`flex items-center justify-between p-3 rounded-xl border cursor-pointer transition-all ${homeBuprenorphine ? 'bg-indigo-50 dark:bg-indigo-900/20 border-indigo-200' : 'bg-surface-card border-border'}`}>
                            <div>
                                <span className="text-xs font-bold text-text-primary block">Home Buprenorphine</span>
                                <span className="text-[10px] text-text-tertiary font-medium">Suboxone / Subutex (MAT)</span>
                            </div>
                            <input type="checkbox" checked={homeBuprenorphine} onChange={e => setHomeBuprenorphine(e.target.checked)} className="w-4 h-4 accent-indigo-500 rounded" />
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
                                <ParameterBtn active={hemoStatus === 'stable'} onClick={() => setHemoStatus('stable')} label="Hemodynamically Stable" />
                                <ParameterBtn active={hemoStatus === 'unstable'} onClick={() => setHemoStatus('unstable')} label="Shock / Hypotensive" sub="MAP < 65 or Pressors" />
                            </div>
                        </div>

                        {/* 2. Renal Function */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">2. Renal Function</label>
                            <div className="space-y-1">
                                <ParameterBtn active={renalFunction === 'normal'} onClick={() => setRenalFunction('normal')} label="Normal Function" sub="eGFR > 60" />
                                <ParameterBtn active={renalFunction === 'impaired'} onClick={() => setRenalFunction('impaired')} label="Impaired / CKD" sub="eGFR < 30" />
                                <ParameterBtn active={renalFunction === 'dialysis'} onClick={() => setRenalFunction('dialysis')} label="Dialysis Dependent" sub="HD / PD / CRRT" />
                            </div>
                        </div>

                        {/* 3. GI / AMS / Swallowing */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">3. GI / Mental Status</label>
                            <div className="space-y-1">
                                <ParameterBtn active={giStatus === 'intact'} onClick={() => setGiStatus('intact')} label="Intact / Alert" />
                                <ParameterBtn active={giStatus === 'tube'} onClick={() => setGiStatus('tube')} label="Tube / Dysphagia" sub="NGT / OGT / PEG" />
                                <ParameterBtn active={giStatus === 'npo'} onClick={() => setGiStatus('npo')} label="NPO / GI Failure / AMS" sub="Ileus / Unresponsive" />
                            </div>
                        </div>

                        {/* 4. Desired Route */}
                        <div className="space-y-1.5 bg-action-bg/5 px-2 py-3 rounded-xl border border-action-border/10">
                            <label className="text-[10px] font-bold text-action uppercase ml-1">4. Desired Route</label>
                            <div className="grid grid-cols-2 gap-2 mt-1">
                                <ParameterBtn active={routePreference === 'iv'} onClick={() => setRoutePreference('iv')} label="IV / SQ" />
                                <ParameterBtn active={routePreference === 'po'} onClick={() => setRoutePreference('po')} label="Oral (PO)" />
                                <ParameterBtn active={routePreference === 'both'} onClick={() => setRoutePreference('both')} label="Both" />
                                <ParameterBtn active={routePreference === 'either'} onClick={() => setRoutePreference('either')} label="Either" />
                            </div>
                        </div>

                        {/* 5. Hepatic Function */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-text-tertiary uppercase ml-1">5. Hepatic Function</label>
                            <div className="space-y-1">
                                <ParameterBtn active={hepaticFunction === 'normal'} onClick={() => setHepaticFunction('normal')} label="Normal Function" />
                                <ParameterBtn active={hepaticFunction === 'impaired'} onClick={() => setHepaticFunction('impaired')} label="Impaired / Cirrhosis" sub="Child-Pugh A/B" />
                                <ParameterBtn active={hepaticFunction === 'failure'} onClick={() => setHepaticFunction('failure')} label="Liver Failure" sub="Child-Pugh C" />
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
                                {(hepaticFunction === 'impaired' || hepaticFunction === 'failure' || (hepaticFunction === 'normal' && renalFunction === 'normal')) && (
                                    <p className="mt-0.5">• Avoid Tylenol {'>'} 4g daily (2g if liver failure).</p>
                                )}
                                {(renalFunction === 'impaired' || renalFunction === 'dialysis' || hepaticFunction === 'failure' || (hepaticFunction === 'normal' && renalFunction === 'normal')) && (
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
