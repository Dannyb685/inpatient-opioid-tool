# Clinical Intelligence Architecture & Logic Protocol

## Executive Summary (v7.2+)

The application employs a **Stateless Clinical Engine** designed for high-stakes inpatient environments. This document serves as the technical and clinical reference for the logic governing calculations, safety gates, and data synchronization.

### Core Principles

1. **Global Source of Truth (`AssessmentStore`):** The definitive clinical session for the active patient.
2. **Transactional Sandbox (`CalculatorStore`):** A transient workspace for "What-If" scenarios that auto-seeds from the Assessment but **NEVER** writes back.
3. **Strict Validation (`ClinicalValidationEngine`):** A centralized logic gate that enforces CDC 2022 and NCCN 2025 guidelines.

---

## 1. System Architecture

### The Sandbox Model

To prevent stale data errors (e.g., calculating a dose for Patient A using Patient B's physiology), the app enforces a strict synchronization protocol:

- **Seed Phase:** On initialization, child stores (Calculator, OUD) pull `age`, `renalStatus`, and `hepaticStatus` from the `AssessmentStore`.
- **Isolation:** Users may modify physiology locally within the Calculator to test scenarios.
- **Destruction:** On exiting a feature (pop view), the local sandbox is destroyed. No data is saved to disk or written back to the global profile.

---

## 2. Dynamic Assessment & Safe Defaults

The application utilizes a single, unified assessment workflow designed to provide immediate feedback based on available patient data.

### The "Safe Default" Model

To ensure operational speed in acute settings, the clinical engine is designed to function even when certain data points are missing:

- **Default State:** Any field not explicitly modified defaults to a "Healthy" or "Not Affected" state (e.g., Normal Renal Function, No Sleep Apnea, Not Pregnant).
- **Asymmetric Validation:** While the engine works with minimal data (e.g., just Age and Renal Function), it proactively alerts the user when "Synergistic Threats" are detected as more data is added (e.g., adding OSA to a patient on Benzos).
- **Geriatric/Pediatric Persistence:** Core safety rules (geriatric dose reductions and pediatric contraindications) remain active at all times because Age is a baseline required input.

---

## 3. Risk Scoring & Monitoring

### OIRD / PRODIGY Integration

The engine calculates a composite **Post-Op Respiratory Index** (OIRD) using weighted parameters:

- **Age ≥ 80:** +16 pts (70-79: +12, 60-69: +8)
- **History of Overdose:** +25 pts
- **Concurrent Benzos:** +9 pts
- **Sleep Apnea (OSA) / CHF / COPD:** +5 pts each
- **Psychiatric History:** +10 pts
- **Renal Impairment:** +8 pts / **Hepatic Failure:** +7 pts

**Tiers:**

- **High Risk (Score > 15):** Mandatory Continuous Capnography Bundle.
- **Moderate Risk (Score 10-15):** Pulse Oximetry Bundle.
- **Low Risk (< 10):** Routine intermittent monitoring.

---

## 4. Equianalgesic Algorithms (MME)

The engine uses a tiered conversion database (`drug_database.json`) aligned with **NCCN 2025** and **CDC 2022** standards.

### MME Conversion Ratios (Reference Table)

| Opioid | Route | Factor (MME) | Clinical Context/Rationale |
| :--- | :--- | :---: | :--- |
| **Morphine** | PO | 1.0 | Reference Standard. |
| **Morphine** | IV | 3.0 | Chronic dosing ratio (1:3 IV:PO). |
| **Oxycodone** | PO | 1.5 | Consistent across all professional guidelines. |
| **Hydromorphone** | PO | 4.0 | CDC Standard (7.5mg HM = 30 MME). |
| **Hydromorphone** | IV | 15.0 | Adjusted from 20 to 15 for safety (Reddy 2017). |
| **Fentanyl** | IV (Acute) | 0.3 | 100mcg Fentanyl ≈ 10mg IV Morphine (Bolus). |
| **Fentanyl** | IV (Cont.) | 0.12 | Steady-state ratio (250mcg Fent = 10mg IV Mor). |
| **Fentanyl** | Patch | 2.0 | 50 mcg/hr Patch ≈ 100 MME/day. |
| **Hydrocodone** | PO | 1.0 | Standard 1:1 with Morphine. |
| **Tramadol** | PO | 0.2 | CDC 2022 Standard. |
| **Methadone** | PO | 4.7 | **Risk Stratification ONLY.** |

### Temporal Accumulation (Fentanyl)

The engine differentiates between **IV Bolus** and **IV Continuous Infusion**.

- **Rule:** If an infusion is >24 hours, the factor drops from **0.3** to **0.12** to account for context-sensitive half-life and tissue accumulation.
- **Rationale:** Fentanyl is highly lipophilic; at steady state, the potency ratio shift is significant to avoid massive MME overestimation.

---

## 5. The Methadone Safety Engine

Methadone conversion is non-linear and governed by a tiered ratio system instead of a fixed MME factor.

### Tiered Conversion Matrix (MME -> Methadone)

| Baseline MME | Ratio (PO) | Reduction | Safety Cap |
| :--- | :---: | :---: | :--- |
| < 30 MME | 2 : 1 | 0% | Fixed Start (2.5mg TID) |
| 31 - 100 MME | 4 : 1 | 0% | NCCN Conservative |
| 101 - 300 MME | 8 : 1 | 0% | APS Standard |
| 301 - 500 MME | 12 : 1 | 30% | VA/DoD Protocol |
| 501 - 1000 MME | 15 : 1 | 50% | High-Dose Caution |
| > 1000 MME | 20 : 1 | 75% | APS Absolute Max |

---

## 6. Logic Synchronization Map (Auto-Adjustments)

The engine applies automatic safety reductions based on the patient's physiology.

### Organ Function & Geriatric Adjustments

| Drug | Scenario | Action | Logic Rationale |
| :--- | :--- | :--- | :--- |
| **Morphine** | Renal < 30 | **BLOCK** | Accumulation of neurotoxic (M3G/M6G) metabolites. |
| **Morphine** | Renal 30-60 | -25% | Relative caution; start low. |
| **Hydromorphone** | Renal < 30 | -50% | Metabolite (H3G) seizure risk. |
| **Hydromorphone** | Hepatic C | **CONSULT** | PO routes contraindicated due to loss of first-pass effect (shunting). |
| **Oxycodone** | Renal Failure | -25% | Reduced clearance of parent and metabolites. |
| **General** | Hepatic C | -50% | Impaired hepatic clearance for all except Fentanyl. |
| **General** | Age 60-79 | -25% | Standard Geriatric safety buffer. |
| **General** | Age 80+ | -50% | High-risk Geriatric safety buffer. |

---

## 7. Clinical Safety Gates (Red Hat Protocol)

Red Hat tests are hard-coded validation rules that trigger critical alerts or remove drugs from recommendation lists.

- **RH1 (Renal Failure):** Hard block on Morphine, Codeine, and Meperidine if eGFR < 30.
- **RH2 (Hepatic Failure):** Hard block on Methadone if Child-Pugh C or Hepatorenal Syndrome detected.
- **RH3 (Pediatrics):** FDA Black Box block on Codeine and Tramadol if age < 18.
- **RH4 (Pregnancy):** Hard block on NSAIDs (Pericarditis/3rd Trimester) and Codeine/Tramadol. Risk of NAS; requires MFM consultation.
- **RH5 (QTc Risk):** Hard block on Methadone if QTc > 500ms.
- **RH6 (Cross-Tolerance):** Warning triggered if user selects < 25% reduction for an opioid rotation.
- **RH7 (Lactation):** Monitoring warning for Oxycodone and Methadone; secretes in milk. Infant must be screened for sedation and weight gain.

---

## 8. OUD Consult Wizard Intelligence

### Bernese Micro-Induction (Bernese Protocol)

- **Trigger:** Detection of **Fentanyl** as primary substance.
- **Rationale:** Traditional induction in fentanyl-exposed patients carries a 30%+ risk of precipitated withdrawal.
- **Algorithm:** Recommends 0.2mg - 0.5mg SL qday while maintaining low-dose full agonists, doubling SL dose daily.

---

## 9. Key Decision Logs & Rationale (Reviewer Insight)

This section documents critical "Fork-in-the-road" decisions made during development to assist clinical auditors.

### I. The "No Math" Block for Hydromorphone PO (Hepatic C)

- **Problem:** In decompensated liver failure, the liver's "First Pass" metabolism is bypassed due to portosystemic shunting.
- **Decision:** Instead of providing a calculated reduced dose, the app returns **"CONSULT"**.
- **Rationale:** The bioavailability of oral hydromorphone becomes completely unpredictable in shunt physiology. Calculating a dose provides a false sense of security; direct specialist consultation is the only safe standard.

### II. Fentanyl IV Pottency Shift (0.3 vs 0.12)

- **Decision:** Implemented a binary split between "Acute/Bolus" (0.3) and "Continuous/Steady State" (0.12).
- **Rationale:** Standard tables (like the CDC's) use a fixed factor of 0.1 to 0.3. However, anesthesia data shows that context-sensitive half-life significantly increases accumulation. By enforcing the lower 0.12 factor for continuous drips, we prevent dangerous overestimation of tolerance when calculating a patient's baseline MME.

### III. The Sandbox Persistence Policy

- **Decision:** Zero persistence of patient data between sessions.
- **Rationale:**
    1. **PII/HIPAA:** By never saving data to `UserDefaults` or a database, the app remains HIPAA-compliant by design.
    2. **Clinical Safety:** In a "fast-paced" environment, it is common for a clinician to walk from Patient A to Patient B. Persisting a "Renal Failure" status from a previous session is a known failure mode for clinical tools. Forcing a "Fresh Pull" from the Assessment Tab on every entry is a forced cognitive check.

### IV. Removal of Textual Emojis (UI Hygiene)

- **Decision:** Systematic removal of ⚠️, 🚨, and ❌ from clinical text.
- **Rationale:** While emojis feel "modern," they lack clinical rigor and can lead to alert fatigue. The app now relies on **Semantic UI components**:
  - **Rose 500 Backgrounds:** Indicates a Hard Stop/Contraindication.
  - **Amber 500 Symbols:** Indicates a Cautionary Adjustment.
  - **SF Symbols:** Uses standard system icons (`hand.raised.fill`, `exclamationmark.triangle`) for universal recognition among medical users.

### V. Hydromorphone Renal Reduction (50% vs 75%)

- **Decision:** Relaxed the hard block to a 50% reduction for Dialysis patients.
- **Rationale:** Original logic (v4.0) used a 75% reduction (Factor 0.25). Clinical feedback indicated this led to significant under-treatment of pain in the ESRD population. v7.0 uses the more balanced 50% reduction with a strict "Monitor for neurotoxicity" advisory.

### VI. Pregnancy Category Buprenorphine Shift

- **Decision:** Removed "Monoproduct Only" restriction.
- **Rationale:** Updated ACOG/ASAM guidelines now recognize Buprenorphine/Naloxone (Combo) as a safe and effective option in pregnancy. The app no longer forces a shift to Subutex (Bup monoproduct), reflecting current standard of care.

---

## 10. Development & Audit Trail

### ClinicalValidationEngine

- **Stress Testing:** A battery of 40+ clinical scenarios (Red Hat Tests) that the engine must pass on every build.
- **Transparency:** The "Validation Runner" in Settings allows any reviewer to see the engine execute these tests in real-time, providing an "open box" audit of the logic.

### SafetyLogger

- Monitors every "Safety Gate Failure" and "Hard Stop" trigger.
- Operates locally in DEBUG builds to audit clinical logic flows without transmitting PII.
