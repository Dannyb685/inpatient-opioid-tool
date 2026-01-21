import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

// --- Types ---
export interface Question {
    id: string;
    text: string;
    subQuestions?: Question[];
}

// Logic extracted from View
export const assistQuestions: Question[] = [
    {
        id: 'tobacco',
        text: '1. Did you smoke a cigarette containing tobacco?',
        subQuestions: [
            { id: 'tobacco_10', text: '1a. Did you usually smoke more than 10 cigarettes each day?' },
            { id: 'tobacco_30min', text: '1b. Did you usually smoke within 30 minutes after waking?' }
        ]
    },
    {
        id: 'alcohol',
        text: '2. Did you have a drink containing alcohol?',
        subQuestions: [
            { id: 'alcohol_4drinks', text: '2a. On any occasion, did you drink more than 4 standard drinks of alcohol?' },
            { id: 'alcohol_control', text: '2b. Have you tried and failed to control, cut down or stop drinking?' },
            { id: 'alcohol_concern', text: '2c. Has anyone expressed concern about your drinking?' }
        ]
    },
    {
        id: 'cannabis',
        text: '3. Did you use cannabis?',
        subQuestions: [
            { id: 'cannabis_urge', text: '3a. Have you had a strong desire or urge to use cannabis at least once a week or more often?' },
            { id: 'cannabis_concern', text: '3b. Has anyone expressed concern about your use of cannabis?' }
        ]
    },
    {
        id: 'stimulants',
        text: '4. Did you use an amphetamine-type stimulant, or cocaine, or a stimulant medication not as prescribed?',
        subQuestions: [
            { id: 'stimulants_weekly', text: '4a. Did you use a stimulant at least once each week or more often?' },
            { id: 'stimulants_concern', text: '4b. Has anyone expressed concern about your use of a stimulant?' }
        ]
    },
    {
        id: 'sedatives',
        text: '5. Did you use a sedative or sleeping medication not as prescribed?',
        subQuestions: [
            { id: 'sedatives_urge', text: '5a. Have you had a strong desire or urge to use a sedative or sleeping medication at least once a week or more?' },
            { id: 'sedatives_concern', text: '5b. Has anyone expressed concern about your use of a sedative or sleeping medication?' }
        ]
    },
    {
        id: 'opioids',
        text: '6. Did you use a street opioid (e.g. heroin) or an opioid-containing medication not as prescribed?',
        subQuestions: [
            { id: 'opioids_control', text: '6a. Have you tried and failed to control, cut down or stop using an opioid?' },
            { id: 'opioids_concern', text: '6b. Has anyone expressed concern about your use of an opioid?' }
        ]
    },
    {
        id: 'other',
        text: '7. Did you use any other psychoactive substances?'
    }
];

interface SBIRTState {
    // Screening Data
    assistScores: Record<string, boolean>;

    // Actions
    toggleAssistScore: (id: string) => void;
    getScore: (category: string) => number;
    getRiskCategory: (category: string, score: number) => { label: string; color: string };
    reset: () => void;
}

export const useSBIRTStore = create<SBIRTState>()(
    devtools(
        persist(
            (set, get) => ({
                assistScores: {},

                toggleAssistScore: (id) => {
                    set((state) => ({
                        assistScores: {
                            ...state.assistScores,
                            [id]: !state.assistScores[id]
                        }
                    }));
                },

                getScore: (category) => {
                    const { assistScores } = get();
                    let count = 0;
                    if (assistScores[category]) count++;
                    const subQs = assistQuestions.find(q => q.id === category)?.subQuestions;
                    subQs?.forEach(sq => {
                        if (assistScores[sq.id]) count++;
                    });
                    return count;
                },

                getRiskCategory: (category, score) => {
                    if (category === 'alcohol') {
                        if (score <= 1) return { label: 'Low', color: 'text-emerald-600' };
                        if (score === 2) return { label: 'Moderate', color: 'text-amber-600' };
                        return { label: 'High', color: 'text-rose-600' };
                    } else {
                        if (score === 0) return { label: 'Low', color: 'text-emerald-600' };
                        if (score <= 2) return { label: 'Moderate', color: 'text-amber-600' };
                        return { label: 'High', color: 'text-rose-600' };
                    }
                },

                reset: () => set({ assistScores: {} })
            }),
            {
                name: 'sbirt-storage',
            }
        )
    )
);
