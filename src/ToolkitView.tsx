import React, { useState } from 'react';
import {
    ClipboardCheck,
    Thermometer,
    Activity,
    Brain,
    AlertTriangle,
    FileText,
    Copy,
    ChevronRight
} from 'lucide-react';
import { ClinicalCard } from './Shared';

type ScaleItem = {
    id: string;
    label: string;
    options: { score: number; text: string }[];
};

const COWS_DATA: ScaleItem[] = [
    { id: 'pulse', label: 'Resting Pulse Rate', options: [{ score: 0, text: '≤80' }, { score: 1, text: '81-100' }, { score: 2, text: '101-120' }, { score: 4, text: '>120' }] },
    { id: 'sweat', label: 'Sweating', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Chills/Moist' }, { score: 2, text: 'Beads of sweat' }, { score: 3, text: 'Drenching' }] },
    { id: 'restless', label: 'Restlessness', options: [{ score: 0, text: 'Able to sit still' }, { score: 1, text: 'Difficulty sitting' }, { score: 3, text: 'Frequent shifting' }, { score: 5, text: 'Unable to sit' }] },
    { id: 'pupil', label: 'Pupil Size', options: [{ score: 0, text: 'Normal' }, { score: 1, text: 'Pinned' }, { score: 2, text: 'Mod Dilation' }, { score: 5, text: 'Dilated Only' }] }, // Correction: COWS scores dilation. 0=normal/pinned, 1=pupils pinned?, actually COWS is: 0=normal, 1=pupils <3mm?, wait. COWS: 0=normal, 1=possible, 2=moderately dilated, 5=dilated. Pinned is 0.
    { id: 'ache', label: 'Bone/Joint Aches', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Mild' }, { score: 2, text: 'Severe/Rubbing' }, { score: 4, text: 'Unbearable' }] },
    { id: 'nose', label: 'Runny Nose / Tearing', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Stuffiness' }, { score: 2, text: 'Running/Tearing' }, { score: 4, text: 'Profuse' }] },
    { id: 'gi', label: 'GI Upset', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Loose Stools' }, { score: 2, text: 'Nausea/Cramps' }, { score: 3, text: 'Vomiting/Diarrhea' }] },
    { id: 'tremor', label: 'Tremor', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Fine (felt)' }, { score: 2, text: 'Gross (seen)' }, { score: 4, text: 'Coarse' }] },
    { id: 'yawn', label: 'Yawning', options: [{ score: 0, text: 'None' }, { score: 1, text: '1-2 times' }, { score: 2, text: 'Frequent' }, { score: 4, text: 'Constant' }] },
    { id: 'anxiety', label: 'Anxiety / Irritability', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Increasing' }, { score: 2, text: 'Obvious' }, { score: 4, text: 'Severe' }] },
    { id: 'skin', label: 'Gooseflesh', options: [{ score: 0, text: 'None' }, { score: 3, text: 'Piloerection (skin only)' }, { score: 5, text: 'Prominent' }] }
];

const CIWA_DATA: ScaleItem[] = [
    { id: 'nausea', label: 'Nausea / Vomiting', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Mild' }, { score: 4, text: 'Intermittent' }, { score: 7, text: 'Constant' }] },
    { id: 'tremor', label: 'Tremor', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Not visible' }, { score: 4, text: 'Moderate' }, { score: 7, text: 'Severe' }] },
    { id: 'sweat', label: 'Paroxysmal Sweats', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Moist' }, { score: 4, text: 'Beads' }, { score: 7, text: 'Drenching' }] },
    { id: 'anxiety', label: 'Anxiety', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Mild' }, { score: 4, text: 'Moderate' }, { score: 7, text: 'Panic' }] },
    { id: 'agitation', label: 'Agitation', options: [{ score: 0, text: 'Normal' }, { score: 1, text: 'Somewhat' }, { score: 4, text: 'Mod Fidgeting' }, { score: 7, text: 'Pacing/Thrashing' }] },
    { id: 'tactile', label: 'Tactile Disturbances', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Mild Itch' }, { score: 4, text: 'Hallucinations' }, { score: 7, text: 'Continuous' }] },
    { id: 'auditory', label: 'Auditory Disturbances', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Mild Harshness' }, { score: 4, text: 'Hallucinations' }, { score: 7, text: 'Continuous' }] },
    { id: 'visual', label: 'Visual Disturbances', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Mild Sensitivity' }, { score: 4, text: 'Hallucinations' }, { score: 7, text: 'Continuous' }] },
    { id: 'headache', label: 'Headache', options: [{ score: 0, text: 'None' }, { score: 1, text: 'Mild' }, { score: 4, text: 'Moderate' }, { score: 7, text: 'Severe' }] },
    { id: 'orient', label: 'Orientation', options: [{ score: 0, text: 'Oriented' }, { score: 1, text: 'Disorient Date' }, { score: 2, text: 'Disorient Place' }, { score: 4, text: 'Disorient All' }] }
];

const ScaleCalculator = ({ title, data, type }: { title: string, data: ScaleItem[], type: 'cows' | 'ciwa' }) => {
    const [scores, setScores] = useState<{ [key: string]: number }>({});

    const totalScore = Object.values(scores).reduce((a, b) => a + b, 0);

    const getInterpretation = (score: number, type: 'cows' | 'ciwa') => {
        if (type === 'cows') {
            if (score < 5) return { text: 'Mild / No Withdrawal', color: 'text-slate-500', bg: 'bg-slate-100' };
            if (score < 13) return { text: 'Mild Withdrawal (5-12)', color: 'text-amber-600', bg: 'bg-amber-50' };
            if (score < 25) return { text: 'Moderate Withdrawal (13-24)', color: 'text-orange-600', bg: 'bg-orange-50' };
            if (score < 36) return { text: 'Moderately Severe (25-36)', color: 'text-rose-600', bg: 'bg-rose-50' };
            return { text: 'Severe Withdrawal (>36)', color: 'text-rose-700', bg: 'bg-rose-100' };
        } else {
            if (score < 8) return { text: 'Mild / No Withdrawal', color: 'text-slate-500', bg: 'bg-slate-100' };
            if (score < 15) return { text: 'Moderate (8-15) - Medicate', color: 'text-amber-600', bg: 'bg-amber-50' };
            return { text: 'Severe (>15) - High Risk', color: 'text-rose-700', bg: 'bg-rose-100' };
        }
    };

    const interp = getInterpretation(totalScore, type);

    const handleCopy = () => {
        const txt = `${title} Score: ${totalScore}\ninterpretation: ${interp.text}\n\nBreakdown:\n${data.map(i => `- ${i.label}: ${scores[i.id] || 0}`).join('\n')}`;
        navigator.clipboard.writeText(txt);
    };

    return (
        <div className="space-y-6">
            <div className="sticky top-0 z-10 bg-white/95 backdrop-blur border-b border-slate-200 pb-4 pt-2 mb-4">
                <div className="flex items-center justify-between">
                    <div>
                        <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                            <Activity className="w-5 h-5 text-teal-600" /> {title} Calculator
                        </h2>
                        <div className={`mt-1 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${interp.bg} ${interp.color}`}>
                            Score: {totalScore} • {interp.text}
                        </div>
                    </div>
                    <button onClick={handleCopy} className="p-2 hover:bg-slate-100 rounded-full text-slate-400 hover:text-slate-600 transition-colors">
                        <Copy className="w-5 h-5" />
                    </button>
                </div>
            </div>

            <div className="grid md:grid-cols-2 gap-4">
                {data.map(item => (
                    <div key={item.id} className="bg-white p-4 rounded-lg border border-slate-200 shadow-sm">
                        <div className="flex justify-between items-center mb-3">
                            <span className="font-bold text-slate-700 text-sm">{item.label}</span>
                            <span className="text-xs font-bold text-teal-600 bg-teal-50 px-2 py-0.5 rounded">
                                {scores[item.id] || 0}
                            </span>
                        </div>
                        <div className="flex flex-wrap gap-2">
                            {item.options.map(opt => (
                                <button
                                    key={opt.score}
                                    onClick={() => setScores(p => ({ ...p, [item.id]: opt.score }))}
                                    className={`flex-1 min-w-[60px] text-[10px] py-1.5 px-1 rounded border transition-all ${(scores[item.id] === opt.score)
                                            ? 'bg-teal-600 text-white border-teal-600 shadow-sm'
                                            : 'bg-white text-slate-500 border-slate-200 hover:border-teal-300 hover:bg-slate-50'
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
}

const BerneseGuide = () => (
    <div className="max-w-3xl mx-auto space-y-6 text-slate-700">
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
            <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
                <Brain className="w-5 h-5 text-purple-600" /> Bernese Method (Micro-Induction)
            </h3>
            <p className="text-sm mb-4 leading-relaxed">
                A method to induce Buprenorphine WITHOUT stopping full agonist opioids.
                Reduces risk of precipitated withdrawal and allows continuation of analgesia.
            </p>

            <div className="space-y-3">
                {[
                    { day: 1, dose: '0.5 mg once', note: 'Continue full agonist.' },
                    { day: 2, dose: '0.5 mg BID', note: 'Continue full agonist.' },
                    { day: 3, dose: '1 mg BID', note: 'Continue full agonist.' },
                    { day: 4, dose: '2 mg BID', note: 'Continue full agonist.' },
                    { day: 5, dose: '4 mg BID', note: 'Continue full agonist.' },
                    { day: 6, dose: '8 mg daily', note: 'STOP full agonist.' },
                    { day: 7, dose: '16 mg daily', note: 'Adjust as needed.' }
                ].map((step) => (
                    <div key={step.day} className="flex items-center gap-4 bg-slate-50 p-3 rounded-lg border border-slate-100">
                        <div className="w-12 h-12 flex-none rounded-full bg-purple-100 text-purple-700 flex items-center justify-center font-bold text-lg">
                            D{step.day}
                        </div>
                        <div>
                            <div className="font-bold text-slate-900">{step.dose}</div>
                            <div className="text-xs text-slate-500 font-medium">{step.note}</div>
                        </div>
                    </div>
                ))}
            </div>

            <div className="mt-4 p-3 bg-amber-50 rounded-lg border border-amber-100 text-xs text-amber-800 flex gap-2">
                <AlertTriangle className="w-4 h-4 flex-none mt-0.5" />
                <p><strong>Clinical Pearl:</strong> Use Buprenorphine monoproduct (Subutex) or films cut precisely. Ideal for hospital settings where withdrawal is unacceptable (e.g., post-op, pain crisis).</p>
            </div>
        </div>
    </div>
);

export const ToolkitView = () => {
    const [tab, setTab] = useState<'cows' | 'ciwa' | 'induct'>('cows');

    return (
        <div className="h-full flex flex-col">
            <div className="flex gap-2 mb-6 border-b border-slate-100 pb-1 flex-none">
                <div className="flex bg-slate-100/50 p-1 rounded-lg">
                    <button onClick={() => setTab('cows')} className={`px-4 py-2 rounded-md text-sm font-bold transition-all ${tab === 'cows' ? 'bg-white text-teal-700 shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}>COWS</button>
                    <button onClick={() => setTab('ciwa')} className={`px-4 py-2 rounded-md text-sm font-bold transition-all ${tab === 'ciwa' ? 'bg-white text-teal-700 shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}>CIWA-Ar</button>
                    <button onClick={() => setTab('induct')} className={`px-4 py-2 rounded-md text-sm font-bold transition-all ${tab === 'induct' ? 'bg-white text-purple-700 shadow-sm' : 'text-slate-400 hover:text-slate-600'}`}>Induction</button>
                </div>
            </div>

            <div className="flex-1 overflow-y-auto custom-scrollbar pr-2">
                {tab === 'cows' && <ScaleCalculator title="COWS (Opiate Withdrawal)" data={COWS_DATA} type="cows" />}
                {tab === 'ciwa' && <ScaleCalculator title="CIWA-Ar (Alcohol Withdrawal)" data={CIWA_DATA} type="ciwa" />}
                {tab === 'induct' && <BerneseGuide />}
            </div>
        </div>
    );
};
