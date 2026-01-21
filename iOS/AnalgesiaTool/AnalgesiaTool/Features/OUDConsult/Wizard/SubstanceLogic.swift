import Foundation

// MARK: - 1. Input Models (The "Checkboxes")

enum ProtocolType: String, CaseIterable, Hashable {
    case standardBup       // Short acting, COWS ≥ 12
    case highDoseBup       // ER Setting, High-Dose Initiation
    case microInduction    // (Bernese) Fentanyl or Low COWS/Urgent
    case fullAgonist       // Methadone/Oxy (Liver Failure, Acute Pain)
    case symptomManagement // COWS < 8, no immediate induction
}

enum SubstanceType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    // Street / HPSO (High Potency Synthetic Opioids)
    case streetFentanylPowder = "Street Fentanyl (Powder/Rock)"
    case pressedPills = "Pressed 'M30' Pills (Blues/Fent)"
    case streetHeroin = "Heroin (Black Tar/Powder)"
    case xylazineAdulterant = "Tranq / Xylazine (Suspected)"
    case nitazeneAnalogues = "Nitazenes / Isotonitazene (Synthetic)"
    case benzoDope = "Benzo-Dope (Opioid + Benzo)"
    
    // Benzodiazepines (Concurrent Use)
    case benzodiazepinesPharma = "Benzodiazepines (Pharma: Xanax/Klonopin)"
    case benzodiazepinesStreet = "Street Benzos (Pressed Bars/Bromazolam)"
    
    // Pharmaceutical (Short Acting)
    case oxycodone = "Oxycodone (IR/ER)"
    case hydrocodone = "Hydrocodone"
    case hydromorphone = "Hydromorphone (Dilaudid)"
    
    // Pharmaceutical (Long Acting/Maintenance)
    case methadone = "Methadone"
    case suboxoneStreet = "Street Buprenorphine"
    
    // MARK: - Clinical Intelligence Properties
    
    var isLipophilicOrLongActing: Bool {
        switch self {
        case .streetFentanylPowder, .pressedPills, .methadone, .nitazeneAnalogues, .benzodiazepinesStreet: return true
        case .streetHeroin: return true
        default: return false
        }
    }
    
    /// Identifies substances that cause synergistic respiratory depression.
    var isCNSDepressant: Bool {
        switch self {
        case .benzodiazepinesPharma, .benzodiazepinesStreet, .benzoDope, .xylazineAdulterant:
            return true
        default:
            return false
        }
    }
    
    var withdrawalOnsetWindow: String {
        switch self {
        case .streetFentanylPowder, .pressedPills, .nitazeneAnalogues:
            return "Unpredictable (Delayed): 12-48+ hours (due to lipid storage)"
        case .benzodiazepinesPharma, .benzodiazepinesStreet:
            return "Seizure Risk Window: 1-10 days (Long acting metabolites)"
        case .xylazineAdulterant, .benzoDope:
            return "Non-Opioid: Anxiety/HTN persists despite opioid blockade"
        default:
            return "Variable"
        }
    }
    
    var slangTerms: [String] {
        switch self {
        case .streetFentanylPowder: return ["Fetty", "Powder", "Down"]
        case .pressedPills: return ["Blues", "M30s"]
        case .benzodiazepinesStreet: return ["Bars", "School Busses", "Hulks", "Bromaz"]
        case .benzoDope: return ["Sleepy Dope", "Down"]
        default: return []
        }
    }
    
    var urineScreenDetection: String {
        switch self {
        case .streetFentanylPowder, .pressedPills:
            return "NEGATIVE on standard Opiate screen. Requires Fentanyl assay."
        case .benzodiazepinesStreet, .benzoDope:
            return "NEGATIVE for Benzos often (Bromazolam/Etizolam missed by immunoassays)."
        case .nitazeneAnalogues:
            return "NEGATIVE. Rare/Specialized testing only."
        case .xylazineAdulterant:
            return "NEGATIVE. Requires Xylazine confirmatory testing."
        case .benzodiazepinesPharma:
            return "POSITIVE for Benzodiazepines."
        default:
            return "Standard"
        }
    }
    
    var overdoseReversalProfile: String {
        switch self {
        case .benzodiazepinesPharma, .benzodiazepinesStreet, .benzoDope:
            return "Resistant: Narcan will NOT reverse Benzo coma. Risk of aspiration."
        case .xylazineAdulterant:
            return "Resistant: Sedation is Alpha-2 mediated. Support airway."
        default:
            return "Responsive to Narcan (Dose dependent)."
        }
    }
}

enum RouteOfAdministration: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case intravenous = "IV (Injection)"
    case inhalation = "Inhalation (Smoking/Vaping)"
    case intranasal = "Intranasal (Snorting)"
    case oral = "Oral (Swallowing)"
    case intramuscular = "IM (Muscling)"
}

struct SubstanceEntry: Identifiable, Hashable {
    let id = UUID()
    let type: SubstanceType
    let quantity: Double
    let unit: String
    let route: RouteOfAdministration
    let lastUseHoursAgo: Int
}

// MARK: - 2. Physiology Engine

struct PhysiologyProfile {
    
    enum ToleranceTier {
        case naive, low, high, massive
    }
    
    enum PrecipitatedWDRisk {
        case standard, elevated
    }
    
    enum XylazineRisk {
        case unlikely, possible, high
    }
    
    enum CNSDepressionRisk {
        case standard
        case high // Concurrent Benzos/Alcohol
        case extreme // Benzo-Dope + Xylazine + Fentanyl
    }
    
    let tier: ToleranceTier
    let pwdRisk: PrecipitatedWDRisk
    let xylazine: XylazineRisk
    let cnsRisk: CNSDepressionRisk
    let isPregnant: Bool
    let isBreastfeeding: Bool
    let hasLiverFailure: Bool
    let hasAcutePain: Bool
}

// MARK: - 3. Logic Calculator

class OUDCalculator {
    
    static func assess(entries: [SubstanceEntry], hasUlcers: Bool, isPregnant: Bool, isBreastfeeding: Bool, hasLiverFailure: Bool, hasAcutePain: Bool) -> PhysiologyProfile {
        var isHPSOPresent = false
        var isMethadonePresent = false
        var isBenzoPresent = false
        var heavyUse = false
        
        for entry in entries {
            if entry.type.isLipophilicOrLongActing {
                if entry.type == .methadone { isMethadonePresent = true }
                else { isHPSOPresent = true }
            }
            
            if entry.type.isCNSDepressant {
                isBenzoPresent = true
            }
            
            if (entry.type == .pressedPills && entry.quantity > 5) || 
               entry.type == .streetFentanylPowder || 
               entry.type == .nitazeneAnalogues {
                heavyUse = true
            }
        }
        
        // Tolerance
        let tier: PhysiologyProfile.ToleranceTier
        if isHPSOPresent && heavyUse { tier = .massive }
        else if isHPSOPresent || isMethadonePresent { tier = .high }
        else { tier = .low }
        
        // CNS Risk
        // If Fentanyl (Massive) + Benzos are mixed, risk is Extreme
        let cnsRisk: PhysiologyProfile.CNSDepressionRisk
        if isBenzoPresent && tier == .massive { cnsRisk = .extreme }
        else if isBenzoPresent { cnsRisk = .high }
        else { cnsRisk = .standard }
        
        // Xylazine
        var xylazineRisk: PhysiologyProfile.XylazineRisk = .unlikely
        if hasUlcers || entries.contains(where: { $0.type == .xylazineAdulterant }) {
            xylazineRisk = .high
        } else if isHPSOPresent {
            xylazineRisk = .possible
        }
        
        return PhysiologyProfile(
            tier: tier,
            pwdRisk: (isHPSOPresent || isMethadonePresent) ? .elevated : .standard,
            xylazine: xylazineRisk,
            cnsRisk: cnsRisk,
            isPregnant: isPregnant,
            isBreastfeeding: isBreastfeeding,
            hasLiverFailure: hasLiverFailure,
            hasAcutePain: hasAcutePain
        )
    }
}

// MARK: - 4. Protocol Generator

struct ClinicalPlan {
    let type: ProtocolType
    let protocolName: String
    let evidenceNote: String
    let safetyAlerts: [String] // New field for alerts
    let inductionSteps: [String]
    let adjunctMeds: [String]
}

class ProtocolGenerator {
    
    static func generate(profile: PhysiologyProfile, cows: Int, isERSetting: Bool) -> ClinicalPlan {
        
        var safetyAlerts: [String] = []
        
        // --- ADJUNCT LOGIC (Reactive to Sedation Risk) ---
        var adjuncts = ["Zofran 4mg q6h PRN Nausea"]
        
        // Handle CNS Risk (The "Stacking" Warning)
        if profile.cnsRisk == .extreme || profile.cnsRisk == .high {
            safetyAlerts.append("FDA ALERT: Concomitant Benzodiazepine Use. Risk of respiratory depression.")
            safetyAlerts.append("GUIDELINE: Do NOT withhold MOUD. Untreated OUD carries higher mortality risk than concurrent use.")
            safetyAlerts.append("DIAGNOSTIC: Distinguish Opioid WD (Restlessness, Pupils, Sweating) from Benzo WD (Tremor, Seizures, Autonomic Instability).")
            
            // Modify adjuncts to avoid over-sedation
            adjuncts.append("Clonidine: CAUTION due to sedation. Use lower doses (0.1mg) or omit.")
            adjuncts.append("gabapentin: CAUTION (Sedative Stacking). Avoid or use low dose.")
            adjuncts.append("NALOXONE: Prescribe for home use / emergency reversal.")
            
            // Add Sedation Check to steps (will be added to protocol steps below)
        } else {
            // Standard adjuncts
            if profile.xylazine == .high || profile.xylazine == .possible {
                adjuncts.append("Clonidine 0.2mg - 0.3mg q6-8h (Supportive for Xylazine)")
                adjuncts.append("Gabapentin 600mg TID (Supportive)")
            } else {
                adjuncts.append("Clonidine 0.1mg q6-8h PRN Anxiety")
            }
            adjuncts.append("Naloxone (Narcan) for overdose safety.")
        }
        
        if profile.xylazine == .high {
             safetyAlerts.append("XYLAZINE RISK: Buprenorphine will not treat Xylazine symptoms. Managing 'Tranq' withdrawal requires supportive care.")
        }

        // --- SCENARIO 0: CLINICAL GATING ---
        
        // 1. Acute Pain or Liver Failure: Prioritize Full Agonists, BUT allow Buprenorphine if appropriate
        if profile.hasAcutePain || profile.hasLiverFailure {
            // Soft Warning instead of Hard Block
            safetyAlerts.append("COMPLEX CONTEXT: Patient has Acute Pain and/or Liver Failure. Full Agonists (e.g. Methadone) are often preferred, but Buprenorphine is safe if carefully titrated.")
            
            // If Liver Failure, allow Mono-product Buprenorphine (Subutex) or Standard.
            // We do NOT block, but we add a note.
        }
        
        // 2. Pregnancy: Prefer LDI if Fentanyl, but allow Standard Bup/Nal
        if profile.isPregnant {
            safetyAlerts.append("PREGNANCY: Buprenorphine/Naloxone (Suboxone) is safe. High-dose induction is avoided (use LDI/Standard).")
        }
        
        if profile.isBreastfeeding {
            safetyAlerts.append("LACTATION: Buprenorphine is standard of care. Monitor infant for increased sleepiness/poor feeding.")
        }

        // --- INDUCTION LOGIC ---
        
        // SCENARIO 1: FENTANYL / HPSO
        if profile.tier == .massive || profile.tier == .high {
            
            // Fix: Relax Micro-Induction threshold to COWS < 13 (Mild Withdrawal) because Predicated Withdrawal risk is high.
            if cows < 13 && !isERSetting {
                return ClinicalPlan(
                    type: .microInduction,
                    protocolName: "Low-Dose Initiation (LDI)",
                    evidenceNote: "Preferred for Fentanyl/High-Risk. avoids PWD.",
                    safetyAlerts: safetyAlerts,
                    inductionSteps: [
                        "1. SAFETY: Assess sedation (RASS) before each dose. Hold if sedated.",
                        "2. Day 1: Buprenorphine 0.5mg SL once.",
                        "3. Continue full agonist opioids (prevents withdrawal).",
                        "4. Day 2: 0.5mg BID.",
                        "5. Escalate daily over 5-7 days."
                    ],
                    adjunctMeds: adjuncts
                )
            } else {
                // If ER Setting OR COWS is substantial, proceed to High Dose
                let protocolName = isERSetting ? "ER High-Dose Initiation (>16mg)" : "Standard/High-Dose Initiation"
                return ClinicalPlan(
                    type: .highDoseBup,
                    protocolName: protocolName,
                    evidenceNote: "Evidence supports starting when COWS ≥ 8 (or ≥ 13 for Fentanyl). High dose OK in ER.",
                    safetyAlerts: safetyAlerts,
                    inductionSteps: [
                        "1. Initial Dose: Buprenorphine 4-8mg SL.",
                        "2. SAFETY: Observe 60 mins. Monitor for sedation (RASS).",
                        "3. If alert and improved: Repeat 4-8mg.",
                        "4. Target Day 1: 16-32mg."
                    ],
                    adjunctMeds: adjuncts
                )
            }
        }
        
        // SCENARIO 2: LOW TOLERANCE
        else {
            if cows >= 8 {
                return ClinicalPlan(
                    type: .standardBup,
                    protocolName: "Traditional Induction",
                    evidenceNote: "Standard protocol.",
                    safetyAlerts: safetyAlerts,
                    inductionSteps: [
                        "1. Buprenorphine 2-4mg SL.",
                        "2. Wait 60-90 mins.",
                        "3. Max Day 1: 8-16mg."
                    ],
                    adjunctMeds: adjuncts
                )
            } else {
                 return ClinicalPlan(
                    type: .symptomManagement,
                    protocolName: "Wait and Assess",
                    evidenceNote: "Wait for mild withdrawal (COWS ≥ 8).",
                    safetyAlerts: safetyAlerts,
                    inductionSteps: ["Wait for COWS ≥ 8"],
                    adjunctMeds: adjuncts
                )
            }
        }
    }
}
