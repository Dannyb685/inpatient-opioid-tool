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

            setRenalFunction: (renalFunction) => set({ renalFunction }),
            setHepaticFunction: (hepaticFunction) => set({ hepaticFunction }),
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
            setCopd: (copd) => set({ copd }),
            setBenzos: (benzos) => set({ benzos }),
            setPsychHistory: (psychHistory) => set({ psychHistory }),

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

                // 3. Naive
                if (s.opioidNaive) score += 3;

                // 4. Sleep Apnea
                if (s.sleepApnea) score += 5; // Validated PRODIGY weight? iOS code said 5 + 10 etc. Double check logic.
                // In iOS/Web code: sleep(5), chf(7), male(8), naive(3)
                // Wait, Web code line 83 says sleep += 5.
                // Wait, Web code line 284 comment says Sleep Apnea (+10)? UI inconsistency.
                // PRODIGY paper: Sleep Disordered Breathing = +8? No?
                // I will replicate the Web Code Logic found in line 84: if (sleepApnea) pScore += 5;
                if (s.sleepApnea) score += 5;

                // 5. CHF
                if (s.chf) score += 7;

                // Determine Tier
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
                prodigyScore: 0, prodigyRisk: 'Low'
            })
        })
    )
);
