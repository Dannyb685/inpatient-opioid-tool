import { create } from 'zustand';
import { devtools } from 'zustand/middleware';
import { useAssessmentStore, RenalFunction, HepaticFunction } from './AssessmentStore';

// The Calculator needs its own copy of these for "What-If" scenarios
// that don't corrupt the main patient record.
interface CalculatorState {
    // Inputs
    ivMorphine: number;
    reduction: number;
    infusionRate: number;

    // Local Clinical Context (Seeded from Assessment, but editable locally)
    age: string;
    renalFunction: RenalFunction;
    hepaticFunction: HepaticFunction;

    // UI Flags
    showInfusion: boolean;
    showSafetyCheck: boolean;
    showMethadoneCalc: boolean;

    // Actions
    setIvMorphine: (val: number) => void;
    setReduction: (val: number) => void;
    setInfusionRate: (val: number) => void; // Side effect: updates ivMorphine

    // UI Actions
    toggleInfusion: () => void;
    toggleSafetyCheck: () => void;
    toggleMethadoneCalc: () => void;

    // SAFETY GATES
    seedFromAssessment: () => void;
    reset: () => void;
}

export const useCalculatorStore = create<CalculatorState>()(
    devtools(
        (set, get) => ({
            ivMorphine: 10,
            reduction: 30,
            infusionRate: 0,

            age: '',
            renalFunction: null as RenalFunction,
            hepaticFunction: null as HepaticFunction,

            showInfusion: false,
            showSafetyCheck: false,
            showMethadoneCalc: false,

            setIvMorphine: (ivMorphine) => set({ ivMorphine }),
            setReduction: (reduction) => set({ reduction }),
            setInfusionRate: (rate) => {
                set({ infusionRate: rate, ivMorphine: rate * 24 });
            },

            toggleInfusion: () => set((state) => ({ showInfusion: !state.showInfusion })),
            toggleSafetyCheck: () => set((state) => ({ showSafetyCheck: !state.showSafetyCheck })),
            toggleMethadoneCalc: () => set((state) => ({ showMethadoneCalc: !state.showMethadoneCalc })),

            seedFromAssessment: () => {
                // Read from the Global Source of Truth (AssessmentStore)
                // This is a one-way sync on entry.
                const assessment = useAssessmentStore.getState();

                set({
                    age: assessment.age,
                    renalFunction: assessment.renalFunction,
                    hepaticFunction: assessment.hepaticFunction
                });

                console.log("Calculator Seeded", { age: assessment.age, renal: assessment.renalFunction });
            },

            reset: () => set({
                ivMorphine: 10, reduction: 30, infusionRate: 0,
                showInfusion: false, showSafetyCheck: false, showMethadoneCalc: false
            })
        })
    )
);
