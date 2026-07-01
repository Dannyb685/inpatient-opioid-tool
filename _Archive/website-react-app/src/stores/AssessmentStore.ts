import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

// --- Types ---
export type RenalFunction = 'normal' | 'impaired' | 'dialysis' | null;
export type HepaticFunction = 'normal' | 'impaired' | 'failure' | null;
export type HemoStatus = 'stable' | 'unstable' | null;
export type PainType = 'nociceptive' | 'neuropathic' | 'inflammatory' | 'bone' | null;
export type ClinicalIndication = 'standard' | 'dyspnea' | 'cancer_pain' | null;
export type RoutePreference = 'iv' | 'po' | 'both' | 'either' | null;
export type GIStatus = 'intact' | 'tube' | 'npo' | null;
export type Sex = 'male' | 'female' | null;
export type RiskTier = 'Low' | 'Intermediate' | 'High';

interface PatientAssessmentState {
    // Demographics
    age: string;
    sex: Sex;
    opioidNaive: boolean;
    homeBuprenorphine: boolean; // MAT

    // Clinical Parameters
    renalFunction: RenalFunction;
    hepaticFunction: HepaticFunction;
    hemoStatus: HemoStatus;
    painType: PainType;
    indication: ClinicalIndication;
    routePreference: RoutePreference;
    giStatus: GIStatus;
    organSupport: boolean;

    // Risk Factors (PRODIGY + Custom)
    sleepApnea: boolean;
    chf: boolean;
    copd: boolean;
    benzos: boolean;
    psychHistory: boolean;
    historyOverdose: boolean;

    // Computed / Output State (Optional - can be derived in components, but storing allows easy access)
    prodigyScore: number;
    prodigyRisk: RiskTier;

    // Actions
    setAge: (age: string) => void;
    setSex: (sex: Sex) => void;
    setOpioidNaive: (naive: boolean) => void;
    setHomeBuprenorphine: (mat: boolean) => void;

    setRenalFunction: (status: RenalFunction) => void;
    setHepaticFunction: (status: HepaticFunction) => void;
    setHemoStatus: (status: HemoStatus) => void;
    setPainType: (type: PainType) => void;
    setIndication: (indication: ClinicalIndication) => void;
    setRoutePreference: (route: RoutePreference) => void;
    setGiStatus: (status: GIStatus) => void;
    setOrganSupport: (active: boolean) => void;

    setSleepApnea: (active: boolean) => void;
    setChf: (active: boolean) => void;
    setCopd: (active: boolean) => void;
    setBenzos: (active: boolean) => void;
    setPsychHistory: (active: boolean) => void;
    setHistoryOverdose: (active: boolean) => void;

    // Calculation Logic (can be called by components or middleware)
    updateProdigyScore: () => void;
    reset: () => void;
}

export const useAssessmentStore = create<PatientAssessmentState>()(
    devtools(
        (set, get) => ({
            // Defaults
            age: '',
            sex: null as Sex,
            opioidNaive: false,
            homeBuprenorphine: false,

            renalFunction: null as RenalFunction,
            hepaticFunction: null as HepaticFunction,
            hemoStatus: null as HemoStatus,
            painType: null as PainType,
            indication: null as ClinicalIndication,
            routePreference: null as RoutePreference,
            giStatus: null as GIStatus,
            organSupport: false,

            sleepApnea: false,
            chf: false,
            copd: false,
            benzos: false,
            psychHistory: false,
            historyOverdose: false,

            prodigyScore: 0,
            prodigyRisk: 'Low',

            // Setters
            setAge: (age) => {
                set({ age });
                get().updateProdigyScore();
            },
            setSex: (sex) => {
                set({ sex });
                get().updateProdigyScore();
            },
            setOpioidNaive: (opioidNaive) => {
                set({ opioidNaive });
                get().updateProdigyScore();
            },
            setHomeBuprenorphine: (homeBuprenorphine) => set({ homeBuprenorphine }),

            setRenalFunction: (renalFunction) => {
                set({ renalFunction });
                get().updateProdigyScore();
            },
            setHepaticFunction: (hepaticFunction) => {
                set({ hepaticFunction });
                get().updateProdigyScore();
            },
            setHemoStatus: (hemoStatus) => set({ hemoStatus }),
            setPainType: (painType) => set({ painType }),
            setIndication: (indication) => set({ indication }),
            setRoutePreference: (routePreference) => set({ routePreference }),
            setGiStatus: (giStatus) => set({ giStatus }),
            setOrganSupport: (organSupport) => set({ organSupport }),

            setSleepApnea: (sleepApnea) => {
                set({ sleepApnea });
                get().updateProdigyScore();
            },
            setChf: (chf) => {
                set({ chf });
                get().updateProdigyScore();
            },
            setCopd: (copd) => {
                set({ copd });
                get().updateProdigyScore();
            },
            setBenzos: (benzos) => {
                set({ benzos });
                get().updateProdigyScore();
            },
            setPsychHistory: (psychHistory) => {
                set({ psychHistory });
                get().updateProdigyScore();
            },
            setHistoryOverdose: (historyOverdose) => {
                set({ historyOverdose });
                get().updateProdigyScore();
            },

            // Canonical PRODIGY + extra-factor scoring (founder-override
            // canonicalization, 2026-07-01; see
            // change_requests/CR-2026-004_oird_prodigy_canonicalization.md).
            // Core PRODIGY factors: Khanna et al., Anesth Analg 2020.
            // Extra factors: venture-specific additions matching the iOS
            // reference implementation.
            //
            // NOT YET IMPLEMENTED on the website: high-dose MME (>=100, +7).
            // This store has no MME/dose state (MME lives in a separate
            // calculator store) — wiring it here needs cross-store plumbing
            // that's out of scope for this fix. Documented gap, not silent.
            updateProdigyScore: () => {
                const s = get();
                let score = 0;

                // 1. Age
                const ageNum = parseInt(s.age);
                if (!isNaN(ageNum)) {
                    if (ageNum >= 80) score += 16;
                    else if (ageNum >= 70) score += 12;
                    else if (ageNum >= 60) score += 8;
                }

                // 2. Sex
                if (s.sex === 'male') score += 8;

                // 3. Opioid-naive
                if (s.opioidNaive) score += 3;

                // 4. Sleep Apnea (OSA)
                if (s.sleepApnea) score += 5;

                // 5. CHF
                if (s.chf) score += 7;

                // 6. Concurrent benzodiazepines (extra factor)
                if (s.benzos) score += 9;

                // 7. COPD (extra factor)
                if (s.copd) score += 5;

                // 8. Psychiatric history (extra factor)
                if (s.psychHistory) score += 10;

                // 9. History of overdose/SUD (extra factor)
                if (s.historyOverdose) score += 25;

                // 10. Renal impairment (extra factor) — any tier beyond normal
                if (s.renalFunction === 'impaired' || s.renalFunction === 'dialysis') score += 8;

                // 11. Hepatic failure (extra factor) — Child-Pugh C only, not "impaired"
                if (s.hepaticFunction === 'failure') score += 7;

                // Determine Tier (Low <8, Intermediate 8-14, High >=15 — Khanna et al. 2020)
                let risk: RiskTier = 'Low';
                if (score >= 15) risk = 'High';
                else if (score >= 8) risk = 'Intermediate';

                set({ prodigyScore: score, prodigyRisk: risk });
            },

            reset: () => set({
                age: '', sex: null, opioidNaive: false, homeBuprenorphine: false,
                renalFunction: null, hepaticFunction: null, hemoStatus: null, painType: null,
                indication: null, routePreference: null, giStatus: null, organSupport: false,
                sleepApnea: false, chf: false, copd: false, benzos: false, psychHistory: false,
                historyOverdose: false,
                prodigyScore: 0, prodigyRisk: 'Low'
            })
        })
    )
);
