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

        // 1. HEMODYNAMICS (Immediate Override)
        // If unstable, we recommend Fentanyl immediately, regardless of other states.
        if (hemo === 'unstable') {
            rReasons.push('Hemodynamic Instability');
            score = 'High';
            r.push({ name: 'Fentanyl', reason: 'Preferred.', detail: 'Cardiostable; no histamine release.', type: 'safe' });
            w.push('Morphine: Histamine release precipitates vasodilation/hypotension.');
        }

        // 2. STANDARD OPIOID SELECTION (Requires Renal & Hemo Status)
        // Only proceed with standard suggestions if we know renal status and we aren't already forced into Fentanyl-only by instability.
        if (renal && hemo !== 'unstable') {
            if (renal === 'dialysis' || renal === 'impaired') {
                rReasons.push('Renal Insufficiency');
                score = 'High';

                // Safe Options
                r.push({ name: 'Fentanyl', reason: 'Safe (no active metabolites).', detail: 'Watch context-sensitive t1/2 in ICU infusions.', type: 'safe' });
                r.push({ name: 'Methadone', reason: 'Safe (fecal excretion).', detail: 'Use low dose; monitor QTc and day 3-5 accumulation.', type: 'safe' });

                // Cautious Options (Only if Route is known or default to IV warnings)
                if (route === 'po') {
                    r.push({ name: 'Hydromorphone PO', reason: 'Use with caution.', detail: 'Reduce dose 50%. Monitor for allodynia (H3G).', type: 'caution' });
                    r.push({ name: 'Oxycodone', reason: 'Use with caution.', detail: 'Reduce frequency. Monitor sedation.', type: 'caution' });
                } else if (route === 'iv' || !route) { // Default to IV assumptions if route unknown but renal implies strictness
                    r.push({ name: 'Hydromorphone IV', reason: 'Caution.', detail: 'Reduce dose. Dialyzable, but H3G neurotoxicity is real.', type: 'caution' });
                }
                w.push('Morphine Contraindicated: M6G/M3G accumulation causes coma and myoclonus.');

            } else {
                // Normal Renal Function
                if (route === 'po') {
                    r.push({ name: 'Oxycodone', reason: 'Preferred.', detail: 'Superior bioavailability to Morphine/Dilaudid PO.', type: 'safe' });
                } else {
                    // IV or Route Unknown (standard defaults)
                    r.push({ name: 'Morphine', reason: 'Standard.', detail: 'Ideal unless hypotension present.', type: 'safe' });
                    r.push({ name: 'Hydromorphone', reason: 'Standard.', detail: 'Preferred in high tolerance.', type: 'safe' });
                }
            }
        }

        // 3. HEPATIC SAFETY GATES
        // Can apply to existing recommendations
        if (hepatic) {
            if (hepatic === 'failure') {
                rReasons.push('Hepatic Failure');
                score = 'High';
                w.push('Liver Failure (Child-Pugh C): Avoid Methadone (accumulation) and Morphine/Codeine (prodrug failure).');

                // Filter unsafe
                r = r.filter(x => x.name !== 'Methadone' && !x.name.includes('Morphine'));

                // Ensure Fentanyl is present if not already
                if (!r.find(x => x.name === 'Fentanyl')) {
                    r.unshift({ name: 'Fentanyl', reason: 'Preferred.', detail: 'Safest option in failures (no active metabolites).', type: 'safe' });
                }
                r = r.map(x => ({ ...x, detail: x.detail + ' Reduce initial dose 50% and extend interval.' }));

            } else if (hepatic === 'impaired') {
                rReasons.push('Hepatic Impairment');
                if (score !== 'High') score = 'Moderate';
                r = r.map(x => ({ ...x, detail: x.detail + ' Reduce initial dose 50%.' }));
            }
        }

        // 4. GI / NPO Logic
        if (gi === 'npo') {
            if (route === 'po') {
                r = []; // Clear PO recs
                w.push('PO Contraindicated: Patient is NPO / AMS. Switch to IV or Patch.');
            }
        } else if (gi === 'tube') {
            if (route === 'po') {
                w.push('DO NOT CRUSH Extended Release (ER/LA) formulations. Fatal dose dumping risk.');
                r = r.map(x => ({ ...x, detail: x.detail + ' Use liquid formulation.' }));
            }
        }

        // 5. PAIN TYPE ADJUVANTS (Can appear independently)
        if (painType) {
            if (painType === 'neuropathic') {
                // Modify existing opioids if Methadone present
                const methadone = r.find(x => x.name === 'Methadone');
                if (methadone) {
                    r = r.filter(x => x.name !== 'Methadone');
                    r.unshift({ ...methadone, type: 'safe', reason: 'Preferred.', detail: 'NMDA antagonism treats neuropathic component. Monitor QTc.' });
                }
                // Add specific adjuvants
                adj.push('Gabapentinoids: Gabapentin (start 100-300mg TID) or Pregabalin (Lyrica) 25-75mg BID.');
                adj.push('Antidepressants: Duloxetine (Cymbalta) 30mg daily or Nortriptyline/Amitriptyline 10mg qHS.');
                adj.push('Topicals: Lidocaine 5% patch or Capsaicin (if localized).');
            } else if (painType === 'inflammatory') {
                adj.push('NSAIDs: Naproxen 500mg BID or Celecoxib 100-200mg BID (if GI risk).');
                adj.push('Acetaminophen: 650-1000mg q6h (Max 3-4g/day).');
                adj.push('Corticosteroids: Dexamethasone 4mg daily (consider for acute inflammatory flares).');
            } else if (painType === 'bone') {
                adj.push('NSAIDs: Ketorolac (short term) or Naproxen (standard for PGE2-mediated bone pain).');
                adj.push('Corticosteroids: Dexamethasone 4-8mg daily (superior for stretching of periosteum).');
                adj.push('Bone-Targeted: Bisphosphonates (Zoledronic acid) or Denosumab.');
                w.push('Bone Pain: Consider palliative radiation or orthopedic consult for pathologic fracture risk.');
            } else if (painType === 'nociceptive') {
                adj.push('Acetaminophen: 650-1000mg q6h scheduled.');
                adj.push('NSAIDs: Ibuprofen 400-600mg q6h (if renal function allows).');
            }
        }

        // 6. CLINICAL SCENARIO CONTEXT
        if (indication) {
            if (indication === 'cancer_pain') {
                w.push('Cancer Pain: Utilize short-acting opioids for initiation per NCCN/ASCO guidelines.');
                // Escalation logic
                w.push('Palliative Crisis: If severe/uncontrolled, consider rapid titration (IV/SQ) +50-100% q15min.');
                if (painType === 'bone') {
                    adj.push('Bone Pain: NSAIDs / Acetaminophen are effective adjuvants.');
                    adj.push('Metabolic warning: Monitor for Hypercalcemia of Malignancy.');
                }
                if (painType === 'neuropathic') {
                    adj.push('Neuropathic Adjuvants (NCCN): SNRIs (Duloxetine), TCAs (Nortriptyline), or Gabapentinoids.');
                }
            } else if (indication === 'dyspnea') {
                const hasMorphine = r.find(x => x.name === 'Morphine' || x.name === 'Morphine PO');
                // Only suggest morphine specifically for dyspnea if we know it's safe (renal)
                if (renal === 'normal' && !hasMorphine) {
                    r.unshift({
                        name: route === 'po' ? 'Morphine PO' : 'Morphine',
                        reason: 'Gold Standard.',
                        detail: 'Strongest evidence for reducing air hunger (ATS).',
                        type: 'safe'
                    });
                } else if (renal && renal !== 'normal') {
                    // Only warn if we actually know renal is bad
                    w.push('Dyspnea: Morphine preferred but unsafe in renal failure. Consider Fentanyl/Hydromorphone.');
                }
                adj.push('Anxiety (associated with Dyspnea): Benzodiazepines (Lorazepam 0.5-1mg) may be added if anxiety is prominent.');
            } else if (indication === 'standard') {
                // Opioid Context
                r = r.map(x => {
                    if (['Morphine', 'Oxycodone', 'Hydromorphone'].some(d => x.name.includes(d))) {
                        return { ...x, detail: x.detail + ' Reserve for severe pain; use short-acting formulations.' };
                    }
                    return x;
                });

                // Burn Pain Context (Inflammatory + Acute)
                if (painType === 'inflammatory') {
                    adj.push('Burn Pain (ABA): Multimodal approach critical. Acetaminophen + NSAIDs foundation. Determine if procedural.');
                }
            }
        }

        // 7. General Risk Factors
        if (sleepApnea) {
            rReasons.push('Sleep Apnea (OSA)');
            score = score === 'High' ? 'High' : 'Moderate';
            w.push('OSA Risk: Continuous pulse oximetry recommended. Avoid basal infusions.');
        }
        if (psychHistory) {
            rReasons.push('Substance/Psych History');
            score = 'High';
            w.push('High Risk: Consult Addiction Med / Check PDMP. Strict pill counts strictly.');
        }
        if (naive) {
            w.push('Opioid Naive: Start low and titrate. PRODIGY: +5 points for Naivety.');
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
Prob. Resp Depression: ${prodigyScore >= 21 ? '>20%' : prodigyScore >= 10 ? '11-20%' : '<10%'}

Monitoring Plan:
${monitoringRecs.map(m => `- ${m}`).join('\n')}

Risk Factors:
${sleepApnea ? '- Sleep Apnea (+4)' : ''}
${naive ? '- Opioid Naive (+5)' : ''}
${chf ? '- Chronic Heart Failure (+3)' : ''}
${sex === 'male' ? '- Male Sex (+3)' : ''}
${parseInt(age) >= 60 ? '- Age > 60 (+2-6)' : ''}
${benzos ? '- Concurrent Benzodiazepines' : ''}

Clinical Recommendations:
${recs.map(r => `- ${r.name}: ${r.reason} (${r.detail})`).join('\n')}
${adjuvants.length > 0 ? '\nAdjuvants:\n' + adjuvants.map(a => `- ${a}`).join('\n') : ''}
${warnings.length > 0 ? '\nWarnings:\n' + warnings.map(w => `- ${w}`).join('\n') : ''}
    `.trim(); // Clean up empty lines
        navigator.clipboard.writeText(note);
    };

    return (
        <div className="flex flex-col lg:flex-row gap-4 h-auto lg:h-full p-4 md:p-0">
            {/* Left Pane: Patient Profile */}
            <div className="lg:w-1/3 flex-none space-y-3 lg:overflow-y-auto pr-2 custom-scrollbar">
                <h2 className="text-lg font-bold text-slate-800 mb-2 px-1">Case Parameters</h2>
                <div className="space-y-3">

                    {/* Demographics & PRODIGY */}
                    <div className="bg-slate-50 p-3 rounded-lg border border-slate-200 space-y-3">
                        <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider flex items-center gap-2">
                            <Users className="w-4 h-4" /> Patient Demographics
                        </h3>

                        <div className="flex gap-3">
                            <div className="flex-1">
                                <label className="block text-xs font-bold text-slate-400 uppercase mb-1">Age</label>
                                <input
                                    type="number"
                                    placeholder="Yrs"
                                    value={age}
                                    onChange={(e) => setAge(e.target.value)}
                                    className="w-full px-3 py-1.5 rounded-sm border border-slate-200 text-sm font-bold text-slate-700 outline-none focus:border-teal-500"
                                />
                            </div>
                            <div className="flex-1">
                                <label className="block text-xs font-bold text-slate-400 uppercase mb-1">Sex</label>
                                <div className="flex bg-white rounded-sm border border-slate-200 overflow-hidden">
                                    <button onClick={() => setSex('male')} className={`flex-1 py-1.5 text-xs font-bold ${sex === 'male' ? 'bg-teal-50 text-teal-700' : 'text-slate-400 hover:bg-slate-50'}`}>M</button>
                                    <div className="w-px bg-slate-200"></div>
                                    <button onClick={() => setSex('female')} className={`flex-1 py-1.5 text-xs font-bold ${sex === 'female' ? 'bg-teal-50 text-teal-700' : 'text-slate-400 hover:bg-slate-50'}`}>F</button>
                                </div>
                            </div>
                        </div>

                        <label className={`flex items-center justify-between p-2 rounded-sm border cursor-pointer transition-colors ${naive ? 'bg-teal-50 border-teal-200' : 'bg-white border-slate-200'}`}>
                            <div>
                                <span className="text-xs font-bold text-slate-700 block">Opioid Naive</span>
                                <span className="text-[10px] text-slate-400 font-medium">No exposure last 7 days</span>
                            </div>
                            <input type="checkbox" checked={naive} onChange={e => setNaive(e.target.checked)} className="w-4 h-4 accent-teal-600 rounded" />
                        </label>
                    </div>

                    {/* Risk Factors Section */}
                    <div className="bg-rose-50/50 p-3 rounded-lg border border-rose-100 space-y-2">
                        <h3 className="text-xs font-bold text-rose-500 uppercase tracking-wider flex items-center gap-2">
                            <ShieldAlert className="w-4 h-4" /> PRODIGY & Safety
                        </h3>

                        <div className="grid grid-cols-1 gap-1.5">
                            <label className="flex items-center gap-2 p-1.5 bg-white rounded border border-slate-200 cursor-pointer">
                                <input type="checkbox" checked={sleepApnea} onChange={e => setSleepApnea(e.target.checked)} className="w-3.5 h-3.5 accent-rose-500" />
                                <span className="text-[11px] font-bold text-slate-600">Sleep Apnea (OSA/CSA)</span>
                            </label>
                            <label className="flex items-center gap-2 p-1.5 bg-white rounded border border-slate-200 cursor-pointer">
                                <input type="checkbox" checked={chf} onChange={e => setChf(e.target.checked)} className="w-3.5 h-3.5 accent-rose-500" />
                                <span className="text-[11px] font-bold text-slate-600">Chronic Heart Failure</span>
                            </label>
                            <label className="flex items-center gap-2 p-1.5 bg-white rounded border border-slate-200 cursor-pointer">
                                <input type="checkbox" checked={benzos} onChange={e => setBenzos(e.target.checked)} className="w-3.5 h-3.5 accent-rose-500" />
                                <span className="text-[11px] font-bold text-slate-600">Benzos / Sedatives</span>
                            </label>
                            <label className="flex items-center gap-2 p-1.5 bg-white rounded border border-slate-200 cursor-pointer">
                                <input type="checkbox" checked={copd} onChange={e => setCopd(e.target.checked)} className="w-3.5 h-3.5 accent-rose-500" />
                                <span className="text-[11px] font-bold text-slate-600">COPD / Lung Disease</span>
                            </label>
                            <label className="flex items-center gap-2 p-1.5 bg-white rounded border border-slate-200 cursor-pointer">
                                <input type="checkbox" checked={psychHistory} onChange={e => setPsychHistory(e.target.checked)} className="w-3.5 h-3.5 accent-rose-500" />
                                <span className="text-[11px] font-bold text-slate-600">Substance / Psych Hx</span>
                            </label>
                        </div>
                    </div>

                    <div className="space-y-3 pt-1">
                        {/* 1. Hemodynamics */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-slate-400 uppercase ml-1">1. Hemodynamics</label>
                            <div className="space-y-1">
                                <ParameterBtn active={hemo === 'stable'} onClick={() => setHemo('stable')} label="Hemodynamically Stable" />
                                <ParameterBtn active={hemo === 'unstable'} onClick={() => setHemo('unstable')} label="Shock / Hypotensive" sub="MAP < 65 or Pressors" />
                            </div>
                        </div>

                        {/* 2. Renal Function */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-slate-400 uppercase ml-1">2. Renal Function</label>
                            <div className="space-y-1">
                                <ParameterBtn active={renal === 'normal'} onClick={() => setRenal('normal')} label="Normal Function" sub="eGFR > 60" />
                                <ParameterBtn active={renal === 'impaired'} onClick={() => setRenal('impaired')} label="Impaired / CKD" sub="eGFR < 30" />
                                <ParameterBtn active={renal === 'dialysis'} onClick={() => setRenal('dialysis')} label="Dialysis Dependent" sub="HD / PD / CRRT" />
                            </div>
                        </div>

                        {/* 3. GI / AMS / Swallowing */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-slate-400 uppercase ml-1">3. GI / Mental Status</label>
                            <div className="space-y-1">
                                <ParameterBtn active={gi === 'intact'} onClick={() => setGi('intact')} label="Intact / Alert" />
                                <ParameterBtn active={gi === 'tube'} onClick={() => setGi('tube')} label="Tube / Dysphagia" sub="NGT / OGT / PEG" />
                                <ParameterBtn active={gi === 'npo'} onClick={() => setGi('npo')} label="NPO / GI Failure / AMS" sub="Ileus / Unresponsive" />
                            </div>
                        </div>

                        {/* 4. Hepatic Function */}
                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-slate-400 uppercase ml-1">4. Hepatic Function</label>
                            <div className="space-y-1">
                                <ParameterBtn active={hepatic === 'normal'} onClick={() => setHepatic('normal')} label="Normal Function" />
                                <ParameterBtn active={hepatic === 'impaired'} onClick={() => setHepatic('impaired')} label="Impaired / Cirrhosis" sub="Child-Pugh A/B" />
                                <ParameterBtn active={hepatic === 'failure'} onClick={() => setHepatic('failure')} label="Liver Failure" sub="Child-Pugh C" />
                            </div>
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-slate-400 uppercase ml-1">Clinical Scenario</label>
                            <div className="space-y-1">
                                <ParameterBtn active={indication === 'standard'} onClick={() => setIndication('standard')} label="General / Acute Pain" sub="Post-Op / Trauma / Medical" />
                                <ParameterBtn active={indication === 'dyspnea'} onClick={() => setIndication('dyspnea')} label="Palliative Dyspnea" sub="End of Life / Air Hunger" />
                                <ParameterBtn active={indication === 'cancer_pain'} onClick={() => setIndication('cancer_pain')} label="Cancer Pain" sub="Active Malignancy / Metastatic" />
                            </div>
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-slate-400 uppercase ml-1">Dominant Pathophysiology</label>
                            <div className="space-y-1">
                                <ParameterBtn active={painType === 'nociceptive'} onClick={() => setPainType('nociceptive')} label="Nociceptive (Tissue)" sub="Somatic / Visceral" />
                                <ParameterBtn active={painType === 'neuropathic'} onClick={() => setPainType('neuropathic')} label="Neuropathic (Nerve)" sub="Radiculopathy / Spinal Cord" />
                                <ParameterBtn active={painType === 'inflammatory'} onClick={() => setPainType('inflammatory')} label="Inflammatory" sub="Autoimmune / Infection / Abscess" />
                                <ParameterBtn active={painType === 'bone'} onClick={() => setPainType('bone')} label="Bone Pain" sub="Metastatic / Periosteal" />
                            </div>
                        </div>

                        <div className="space-y-1.5">
                            <label className="text-[10px] font-bold text-slate-400 uppercase ml-1">Route of Admin</label>
                            <div className="grid grid-cols-2 gap-2">
                                <ParameterBtn active={route === 'iv'} onClick={() => setRoute('iv')} label="IV / SQ" />
                                <ParameterBtn active={route === 'po'} onClick={() => setRoute('po')} label="Oral (PO)" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            {/* Right Pane: Guidance */}
            <div className="lg:flex-1 h-auto lg:h-full min-h-[400px] bg-slate-50 rounded-lg border border-slate-200 p-4 flex flex-col">
                {recs.length > 0 ? (
                    <div className="space-y-4 animate-in fade-in slide-in-from-bottom-2 flex-1 flex flex-col h-auto lg:h-full lg:overflow-hidden">

                        {/* Static Advisory - Always Visible */}
                        <div className="bg-blue-50/50 border border-blue-100 p-2.5 rounded-sm flex items-start gap-3 shrink-0">
                            <Activity className="w-4 h-4 text-blue-500 mt-0.5" />
                            <div className="text-xs text-blue-900 leading-relaxed font-medium">
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
                            <div className="bg-white rounded-sm border border-slate-200 shadow-sm overflow-hidden mb-2">
                                <div className="p-3 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                                    <div className="flex items-center gap-2">
                                        <Activity className="w-5 h-5 text-indigo-600" />
                                        <div>
                                            <h3 className="text-xs font-bold text-indigo-900 uppercase tracking-wide">PRODIGY Risk Score</h3>
                                            <p className="text-[10px] text-slate-500 font-medium">Respiratory Depression Prediction</p>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <div className="text-2xl font-black text-indigo-600 leading-none">{prodigyScore}</div>
                                        <div className={`text-[10px] font-bold uppercase px-1.5 py-0.5 rounded ${prodigyRisk === 'High' ? 'bg-rose-100 text-rose-700' :
                                            prodigyRisk === 'Intermediate' ? 'bg-amber-100 text-amber-700' :
                                                'bg-emerald-100 text-emerald-700'
                                            }`}>{prodigyRisk} Risk</div>
                                    </div>
                                </div>

                                {/* Monitoring Plan */}
                                <div className={`p-3 ${prodigyRisk === 'High' ? 'bg-rose-50' : prodigyRisk === 'Intermediate' ? 'bg-amber-50' : 'bg-slate-50'}`}>
                                    <h4 className={`text-xs font-bold uppercase mb-2 flex items-center gap-2 ${prodigyRisk === 'High' ? 'text-rose-700' :
                                        prodigyRisk === 'Intermediate' ? 'text-amber-700' :
                                            'text-slate-500'
                                        }`}>
                                        <HeartPulse className="w-4 h-4" /> Monitoring Strategy
                                    </h4>
                                    <ul className="space-y-1 mb-2">
                                        {monitoringRecs.map((m, i) => (
                                            <li key={i} className="text-xs font-medium text-slate-700 flex items-start gap-2">
                                                <span className="mt-1 w-1 h-1 rounded-full bg-slate-400 flex-none" />
                                                {m}
                                            </li>
                                        ))}
                                    </ul>

                                    {/* Temporal Alert */}
                                    <div className="bg-white/60 rounded border border-black/5 p-2 flex gap-3 items-center">
                                        <Timer className="w-4 h-4 text-slate-400 flex-none" />
                                        <div className="text-[10px] text-slate-600 leading-tight">
                                            <strong>Peak Risk:</strong> 14:00-20:00 (Day 0) & 02:00-06:00 (Night).
                                            Median onset 8.8h post-op. 46% of PRODIGY patients had an event.
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div className="flex items-center justify-between mt-2">
                                <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider flex items-center gap-2">
                                    <Beaker className="w-4 h-4" /> Clinical Recommendations
                                </h3>
                                <button
                                    onClick={handleCopy}
                                    className="flex items-center gap-2 px-3 py-1.5 bg-slate-100 hover:bg-slate-200 text-slate-600 rounded-md transition-colors text-[10px] font-bold"
                                >
                                    <Copy className="w-3 h-3" />
                                    Smart Copy
                                </button>
                            </div>

                            <div className="space-y-3 lg:overflow-y-auto custom-scrollbar flex-1 pr-1">
                                {recs.map((rec, i) => (
                                    <div key={i} className="bg-white p-3 rounded-sm shadow-sm border border-slate-100 hover:shadow-md transition-shadow">
                                        <div className="flex justify-between items-start mb-1.5">
                                            <div className="flex items-center gap-2">
                                                {rec.type === 'safe'
                                                    ? <div className="p-1 rounded-full bg-emerald-100 text-emerald-600"><Activity className="w-4 h-4" /></div>
                                                    : <div className="p-1 rounded-full bg-amber-100 text-amber-600"><AlertTriangle className="w-4 h-4" /></div>
                                                }
                                                <span className="font-bold text-slate-800 text-base">{rec.name}</span>
                                            </div>
                                            <Badge type={rec.type} text={rec.type === 'safe' ? 'Preferred' : 'Monitor'} />
                                        </div>
                                        <p className="text-slate-600 text-xs font-medium mb-1">{rec.reason}</p>
                                        <p className="text-[10px] text-slate-500 bg-slate-50 p-1.5 rounded border border-slate-100 inline-block leading-relaxed">{rec.detail}</p>
                                    </div>
                                ))}

                                {adjuvants.length > 0 && (
                                    <div className="mt-4 space-y-2">
                                        <h3 className="text-xs font-bold text-teal-600 uppercase tracking-wider flex items-center gap-2">
                                            <CheckCircle2 className="w-4 h-4" /> Suggested Adjuvants
                                        </h3>
                                        {adjuvants.map((adj, i) => (
                                            <div key={i} className="bg-teal-50/50 p-2.5 rounded-sm border border-teal-100 text-xs text-teal-900 leading-relaxed font-medium">
                                                {adj}
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>

                            {/* Close Scrollable Container */}
                        </div>

                        {warnings.length > 0 && (
                            <div className="mt-auto">
                                <h3 className="text-xs font-bold text-rose-500 uppercase tracking-wider mb-2 flex items-center gap-2">
                                    <ShieldAlert className="w-4 h-4" /> Contraindications
                                </h3>
                                <div className="bg-rose-50 border border-rose-100 rounded-sm p-3">
                                    <ul className="space-y-1.5">
                                        {warnings.map((w, i) => (
                                            <li key={i} className="flex items-start gap-2 text-xs text-rose-800 font-medium">
                                                <span className="block w-1.5 h-1.5 mt-1 rounded-full bg-rose-400 flex-none" />
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
        </div >
    );
};
