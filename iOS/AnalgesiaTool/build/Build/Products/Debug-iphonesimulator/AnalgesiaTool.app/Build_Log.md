# Build Log: Inpatient Opioid Tool

## v6.12.7 - OUD Protocol Refinement

**Date:** Jan 9, 2026
**Focus:** Safety Gates & Evidence Alignment

* **Clinical Logic (`ClinicalData.swift`)**:
  * **Micro-Induction Threshold**: Fentanyl induction now only triggers Micro-Induction if COWS < 13.
  * **Safety Gates Removed**: removed "Liver Failure" and "Acute Pain" as contraindications for Buprenorphine; they now map to Standard Induction (Safe).
  * **Pregnancy Management**: Updated standard of care to "Buprenorphine/Naloxone (Suboxone)" (Combo preferred over Mono).
  * **Terminology**: Renamed "Macrodosing" to "High-Dose Initiation" for ER/Inpatient contexts.
* **Aberrant Behavior Protocol (ASCO vs CDC)**:
  * **Interactive Module**: Created `AberrantBehaviorView` for responding to yellow/red flags.
  * **Cancer Context**: Implemented logic bifurcation for Yellow Flags:
    * **Cancer**: "Restructure (No Taper)" (ASCO 2016/NCCN 2025).
    * **Non-Cancer**: "Tighten & Consider Taper" (CDC 2022).
  * **Integration**: Auto-detects context from Assessment indication (`.cancer`).
* **Testing (`ClinicalValidationEngine`)**:
  * Updated Test Cases O1-O10 to reflect the new logic (O2 Fentanyl Micro threshold, O6/O7 Safety).

## v6.12.6 - Fentanyl Conversion Update

**Date:** Jan 9, 2026
**Focus:** Guideline Alignment (NCCN/FDA)

* **Conversion Logic**:
  * **Fentanyl Transdermal**: Updated conversion factor from 2.4 to **2.0** (25 mcg/hr = 50 MME) to match NCCN 2025 and FDA guidelines.
  * **Data Source**: Updated `drug_database.json` with new factor and "High" evidence quality source.
* **Validation**:
  * Updated Test Case **M2** to expect 50 MME (±1.0).

## v6.12.5 - Clinical Guideline Overhaul

**Date:** Jan 9, 2026
**Focus:** CPG Updates (Pericarditis, Gout, PCA)

* **Protocols**:
  * **Pericarditis**: Added Colchicine + Aspirin/NSAID regimens; updated corticosteroid warnings.
  * **Gout**: Updated acute flare management (Colchicine loading dose, Prednisone alternative).
  * **PCA Logic**: Refined demand dose/lockout intervals based on latest safety data.
* **Drip Logic**:
  * **Hydromorphone/Fentanyl**: Refined conversion factors for continuous infusions.
  * **Monitoring**: Added specific PRODIGY-based monitoring triggers for high-risk profiles.

## v6.12.0 - PRODIGY & Drug Database

**Date:** Jan 4, 2026
**Focus:** Risk Stratification & Data Architecture

* **Risk Engine**:
  * **PRODIGY Score**: Corrected point values for Male sex and CHF to align with Khanna et al.
  * **Validation**: Added regression tests for PRODIGY scoring.
* **Architecture**:
  * **Drug Database**: Migrated hardcoded drug data to `drug_database.json` for centralized management.
  * **Infusion Logic**: Implemented `InfusionDuration` to distinguish between Acute (0.3x) and Continuous (0.12x) Fentanyl factors.

## v6.11.0 - Library & Search Enhancements

**Date:** Jan 7, 2026
**Focus:** Usability & Metadata

* **Features**:
  * **Tag Integration**: Integrated drug tags (e.g., "Full Agonist", "Safe in Renal Failure") into the library search engine.
  * **Visual Badges**: Added color-coded badges to drug reference cards for quick safety identification.

## v6.10.1 - Calculator Architecture Refactor

**Date:** Jan 4, 2026
**Focus:** Data Safety & Sandbox Isolation

* **Refactor**:
  * **Decoupled Stores**: Implemented `CalculatorInputs` protocol to decouple `CalculatorStore` from the global `AssessmentStore`.
  * **Transactional Logic**: Calculator now operates as a true sandbox (inputs seed from Assessment but never write back), preventing cross-patient state contamination.

## v6.10.0 - Safety Gates Implementation

**Date:** Jan 4, 2026
**Focus:** Critical Safety Controls

* **Safety Gates**:
  * **Pediatric Lock**: Hard stop interface for patients < 18 years old.
  * **Dirty State Checks**: Implemented tab switching warnings to prevent accidental data loss.
  * **Reset Controls**: Added global "Reset" functionality to clear the active assessment.

## v6.9.0 - UI "Clinical Modern" Overhaul

**Date:** Dec 31, 2025
**Focus:** Aesthetic Alignment & Code Cleanup

* **UI Design**:
  * **Theme Update**: Aligned iOS app with the "Clinical Modern" web aesthetic (Tea/Green palette, clean typography).
  * **Component Refactor**: Updated `CalculatorView` and `Theme.swift` to use the new design system.
* **Codebase Hygiene**:
  * Removed dead code/artifacts from legacy implementations.
  * Cleaned up `ReferenceItem` naming conflicts (`ClinicalReferenceItem`).

## v6.8.0 - Codebase Hygiene & Build Stabilization

**Date:** Dec 18, 2025
**Focus:** Build Repair & Debt Reduction

* **Stabilization**:
  * **Build Fixes**: Resolved critical compilation errors (unbalanced braces, unescaped characters) that were preventing successful builds.
  * **Dead Code Removal**: Aggressively pruned unused legacy files and functions to reduce technical debt.
  * **Syntax Corrections**: Fixed syntax errors across the core module to ensure a clean "Zero-Warning" build state.
