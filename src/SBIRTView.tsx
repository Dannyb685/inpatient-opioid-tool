import React, { useState } from 'react';
import {
    AlertCircle,
    Beer,
    ClipboardCheck,
    Info,
    MessageSquare,
    ShieldAlert,
    Wine,
    GlassWater,
    DollarSign,
    Package,
    Zap
} from 'lucide-react';
import { ClinicalCard, Badge } from './Shared';

interface Question {
    id: string;
    text: string;
    subQuestions?: Question[];
}

// assistQuestions moved to Store
import { useSBIRTStore, assistQuestions } from './stores/SBIRTStore';

export const SBIRTView = () => {
    const [activeSubTab, setActiveSubTab] = useState('assist');

    // Global Store
    const {
        assistScores,
        toggleAssistScore,
        getScore,
        getRiskCategory
    } = useSBIRTStore();

    return (
        <div className="flex flex-col h-full gap-4">
            <div className="flex bg-white dark:bg-slate-900 p-1 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm shrink-0 overflow-x-auto no-scrollbar">
                {[
                    { id: 'assist', label: 'ASSIST-Lyte', icon: ClipboardCheck },
                    { id: 'dast', label: 'DAST-10', icon: AlertCircle },
                    { id: 'audit', label: 'AUDIT', icon: ShieldAlert },
                    { id: 'bi', label: 'Brief Intervention', icon: MessageSquare },
                    { id: 'visuals', label: 'Visual Aids', icon: Beer }
                ].map(tab => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveSubTab(tab.id)}
                        className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all whitespace-nowrap ${activeSubTab === tab.id
                            ? 'bg-teal-600 text-white shadow-md'
                            : 'text-slate-500 hover:bg-slate-50 dark:hover:bg-slate-800'
                            }`}
                    >
                        <tab.icon className="w-4 h-4" />
                        {tab.label}
                    </button>
                ))}
            </div>

            <div className="flex-1 overflow-y-auto pr-2 custom-scrollbar">
                {activeSubTab === 'assist' && (
                    <div className="space-y-6">
                        <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg border border-blue-100 dark:border-blue-800/50">
                            <div className="flex gap-3">
                                <Info className="w-5 h-5 text-blue-600 dark:text-blue-400 shrink-0" />
                                <div>
                                    <h4 className="text-sm font-bold text-blue-900 dark:text-blue-200">ASSIST-Lyte Instructions</h4>
                                    <p className="text-xs text-blue-800 dark:text-blue-300 mt-1 leading-relaxed">
                                        The questions ask about psychoactive substance use in the <strong>PAST 3 MONTHS ONLY</strong>.
                                        Ask about each substance in order. Mark "Yes" if used.
                                    </p>
                                </div>
                            </div>
                        </div>

                        {assistQuestions.map(q => {
                            const score = getScore(q.id);
                            const risk = getRiskCategory(q.id, score);
                            return (
                                <ClinicalCard key={q.id} title={q.text} action={
                                    q.id !== 'other' && (
                                        <div className="flex items-center gap-3">
                                            <span className="text-[10px] font-bold text-slate-400 uppercase">Score: {score}</span>
                                            <span className={`text-[10px] font-bold uppercase px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-900 ${risk.color}`}>
                                                {risk.label} Risk
                                            </span>
                                        </div>
                                    )
                                }>
                                    <div className="space-y-4">
                                        <label className="flex items-center justify-between group cursor-pointer">
                                            <span className="text-sm font-medium text-slate-700 dark:text-slate-200">Did you use this substance?</span>
                                            <input
                                                type="checkbox"
                                                checked={!!assistScores[q.id]}
                                                onChange={() => toggleAssistScore(q.id)}
                                                className="w-5 h-5 accent-teal-600 rounded"
                                            />
                                        </label>

                                        {assistScores[q.id] && q.subQuestions && (
                                            <div className="pl-6 border-l-2 border-teal-100 dark:border-teal-900 space-y-4 animate-in slide-in-from-left-2">
                                                {q.subQuestions.map(sq => (
                                                    <label key={sq.id} className="flex items-center justify-between cursor-pointer">
                                                        <span className="text-xs font-medium text-slate-600 dark:text-slate-400 pr-4">{sq.text}</span>
                                                        <input
                                                            type="checkbox"
                                                            checked={!!assistScores[sq.id]}
                                                            onChange={() => toggleAssistScore(sq.id)}
                                                            className="w-4 h-4 accent-teal-600 rounded"
                                                        />
                                                    </label>
                                                ))}
                                            </div>
                                        )}

                                        {q.id === 'other' && assistScores[q.id] && (
                                            <input
                                                type="text"
                                                placeholder="Specify substance..."
                                                className="w-full mt-2 p-2 rounded border border-slate-200 dark:border-slate-700 bg-transparent text-sm focus:border-teal-500 outline-none"
                                            />
                                        )}
                                    </div>
                                </ClinicalCard>
                            );
                        })}
                    </div>
                )}

                {activeSubTab === 'bi' && (
                    <div className="space-y-6 animate-in fade-in">
                        <ClinicalCard title="Rapid Guide to Brief Intervention">
                            <div className="space-y-4">
                                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                                    <div className="p-3 bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-100 dark:border-emerald-800/50 rounded-lg">
                                        <h5 className="text-[10px] font-bold text-emerald-700 dark:text-emerald-400 uppercase">Low Risk</h5>
                                        <p className="text-xs mt-1 text-emerald-800 dark:text-emerald-300">General health advice and encourage not to increase use.</p>
                                    </div>
                                    <div className="p-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-100 dark:border-amber-800/50 rounded-lg">
                                        <h5 className="text-[10px] font-bold text-amber-700 dark:text-amber-400 uppercase">Moderate Risk</h5>
                                        <p className="text-xs mt-1 text-amber-800 dark:text-amber-300">Brief intervention using FRAMES Model. Offer take home info.</p>
                                    </div>
                                    <div className="p-3 bg-rose-50 dark:bg-rose-900/20 border border-rose-100 dark:border-rose-800/50 rounded-lg">
                                        <h5 className="text-[10px] font-bold text-rose-700 dark:text-rose-400 uppercase">High Risk</h5>
                                        <p className="text-xs mt-1 text-rose-800 dark:text-rose-300">Brief intervention (FRAMES) + Encourage specialist referral.</p>
                                    </div>
                                </div>

                                <div className="bg-slate-50 dark:bg-slate-900/50 p-4 rounded-lg border border-slate-200 dark:border-slate-700">
                                    <h5 className="text-sm font-bold text-slate-800 dark:text-slate-200 mb-3 flex items-center gap-2">
                                        <MessageSquare className="w-4 h-4 text-teal-600" /> The FRAMES Model
                                    </h5>
                                    <div className="grid grid-cols-1 gap-2">
                                        {[
                                            { l: 'F', t: 'Feedback', d: 'Provide personal feedback about risks related to their specific use.' },
                                            { l: 'R', t: 'Responsibility', d: 'Emphasize that the individual is responsible for change.' },
                                            { l: 'A', t: 'Advice', d: 'Give clear advice on the importance of reducing or stopping use.' },
                                            { l: 'M', t: 'Menu', d: 'Offer a menu of options for different strategies to change.' },
                                            { l: 'E', t: 'Empathy', d: 'Use a warm, reflective, and non-judgmental counseling style.' },
                                            { l: 'S', t: 'Self-Efficacy', d: 'Support the person’s belief in their ability to change.' }
                                        ].map(item => (
                                            <div key={item.l} className="flex gap-3 items-start">
                                                <div className="w-6 h-6 flex-none bg-teal-600 text-white rounded flex items-center justify-center font-bold text-xs">{item.l}</div>
                                                <div>
                                                    <span className="text-xs font-bold text-slate-800 dark:text-slate-200">{item.t}: </span>
                                                    <span className="text-xs text-slate-600 dark:text-slate-400">{item.d}</span>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>

                                <div className="bg-teal-50/50 dark:bg-teal-900/10 p-4 rounded-lg border border-teal-100 dark:border-teal-900/30">
                                    <h5 className="text-xs font-bold text-teal-700 dark:text-teal-400 uppercase mb-3 flex items-center gap-2">
                                        <Zap className="w-3 h-3" /> Core Technique (OARS)
                                    </h5>
                                    <div className="grid grid-cols-1 gap-3">
                                        {[
                                            { l: 'O', t: 'Open-ended questions', d: 'Encourage further discussion and exploration.' },
                                            { l: 'A', t: 'Affirmations', d: 'Recognize the patient\'s strengths and efforts.' },
                                            { l: 'R', t: 'Reflect', d: 'Listen deeply and reflect back what you hear.' },
                                            { l: 'S', t: 'Summarize', d: 'Pull together the main points discussed.' }
                                        ].map(item => (
                                            <div key={item.l} className="flex gap-3 items-center">
                                                <div className="w-5 h-5 flex-none bg-teal-100 dark:bg-teal-900 text-teal-700 dark:text-teal-300 rounded border border-teal-200 dark:border-teal-800 flex items-center justify-center font-black text-[10px]">{item.l}</div>
                                                <div className="text-[11px]">
                                                    <span className="font-bold text-slate-800 dark:text-slate-200">{item.t}: </span>
                                                    <span className="text-slate-600 dark:text-slate-400">{item.d}</span>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        </ClinicalCard>

                        <ClinicalCard title="Motivational Interviewing (MI)">
                            <div className="space-y-4">
                                <div className="bg-indigo-50/50 dark:bg-indigo-900/10 p-4 rounded-lg border border-indigo-100 dark:border-indigo-900/30">
                                    <h5 className="text-xs font-bold text-indigo-700 dark:text-indigo-400 uppercase mb-3">MI Strategy (Miller & Rollnick)</h5>
                                    <div className="space-y-3">
                                        {[
                                            "(1) What would motivate you to make this change?",
                                            "(2) What are the 3 best reasons to do it?",
                                            "(3) How important is it to you to make this change, & why?",
                                            "(4) How would you go about it in order to succeed?",
                                            "(5) Reflect answers back to patient.",
                                            "(6) So what do you think you'll do?"
                                        ].map((step, i) => (
                                            <div key={i} className="text-xs text-slate-700 dark:text-slate-300 flex gap-2">
                                                <span className="text-indigo-500 font-bold">•</span>
                                                <span>{step}</span>
                                            </div>
                                        ))}
                                    </div>
                                </div>

                                <div className="bg-slate-50 dark:bg-slate-900/50 p-4 rounded-lg border border-slate-200 dark:border-slate-700">
                                    <h5 className="text-xs font-bold text-slate-800 dark:text-slate-200 mb-3 flex items-center gap-2">
                                        <Info className="w-4 h-4 text-teal-600" /> The RULE Mnemonic
                                    </h5>
                                    <div className="grid grid-cols-2 gap-4">
                                        {[
                                            { l: 'R', t: 'Resist', d: 'telling patients what to do' },
                                            { l: 'U', t: 'Understand', d: 'patient motivators' },
                                            { l: 'L', t: 'Listen', d: 'to your patient' },
                                            { l: 'E', t: 'Empower', d: 'patient decisions' }
                                        ].map(item => (
                                            <div key={item.l}>
                                                <div className="text-[10px] font-black text-teal-600 dark:text-teal-400 uppercase">{item.l}: {item.t}</div>
                                                <div className="text-[10px] text-slate-500 dark:text-slate-400 leading-tight">{item.d}</div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        </ClinicalCard>

                        <ClinicalCard title="BATHE Protocol">
                            <div className="space-y-4">
                                <div className="bg-rose-50/50 dark:bg-rose-900/10 p-4 rounded-lg border border-rose-100 dark:border-rose-900/30">
                                    <p className="text-[10px] text-rose-800 dark:text-rose-300 font-medium mb-4">A 15-minute intervention for eliciting stressors and validating emotions.</p>
                                    <div className="space-y-4">
                                        {[
                                            { l: 'B', t: 'Background', d: 'Elicit stressors: "You seem upset; what\'s going on in your life?"' },
                                            { l: 'A', t: 'Affect', d: 'Identify feelings: "How do you feel about it?"' },
                                            { l: 'T', t: 'Troubles', d: 'Manageable part: "What troubles you most about this?"' },
                                            { l: 'H', t: 'Handling', d: 'Assess coping: "How are you handling this?"' },
                                            { l: 'E', t: 'Empathy', d: 'Validate: "That sounds very difficult for you."' }
                                        ].map(item => (
                                            <div key={item.l} className="flex gap-4 items-start">
                                                <div className="w-8 h-8 flex-none bg-rose-500 text-white rounded-full flex items-center justify-center font-black text-sm shadow-sm">{item.l}</div>
                                                <div>
                                                    <div className="text-xs font-bold text-rose-900 dark:text-rose-200 uppercase tracking-tight">{item.t}</div>
                                                    <p className="text-xs text-rose-800 dark:text-rose-300 italic">"{item.d.split(': ')[1]}"</p>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            </div>
                        </ClinicalCard>
                    </div>
                )}

                {activeSubTab === 'visuals' && (
                    <div className="space-y-6 animate-in fade-in">
                        <ClinicalCard title="Standard Drink Equivalents">
                            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                <div className="flex flex-col items-center p-3 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-100 dark:border-slate-800">
                                    <Beer className="w-8 h-8 text-amber-500 mb-2" />
                                    <span className="text-xs font-bold">12 oz Beer</span>
                                    <span className="text-[10px] text-slate-400">~5% Alcohol</span>
                                </div>
                                <div className="flex flex-col items-center p-3 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-100 dark:border-slate-800">
                                    <Wine className="w-8 h-8 text-rose-500 mb-2" />
                                    <span className="text-xs font-bold">5 oz Wine</span>
                                    <span className="text-[10px] text-slate-400">~12% Alcohol</span>
                                </div>
                                <div className="flex flex-col items-center p-3 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-100 dark:border-slate-800">
                                    <GlassWater className="w-8 h-8 text-blue-400 mb-2" />
                                    <span className="text-xs font-bold">1.5 oz Spirits</span>
                                    <span className="text-[10px] text-slate-400">~40% Alcohol</span>
                                </div>
                                <div className="flex flex-col items-center p-3 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-100 dark:border-slate-800">
                                    <Wine className="w-8 h-8 text-teal-500 mb-2" />
                                    <span className="text-xs font-bold">8-9 oz Malt</span>
                                    <span className="text-[10px] text-slate-400">~7% Alcohol</span>
                                </div>
                            </div>
                        </ClinicalCard>

                        <ClinicalCard title="Drug Quantity Guides (Common Metrics)">
                            <div className="space-y-4">
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    <div className="flex gap-4 p-3 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-100 dark:border-slate-800">
                                        <Package className="w-10 h-10 text-slate-400" />
                                        <div>
                                            <h6 className="text-xs font-bold">Heroin / Powder Metrics</h6>
                                            <ul className="text-[10px] text-slate-500 mt-1 space-y-1">
                                                <li>• <strong>"Bag/Baggie"</strong> = $5-20 (~0.05g / 50mg)</li>
                                                <li>• <strong>"Point"</strong> = 0.1g (~$10-20)</li>
                                                <li>• <strong>"Bundle"</strong> = 10 bags/packets</li>
                                                <li>• <strong>"Gram"</strong> = 20 bags or 10 points</li>
                                            </ul>
                                        </div>
                                    </div>
                                    <div className="flex gap-4 p-3 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-100 dark:border-slate-800 border-l-rose-500 border-l-2">
                                        <Zap className="w-10 h-10 text-rose-500" />
                                        <div>
                                            <h6 className="text-xs font-bold">Clinical Pearl: Target Dosing</h6>
                                            <p className="text-[10px] text-slate-500 mt-1 leading-relaxed">
                                                Ask patients how many bags it takes to <strong>"get well"</strong> (stop withdrawal).
                                                1 bag is roughly 3 MME, but variability is extremely high.
                                            </p>
                                        </div>
                                    </div>
                                    <div className="flex gap-4 p-3 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-100 dark:border-slate-800">
                                        <DollarSign className="w-10 h-10 text-emerald-500" />
                                        <div>
                                            <h6 className="text-xs font-bold">Prescription & Alt Values</h6>
                                            <ul className="text-[10px] text-slate-500 mt-1 space-y-1">
                                                <li>• <strong>Buprenorphine dose</strong>: ~$10 street value</li>
                                                <li>• <strong>Prescription Opioids</strong>: Often significantly more expensive than street heroin/fentanyl.</li>
                                            </ul>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </ClinicalCard>
                    </div>
                )}

                {activeSubTab === 'dast' && (
                    <div className="flex flex-col items-center justify-center h-full text-slate-400 py-12">
                        <AlertCircle className="w-12 h-12 mb-4 opacity-50" />
                        <span className="text-sm font-medium">DAST-10 Tool Implementation in Progress</span>
                    </div>
                )}

                {activeSubTab === 'audit' && (
                    <div className="flex flex-col items-center justify-center h-full text-slate-400 py-12">
                        <ShieldAlert className="w-12 h-12 mb-4 opacity-50" />
                        <span className="text-sm font-medium">AUDIT Tool Implementation in Progress</span>
                    </div>
                )}
            </div>
        </div>
    );
};
