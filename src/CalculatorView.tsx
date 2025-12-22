import React, { useState } from 'react';
import {
    Activity,
    Calculator,
    Info,
    ShieldAlert,
    Zap
} from 'lucide-react';
import { ClinicalCard } from './Shared';

export const CalculatorView = () => {
    const [ivMorphine, setIvMorphine] = useState<string | number>(10);
    const [reduction, setReduction] = useState(30);
    const [showInfusion, setShowInfusion] = useState(false);
    const [infusionRate, setInfusionRate] = useState<string | number>(0);
    const [showSafetyCheck, setShowSafetyCheck] = useState(false);
    const [pendingDrug, setPendingDrug] = useState<string | null>(null);

    const convert = (factor: number) => {
        const val = typeof ivMorphine === 'string' ? parseFloat(ivMorphine) || 0 : ivMorphine;
        const raw = val * factor;
        const reduced = raw * (1 - (reduction / 100));
        // Breakthrough = 10-15% of REDUCED total daily dose. Using ~12.5% (1/8th) or range.
        // NCCN suggests 10-20%. Let's display 10%.
        const btd = reduced * 0.10;
        return {
            raw: raw.toFixed(1),
            reduced: reduced.toFixed(1),
            btd: btd.toFixed(1)
        };
    };

    const handleInfusionCalc = (val: string) => {
        setInfusionRate(val);
        const rate = parseFloat(val) || 0;
        setIvMorphine(rate * 24);
    };

    React.useEffect(() => {
        const timeoutId = setTimeout(() => {
            const { trackEvent } = require('./analytics');
            trackEvent('calculation_updated', {
                iv_morphine_dose: ivMorphine,
                reduction_percentage: reduction
            });
        }, 1000); // Debounce for 1 second

        return () => clearTimeout(timeoutId);
    }, [ivMorphine, reduction]);

    return (
        <div className="grid lg:grid-cols-2 gap-8 max-w-4xl mx-auto p-4 md:p-0">
            <div className="lg:col-span-2 bg-surface-highlight border border-border rounded-2xl p-4 flex gap-4 items-start shadow-sm">
                <div className="p-2 bg-white text-action rounded-lg flex-none border border-border/50">
                    <Info className="w-5 h-5" />
                </div>
                <div>
                    <h3 className="text-sm font-bold text-text-primary mb-1">Safety First: 24-Hour Totals</h3>
                    <p className="text-sm text-text-secondary leading-relaxed">
                        Calculations must be based on the <strong>TOTAL 24-Hour Opioid Exposure</strong> (Scheduled + Breakthrough).
                        Do not use single doses or hourly rates directly.
                        <span className="block mt-1.5 font-bold text-danger">
                            ⚠️ Do NOT use this for patients who are not currently taking opioids (opioid-naive).
                        </span>
                    </p>
                </div>
            </div>
            {/* Input Side */}
            <div className="space-y-6">
                <ClinicalCard title="Input Dose">
                    <div className="flex items-center justify-between mb-2">
                        <div>
                            <span className="block text-2xl font-bold text-text-primary">Total 24-Hour Dose</span>
                            <span className="text-xs text-text-tertiary font-medium uppercase tracking-wide">Morphine IV Equivalents</span>
                        </div>
                        <div className="flex items-baseline gap-1 relative">
                            <input
                                type="number"
                                value={ivMorphine}
                                onChange={(e) => setIvMorphine(e.target.value)}
                                className="w-28 text-4xl font-bold text-right text-action border-b-2 border-border focus:border-action outline-none bg-transparent pb-1"
                            />
                            <span className="text-sm font-bold text-text-tertiary absolute -right-6 bottom-2">mg/24h</span>
                        </div>
                    </div>

                    <div className="mb-6 flex justify-between items-start">
                        <p className="text-[10px] text-text-tertiary italic max-w-[60%]">
                            *Include all scheduled doses AND breakthrough doses administered in the last 24 hours.
                        </p>
                        <button
                            onClick={() => setShowInfusion(!showInfusion)}
                            className="text-[10px] font-bold text-action bg-action-bg px-2 py-1 rounded border border-action-border/30 hover:bg-action-bg/80 transition-colors"
                        >
                            {showInfusion ? 'Close Helper' : 'Infusion Helper'}
                        </button>
                    </div>

                    {showInfusion && (
                        <div className="mb-6 bg-surface-card p-3 rounded-lg border border-border animate-in slide-in-from-top-2">
                            <div className="flex items-center gap-4">
                                <span className="text-xs font-bold text-text-secondary uppercase">Hourly Rate:</span>
                                <div className="flex items-baseline gap-1">
                                    <input
                                        type="number"
                                        value={infusionRate}
                                        onChange={(e) => handleInfusionCalc(e.target.value)}
                                        className="w-16 p-1 text-right font-bold text-text-primary border-b border-border bg-transparent focus:outline-none focus:border-action"
                                    />
                                    <span className="text-xs text-text-tertiary">mg/hr</span>
                                </div>
                                <span className="text-xs font-bold text-text-secondary">× 24h =</span>
                                <span className="text-sm font-bold text-action">{(parseFloat(infusionRate as string) || 0) * 24} mg/day</span>
                            </div>
                        </div>
                    )}

                    <div className="bg-surface-highlight p-4 rounded-lg border border-border">
                        <div className="flex justify-between items-center mb-3">
                            <span className="text-xs font-bold text-text-secondary uppercase">Cross-Tolerance Reduction</span>
                            <div className="min-w-[3.5rem] text-center px-2 py-0.5 rounded bg-surface-card border border-border shadow-sm">
                                <span className={`text-xs font-extrabold ${reduction < 30 ? 'text-danger' : reduction > 40 ? 'text-warning' : 'text-action'}`}>
                                    -{reduction}%
                                </span>
                            </div>
                        </div>

                        {/* Presets */}
                        <div className="mb-4">
                            <div className="flex justify-between gap-2 mb-4">
                                {[
                                    { val: 0, label: '0%', sub: 'Aggressive' },
                                    { val: 30, label: '30%', sub: 'Standard' },
                                    { val: 50, label: '50%', sub: 'Conservative' }
                                ].map((opt) => (
                                    <button
                                        key={opt.val}
                                        onClick={() => setReduction(opt.val)}
                                        className={`flex-1 py-2 px-1 rounded-lg border transition-all flex flex-col items-center justify-center ${reduction === opt.val
                                            ? 'bg-action-bg border-action-border text-action ring-1 ring-action-border'
                                            : 'bg-surface-card border-border text-text-tertiary hover:border-text-tertiary/50 hover:bg-surface-highlight'
                                            }`}
                                    >
                                        <span className="text-sm font-bold">{opt.label}</span>
                                        <span className="text-[9px] uppercase tracking-wide font-medium opacity-80">{opt.sub}</span>
                                    </button>
                                ))}
                            </div>

                            <div className="px-1">
                                <input
                                    type="range"
                                    min="0"
                                    max="75"
                                    step="5"
                                    value={reduction}
                                    onChange={(e) => setReduction(parseInt(e.target.value))}
                                    className="w-full h-2 bg-surface-card rounded-lg appearance-none cursor-pointer accent-action"
                                />
                                <div className="flex justify-between mt-2 text-[10px] font-medium text-text-tertiary">
                                    <span>Custom: -{reduction}%</span>
                                    <span>(Range: 0-75%)</span>
                                </div>
                            </div>
                        </div>

                        <div className="text-[11px] leading-relaxed text-text-secondary bg-surface-card p-3 rounded-lg border border-border flex gap-3">
                            <div className="mt-0.5 min-w-[16px]">
                                {reduction < 25 ? <Zap className="w-4 h-4 text-danger" /> :
                                    reduction > 40 ? <ShieldAlert className="w-4 h-4 text-warning" /> :
                                        <Activity className="w-4 h-4 text-action" />}
                            </div>
                            <div>
                                <strong className="block text-text-primary mb-1">
                                    {reduction < 25 && "Inadequate Analgesia (10-25%)"}
                                    {reduction >= 25 && reduction <= 40 && "Standard / Reason for Rotation (25-40%)"}
                                    {reduction > 40 && "Severe Adverse Effects (>40%)"}
                                </strong>
                                <span>
                                    {reduction < 25 && "Pain is uncontrolled. Lower reduction maintains higher potency."}
                                    {reduction >= 25 && reduction <= 40 && "Routine rotation or standard safety margin (2025 Consensus)."}
                                    {reduction > 40 && "Patient experiencing sedation/delirium. Requires significant dose reduction. Mandatory for elderly/frail."}
                                </span>
                            </div>
                        </div>
                    </div>
                </ClinicalCard>

                <div className="bg-action-bg p-4 rounded-lg border border-action-border/30 flex gap-3 text-action">
                    <Info className="w-5 h-5 flex-none" />
                    <p className="text-xs leading-relaxed">
                        <strong>Clinical Note:</strong> Calculator uses equianalgesic ratios from NCCN Guidelines.
                        Always use clinical judgment and start lower in elderly/frail patients.
                        <strong> Methadone conversions are non-linear; consult Pain/Pall Care expert.</strong>
                    </p>
                </div>

            </div>

            {/* Output Side */}
            <div className="space-y-6">
                <div>
                    <h3 className="text-sm font-bold text-text-primary mb-4 flex items-center gap-2">
                        <Calculator className="w-4 h-4 text-action" />
                        Estimated 24-Hour Target Doses
                    </h3>
                    <h3 className="text-xs font-bold text-text-tertiary uppercase mb-3 ml-1">Parenteral Targets (IV/SQ)</h3>
                    <div className="space-y-2">
                        <ClinicalCard className="flex justify-between items-center p-4">
                            <div>
                                <div className="font-bold text-text-primary">Hydromorphone IV</div>
                                <div className="text-[10px] text-text-tertiary">Ratio 1:6.7</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-action">{convert(0.15).reduced}<small className="text-xs text-text-tertiary ml-1">mg/24h</small></div>
                                <div className="text-[9px] font-medium text-action bg-action-bg px-1.5 py-0.5 rounded inline-block mt-1">
                                    BT: {convert(0.15).btd} mg q2-4h
                                </div>
                                <div className="text-[10px] text-text-tertiary strikethrough decoration-text-tertiary/50 opacity-60 mt-1">{convert(0.15).raw} raw</div>
                            </div>
                        </ClinicalCard>
                        <ClinicalCard className="flex justify-between items-center p-4">
                            <div>
                                <div className="font-bold text-text-primary">Fentanyl IV</div>
                                <div className="text-[10px] text-text-tertiary font-medium">10mg Mor : 100mcg Fent</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-action">{convert(10).reduced}<small className="text-xs text-text-tertiary ml-1">mcg/24h</small></div>
                                <div className="text-[9px] font-medium text-action bg-action-bg px-1.5 py-0.5 rounded inline-block mt-1">
                                    BT: {convert(10).btd} mcg q1-2h
                                </div>
                            </div>
                        </ClinicalCard>
                    </div>
                </div>

                <div>
                    <div className="flex justify-between items-end mb-3 ml-1">
                        <h3 className="text-xs font-bold text-text-tertiary uppercase">Enteral Targets (PO)</h3>
                        <div className="text-[10px] font-bold text-text-secondary bg-surface-highlight px-2 py-0.5 rounded border border-border">
                            PO Mor Equiv: {convert(3).reduced}mg
                        </div>
                    </div>
                    <div className="space-y-2">
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-action">
                            <div>
                                <div className="font-bold text-text-primary">Oxycodone PO</div>
                                <div className="text-[10px] text-action font-medium">OME Ratio 1:1.5</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-text-primary">{convert(2.0).reduced}<small className="text-xs text-text-tertiary ml-1">mg/24h</small></div>
                                <div className="text-[9px] font-medium text-text-secondary bg-surface-highlight px-1.5 py-0.5 rounded inline-block mt-1">
                                    BT: {convert(2.0).btd} mg q3-4h
                                </div>
                            </div>
                        </ClinicalCard>
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-warning bg-warning-bg/10">
                            <div>
                                <div className="font-bold text-text-primary">Hydromorphone PO</div>
                                <div className="text-[10px] text-warning font-medium">OME Ratio 1:4</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-text-primary">{convert(0.75).reduced}<small className="text-xs text-text-tertiary ml-1">mg/24h</small></div>
                                <div className="text-[9px] font-medium text-text-secondary bg-surface-highlight px-1.5 py-0.5 rounded inline-block mt-1">
                                    BT: {convert(0.75).btd} mg q3-4h
                                </div>
                            </div>
                        </ClinicalCard>
                    </div>
                </div>

                <div>
                    <h3 className="text-xs font-bold text-text-tertiary uppercase mb-3 ml-1">Transdermal / Transmucosal</h3>

                    {/* Safety Interstitial */}
                    <div className="bg-surface-card rounded-xl border border-warning/30 overflow-hidden shadow-sm">
                        <div className="bg-warning-bg p-3 border-b border-warning/20 flex justify-between items-center">
                            <div className="flex items-center gap-2 text-warning font-bold text-xs uppercase tracking-wide">
                                <ShieldAlert className="w-4 h-4" /> Complex Conversions
                            </div>
                            {!showSafetyCheck && (
                                <button
                                    onClick={() => setShowSafetyCheck(true)}
                                    className="text-[10px] bg-surface-card border border-warning/30 px-2 py-1 rounded text-warning hover:bg-warning-bg transition-colors font-bold"
                                >
                                    Show Estimates
                                </button>
                            )}
                        </div>

                        {showSafetyCheck ? (
                            <div className="p-4 space-y-4 animate-in slide-in-from-top-2 fade-in">
                                {/* Fentanyl Patch */}
                                <div className="flex flex-col gap-2 pb-4 border-b border-border">
                                    <div className="flex justify-between">
                                        <h3 className="font-bold text-text-primary">Fentanyl Patch</h3>
                                        <div className="text-right">
                                            <div className="text-xl font-bold text-text-primary">{convert(1.5).reduced} <span className="text-xs font-medium text-text-tertiary">mcg/hr</span></div>
                                            <div className="text-[10px] text-warning mt-1 font-medium">Use closest LOWER patch size</div>
                                        </div>
                                    </div>
                                    <div className="text-[10px] bg-warning-bg text-warning-900 p-2 rounded border border-warning/20 leading-relaxed">
                                        <strong>WARNING:</strong> Patches take 12-24h to onset. Cover with short-acting. Package insert recommends stricter conversion than standard equianalgesic tables.
                                    </div>
                                </div>

                                {/* Methadone (No calc provided) */}
                                <div className="flex flex-col gap-2">
                                    <div className="flex justify-between">
                                        <h3 className="font-bold text-text-primary">Methadone</h3>
                                        <div className="text-right">
                                            <div className="text-xl font-bold text-text-primary">Consult Pain Svc</div>
                                            <div className="text-[10px] text-text-tertiary mt-1">Non-linear kinetics</div>
                                        </div>
                                    </div>
                                    <div className="text-[10px] bg-danger-bg text-danger-900 p-2 rounded border border-danger/20 leading-relaxed">
                                        <strong>DO NOT ESTIMATE:</strong> Methadone conversion varies by total MME (4:1 to 20:1). Accumulates over 5 days (t1/2 8-59h). Risk of QTc prolongation and overdose.
                                    </div>
                                </div>

                                <button onClick={() => setShowSafetyCheck(false)} className="w-full py-2 text-xs font-bold text-text-tertiary hover:text-text-secondary">Hide Complex Conversions</button>
                            </div>
                        ) : (
                            <div className="p-6 text-center text-text-tertiary text-xs">
                                <ShieldAlert className="w-8 h-8 mx-auto mb-2 opacity-20" />
                                <p>High-risk conversions (Patch/Methadone) hidden for safety.</p>
                            </div>
                        )}
                    </div>
                </div>

                <div className="bg-action-bg p-3 rounded-lg border border-action-border/30 flex gap-2 text-action mt-2">
                    <Activity className="w-4 h-4 flex-none mt-0.5" />
                    <p className="text-[10px] leading-relaxed font-medium">
                        <strong>Monitoring:</strong> Assess efficacy & safety q2-4h (first 24h). Re-calculate TDD after 24-72h.
                        Breakthrough (BT) calculated at ~10% of TDD.
                    </p>
                </div>
            </div>
        </div >
    );
};
