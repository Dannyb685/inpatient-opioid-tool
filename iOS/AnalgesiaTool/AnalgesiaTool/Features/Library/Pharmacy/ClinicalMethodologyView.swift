import SwiftUI

struct ClinicalMethodologyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Clinical Methodology")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(ClinicalTheme.teal500)
                    
                    Text("Evidence-based logic validation and citation registry.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 16)
                
                // 1. OPIOID CONVERSION LOGIC
                MethodologySection(
                    title: "Opioid Conversion Logic & Rare Opioids",
                    icon: "arrow.triangle.2.circlepath",
                    content: """
The calculator’s opioid conversion logic is rigorously aligned with the most current (2024–2026) recommendations from the United States Centers for Disease Control and Prevention (CDC), the Department of Veterans Affairs (VA), the Food and Drug Administration (FDA), the American Society of Clinical Oncology (ASCO), and the NIH HEAL MME calculator. For all major opioids, including methadone, fentanyl, sufentanil, alfentanil, and oxymorphone (IV and PO), the calculator implements validated conversion ratios and nonlinear logic, with explicit safety alerts for high-risk scenarios and edge cases.

**Methadone Conversion**
Methadone conversion is handled with particular care due to its nonlinear pharmacokinetics and variable potency at different dose ranges. The calculator uses a variable oral morphine to oral methadone conversion ratio, increasing as the baseline morphine dose increases:
• 2:1 for < 30 mg morphine/day
• 4:1 for 31–99 mg/day
• 8:1 for 100–299 mg/day
• 12:1 for 300–499 mg/day
• 15:1 for 500–999 mg/day
• 20:1 for 1000–1200 mg/day

Expert consultation is recommended for doses above 1200 mg/day. This approach is directly concordant with the VA and FDA guidelines, which emphasize the risk of fatal respiratory depression if methadone is overestimated. The calculator also enforces a 2:1 oral to IV methadone conversion ratio (FDA labeling) and warns that these ratios are not bidirectional.

**Fentanyl**
The calculator implements a **dual-factor logic** for Fentanyl to account for pharmacokinetic differences between acute and steady-state administration:
• **Acute/Bolus (IV):** 0.3 factor (100 mcg = 10 mg Morphine ≈ 30 MME)
• **Continuous Infusion (IV):** 0.12 factor (Steady-state accumulation model, NCCN 2025). This accounts for significant redistribution and context-sensitive half-life.
• **Transdermal:** 2.4 factor, with alerts for heat-induced absorption.

**Sufentanil & Alfentanil**
Mapped using NIH HEAL MME calculator factors:
• Sufentanil: 500–1000x potency of morphine.
• Alfentanil: 10–20x potency of morphine.
Explicit warnings note these are not validated for chronic pain and require ICU-level monitoring.

**Rare Opioids**
• **Oxymorphone:** 3:1 (Oral) and 10:1 (IV to Oral) ratios.
• **Levorphanol:** 12–15x potency of morphine (Oral), with accumulation warnings.
• **Tapentadol:** 0.4 conversion factor.
• **Buprenorphine:** Excluded from MME calculations for pain (ceiling effect).
"""
                )
                
                // 2. RISK SCORING
                MethodologySection(
                    title: "Risk Scoring & Safety Logic",
                    icon: "exclamationmark.triangle.fill",
                    content: """
The calculator’s risk scoring system is a unique hybrid of the **PRODIGY** and **RIOSORD** models, designed to capture both acute and chronic risk factors for opioid-induced respiratory depression (OIRD) and overdose.

**PRODIGY Score (Acute Risk)**
• Age ≥60 (Highest Weight)
• Male Sex
• Sleep-Disordered Breathing
• Opioid Naivety
• Chronic Heart Failure

**RIOSORD Score (Chronic/Overdose Risk)**
• High-dose opioid therapy (≥100 MME)
• Substance Use Disorder / History of Overdose (Highest Weight)
• Renal Impairment
• Active Psychiatric Conditions
• Benzodiazepine Co-prescription

The calculator assigns patients to the highest risk category identified by either model. High-risk patients trigger mandatory monitoring alerts (Continuous Capnography/Pulse Oximetry).

**Reference Table (RIOSORD)**
Please refer to *Babu et al. (NEJM 2019)* for the detailed breakdown of the RIOSORD risk index.
"""
                )
                
                // 3. INFUSION LOGIC
                MethodologySection(
                    title: "PCA & Continuous Infusion Logic",
                    icon: "ivfluid.bag.fill",
                    content: """
**PCA Validated Settings**
• **Bolus Doses:** Restricted to 1mg (Morphine) equivalents for naive patients.
• **Lockout:** Standard 6-minute lockout (FDA/APS/ASA).
• **Basal Rates:** Default to 0 for opioid-naive patients. Strict warnings for OSA/Obesity.

**Continuous Drips**
• **Start Low:** Recommendations for lowest effective dose.
• **Renal Safety:** Morphine flagged for metabolite accumulation; Fentanyl preferred in renal failure.
• **Monitoring:** Continuous monitoring required for OSA, Naive, or Renal Impairment.
"""
                )
                
                // 4. REFERENCES
                VStack(alignment: .leading, spacing: 12) {
                    Text("References")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ClinicalTheme.teal500)
                    
                    ForEach(references, id: \.self) { ref in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(ref)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(12)
                
            }
            .padding()
        }
        .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Components
    struct MethodologySection: View {
        let title: String
        let icon: String
        let content: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(ClinicalTheme.teal500)
                        .font(.title3)
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(ClinicalTheme.textPrimary)
                }
                
                Text(content)
                    .font(.body)
                    .foregroundColor(ClinicalTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Data
    let references = [
        "1. CDC Clinical Practice Guideline for Prescribing Opioids for Pain - United States, 2022. Dowell D, et al. MMWR 2022;71(3):1-95.",
        "2. VA/DoD Clinical Practice Guideline for the Use of Opioids in the Management of Chronic Pain (2022).",
        "3. FDA Drug Safety Communication. Methadone Hydrochloride (2025).",
        "4. FDA Drug Safety Communication. Oxymorphone Hydrochloride (2025).",
        "5. FDA Drug Safety Communication. Levorphanol Tartrate (2025).",
        "6. FDA Drug Safety Communication. Nalbuphine hydrochloride (2025).",
        "7. NIH HEAL Initiative. Standardizing Research Methods for Opioid Dose Comparison: The NIH HEAL MME Calculator. Pain 2025.",
        "8. Becker WC, et al. Buprenorphine vs High-Dose Opioids for Chronic Pain: A Randomized Clinical Trial. JAMA Intern Med 2025.",
        "9. Smith H, et al. Implications of Opioid Analgesia for Medically Complicated Patients. Drugs & Aging 2010.",
        "10. Grafenreed-Freeman KM, et al. Validation of PRODIGY vs RIOSORD in Hospitalized Patients. AJHP 2025.",
        "11. Dunham JR, et al. RIOSORD Validation in Active Duty Military. Pain Medicine 2022.",
        "12. Babu KM, et al. Prevention of Opioid Overdose (RIOSORD Table 1). NEJM 2019;380(23):2246-2255.",
        "13. ASAM National Practice Guideline on Benzodiazepine Tapering (2025).",
        "14. Weber LM, et al. Implementation of Standard Order Sets for Patient-Controlled Analgesia. AJHP 2008.",
        "15. Sidebotham D, et al. The Safety and Utilization of Patient-Controlled Analgesia. J Pain Symptom Manage 1997."
    ]
}
