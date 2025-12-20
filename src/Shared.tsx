import React from 'react';

// --- Shared Components ---

export const ClinicalCard = ({ children, className = "", title, action }: { children: React.ReactNode, className?: string, title?: string, action?: React.ReactNode }) => (
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

export const Badge = ({ type, text }: { type?: string, text: string }) => {
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

export const ParameterBtn = ({ active, onClick, label, sub }: { active: boolean, onClick: () => void, label: string, sub?: string }) => (
    <button
        onClick={onClick}
        className={`w-full text-left p-2 rounded-md border text-xs transition-all ${active
            ? 'bg-teal-50 border-teal-600 text-teal-900 ring-1 ring-teal-600'
            : 'bg-white border-slate-200 text-slate-600 hover:border-teal-400 hover:bg-slate-50'
            }`}
    >
        <div className="font-bold">{label}</div>
        {sub && <div className="text-[9px] opacity-70 mt-0.5 font-medium">{sub}</div>}
    </button>
);
