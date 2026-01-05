# Clinical Data Architecture & State Management

## Executive Summary

The application employs a **Hybrid State Model** defined by three distinct behaviors:

1. **Global Source of Truth (`AssessmentStore`):** The persistent clinical session.
2. **Session-Ephemeral Sandbox (`CalculatorStore`):** A transient workspace that auto-syncs on entry but never writes back.
3. **Strict Isolation (`OUDConsultStore`, `ToolkitStore`):** Completely detached states for distinct clinical workflows.

This architecture prioritizes **Safety** (preventing stale data in the calculator) over **Persistence** (keeping calculator scratchpad data when switching tabs).

---

## 1. Global Session: `AssessmentStore`

**Typology:** App-Wide Singleton (Injected via `@EnvironmentObject`)
**Role:** The definitive "Patient Object."

### Tracked Variables (Exact Implementation)

| Category | Variable | Type | Source |
| :--- | :--- | :--- | :--- |
| **Demographics** | `age` | `String` | User Input (Assessment Tab) |
| | `sex` | `Sex` (Enum) | User Input |
| **Organ Function** | `renalFunction` | `RenalStatus` | User Input |
| | `hepaticFunction` | `HepaticStatus` | User Input |
| **Clinical Profile** | `analgesicProfile` | `AnalgesicProfile` | User Input (Naive, Tolerant, etc.) |
| **Risk Factors** | `isPregnant` | `Bool` | User Input |
| | `sleepApnea` | `Bool` | User Input |
| | `chf` | `Bool` | User Input |
| | `benzos` | `Bool` | User Input |
| | `historyOverdose` | `Bool` | User Input |
| | `qtcProlonged` | `Bool` | User Input |
| **Acute Context** | `painType` | `PainType` | User Input |
| | `indication` | `ClinicalIndication` | User Input |
| | `gi` | `GIStatus` | User Input (Intact, NPO) |

**Write Access:** `RiskAssessmentView` ONLY.
**Read Access:** `LibraryView`, `CalculatorStore` (via Seed), `MainTabView` (via Watcher).

---

## 2. Session-Ephemeral Sandbox: `CalculatorStore`

**Typology:** Tab-Local State Object (`@StateObject`)
**Role:** A safety-critical scratchpad.

### The "Auto-Seed" Mechanism (Strict Sync)

The `MainTabView` manages synchronization to ensure the Calculator never uses stale clinical context.

**Trigger:** `onChange(of: selectedTab)` when entering the Calculator tab.

**Logic Gate:**

1. **Missing Data:** If `AssessmentStore.age` is empty → **Block Access** (Show Alert).
2. **Context Mismatch:** If Calculator has active drugs AND `age` differs → **Prompt User** (Sync or Keep).
3. **Clean Entry (Default):** **AUTO-OVERWRITE**.
    * The `seed(from:)` function is called immediately.
    * **Implication:** Any local changes made to *Renal Function* or *Pregnancy* in the Calculator are **LOST** if you switch tabs and return. This enforces the Calculator as a *downstream* consumer of the Assessment.
    * **Silent Overwrite:** If `age` matches, the system ASSUMES the user wants to sync. It **silently overwrites** `renalStatus`, `hepaticStatus`, etc., with the Global Session values.
    * **UX Tradeoff:** This prevents prompt fatigue (user doesn't confirm every tab switch) but means *local sandbox changes to non-age variables* are lost immediately upon leaving the tab.

### The "Age Trigger" Specificity

* **Trigger Condition:** `CalculatorStore.hasActiveDrugs == true` AND `CalculatorStore.age != AssessmentStore.age`.
* **Why Only Age?** Age is the primary identifier of patient context. A mismatch here strongly implies a *Different Patient*. Mismatches in Renal/Hepatic variables are treated as "stale sandbox state" and are auto-corrected without prompt to ensure safety.

### Synced Variables (Protocol: `CalculatorInputs`)

These variables are overwritten by the Global Session on every "Clean Entry":

* `age` (String) `[New in v4.6]`
* `renalStatus` (`renalFunction`)
* `hepaticStatus` (`hepaticFunction`)
* `painType`
* `isPregnant`
* `analgesicProfile`
* `benzos`, `sleepApnea`, `historyOverdose` (Safety Flags)

### Independent Variables (Pure Sandbox)

These variables exist *only* in the Calculator and are **NEVER** affected by the Assessment Store:

* `inputs` (List of active drugs and doses)
* `routePreference` (IV vs PO)
* `tolerance` (Though initially seeded by profile, can be toggled independently)

---

## 3. Strict Isolation: Workflows

These modules are clinically distinct and **DO NOT** read or write to the Global Session.

### A. OUD Consult (`OUDConsultStore`)

* **Workflow:** Opioid Use Disorder Induction.
* **State:** Completely independent.
* **Variables:** `cowsScore`, `lastUseTime`, `isPregnant` (Local copy), `liverFailure` (Local copy).
* **Rationale:** "Induction Risk" != "Analgesic Risk". A patient may have liver failure affecting Naltrexone induction (OUD) but not Hydromorphone dosing (Pain), though likely correlated, the decision trees are separate.
* **Risk (Known Constraint):** If a user updates `isPregnant` in the Global Session *after* starting an OUD Consult, the OUD module will retain the **stale** value until manually reset.
  * *Mitigation:* Providers are trained to treat OUD Induction as a distinct procedure requiring its own verification.
  * *Future State:* Consider a "Stale Context Watcher" to alert if Global Session divergences are detected.

### B. Clinical Toolkit (`ToolkitStore`)

* **Workflow:** COWS, ORT, PEG, SOS Assessments.
* **State:** Ephemeral (Resets on view dismissal or manual reset).
* **No Dependency:** Does not import `AssessmentStore`.

---

## 4. Head-Up Display: `LibraryView`

**Typology:** Read-Only Observer
**Role:** Contextual Reference.

The Library uses `@EnvironmentObject var store: AssessmentStore` to read state directly for dynamic badging.

**Badging Logic (Real-Time):**

* **Renal Badge:** Checks `store.renalFunction`. If `.dialysis`, Morphine gets a Red Badge.
* **Hepatic Badge:** Checks `store.hepaticFunction`. if `.failure`, Oxycodone gets a Red Badge.
* **Pregnancy Badge:** Checks `store.isPregnant`. Tramadol gets "Avoid".
* **Profile Badge:** Checks `store.analgesicProfile`. Fentanyl Patch gets "Contraindicated" if `.naive`.

---

## 5. Performance & Scalability

**Current Model:** Monolithic Singleton (`AssessmentStore`).

* **Behavior:** `@EnvironmentObject` injection means *any* update to *any* property causes all listening views (like `LibraryView`) to recheck their body.
* **Optimization Trigger:** If typing lag or UI stutter is observed (especially in the Library search).
* **Future Strategy:** Split the singleton into granular stores:
  * `PatientDemographicsStore` (Age, Sex - Low frequency update)
  * `PatientRiskStore` (Renal, Hepatic - Medium frequency)
  * `ClinicalSessionStore` (Acute inputs - High frequency)

---

## 6. UX Safety Implementation Plan

This section translates the architectural risks (Silent Overwrite, isolation) into concrete UX requirements to ensure provider trust and safety.

### Transparency: Assessment Context Flow (Downstream Use)

**Objective:** Increase provider trust by clearly documenting where `AssessmentStore` data is utilized.

* **Implementation:** Create a static "Safety Context Downstream" card in `RiskAssessmentView`.
* **Content:**
  * **MME Calculator (Rotation Safety):** Consumes Age, Renal/Hepatic Status, Benzos, and Analgesic Profile to apply dose-reduction factors and contraindications.
  * **Library (Drug Badging):** Reads Renal/Hepatic Status and Pregnancy flag to apply real-time Red/Amber/Teal safety badges.

### Mitigation: Critical Context Divergence (OUD Watcher)

**Objective:** Mitigate the "Strict Isolation" risk where OUD Consult might hold stale data.

* **Implementation:** In `OUDConsultView.swift`, establish a reactive check on `AssessmentStore` for `isPregnant` and `hepaticFunction`.
* **Alert Logic:** If local OUD state differs from Global Assessment state when view appears:
  * **Action:** Display a **Red, Non-Dismissible Alert Banner**.
  * **Message:** "🔴 CONTEXT MISMATCH DETECTED: Assessment Status has changed since you entered this tab. Please verify all patient variables before proceeding."

### Feedback: Ephemeral Sandbox Indicator (Calculator)

**Objective:** Provide immediate feedback on the Calculator's ephemeral state to manage the "Silent Overwrite" expectation.

* **Implementation:** Add a persistent status bar above the Calculator content.
* **States:**
  * **Default/Clean:** Subtle Label: "Context Sourced from Assessment (Read-Only Safety Profile)."
  * **Dirty/What-If:** Bold Amber Warning: "⚠️ LOCAL SANDBOX MODE. Changes to Renal/Hepatic status will be lost when you leave this tab."

---

## Summary of Data Flow

| Variable | Assessment (Tab 1) | Calculator (Tab 2) | OUD Consult (Tab 3) | Library (Tab 4) |
| :--- | :--- | :--- | :--- | :--- |
| **Patient Age** | **Master (Write)** | Synced Copy (Read-Only*) | Independent Input | Read-Only |
| **Renal Function** | **Master (Write)** | Synced Copy (Read-Only*) | Independent | Read-Only (Badge) |
| **Active Drugs** | N/A | **Master (Write)** | N/A | N/A |
| **COWS Score** | N/A | N/A | **Master (Write)** | **Separate Instance** |

*\*Calculator "Read-Only" means it accepts the Master value on entry. User CAN change it locally for "What-If" scenarios, but these changes are ephemeral and lost on re-sync.*
