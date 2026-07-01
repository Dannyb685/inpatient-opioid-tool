import React, { useState } from 'react';
import {
    AlertTriangle,
    ShieldAlert,
    Ban,
    Calculator,
    Info,
    ChevronDown,
    ChevronRight,
    Copy,
    Activity,
    CheckCircle2
} from 'lucide-react';
import { ClinicalCard } from './Shared';
import { useAssessmentStore } from './stores/AssessmentStore';

// --- Types ---

type ConversionMethod = 'Rapid' | 'Stepwise';

interface MethadoneScheduleStep {
    dayLabel: string;
    oldOpioidPercent: string;
    methadoneDose: string;
    instructions: string;
    methadoneDailyMg: number; // For Chart
    prevOpioidPercentVal: number; // For Chart
}

interface MethadoneConversionResult {
    totalDailyDose: number;
    individualDose: number;
    dosingSchedule: string;
    warnings: string[];
    isContraindicatedForCalculator: boolean;
    transitionSchedule: MethadoneScheduleStep[] | null;
}

// --- Logic Engine ---

const calculateMethadoneConversion = (totalMME: number, patientAge: number, method: ConversionMethod): MethadoneConversionResult => {
    let ratio: number;
    let maxDailyDose: number | null = null;
    let warnings: string[] = [];
    let crossToleranceReduction = 0.0;

    // NCCN age-based adjustment
    const useConservativeRatio = patientAge >= 65;

    if (totalMME < 30) {
        ratio = 2.0;
        warnings.push("Low baseline MME: Consider fixed starting dose of 2.5mg TID per APS guidelines.");
    } else if (totalMME < 60) {
        // NCCN: Fixed 2-7.5mg/day for <60mg morphine
        ratio = 4.0;
        warnings.push("NCCN recommends fixed dose range 2-7.5mg/day for <60mg baseline morphine.");
    } else if (totalMME < 100) {
        ratio = useConservativeRatio ? 20.0 : 10.0; // NCCN age adjustment
        crossToleranceReduction = 0.10;
    } else if (totalMME < 200) {
        ratio = useConservativeRatio ? 20.0 : 10.0;
        crossToleranceReduction = 0.15;
    } else if (totalMME < 300) {
        ratio = 20.0; // Conservative for all patients ≥200mg
        crossToleranceReduction = 0.20;
        maxDailyDose = 45.0; // NCCN cap
    } else if (totalMME < 500) {
        ratio = 12.0; // VA/DoD
        crossToleranceReduction = 0.25;
        maxDailyDose = 45.0;
    } else if (totalMME < 1000) {
        ratio = 15.0;
        crossToleranceReduction = 0.25;
        maxDailyDose = 45.0;
    } else if (totalMME < 1200) {
        ratio = 20.0;
        crossToleranceReduction = 0.25;
        maxDailyDose = 40.0; // APS maximum
    } else {
        warnings.push("🚨 SPECIALIST CONSULTATION MANDATORY");
        return {
            totalDailyDose: 0,
            individualDose: 0,
            dosingSchedule: "Consult Pain Specialist",
            warnings: warnings,
            isContraindicatedForCalculator: true,
            transitionSchedule: null
        };
    }

    let methadoneDailyDose = totalMME / ratio;

    // Apply Dose-Dependent Cross-Tolerance Reduction
    if (crossToleranceReduction > 0) {
        methadoneDailyDose *= (1.0 - crossToleranceReduction);
        warnings.push(`Applied ${Math.round(crossToleranceReduction * 100)}% reduction for incomplete cross-tolerance.`);
    }

    // Apply minimum floor for very low calculations (< APS Minimum)
    const minimumDose = 7.5; // APS floor (2.5mg TID)
    if (methadoneDailyDose < minimumDose && totalMME >= 30) {
        methadoneDailyDose = minimumDose;
        warnings.push("Note: Dose rounded up to APS minimum (2.5mg TID).");
    }

    // Apply maximum cap
    if (maxDailyDose !== null && methadoneDailyDose > maxDailyDose) {
        methadoneDailyDose = maxDailyDose;
        warnings.push(`⚠️ Dose capped at ${maxDailyDose}mg/day per NCCN/APS guidelines.`);
    }

    // Age-specific warning
    if (useConservativeRatio && totalMME >= 60) {
        warnings.push("⚠️ **ELDERLY PATIENT:** Using more conservative NCCN ratios.");
    }

    // Step 5: Divide into dosing schedule (TID preferred for analgesia)
    let individualDose = methadoneDailyDose / 3.0;

    // Practical Rounding (Nearest 0.5mg) to avoid "1.8mg"
    individualDose = Math.round(individualDose * 2) / 2;

    // Recalculate daily total based on rounded val
    methadoneDailyDose = individualDose * 3.0;

    // Step 6: Generate comprehensive warnings
    warnings.push("🚨 **METHADONE SAFETY PROTOCOL:**");
    warnings.push("**Do NOT titrate** more frequently than every 5-7 days.");
    warnings.push("**ECG required:** Baseline, 2-4 weeks, and at 100mg/day.");
    warnings.push("   • **Avoid if QTc >500ms;** Caution if 450-500ms.");
    warnings.push("**Monitor** for delayed respiratory depression (peak 2-4 days).");
    warnings.push("**Provide** naloxone rescue kit.");
    warnings.push("**UNIDIRECTIONAL conversion** - do NOT use reverse calculation.");

    // Generate Schedule if Stepwise
    let schedule: MethadoneScheduleStep[] | null = null;
    if (method === 'Stepwise') {
        const step1Methadone = Math.round((methadoneDailyDose * 0.33 / 3.0) * 2) / 2; // TID
        const step2Methadone = Math.round((methadoneDailyDose * 0.66 / 3.0) * 2) / 2; // TID
        const finalMethadone = individualDose;

        schedule = [
            {
                dayLabel: "Days 1-3",
                oldOpioidPercent: "Reduce Previous to 66% (2/3)",
                methadoneDose: `${step1Methadone} mg TID`,
                instructions: "Continue PRN breakthrough.",
                methadoneDailyMg: step1Methadone * 3,
                prevOpioidPercentVal: 66
            },
            {
                dayLabel: "Days 4-6",
                oldOpioidPercent: "Reduce Previous to 33% (1/3)",
                methadoneDose: `${step2Methadone} mg TID`,
                instructions: "Monitor for sedation.",
                methadoneDailyMg: step2Methadone * 3,
                prevOpioidPercentVal: 33
            },
            {
                dayLabel: "Day 7+",
                oldOpioidPercent: "Discontinue Previous",
                methadoneDose: `${finalMethadone} mg TID`,
                instructions: "Full Target Dose Reached.",
                methadoneDailyMg: finalMethadone * 3,
                prevOpioidPercentVal: 0
            }
        ];

        warnings.push("**STEPWISE INDUCTION:** Follow the 3-Step Transition Schedule below.");
    }

    return {
        totalDailyDose: methadoneDailyDose,
        individualDose: individualDose,
        dosingSchedule: "Every 8 hours (TID)",
        warnings: warnings,
        isContraindicatedForCalculator: false,
        transitionSchedule: schedule
    };
};

// --- Components ---

const MethadoneStepwiseChart = ({ schedule }: { schedule: MethadoneScheduleStep[] }) => {
    // Basic SVG Chart
    const height = 150;
    const width = 300;
    const padding = 20;
    const chartW = width - padding * 2;
    const chartH = height - padding * 2;

    const steps = schedule.length;
    // X points: 0, 1, 2
    const getX = (i: number) => padding + (i / (steps - 1)) * chartW;

    // Normalize Y
    const maxY = Math.max(...schedule.map(s => s.methadoneDailyMg), 10); // Ensure non-zero
    const getYM = (mg: number) => padding + chartH - ((mg / maxY) * chartH);

    // Y for Previous Opioid (0-100)
    const getYP = (pct: number) => padding + chartH - ((pct / 100) * chartH);

    const pointsM = schedule.map((s, i) => `${getX(i)},${getYM(s.methadoneDailyMg)}`).join(' ');
    const pointsP = schedule.map((s, i) => `${getX(i)},${getYP(s.prevOpioidPercentVal)}`).join(' ');

    return (
        <div className="bg-surface-card p-4 rounded-xl border border-border">
            <h4 className="text-xs font-bold text-text-secondary mb-4 uppercase">Cross-Taper Visualization</h4>
            <div className="w-full flex justify-center">
                <svg width={width} height={height} className="overflow-visible">
                    {/* Grid lines */}
                    <line x1={padding} y1={padding} x2={padding} y2={height - padding} stroke="#334155" strokeWidth="1" />
                    <line x1={padding} y1={height - padding} x2={width - padding} y2={height - padding} stroke="#334155" strokeWidth="1" />

                    {/* Methadone Line (Teal) */}
                    <polyline points={pointsM} fill="none" stroke="#14b8a6" strokeWidth="3" />
                    {schedule.map((s, i) => (
                        <circle key={`m-${i}`} cx={getX(i)} cy={getYM(s.methadoneDailyMg)} r="4" fill="#14b8a6" />
                    ))}

                    {/* Previous Line (Amber) */}
                    <polyline points={pointsP} fill="none" stroke="#f59e0b" strokeWidth="3" strokeDasharray="5,5" />
                    {schedule.map((s, i) => (
                        <circle key={`p-${i}`} cx={getX(i)} cy={getYP(s.prevOpioidPercentVal)} r="4" fill="#f59e0b" />
                    ))}
                </svg>
            </div>
            <div className="flex justify-between mt-4 px-4">
                <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-action"></div>
                    <span className="text-[10px] text-text-secondary">Methadone (mg)</span>
                </div>
                <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-warning"></div>
                    <span className="text-[10px] text-text-secondary">Previous Opioid (%)</span>
                </div>
            </div>
        </div>
    );
};

export const MethadoneCalculator = ({ onClose, initialMME }: { onClose: () => void, initialMME?: string }) => {
    const assessmentAge = useAssessmentStore(state => state.age);

    // Auto-seed local state from Global Store if available, else default to 50
    const [mme, setMme] = useState(initialMME || '');
    const [age, setAge] = useState(() => {
        const parsed = parseInt(assessmentAge);
        return !isNaN(parsed) ? parsed : 50;
    });

    // Update if global store changes while open
    React.useEffect(() => {
        const parsed = parseInt(assessmentAge);
        if (!isNaN(parsed)) {
            setAge(parsed);
        }
    }, [assessmentAge]);

    const [qtcIssue, setQtcIssue] = useState(false);
    const [method, setMethod] = useState<ConversionMethod>('Rapid');

    // Safety Gates (Manual for now, since we don't have global state connected yet)
    const [isNaltrexone, setIsNaltrexone] = useState(false);
    const [isPregnant, setIsPregnant] = useState(false);

    const [result, setResult] = useState<MethadoneConversionResult | null>(null);
    const [showChart, setShowChart] = useState(false);
    const [showTransparency, setShowTransparency] = useState(false);

    const handleCalculate = () => {
        const val = parseFloat(mme);
        if (val > 0) {
            setResult(calculateMethadoneConversion(val, age, method));
            setShowChart(false);
        }
    };

    const copySchedule = () => {
        if (!result?.transitionSchedule) return;
        let text = "Methadone Stepwise Induction Plan\n";
        text += "Strategy: 3-Step Rotation (33% increments)\n";
        text += `Target Dose: ${result.totalDailyDose} mg/day (${result.individualDose} mg TID)\n\n`;

        result.transitionSchedule.forEach(step => {
            text += `${step.dayLabel}:\n`;
            text += ` - Previous Opioid: ${step.oldOpioidPercent}\n`;
            text += ` - Methadone: ${step.methadoneDose}\n`;
            text += ` - Note: ${step.instructions}\n\n`;
        });

        text += "WARNING: Pause taper if profound sedation or respiratory issues occur.";

        navigator.clipboard.writeText(text);
        alert("Schedule copied to clipboard!");
    };

    return (
        <div className="fixed inset-0 z-50 bg-surface-base lg:static lg:bg-transparent lg:z-auto animate-fade-in overflow-y-auto">
            <div className="max-w-4xl mx-auto p-4 lg:p-0 space-y-6 pb-20">
                {/* Header (Mobile Only) */}
                <div className="lg:hidden flex justify-between items-center mb-4">
                    <h2 className="text-xl font-bold text-text-primary">Methadone Calc</h2>
                    <button onClick={onClose} className="text-action font-bold">Close</button>
                </div>

                {/* Banner */}
                <div className="bg-danger/10 border border-danger/30 rounded-xl p-4 flex gap-4 items-start">
                    <AlertTriangle className="w-6 h-6 text-danger flex-none" />
                    <div>
                        <h3 className="font-bold text-danger text-sm">SPECIALIST CONSULTATION RECOMMENDED</h3>
                        <p className="text-xs text-text-primary mt-1">
                            Methadone conversion is complex and risky. This tool calculates a STARTING dose only.
                        </p>
                    </div>
                </div>

                {/* Inputs */}
                <div className="bg-surface-highlight border border-border rounded-xl p-6 space-y-6">
                    <div className="flex items-center gap-2 mb-2">
                        <Activity className="w-5 h-5 text-action" />
                        <h3 className="font-bold text-text-primary">Conversion Inputs</h3>
                    </div>

                    <div className="grid md:grid-cols-2 gap-6">
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-text-tertiary">Current Total Daily MME</label>
                            <div className="relative">
                                <input
                                    type="number"
                                    value={mme}
                                    onChange={e => setMme(e.target.value)}
                                    className="w-full text-2xl font-bold bg-surface-card border border-border rounded-lg p-3 text-text-primary focus:border-action outline-none"
                                    placeholder="0"
                                />
                                <span className="absolute right-4 top-4 text-text-tertiary font-bold">mg</span>
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div className="flex justify-between items-center">
                                <label className="text-sm font-medium text-text-tertiary">Patient Age</label>
                                <div className="flex items-center gap-4">
                                    <span className="text-xl font-bold text-text-primary">{age}</span>
                                    <input
                                        type="range"
                                        min="18"
                                        max="100"
                                        value={age}
                                        onChange={e => setAge(parseInt(e.target.value))}
                                        className="w-32 h-2 bg-surface-card rounded-lg appearance-none cursor-pointer accent-action"
                                    />
                                </div>
                            </div>

                            <label className="flex items-center justify-between p-3 rounded-lg border border-border bg-surface-card cursor-pointer hover:bg-surface-base transition-colors">
                                <span className="text-sm font-medium text-text-primary">QTc Prolongation (&gt;450ms)</span>
                                <input
                                    type="checkbox"
                                    checked={qtcIssue}
                                    onChange={e => setQtcIssue(e.target.checked)}
                                    className="w-5 h-5 rounded border-text-tertiary text-danger focus:ring-danger"
                                />
                            </label>
                            {qtcIssue && (
                                <div className="text-[10px] text-danger font-bold bg-danger/10 p-2 rounded border border-danger/20 flex gap-2 items-center">
                                    <Ban className="w-4 h-4" />
                                    Methadone may be contraindicated.
                                </div>
                            )}
                        </div>
                    </div>

                    <div className="h-px bg-border my-4"></div>

                    {/* Method & Safety Gates */}
                    <div className="grid md:grid-cols-2 gap-6">
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-text-tertiary">Conversion Method</label>
                            <div className="flex bg-surface-card p-1 rounded-lg border border-border">
                                {(['Rapid', 'Stepwise'] as const).map(m => (
                                    <button
                                        key={m}
                                        onClick={() => setMethod(m)}
                                        className={`flex-1 py-2 text-sm font-bold rounded-md transition-all ${method === m
                                            ? 'bg-action text-white shadow-sm'
                                            : 'text-text-tertiary hover:text-text-primary'
                                            }`}
                                    >
                                        {m}
                                    </button>
                                ))}
                            </div>
                            <p className="text-[11px] text-text-tertiary italic">
                                {method === 'Stepwise'
                                    ? "Strategy: Reduce previous opioid by 1/3 every few days."
                                    : "Strategy: Discontinue previous opioid completely before first dose."}
                            </p>
                        </div>

                        <div className="space-y-2">
                            <label className="text-sm font-medium text-text-tertiary">Safety Gates (Test)</label>
                            <div className="flex gap-2">
                                <button
                                    onClick={() => setIsNaltrexone(!isNaltrexone)}
                                    className={`px-3 py-1.5 rounded-lg border text-xs font-bold transition-colors ${isNaltrexone ? 'bg-danger text-white border-danger' : 'bg-surface-card border-border text-text-tertiary'}`}
                                >
                                    Naltrexone
                                </button>
                                <button
                                    onClick={() => setIsPregnant(!isPregnant)}
                                    className={`px-3 py-1.5 rounded-lg border text-xs font-bold transition-colors ${isPregnant ? 'bg-purple-500 text-white border-purple-500' : 'bg-surface-card border-border text-text-tertiary'}`}
                                >
                                    Pregnant
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Active Safety Gates Interstitial */}
                    {isNaltrexone && (
                        <div className="bg-surface-base p-8 rounded-xl border border-danger flex flex-col items-center text-center animate-fade-in">
                            <Ban className="w-12 h-12 text-danger mb-4" />
                            <h3 className="text-xl font-bold text-danger">Opioid Blockade Active</h3>
                            <p className="text-sm text-text-secondary mt-2">Patient is on Naltrexone/Vivitrol. Methadone induction is CONTRAINDICATED without specialist detox protocol.</p>
                        </div>
                    )}

                    {isPregnant && !isNaltrexone && (
                        <div className="bg-surface-base p-8 rounded-xl border border-purple-500 flex flex-col items-center text-center animate-fade-in">
                            <ShieldAlert className="w-12 h-12 text-purple-500 mb-4" />
                            <h3 className="text-xl font-bold text-purple-500">Perinatal Management Required</h3>
                            <p className="text-sm text-text-secondary mt-2">Methadone is standard of care but requires OB/Addiction Specialist management.</p>
                        </div>
                    )}

                    {!isNaltrexone && !isPregnant && (
                        <button
                            onClick={handleCalculate}
                            className="w-full bg-action hover:bg-action/90 text-white font-bold py-4 rounded-xl shadow-lg shadow-action/20 transition-all active:scale-[0.98]"
                        >
                            Calculate Starting Dose
                        </button>
                    )}
                </div>

                {/* Results */}
                {result && !result.isContraindicatedForCalculator && !isNaltrexone && !isPregnant && (
                    <div className="space-y-6 animate-fade-in-up">
                        <ClinicalCard title="Recommended Protocol" className="border-l-4 border-l-action">
                            <div className="flex justify-between items-center mb-6">
                                <div>
                                    <h4 className="text-sm text-text-tertiary uppercase font-bold text-left">Scheduled Dose</h4>
                                    <div className="text-4xl font-black text-action mt-1">{result.individualDose} <span className="text-lg text-text-secondary font-bold">mg</span></div>
                                    <div className="text-sm font-bold text-action">TID (Every 8 hours)</div>
                                </div>
                                <div className="text-right">
                                    <h4 className="text-[10px] text-text-tertiary uppercase font-bold">Total Daily</h4>
                                    <div className="text-xl font-bold text-text-primary">{result.totalDailyDose.toFixed(1)} mg</div>
                                </div>
                            </div>

                            {/* Stepwise Schedule */}
                            {result.transitionSchedule && Array.isArray(result.transitionSchedule) && (
                                <div className="space-y-4">
                                    <div className="flex gap-2">
                                        <button
                                            onClick={() => setShowChart(!showChart)}
                                            className="flex-1 bg-surface-card hover:bg-surface-highlight border border-border p-3 rounded-lg flex items-center justify-between transition-colors"
                                        >
                                            <div className="flex items-center gap-2">
                                                <Activity className="w-4 h-4 text-action" />
                                                <span className="text-sm font-bold text-text-primary">Visualize Plan</span>
                                            </div>
                                            <ChevronRight className={`w-4 h-4 text-text-tertiary transition-transform ${showChart ? 'rotate-90' : ''}`} />
                                        </button>
                                        <button
                                            onClick={copySchedule}
                                            className="bg-surface-card hover:bg-surface-highlight border border-border p-3 rounded-lg text-action"
                                            title="Copy Schedule"
                                        >
                                            <Copy className="w-5 h-5" />
                                        </button>
                                    </div>

                                    {showChart && <MethadoneStepwiseChart schedule={result.transitionSchedule} />}

                                    <div className="bg-surface-card rounded-xl border border-border divide-y divide-border">
                                        {result.transitionSchedule.map((step, idx) => (
                                            <div key={idx} className="p-4 flex gap-4">
                                                <div className="w-20 font-bold text-text-secondary text-sm">{step.dayLabel}</div>
                                                <div className="space-y-1">
                                                    <div className="text-xs text-text-tertiary font-bold">PREV: {step.oldOpioidPercent}</div>
                                                    <div className="text-sm font-bold text-action">METHADONE: {step.methadoneDose}</div>
                                                    <div className="text-[10px] text-warning italic">{step.instructions}</div>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {/* Warnings */}
                            <div className="bg-warning/10 rounded-xl p-4 mt-6">
                                <h4 className="text-xs font-bold text-text-primary mb-3 uppercase">Safety Warnings & Monitoring</h4>
                                <ul className="space-y-2">
                                    {result.warnings.map((w, i) => (
                                        <li key={i} className="text-xs text-text-primary flex gap-2 items-start">
                                            <div className="w-1.5 h-1.5 rounded-full bg-warning mt-1 flex-none"></div>

                                            {/* Crude parser for bolding */}
                                            <span>
                                                {w.split('**').map((part, idx) =>
                                                    idx % 2 === 1 ? <strong key={idx}>{part}</strong> : part
                                                )}
                                            </span>
                                        </li>
                                    ))}
                                </ul>
                            </div>
                        </ClinicalCard>
                    </div>
                )}
            </div>
        </div>
    );
};
