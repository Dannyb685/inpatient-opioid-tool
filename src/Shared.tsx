import React from 'react';

// --- Shared Components ---

export const ClinicalCard = ({ children, className = "", title, action }: { children: React.ReactNode, className?: string, title?: string, action?: React.ReactNode }) => (
    <div className={`bg-surface-card rounded-2xl border border-border/60 shadow-sm overflow-hidden ${className}`}>
        {title && (
            <div className="px-4 py-3 border-b border-border flex justify-between items-center bg-surface-highlight/50">
                <h3 className="text-xs font-bold text-text-secondary uppercase tracking-wider">{title}</h3>
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
        safe: "bg-surface-highlight text-action border-action-border", // Emerald -> Action (Teal)
        caution: "bg-warning-bg text-warning border-warning",
        unsafe: "bg-danger-bg text-danger border-danger",
        neutral: "bg-surface-highlight text-text-secondary border-border",
        purple: "bg-surface-highlight text-text-primary border-border" // Generic highlighting
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
        className={`w-full text-left p-3 rounded-md border text-xs transition-all ${active
            ? 'bg-action-bg border-action-border text-action ring-1 ring-action-border'
            : 'bg-surface-card border-border text-text-secondary hover:border-action-border hover:bg-surface-highlight'
            }`}
    >
        <div className="font-bold">{label}</div>
        {sub && <div className="text-[9px] opacity-70 mt-0.5 font-medium">{sub}</div>}
    </button>
);
