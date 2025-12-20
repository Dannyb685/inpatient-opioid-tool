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
    const [ivMorphine, setIvMorphine] = useState(10);
    const [reduction, setReduction] = useState(30);
    const [showInfusion, setShowInfusion] = useState(false);
    const [infusionRate, setInfusionRate] = useState(0);

    const convert = (factor: number) => {
        const raw = ivMorphine * factor;
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

    const handleInfusionCalc = (rate: number) => {
        setInfusionRate(rate);
        setIvMorphine(rate * 24);
    };

    return (
        <div className="grid lg:grid-cols-2 gap-8 max-w-4xl mx-auto">
            <div className="lg:col-span-2 bg-blue-50 border border-blue-100 rounded-xl p-4 flex gap-4 items-start shadow-sm">
                <div className="p-2 bg-blue-100 text-blue-600 rounded-lg flex-none">
                    <Info className="w-5 h-5" />
                </div>
                <div>
                    <h3 className="text-sm font-bold text-blue-900 mb-1">Safety First: 24-Hour Totals</h3>
                    <p className="text-sm text-blue-800 leading-relaxed">
                        Calculations must be based on the <strong>TOTAL 24-Hour Opioid Exposure</strong> (Scheduled + Breakthrough).
                        Do not use single doses or hourly rates directly.
                        <span className="block mt-1.5 font-bold text-rose-600">
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
                            <span className="block text-2xl font-bold text-slate-900">Total 24-Hour Dose</span>
                            <span className="text-xs text-slate-500 font-medium uppercase tracking-wide">Morphine IV Equivalents</span>
                        </div>
                        <div className="flex items-baseline gap-1 relative">
                            <input
                                type="number"
                                value={ivMorphine}
                                onChange={(e) => setIvMorphine(Math.max(0, parseFloat(e.target.value)))}
                                className="w-28 text-4xl font-bold text-right text-teal-600 border-b-2 border-slate-100 focus:border-teal-500 focus:outline-none bg-transparent pb-1"
                            />
                            <span className="text-sm font-bold text-slate-400 absolute -right-6 bottom-2">mg/24h</span>
                        </div>
                    </div>

                    <div className="mb-6 flex justify-between items-start">
                        <p className="text-[10px] text-slate-400 italic max-w-[60%]">
                            *Include all scheduled doses AND breakthrough doses administered in the last 24 hours.
                        </p>
                        <button
                            onClick={() => setShowInfusion(!showInfusion)}
                            className="text-[10px] font-bold text-teal-600 bg-teal-50 px-2 py-1 rounded border border-teal-100 hover:bg-teal-100 transition-colors"
                        >
                            {showInfusion ? 'Close Helper' : 'Infusion Helper'}
                        </button>
                    </div>

                    {showInfusion && (
                        <div className="mb-6 bg-slate-50 p-3 rounded-lg border border-slate-200 animate-in slide-in-from-top-2">
                            <div className="flex items-center gap-4">
                                <span className="text-xs font-bold text-slate-500 uppercase">Hourly Rate:</span>
                                <div className="flex items-baseline gap-1">
                                    <input
                                        type="number"
                                        value={infusionRate}
                                        onChange={(e) => handleInfusionCalc(Math.max(0, parseFloat(e.target.value)))}
                                        className="w-16 p-1 text-right font-bold text-slate-700 border-b border-slate-300 bg-transparent focus:outline-none focus:border-teal-500"
                                    />
                                    <span className="text-xs text-slate-400">mg/hr</span>
                                </div>
                                <span className="text-xs font-bold text-slate-400">× 24h =</span>
                                <span className="text-sm font-bold text-teal-600">{infusionRate * 24} mg/day</span>
                            </div>
                        </div>
                    )}

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
                                            ? 'bg-teal-50 border-teal-500 text-teal-700 ring-1 ring-teal-500'
                                            : 'bg-white border-slate-200 text-slate-400 hover:border-slate-300 hover:bg-slate-50'
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
                                    className="w-full h-2 bg-slate-100 rounded-lg appearance-none cursor-pointer accent-teal-600"
                                />
                                <div className="flex justify-between mt-2 text-[10px] font-medium text-slate-400">
                                    <span>Custom: -{reduction}%</span>
                                    <span>(Range: 0-75%)</span>
                                </div>
                            </div>
                        </div>

                        <div className="text-[11px] leading-relaxed text-slate-600 bg-slate-50 p-3 rounded-lg border border-slate-200 flex gap-3">
                            <div className="mt-0.5 min-w-[16px]">
                                {reduction < 25 ? <Zap className="w-4 h-4 text-rose-500" /> :
                                    reduction > 40 ? <ShieldAlert className="w-4 h-4 text-blue-600" /> :
                                        <Activity className="w-4 h-4 text-teal-600" />}
                            </div>
                            <div>
                                <strong className="block text-slate-900 mb-1">
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

                <div className="bg-blue-50 p-4 rounded-lg border border-blue-100 flex gap-3 text-blue-900">
                    <Info className="w-5 h-5 flex-none text-blue-500" />
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
                    <h3 className="text-sm font-bold text-slate-900 mb-4 flex items-center gap-2">
                        <Calculator className="w-4 h-4 text-teal-600" />
                        Estimated 24-Hour Target Doses
                    </h3>
                    <h3 className="text-xs font-bold text-slate-400 uppercase mb-3 ml-1">Parenteral Targets (IV/SQ)</h3>
                    <div className="space-y-2">
                        <ClinicalCard className="flex justify-between items-center p-4">
                            <div>
                                <div className="font-bold text-slate-800">Hydromorphone IV</div>
                                <div className="text-[10px] text-slate-400">Ratio 1:6.7</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-teal-600">{convert(0.15).reduced}<small className="text-xs text-slate-400 ml-1">mg/24h</small></div>
                                <div className="text-[9px] font-medium text-teal-600 bg-teal-50 px-1.5 py-0.5 rounded inline-block mt-1">
                                    BT: {convert(0.15).btd} mg q2-4h
                                </div>
                                <div className="text-[10px] text-slate-400 strikethrough decoration-slate-300 opacity-60 mt-1">{convert(0.15).raw} raw</div>
                            </div>
                        </ClinicalCard>
                        <ClinicalCard className="flex justify-between items-center p-4">
                            <div>
                                <div className="font-bold text-slate-800">Fentanyl IV</div>
                                <div className="text-[10px] text-slate-400 font-medium">10mg Mor : 100mcg Fent</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-teal-600">{convert(10).reduced}<small className="text-xs text-slate-400 ml-1">mcg/24h</small></div>
                                <div className="text-[9px] font-medium text-teal-600 bg-teal-50 px-1.5 py-0.5 rounded inline-block mt-1">
                                    BT: {convert(10).btd} mcg q1-2h
                                </div>
                            </div>
                        </ClinicalCard>
                    </div>
                </div>

                <div>
                    <div className="flex justify-between items-end mb-3 ml-1">
                        <h3 className="text-xs font-bold text-slate-400 uppercase">Enteral Targets (PO)</h3>
                        <div className="text-[10px] font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                            PO Mor Equiv: {convert(3).reduced}mg
                        </div>
                    </div>
                    <div className="space-y-2">
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-emerald-400">
                            <div>
                                <div className="font-bold text-slate-800">Oxycodone PO</div>
                                <div className="text-[10px] text-emerald-600 font-medium">OME Ratio 1:1.5</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-slate-800">{convert(2.0).reduced}<small className="text-xs text-slate-400 ml-1">mg/24h</small></div>
                                <div className="text-[9px] font-medium text-slate-600 bg-slate-100 px-1.5 py-0.5 rounded inline-block mt-1">
                                    BT: {convert(2.0).btd} mg q3-4h
                                </div>
                            </div>
                        </ClinicalCard>
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-amber-400 bg-amber-50/30">
                            <div>
                                <div className="font-bold text-slate-800">Hydromorphone PO</div>
                                <div className="text-[10px] text-amber-600 font-medium">OME Ratio 1:4</div>
                            </div>
                            <div className="text-right">
                                <div className="text-2xl font-bold text-slate-800">{convert(0.75).reduced}<small className="text-xs text-slate-400 ml-1">mg/24h</small></div>
                                <div className="text-[9px] font-medium text-slate-600 bg-slate-100 px-1.5 py-0.5 rounded inline-block mt-1">
                                    BT: {convert(0.75).btd} mg q3-4h
                                </div>
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
                                <div className="text-[9px] text-slate-400">Consult Pkg Insert</div>
                            </div>
                        </ClinicalCard>
                        <ClinicalCard className="flex justify-between items-center p-4 border-l-4 border-l-indigo-400 bg-indigo-50/20">
                            <div>
                                <div className="font-bold text-slate-800">Butrans Patch</div>
                                <div className="text-[10px] text-indigo-600 font-medium italic">Consult Specialist</div>
                            </div>
                            <div className="text-right">
                                <div className="text-xs font-bold text-slate-400 uppercase">No Ratio</div>
                                <div className="text-[9px] text-rose-500 font-bold">Withdrawal Risk</div>
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
                                <div className="text-[10px] text-rose-600 font-medium italic">Titrate from lowest</div>
                            </div>
                            <div className="text-right">
                                <div className="text-xs font-bold text-slate-400 uppercase">Independent</div>
                                <div className="text-[9px] text-slate-400">Not for Naive</div>
                            </div>
                        </ClinicalCard>
                    </div>
                </div>

                <div className="bg-emerald-50 p-3 rounded-lg border border-emerald-100 flex gap-2 text-emerald-900 mt-2">
                    <Activity className="w-4 h-4 flex-none text-emerald-600 mt-0.5" />
                    <p className="text-[10px] leading-relaxed font-medium">
                        <strong>Monitoring:</strong> Assess efficacy & safety q2-4h (first 24h). Re-calculate TDD after 24-72h.
                        Breakthrough (BT) calculated at ~10% of TDD.
                    </p>
                </div>
            </div>
        </div >
    );
};
