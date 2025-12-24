# Clinical Logic: Selection & Risk Assessment

The Inpatient Opioid Tool implements validated clinical scoring and consensus guidelines for medication selection, centered around the **Selection & Risk** profile.

## Tool Focus & Scope

To ensure maximum clinical utility and avoid "cognitive sprawl," the tool is strictly focused on **Opioid Use Disorder (OUD)** and **Acute/Chronic Pain Management**.

- **COWS (Opioid Withdrawal)**: Integrated as the primary withdrawal assessment.
- **CIWA-Ar (Alcohol Withdrawal)**: Purposely excluded/removed to maintain procedural clarity within opioid pathways.

## PRODIGY Risk Assessment

The tool incorporates the PRODIGY (PRediction of Opioid-induced respiratory Depression In patients on General medication units) score to identify patients at high risk for opioid-induced respiratory depression (OIRD).

### Scoring Parameters (Validated)

- **Age**:
  - < 60: 0 pts
  - 60-69: +8 pts
  - 70-79: +12 pts
  - ≥ 80: +16 pts
- **Sex**: Male (+8 pts)
- **Opioid Naivety**: +3 pts
- **Sleep Disordered Breathing (SDB)**: +5 pts
- **Chronic Heart Failure (CHF)**: +7 pts

### Risk Stratification (Validated)

- **High Risk (≥ 15 pts)**: High probability of OIRD. Requires continuous capnography + pulse oximetry. Nursing assessment q1h x 6h then q2h.
- **Intermediate Risk (8-14 pts)**: Moderate probability. Consider continuous capnography. Nursing assessment q4h.
- **Low Risk (< 8 pts)**: Standard monitoring.

### Clinical Caveats (CDC & ASCO)

Per CDC and ASCO guidelines, risk stratification tools (like PRODIGY or ORT) demonstrate **limited accuracy** and must never be used in isolation. Clinical judgment and holistic assessment are paramount.

### Substance Use Disorder (SUD) Monitoring

For patients with SUD receiving opioids, clinicians should:

- Increase monitoring frequency (sedation/respiratory status).
- Offer **Naloxone** as a standard safety precaution.
- Coordinate care with addiction specialists.
- Utilize **PDMP (Prescription Drug Monitoring Program)** data alongside screening tools.

## Patient Assessment (Selection & Risk)

The tool utilizes a **1-7 Sequential Assessment Flow** to gather clinical parameters. This numbering provides a clear mental model for clinicians, ensuring all critical safety gates are addressed.

### Sequential Flow

1. **Hemodynamics**: Stability check (Shock vs. Stable).
2. **Renal Function**: eGFR status (Normal, Impaired, Dialysis).
3. **GI / Mental Status**: Oral intake viability (Intact, Tube, NPO/AMS).
4. **Desired Route**: Preferred administration route (**IV/SQ**, **Oral**, **Both**, or **Either**).
5. **Hepatic Function**: Liver status (Normal, Impaired, Failure).
6. **Clinical Scenario**: Contextual goal (Acute, Palliative, Cancer).
7. **Dominant Pathophysiology**: Pain type (Nociceptive, Neuropathic, Inflammatory, Bone).

### Route Selection Logic (Section #4)

The **Desired Route** parameter determines which medication formulations are displayed.

- **IV/SQ**: Recommendations are restricted to parenteral routes.
- **Oral (PO)**: Recommendations are restricted to oral formulations.
- **Both**: Displays recommendations for both IV and Oral routes simultaneously (e.g., for simultaneous IV titration and transition planning).
- **Either**: Displays both routes but adds a preference note: *"Determine based on GI tolerance and required speed of onset."*

### GI / NPO & Route Interaction Logic

- **NPO / AMS**:
  - If the Desired Route is `po`, recommendations are suppressed and a warning is triggered.
  - If the Desired Route is `Both` or `Either`, the tool automatically **filters out** PO options, highlighting only the parenteral candidates while flagging PO as contraindicated.
- **Tube / Dysphagia**: Automatically triggers a "Do Not Crush" warning and suggests liquid formulations if a PO route is active.

### Renal Impairment (eGFR < 30 or Dialysis)

When managing cancer pain or chronic renal impairment, equianalgesic calculations must account for organ-specific pharmacokinetics.

- **First-Line/Preferred**: **Buprenorphine** and **Fentanyl** (short-acting IV). Buprenorphine is non-dialyzable and has simpler kinetics in renal failure compared to Methadone.
- **Alternative Safe**: **Methadone** (fecal excretion profile).
- **Caution**: Hydromorphone, Oxycodone (reduce starting dose by 50% and monitor for slow metabolite accumulation).
- **Strict Avoidance**: **Morphine**, **Codeine**, **Tramadol**, and **Meperidine** (toxic metabolites accumulate rapidly causing neurotoxicity/seizure/sepsis risk).
- **Non-Opioid Restriction**: Strictly avoid **NSAIDs** (Naproxen/Celecoxib) if eGFR < 30 due to nephrotoxicity risk.

### Hepatic Impairment / Failure

- **Preferred**: Fentanyl (safest; no dose adjustment usually needed).
- **Caution**: Hydromorphone (reduce dose 50%).
- **Strict Filter (Avoid)**: **Morphine**, **Codeine**, **Oxycodone**, and **Methadone**.
  - *Rationale*: Oxycodone elimination is significantly impaired (half-life extends from ~3h to ~14h); Morphine/Codeine prodrug failure and toxic metabolite accumulation.
- **Adjuvant Safety (Strict Filters)**:
  - **Duloxetine**: Strictly avoid in hepatic impairment (FDA warning for hepatotoxicity in chronic liver disease).
  - **Acetaminophen**: Strictly cap at **2g/day** in hepatic failure (Child-Pugh C) or 3g in impairment.
  - **NSAIDs**: Avoid in liver failure due to bleeding risk/varices.

### Clinical Scenario Overrides

- **Hemodynamic Instability**: Prioritize Fentanyl (cardiostable, no histamine release). Avoid Morphine.
- **Acute Pain on MAT (Buprenorphine)**: A high-frequency, high-risk scenario.
  - **Strategy**: **Continue basal Home Buprenorphine** (prevent withdrawal) and add a high-affinity full agonist (e.g., **Fentanyl** or **Hydromorphone**) for breakthrough pain.
  - **Hemodynamics**: If unstable, prioritize Fentanyl breakthrough.
- **Palliative Dyspnea**: Morphine (IV) is the gold standard (ATS guidelines).
  - **Logic Gate**: Recommended ONLY if `Renal Function` is "Normal" AND the `Desired Route` is "IV/SQ", "Both", or "Either" (or unspecified).
  - **Renal Impairment**: If impaired, the tool warns against Morphine and suggests Hydromorphone/Fentanyl.
- **Neuropathic Pain**: Methadone is preferred (NMDA antagonism) or use adjuvants (Gabapentinoids, SNRIs).
- **Altered Mental Status (AMS) + NPO/GI Failure**: High-risk. Pivot to IV/Transdermal (typically Fentanyl) with extremely frequent monitoring.
- **Severe Cancer Pain**: Morphine PO is prioritized as a starting point (barring renal failure).

## Progressive Recommendation Flow

To enhance responsiveness and clinical utility, the tool provides guidance as soon as medically reasonable, rather than waiting for all parameters to be selected.

### Key Progressive Logic

- **Immediate Fentanyl Prompt**: If `Hemodynamically Unstable` is selected, Fentanyl is recommended immediately as the cardiostable choice, bypassing the requirement for other organ function data.
- **Safety Gating for Standard Opioids**: Suggestions for Morphine, Hydromorphone, and Oxycodone are suppressed until `Renal Function` is specified to prevent unsafe administration in acute kidney injury or chronic kidney disease.
- **Pathophysiology-Driven Adjuvants**: Adjuvants (e.g., Gabapentin for neuropathic pain, NSAIDs for bone pain) appear as soon as the `Pathophysiology` or `Clinical Scenario` is defined, providing multimodal suggestions even if the primary opioid selection is still pending.

## Non-Opioid Advisory Logic

To reduce clinical noise, safety flags for non-opioids are rendered conditionally based on the patient's organ function.

| Filter | Logic / Triggers |
| :--- | :--- |
| **Max 2g APAP/Tylenol** | Show if `hepatic` is failure. (3g if impaired). |
| **Avoid NSAIDS** | Show if `renal` is impaired/dialysis (Strict blocker for Bone/Inflammatory pain), `hepatic` is failure, OR if `hepatic`/`renal` are both normal (general precaution). |

## Opioid Withdrawal Management (MOUD)

The tool supports both traditional and aggressive induction strategies for Medication-Assisted Treatment (MAT).

### Temple Protocol (Aggressive MOUD)

An aggressive protocol for managing acute withdrawal in hospital settings using full agonists alongside induction targets.

- **Primary Agent**: Oxycodone ER + IR for stabilization.
- **Breakthrough**: Dilaudid (Hydromorphone) for acute spikes.
- **Goal**: Rapidly reach therapeutic levels to prevent AMA discharge.

### Bernese Method (Micro-Induction)

A protocol for transitioning to Buprenorphine without requiring prior withdrawal.

- **Mechanism**: Low-dose Buprenorphine (e.g., 0.2mg - 0.5mg) administered alongside a full agonist.
- **Titration**: Buprenorphine dose is gradually increased as full agonist is tapered, displacing it from receptors without triggering precipitated withdrawal.

## Non-Opioid Clinical Pathways

Structured non-opioid analgesic recommendations for specific clinical presentations:

- **Abdominal Pain**: Prioritize Lidocaine/Ketamine/IV APAP.
- **Back Pain**: Focus on NSAIDs, MSK relaxants, and movement.
- **Sickle Cell Crisis**: Multimodal approach (Ketamine, regional blocks, NSAIDs) to spare opioid use.
- **Neuropathic Pain**: SNRI/Gabapentinoid first-line over opioids.

## Symptom Management (Palliative)

Guidelines for managing common symptoms associated with opioid use and withdrawal:

- **Nausea**: Receptor-based anti-emetics:
  - **Zofran (5-HT3)**: First-line, but check QTc.
  - **Compazine/Haldol (D2)**: Added for gastroparesis or opioid-induced nausea.
  - **Reglan**: For prokinetic effect.
- **Anxiety**: Non-benzodiazepine focus (Hydroxyzine, Quetiapine).
- **Dyspnea**: Low-dose Morphine (first-line) and proper positioning.
  - **Morphine**: 2.5-5mg PO q4h or 1-2mg IV q2-3h. Reduces sensitivity to dyspnea trigger.
  - **Non-Pharm**: Fan or open window (trigeminal nerve stimulation), O2 only for hypoxia.
- **Anorexia**: Megestrol or Mirtazapine guidelines. Small palatable meals over large portions.
- **Secretions**: Atropine/Glycopyrrolate for terminal "death rattle."
  - **Warning**: Avoid deep suction; often more distressing to family than patient.
  - **Atropine 1% drops**: 1-2 SL q1-2h.
  - **Glycopyrrolate**: 0.1-0.2mg IV/SQ q4h.

## Clinical References

- **Fast Facts #109**: Death Rattle and Oral Secretions.
- **Fast Facts #27**: Dyspnea at End-of-Life.
- **JAMA 2007 (Gordon WJ, et al)**: Management of Intractable Nausea...

## Safety Validation & Red Team Scenarios

The tool's logic has been hardened through a "Red Team" safety audit to ensure convergence on safe agents in high-risk multi-organ failure scenarios.

### Audit Scenarios (Validation Targets)

| Scenario | Inputs | Expected Outcome (Clinical Standard) | Code Logic Path |
| :--- | :--- | :--- | :--- |
| **Triple Failure** | Renal: Dialysis Hepatic: Failure Hemo: Unstable | **Fentanyl IV Only** | `hemo === 'unstable'` forces Fentanyl; Hepatic filter strips all toxic PO/Standard options. |
| **Bone/Renal** | Renal: Impaired (GFR<30) Pain: Bone | **Steroids + Tylenol** (NO NSAIDs) | `!isRenalBad` gate strictly blocks NSAID branch in inflammatory/bone pain. |
| **Neuro/Liver** | Hepatic: Failure Pain: Neuropathic | **Gabapentin + Lidocaine** (NO Duloxetine) | `!isHepaticBad` gate blocks SNRIs (Duloxetine). APAP capped at 2g. |

### Logic Convergence Principles

1. **Safety First**: Toxic metabolites (Morphine, Codeine, Tramadol) are filtered early in the logic flow.
2. **Preference Weights**: Fentanyl and Buprenorphine are weighted higher for patients with variable or critical organ function due to simpler pharmacokinetics.
3. **Multi-Step Gating**: Adjuvants are blocked programmatically even if they are the "preferred" treatment for a pain type (e.g., NSAIDs for Bone Pain) if the patient's risk profile (Renal/Hepatic) carries a contraindication.

## Smart Copy Output Format

When clicking "Smart Copy," the tool generates a standardized clinical note for documentation:

```text
Opioid Risk Assessment
----------------------
PRODIGY Score: [Score] ([Tier] RISK)
Monitoring Plan:
- [Nursing Assessments]
- [Monitoring Modalities]
- [Safety Interventions]

Risk Factors:
- [List of active PRODIGY markers]

Clinical Recommendations:
- [Drug Name]: [Reason] ([Guidance Detail])
- [Adjuvant Suggestions]

Warnings/Contraindications:
- [Organ-specific safety alerts]
```
