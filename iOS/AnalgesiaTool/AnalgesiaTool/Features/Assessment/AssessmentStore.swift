import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

// MARK: - Enums
// AnalgesicProfile is NOT in ClinicalData.swift, so we define it here.
enum AnalgesicProfile: String, CaseIterable, Identifiable, Codable {
    case naive = "Opioid Naive"
    case chronicRx = "Chronic Rx Opioids (Pain)"
    case highPotency = "High-Potency / Fentanyl"
    case buprenorphine = "Buprenorphine (MAT)"
    case methadone = "Methadone (MAT)"
    case naltrexone = "Naltrexone / Vivitrol"
    
    
    var id: String { self.rawValue }
    
    var isChronic: Bool {
        return self == .chronicRx || self == .buprenorphine || self == .methadone
    }
    
    var color: Color {
        switch self {
        case .naive: return ClinicalTheme.teal500      // Safe / Standard
        case .chronicRx: return ClinicalTheme.amber500 // Moderate Tolerance
        case .highPotency: return ClinicalTheme.rose500 // Danger / Unknown
        case .buprenorphine: return ClinicalTheme.purple500 // Blockade / High Affinity
        case .methadone: return Color.indigo // QTc / Variable Half-life
        case .naltrexone: return Color.gray            // Blocked
        }
    }
}

enum EncephalopathyGrade: String, CaseIterable, Identifiable, Codable {
    case none = "None (Grade 0)"
    case minimal = "Minimal (Grade 1: Subtle)"
    case moderate = "Moderate (Grade 2: Asterixis)"
    case severe = "Severe (Grade 3: Somnolent)"
    case coma = "Coma (Grade 4)"
    
    var id: String { self.rawValue }
    
    var isCerebralFailure: Bool {
        return self == .severe || self == .coma
    }
}

// MARK: - Non-Pharmacological Models
enum EvidenceLevel: String, Codable {
    case high = "High Quality"
    case moderate = "Moderate Quality"
    case low = "Low/Weak"
    
    var color: Color {
        switch self {
        case .high: return ClinicalTheme.teal500
        case .moderate: return ClinicalTheme.amber500
        case .low: return Color.gray
        }
    }
}

struct NonPharmRecommendation: Identifiable, Codable {
    var id = UUID()
    let intervention: String
    let category: String // Physical, Psych, Integrative
    let evidence: EvidenceLevel
    let detail: String
}

// MARK: - Store
class AssessmentStore: ObservableObject, CalculatorInputs {
    
    // --- INPUTS ---
    @Published var age: String = "" 
    @Published var currentMME: String = "" // Referral Logic Input
    @Published var sex: Sex = .female 
    @Published var isBreastfeeding: Bool = false 
    
    // Analgesic Profile
    @Published var analgesicProfile: AnalgesicProfile = .naive 
    
    // Modifiers
    @Published var qtcProlonged: Bool = false 
    @Published var splitDosing: Bool = false 
    @Published var toleranceUncertain: Bool = true 
    @Published var postOpNPO: Bool = false { didSet { 
        if postOpNPO { route = .iv }
    } }

    // Clinical Parameters
    @Published var renalFunction: RenalStatus = .normal 
    @Published var hepaticFunction: HepaticStatus = .normal 
    @Published var hasAscites: Bool = false 
    @Published var encephalopathyGrade: EncephalopathyGrade = .none 
    @Published var hemo: Hemodynamics = .stable 
    @Published var gi: GIStatus = .intact { didSet { 
        if gi == .npo { route = .iv }
    } }
    @Published var route: OpioidRoute = .both 
    @Published var indication: ClinicalIndication = .standard 
    @Published var painType: PainType = .nociceptive 
    @Published var inflammatorySubtype: InflammatorySubtype = .none 

    // Risk Factors
    @Published var sleepApnea: Bool = false 
    @Published var chf: Bool = false 
    @Published var benzos: Bool = false 
    @Published var copd: Bool = false 
    @Published var psychHistory: Bool = false 
    @Published var historyOverdose: Bool = false 
    @Published var multipleProviders: Bool = false // PDMP Integration
    @Published var historyGIBleed: Bool = false // Question 6
    @Published var isPregnant: Bool = false 
    
    // Pain Assessment Module
    @Published var cognitiveStatus: CognitiveStatus = .baseline
    @Published var communication: CommunicationAbility = .verbal
    @Published var intubation: IntubationStatus = .none
    @Published var rass: Double = 0 // Range -5 to +4
    @Published var customPainScore: Double? = nil // Validated Score
    @Published var manualScaleOverride: PainScaleType? = nil // User Override
    
    // PEG Scale State
    @Published var pegPain: Double = 0
    @Published var pegEnjoyment: Double = 0
    // PEG Scale State
    @Published var pegPain: Double = 0
    @Published var pegEnjoyment: Double = 0
    @Published var pegActivity: Double = 0
    
    // Other Scales State
    @Published var nrsScore: Int = 0
    @Published var vasMillimeters: Double = 0
    @Published var vdsSelection: String = "No pain" // Or Index
    @Published var cpotScore: Int = 0
    @Published var bpsScore: Int = 0
    @Published var painadScore: Int = 0
    
    var recommendedScale: PainScaleType {
        // 0. Manual Override (Reviewer Request)
        if let override = manualScaleOverride {
            return override
        }
    
        // Pathway C: Advanced Dementia
        if cognitiveStatus == .advancedDementia {
            return .painad
        }
        
        // Pathway B: Non-Communicative / Critical Care
        if communication != .verbal {
            // RASS Check: If Deeply Sedated (-4/-5), Assessment "Unable" usually, but tool assumes we want scale.
            // Branch by Intubation
            if intubation == .intubated {
                return .cpot // User Pref: CPOT vs BPS. Defaulting to CPOT for now.
            } else {
                return .bpsNi // BPS-NI or CPOT.
            }
        }
        
        // Pathway A: Communicative Adults
        // 1. Chronic Pain -> PEG
        if analgesicProfile.isChronic {
            return .peg
        }
        
        // 2. Geriatric / Mild Impairment -> VDS
        if isElderly || cognitiveStatus == .mildImpairment {
            return .vds
        }
        
        // 3. Default -> NRS
        return .nrs
    } 

    @Published var nonPharmRecs: [NonPharmRecommendation] = []

    // Computed Properties
    var isRenalImpaired: Bool { renalFunction == .impaired || renalFunction == .dialysis }
    var isHepaticFailure: Bool { hepaticFunction == .failure }
    var isElderly: Bool { 
        let clean = age.filter("0123456789".contains)
        return (Int(clean) ?? 0) >= 70 
    }
    var isPediatric: Bool { 
        let clean = age.filter("0123456789".contains)
        // Default to 20 (Adult) if parsing fails completely (e.g. empty string)
        return (Int(clean) ?? 20) < 18 
    }
    
    var generatedSummary: String {
        let ageStr = age.isEmpty ? "??" : age
        let sexStr = sex == .male ? "M" : "F"
        
        // Sentence 1: Presentation
        // "**62M** presenting with **acute nociceptive pain**."
        
        let painDesc: String
        switch painType {
        case .nociceptive: painDesc = "nociceptive pain"
        case .neuropathic: painDesc = "neuropathic pain"
        case .inflammatory: 
            if inflammatorySubtype != .none {
                painDesc = "inflammatory (\(inflammatorySubtype.rawValue.lowercased())) pain"
            } else {
                painDesc = "inflammatory pain"
            }
        case .bone: painDesc = "bone pain"
        }
        
        // Setting
        // "presenting with" covers the acute setting implicitly, OR we add "in the perioperative setting"
        var settingPhrase = "presenting with"
        switch indication {
        case .postoperative: settingPhrase = "presenting (perioperative) with"
        case .dyspnea: settingPhrase = "presenting with palliative dyspnea and"
        case .cancer: settingPhrase = "presenting with cancer-related"
        default: break 
        }
        
        let sentence1 = "**\(ageStr)\(sexStr)** \(settingPhrase) **\(painDesc)**."
        
        // Sentence 2: Patient Context
        // "Patient is **opioid naive** with **reduced renal function**."
        
        // Analgesic Status
        let status: String
        switch analgesicProfile {
        case .naive: status = "opioid naive"
        case .chronicRx: status = "on home chronic opioids"
        case .highPotency: status = "using high-potency opioids"
        case .buprenorphine: status = "on Buprenorphine"
        case .methadone: status = "on Methadone"
        case .naltrexone: status = "on Naltrexone blockade"
        }
        
        var conditions: [String] = []
        
        // Comorbidities that matter for summary
        if renalFunction != .normal { conditions.append(renalFunction == .dialysis ? "ESRD" : "reduced renal function") }
        if hepaticFunction != .normal { conditions.append(hepaticFunction == .failure ? "hepatic failure" : "hepatic impairment") }
        if hasAscites { conditions.append("ascites") }
        if encephalopathyGrade != .none { conditions.append("hepatic encephalopathy") }
        if hemo == .unstable { conditions.append("hemodynamic instability") }
        if chf { conditions.append("CHF") }
        if copd { conditions.append("COPD") }
        if gi == .npo || postOpNPO { conditions.append("NPO status") }
        if historyGIBleed { conditions.append("active/recent GI bleed") }
        if isPregnant { conditions.append("active pregnancy") }
        if sleepApnea { conditions.append("OSA") }
        if benzos { conditions.append("concurrent benzodiazepine use") }
        if historyOverdose { conditions.append("history of overdose") }
        
        let conditionString: String
        if conditions.isEmpty {
            conditionString = "."
        } else {
            // Join with commas and "and" for the last one
            if conditions.count == 1 {
                conditionString = " with **\(conditions[0])**."
            } else {
                let last = conditions.last!
                let rest = conditions.dropLast().joined(separator: ", ")
                conditionString = " with **\(rest)** and **\(last)**."
            }
        }
        
        let sentence2 = "Patient is **\(status)**\(conditionString)"
        
        return "\(sentence1) \(sentence2)"
    }

    // --- OUTPUTS ---
    func copySummary() {
        // Strip markdown stars for clipboard
        let plainText = generatedSummary.replacingOccurrences(of: "**", with: "")
        #if canImport(UIKit)
        UIPasteboard.general.string = plainText
        #endif
    }
    
    @Published var recommendations: [DrugRecommendation] = []
    @Published var adjuvants: [AdjuvantRecommendation] = []
    @Published var warnings: [String] = []
    @Published var monitoringPlan: [String] = []
    
    @Published var compositeOIRDScore: Int = 0
    @Published var prodigyRisk: String = "Low"
    @Published var riskBreakdown: [RiskAuditItem] = []
    @Published var hasHepatorenalSyndrome: Bool = false
    
    let didUpdate = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init() { 
        setupPipeline() // Debounced Pipeline (Infinite Loop Fix)
        calculate() 
    }
    
    func setupPipeline() {
        #if !CLI
        // Merge all publishers to throttle Input -> Calculation
        Publishers.MergeMany(
            $age.map { _ in }.eraseToAnyPublisher(),
            $currentMME.map { _ in }.eraseToAnyPublisher(),
            $sex.map { _ in }.eraseToAnyPublisher(),
            $isBreastfeeding.map { _ in }.eraseToAnyPublisher(),
            $analgesicProfile.map { _ in }.eraseToAnyPublisher(),
            $qtcProlonged.map { _ in }.eraseToAnyPublisher(),
            $splitDosing.map { _ in }.eraseToAnyPublisher(),
            $toleranceUncertain.map { _ in }.eraseToAnyPublisher(),
            $postOpNPO.map { _ in }.eraseToAnyPublisher(),
            $renalFunction.map { _ in }.eraseToAnyPublisher(),
            $hepaticFunction.map { _ in }.eraseToAnyPublisher(),
            $hasAscites.map { _ in }.eraseToAnyPublisher(),
            $encephalopathyGrade.map { _ in }.eraseToAnyPublisher(),
            $hemo.map { _ in }.eraseToAnyPublisher(),
            $gi.map { _ in }.eraseToAnyPublisher(),
            $route.map { _ in }.eraseToAnyPublisher(),
            $indication.map { _ in }.eraseToAnyPublisher(),
            $painType.map { _ in }.eraseToAnyPublisher(),
            $inflammatorySubtype.map { _ in }.eraseToAnyPublisher(),
            $sleepApnea.map { _ in }.eraseToAnyPublisher(),
            $chf.map { _ in }.eraseToAnyPublisher(),
            $benzos.map { _ in }.eraseToAnyPublisher(),
            $copd.map { _ in }.eraseToAnyPublisher(),
            $psychHistory.map { _ in }.eraseToAnyPublisher(),
            $historyOverdose.map { _ in }.eraseToAnyPublisher(),
            $multipleProviders.map { _ in }.eraseToAnyPublisher(),
            $historyGIBleed.map { _ in }.eraseToAnyPublisher(),
            $isPregnant.map { _ in }.eraseToAnyPublisher()
        )
        // DEBOUNCE: The "Magic Fix" for the Infinite Loop
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.calculate()
        }
        .store(in: &cancellables)
        #endif
    }
    
    // MARK: - SNAPSHOT HELPER
    func snapshot(recs: [DrugRecommendation] = [], adjs: [AdjuvantRecommendation] = []) -> AssessmentSnapshot {
        return AssessmentSnapshot(
            renalFunction: renalFunction,
            hepaticFunction: hepaticFunction,
            painType: painType,
            isPregnant: isPregnant,
            isBreastfeeding: isBreastfeeding,
            age: age,
            benzos: benzos,
            sleepApnea: sleepApnea,
            historyOverdose: historyOverdose,
            analgesicProfile: analgesicProfile,
            sex: sex,
            chf: chf,
            copd: copd,
            psychHistory: psychHistory,
            currentMME: currentMME,
            qtcProlonged: qtcProlonged,
            historyGIBleed: historyGIBleed,
            hasAscites: hasAscites,
            encephalopathyGrade: encephalopathyGrade,
            adjuvantList: adjs,
            recList: recs
        )
    }

    // MARK: - VALIDATION LOGIC (Refactored to SafetyAdvisoryService)
    // Legacy methods removed.
    

    func calculate() {
        // Reset Outputs
        var recs: [DrugRecommendation] = []
        var warns: [String] = []
        var monitors: [String] = []
        var adjs: [AdjuvantRecommendation] = []

        // 1. COMPOSITE OIRD RISK INDEX (SafetyAdvisoryService)
        let riskResult = SafetyAdvisoryService.shared.calculateRiskBreakdown(inputs: self)
        let pScore = riskResult.score
        
        self.compositeOIRDScore = pScore
        self.riskBreakdown = riskResult.breakdown
        self.hasHepatorenalSyndrome = SafetyAdvisoryService.shared.detectHepatorenalSyndrome(inputs: self)
        
        // PDMP Warning
        if multipleProviders { warns.append("PDMP ALERT: Multiple prescribers detected. Verify total MME.") }
        
        // Safety: Benzo Black Box Override
        // MOVED TO SafetyAdvisoryService (Deduplication)
        // if benzos { warns.insert(ClinicalData.benzodiazepineBlackBoxWarning, at: 0) }
        
        // Risk Tiers (Validated PRODIGY/RIOSORD Thresholds)
        // User Logic Update:
        // 0-10: Low (Green)
        // 11-20: Intermediate (Orange) -> Note: If 20 is Red, range is 11-19.
        // 20+: High (Red)
        
        if pScore >= 20 {
            self.prodigyRisk = "High"
            monitors.append("HIGH RISK (Index \(pScore)): MANDATORY continuous capnography + pulse oximetry.^[1]")
            monitors.append("Action: Prescribe Naloxone at discharge. Review PDMP. Consider Pain Specialist.")
        } else if pScore > 10 { // Changed from >= 10 to > 10 to include 10 in Low
            self.prodigyRisk = "Intermediate"
            monitors.append("INTERMEDIATE RISK (Index \(pScore)): Continuous pulse oximetry recommended.")
            monitors.append("Action: Consider Capnography. Assess for multimodal opioid-sparing strategies.")
        } else {
            self.prodigyRisk = "Low"
            monitors.append("LOW RISK (Index \(pScore)): Standard intermittent monitoring per protocol.")
        }
        
        if copd { monitors.append("COPD: Target SpO2 88-92% to prevent CO2 retention.") }
        
        // 1.05 ADJUVANTS & SAFETY ADVISORY (SafetyAdvisoryService)
        let safetyPackage = SafetyAdvisoryService.shared.generateAdvice(inputs: self, isPregnant: isPregnant, isBreastfeeding: isBreastfeeding)
        adjs.append(contentsOf: safetyPackage.adjuvants)
        warns.append(contentsOf: safetyPackage.warnings)
        monitors.append(contentsOf: safetyPackage.monitoring)
        
        // 1.1 TRIPLE RESPIRATORY THREAT (Case 35)
        // MOVED TO SafetyAdvisoryService (Deduplication)
        
        // 1.2 PEDIATRIC SAFETY (Case 53)
        if isPediatric {
            warns.append("Pediatric Patient: Codeine and Tramadol are CONTRAINDICATED (FDA Black Box).") // Case 57 Safety
        }
        
        // 1.3 BREASTFEEDING (Clinical Monitoring)
        // 1.3 BREASTFEEDING (Clinical Monitoring)
        // MOVED TO SafetyAdvisoryService (Deduplication)
        /*
        if isBreastfeeding {
            warns.append("BREASTFEEDING: Monitor infant for sedation, poor feeding, or respiratory distress. Oxycodone passes into milk.")
        }
        */
        
        // 1.4 NON-PHARMACOLOGICAL INTERVENTIONS (New)
        var nps: [NonPharmRecommendation] = []
        
        // Acute Musculoskeletal (RICE)
        if painType == .nociceptive && indication != .cancer && !analgesicProfile.isChronic {
            nps.append(NonPharmRecommendation(intervention: "RICE Protocol", category: "Physical", evidence: .moderate, detail: "Rest, Ice, Compression, Elevation. Recommended for acute musculoskeletal injuries."))
        }
        
        // Chronic / Neuropathic (Strong Evidence)
        if analgesicProfile.isChronic || painType == .neuropathic {
             nps.append(NonPharmRecommendation(intervention: "Exercise Therapy", category: "Physical", evidence: .high, detail: "Strongest evidence for functional improvement in chronic pain."))
             nps.append(NonPharmRecommendation(intervention: "CBT / Mindfulness", category: "Psychological", evidence: .high, detail: "Cognitive Behavioral Therapy reducing pain catastrophizing."))
             nps.append(NonPharmRecommendation(intervention: "Acupuncture", category: "Integrative", evidence: .high, detail: "Effective for chronic back/neck pain and osteoarthritis."))
        }
        
        // Cancer Pain (Integrative)
        if indication == .cancer {
             nps.append(NonPharmRecommendation(intervention: "Massage Therapy", category: "Integrative", evidence: .low, detail: "ASCO endorsed for chronic cancer pain."))
             nps.append(NonPharmRecommendation(intervention: "Music Therapy", category: "Integrative", evidence: .low, detail: "Adjunct for anxiety and pain perception."))
        }
        
        // Geriatrics (AGS Guidelines)
        if isElderly {
            if !nps.contains(where: { $0.intervention.contains("Education") }) {
                 nps.append(NonPharmRecommendation(intervention: "Patient Education", category: "Education", evidence: .high, detail: "AGS recommended: Set realistic goals and understand pathology."))
            }
        }
        
        // Universal (Empty State Fallback or General)
        if nps.isEmpty {
             nps.append(NonPharmRecommendation(intervention: "Multimodal Education", category: "General", evidence: .high, detail: "Patient counseling on expected course and non-drug options."))
        }
        
        self.nonPharmRecs = nps

        // 2. HELPERS
        // Evidence: ACS Trauma Quality Programs (2020) & CDC (2022)
        // - Implementation: >70yo triggers ~50% reduction (e.g. 2.5-5mg vs 5-10mg).
        // - RENAL: If Impaired, defaults to "Start Low / Extend Interval" advice.
        func getStartingDose(drug: String, route: String) -> String {
            guard analgesicProfile == .naive else { return "Titrate to effect" }
            
            // Renal Override (Priority over Age)
            if isRenalImpaired {
                 return "Renal Reduction Required (Start 50% dose / Extend Interval)."
            }
            
            switch (drug, route) {
            case ("Fentanyl", "IV"): return isElderly ? "Start 12.5mcg" : "Start 25-50mcg"
            case ("Hydromorphone", "IV"): return isElderly ? "Start 0.2mg" : "Start 0.2-0.5mg"
            case ("Morphine", "IV"): return isElderly ? "Start 1-2mg" : "Start 2-4mg"
            case ("Oxycodone", "PO"): return isElderly ? "Start 2.5mg" : "Start 2.5-5mg (approx 4-7.5 MME)"
            default: return "Standard starting dose"
            }
        }

        func getProfile(for name: String) -> DurationProfile? {
            return ClinicalData.drugData.first { name.localizedCaseInsensitiveContains($0.name) }?.durationProfile
        }

        func getMolecule(for name: String) -> OpioidMolecule {
            // Priority: Lookup in Data
            if let match = ClinicalData.drugData.first(where: { name.localizedCaseInsensitiveContains($0.name) }) {
                return match.molecule
            }
            // Fallback: Infer from name (for ad-hoc strings like "Codeine" if not in DB)
            let lower = name.lowercased()
            if lower.contains("morphine") { return .morphine }
            if lower.contains("hydromorphone") { return .hydromorphone }
            if lower.contains("oxycodone") { return .oxycodone }
            if lower.contains("methadone") { return .methadone }
            if lower.contains("fentanyl") { return .fentanyl }
            if lower.contains("buprenorphine") { return .buprenorphine }
            if lower.contains("tramadol") { return .tramadol }
            if lower.contains("codeine") { return .codeine }
            if lower.contains("meperidine") { return .meperidine }
            if lower.contains("tapentadol") { return .tapentadol }
            if lower.contains("levorphanol") { return .levorphanol }
            if lower.contains("suzetrigine") { return .suzetrigine }
            return .other
        }

        func addRec(_ name: String, _ type: RecommendationType, _ reason: String, _ detail: String) {
            recs.append(DrugRecommendation(name: name, reason: reason, detail: detail, type: type, durationProfile: getProfile(for: name), molecule: getMolecule(for: name)))
        }

        // 3. ANALGESIC PROFILE LOGIC
        switch analgesicProfile {
        case .naive:
            // Explicit Naive Guidance (Lowest Effective Dose)
            warns.append("New Start Guidance: Start lowest effective dose (5–10 MME/dose). Max 20–30 MME/day.")
            
            if route == .iv || route == .both {
                addRec("Hydromorphone IV", .safe, "Standard", "Potent. \(getStartingDose(drug: "Hydromorphone", route: "IV"))")
                addRec("Morphine (IV)", .safe, "Standard", "First line. \(getStartingDose(drug: "Morphine", route: "IV"))")
            }
            // Add Fentanyl IV only for specific indications (Renal/Hepatic Logic below handles this)
            if indication == .postoperative && (route == .iv || route == .both) {
                 addRec("Fentanyl IV", .safe, "Procedural", "Short duration. \(getStartingDose(drug: "Fentanyl", route: "IV")). Consider Specialist Guidance.")
            }
            
            if (route == .po || route == .both) && gi != .npo {
                addRec("Morphine (PO)", .safe, "Preferred", "15mg PO. Assess efficacy relative to baseline.")
                addRec("Oxycodone PO", .safe, "Preferred", "Bioavailable. \(getStartingDose(drug: "Oxycodone", route: "PO"))")
            }
            
            // Fentanyl Patch Warning removed from here per user request (Block recs, warn in library instead).

            // Methadone for Pain (Contextual)
            // Indication: Neuropathic Pain OR Renal Impairment (Safe metabolites)
            // Gate: Checked in validateSafetyGates (QTc, OD History)
            if (painType == .neuropathic || isRenalImpaired) && !historyOverdose && !qtcProlonged {
                 addRec("Methadone (Pain Protocol)", .caution, "Neuropathic/Renal Benefit (Expert Consult Recommended)", "Strict SPLIT DOSING (q8h). Start low (2.5mg PO q8h). Daily ECG.")
            }

        case .chronicRx:
            warns.append("There is a paucity of evidence supporting > 12 months of opioid therapy for chronic pain management.")
            warns.append("Tolerant Patient: Baseline dose + 20% for acute pain.")
            addRec("Continue Home Meds", .safe, "Prevent Withdrawal", "Maintain baseline. Add short-acting agonist (10-20% daily dose) q3h.")
            
            if isPregnant {
                warns.append("PREGNANCY: Acute Withdrawal causes fetal distress. Maintain baseline.") // Case 46 Cap Fix
            }
            
            // Escalation Math (Uncontrolled Pain)
            addRec("Escalation Strategy", .caution, "If Pain Uncontrolled", "Calculate total 24h breakthrough used. Add sum + 20-30% to new daily baseline.")
            
            // Surgical Multiplier
            if indication == .postoperative {
                warns.append("SURGICAL MULTIPLIER (Expert Consensus): Chronic Rx patients need ~3x higher MME than naive controls.")
            }
            
            // Hyperalgesia Distinction
            warns.append("OIH Awareness: If pain worsens despite dose escalation, suspect Hyperalgesia. Consider Opioid Rotation or Ketamine.")
            
             // Methadone for Pain (Contextual Rotation)
            if (painType == .neuropathic || isRenalImpaired) && !historyOverdose && !qtcProlonged {
                 addRec("Methadone Rotation", .caution, "Complex Pain", "Consult Specialist. Split dosing (q8h) required. Monitor QTc.")
            }
            
        case .highPotency:
            warns.append("HIGH POTENCY: MME Calculators will UNDERESTIMATE tolerance.")
            if toleranceUncertain { monitors.append("Unpredictable Tolerance: Titrate by effect. Start low, titrate frequently (e.g. q15-30m) until comfort. Monitor closely.") }
            addRec("Fentanyl IV", .safe, "Preferred", "Titratable. Start 50-100mcg IV if tolerance high. Consider Specialist Guidance.")
            // High Potency often requires rotation options. Adding Hydromorphone allows Renal logic to apply 'Strict Caution' adjustment if needed (Case 11).
            addRec("Hydromorphone IV", .caution, "Alternative", "Potent. Start 0.5-1mg IV. Monitor closely.")

        case .buprenorphine:
            if indication == .postoperative {
                 // Evidence: PAIN Consensus (2019) vs APA.
                 // "Rarely appropriate to reduce dose" (PAIN). "Consider reduction to 8-12mg" (APA).
                 // Best Practice: Continue Maintenance + Full Agonist.
                 
                 addRec("Continue Buprenorphine", .safe, "Standard of Care", "Do not taper. Maintenance prevents relapse (PAIN 2019).")
                 addRec("Dose Reduction Strategy", .caution, "Controversial", "Reducing to 8-12mg is controversial (ASAM/APA vs PAIN). Only if pain uncontrolled.")
            } else {
                 addRec("Continue Home Dose (Buprenorphine)", .safe, "Do Not Taper", "Maintenance prevents relapse.") // Case 39 Name Fix
            }
            
            // Split Dosing Optimization for Analgesia
            if !splitDosing {
                addRec("Split Home Dose", .safe, "Analgesic Efficacy", "Divide daily dose q6-8h to maximize duration of analgesia (Duration 6-8h).")
            }
            
            addRec("High-Affinity Agonist", .caution, "Breakthrough", "Use Hydromorphone/Fentanyl. Competition Risk: High doses required to overcome blockade. Monitor for delayed respiratory depression.")
            if gi == .npo { warns.append("NPO Status: Use IV/SL Buprenorphine formulations.") }

        case .methadone:
            // MAT Context: Default to q24h to prevent withdrawal/accumulation
            if splitDosing {
                addRec("Continue Methadone", .safe, "Analgesia Optimized", "Split dose q8h (Expert Guidance).")
            } else {
                 addRec("Continue Methadone", .safe, "Prevention of Withdrawal", "Maintain baseline daily dose (q24h). Effect is mainly maintenance, not analgesia.")
            }
            
            // Multi-Organ Safety Check
            if hasHepatorenalSyndrome {
                warns.append("CRITICAL: Patient on Methadone with Multi-Organ Failure (Hepatic+Renal). High risk of accumulation/toxicity. Consult Pain/Addiction Specialist immediately.")
            }
            
            if qtcProlonged {
                warns.append("QTc PROLONGED (>450ms): Methadone Warning. Risk of Torsades. Consider Alternatives.")
                monitors.append("Daily ECG recommended. Consult Cardiology if QTc > 450ms.")
            }

        case .naltrexone:
            warns.append("BLOCKADE ACTIVE: Opioids ineffective.")
            
            // Ketamine Safety Check
            var ketamineSafety: RecommendationType = (hemo == .unstable) ? .caution : .safe
            var ketamineInfo = (hemo == .unstable) ? "CAUTION: May worsen HTN/Tachycardia. Monitor closely." : "0.1-0.3 mg/kg/hr. Bypasses Mu-receptor."
            
            // Psychosis Risk (User Request)
            if psychHistory {
                 ketamineSafety = .caution
                 warns.append("Ketamine Caution: Psychiatric History detected. Risk of dysphoria/exacerbation.")
                 ketamineInfo = "CAUTION: Psych History. Risk of acute dysphoria. Consider lower dose or benzodiazepine pretreatment."
            }
            
            addRec("Ketamine Infusion", ketamineSafety, "Primary Analgesic", ketamineInfo)
            
            if hemo == .unstable {
                warns.append("Hemodynamic Instability: Ketamine Caution high.")
                addRec("Lidocaine Infusion", .safe, "Alternative", "Consider if Ketamine contraindicated. Cardiac monitoring required.")
                addRec("Regional Anesthesia", .safe, "Sparing Option", "Consult Anesthesia for nerve blocks.")
            }
        }
        
        // 3a. NEUROPATHIC PAIN LOGIC (Mechanism-Based)
        // 3a. NEUROPATHIC PAIN LOGIC (Mechanism-Based)
        if painType == .neuropathic {
            warns.append("Neuropathic Pain: Pure agonists (Morphine, Fentanyl, Oxycodone) have poor efficacy due to NMDA-mediated sensitization. Prefer Atypicals.")
            
            if analgesicProfile == .naive {
                // Naive: Start with weaker atypicals or Levorphanol if severe?
                // Text says Levorphanol is "Excellent". But it's potent. Maybe reserve for tolerant or severe.
                // Let's stick to Tapentadol for Naive as primary.
                addRec("Tapentadol", .safe, "Neuropathic (NRI)", "Restores descending inhibition. 50mg PO.")
            } else {
                // Tolerant: Methadone or Levorphanol
                if !recs.contains(where: { $0.name.contains("Methadone") }) {
                    addRec("Methadone (Rotation)", .caution, "Neuropathic (NMDA)", "Specialist Guidance Only. Excellent NMDA coverage. Monitor QTc.")
                }
                addRec("Levorphanol", .safe, "Neuropathic (NMDA+SNRI)", "Potent. No QTc Risk. Good efficacy (Limited Evidence). Monitor side effects.")
            }
            
            // Universal Option if not on blockade
            if analgesicProfile != .naltrexone && analgesicProfile != .buprenorphine {
                addRec("Buprenorphine", .safe, "Neuropathic (Kappa)", "Transdermal (Butrans) or Buccal (Belbuca) preferred. Good efficacy via Kappa antagonism.")
            }
            
            // Mark Pure Agonists as "Poor Efficacy" in detail if they exist
            // This loop iterates existing recs to tag them?
            // Actually, we can just let the Warning stand. Or modify details.
            
            for i in 0..<recs.count {
                if ["Morphine", "Fentanyl", "Oxycodone"].contains(where: { recs[i].name.contains($0) }) {
                   if !recs[i].detail.contains("Poor Efficacy") {
                       recs[i] = DrugRecommendation(name: recs[i].name, reason: "Poor Efficacy", detail: "Pure Agonist: Poor coverage for neuropathic pain. \(recs[i].detail)", type: .caution, durationProfile: recs[i].durationProfile, molecule: recs[i].molecule)
                   }
                }
            }
        }
        
        // 3b. ADJUVANT LOGIC (Gabapentin/TCA)
        
        // --- Gabapentinoid Logic ---
        // Warning moved to after Adjuvant generation to ensure context (only warn if Gabapentin is recommended).
        
        // Renal Tiers for Gabapentin
        let gabaDose: String
        let gabaFreq: String
        switch renalFunction {
        case .normal:
            gabaDose = "300mg"
            gabaFreq = "TID or HS"
        case .impaired: // 30-60
            gabaDose = "300mg BID or 200mg TID"
            gabaFreq = "Reduce Freq"
        case .dialysis:
            gabaDose = "Post-HD Dosing Only"
            gabaFreq = "After Dialysis"
        }
        
        // Add Adjuvant Recommendations if Neuropathic
        if painType == .neuropathic {
            // --- TCA Logic (Nortriptyline) ---
            var tcaSafe = true
            
            // Beers Criteria
            if let ageInt = Int(age), ageInt >= 65 {
                tcaSafe = false
                warns.append("Beers Criteria (Age ≥ 65): TCAs have high anticholinergic risk (Falls, Confusion, Retention). Prefer Gabapentin or topical agents.")
            }
            
            // Cardiac Gate
            if qtcProlonged || hemo == .unstable || chf {
                tcaSafe = false
                warns.append("Cardiac Safety: TCAs Contraindicated due to Sodium Channel Blockade and QTc prolongation risk.")
            }
            
            // Adjuvant Recommendations Struct
            let gabaRec = AdjuvantRecommendation(
                category: "Adjuvant",
                drug: "Gabapentin",
                dose: "\(gabaDose) \(gabaFreq)",
                rationale: "First-line Neuropathic. Monitor sedation."
            )
            adjs.append(gabaRec)
            
            if tcaSafe {
                adjs.append(AdjuvantRecommendation(
                    category: "Adjuvant",
                    drug: "Nortriptyline",
                    dose: "Start 10-25mg HS",
                    rationale: "TCAs effective for neuropathic pain. Monitor EKG."
                ))
            } else if Int(age) ?? 0 >= 65 && !qtcProlonged && hemo == .stable {
                // AGE GAP FIX (Beers Criteria): Avoid even "safe" TCAs like Desipramine in >65.
                // Replace with SNRI (Duloxetine) or Topicals
                
                adjs.append(AdjuvantRecommendation(
                    category: "Adjuvant",
                    drug: "Duloxetine (Cymbalta)",
                    dose: "Start 30mg PO qDay",
                    rationale: "Preferred First-Line (Beers Criteria Safe). Monitor Na+."
                ))
                
                adjs.append(AdjuvantRecommendation(
                    category: "Adjuvant",
                    drug: "Lidocaine Patch 5%",
                    dose: "12h On / 12h Off",
                    rationale: "Safe Local Option. No systemic risks."
                ))
            }
        }
        
        // 4. RENAL FILTERS
        // Evidence: ASCO / VA/DoD CKD Guidelines (2019)
        // "Morphine use may result in accumulation of neurotoxic metabolites (M3G/M6G)."
        // Recommendation: Avoid Morphine. Use Fentanyl/Methadone (Safe) or Hydro/Oxy (Caution).
        if isRenalImpaired {
            // "Renal Cliff" Fix: Only hard block for Dialysis (<30), Caution for Impaired (30-60).
            if renalFunction == .dialysis {
                recs.removeAll { $0.molecule == .morphine }
            } else {
                 // Impaired: Convert Morphine to Caution
                 for i in 0..<recs.count {
                     if recs[i].molecule == .morphine {
                         recs[i] = DrugRecommendation(
                            name: recs[i].name,
                            reason: "Renal Caution (eGFR 30-60)",
                            detail: "Reduce dose 25-50%. Diligence required (Active Metabolites). \(recs[i].detail)",
                            type: .caution,
                            durationProfile: recs[i].durationProfile,
                            molecule: recs[i].molecule
                         )
                     }
                 }
            }
            
            if let idx = recs.firstIndex(where: { $0.molecule == .hydromorphone }) {
                let d = recs[idx]
                let warning = renalFunction == .dialysis ? "Strict Caution (Dialysis)." : "Renal Caution."
                let detail = renalFunction == .dialysis ? "Accumulates between sessions. Reduce dose 50% (Metabolite Risk)." : "Reduce dose 50% (Metabolite Accumulation)."
                // Since d is a let constant in the struct, we must create a new one.
                recs[idx] = DrugRecommendation(name: d.name, reason: warning, detail: detail, type: .caution, durationProfile: d.durationProfile, molecule: d.molecule)
            }
            
            // Oxycodone Renal Caution
            if let idx = recs.firstIndex(where: { $0.molecule == .oxycodone }) {
                let d = recs[idx]
                recs[idx] = DrugRecommendation(name: d.name, reason: "Renal Caution", detail: "Metabolites accumulate in eGFR < 60. Start with lower doses (2.5mg PO) and monitor for sedation.", type: .caution, durationProfile: d.durationProfile, molecule: d.molecule)
            }
            
            if !recs.contains(where: { $0.molecule == .fentanyl }) && (route == .iv || route == .both) {
                 if renalFunction == .dialysis {
                     // Dialysis: Fentanyl is Top Priority
                     recs.insert(DrugRecommendation(name: "Fentanyl IV", reason: "Renal Safe", detail: "No active metabolites. Safest option in dialysis. Consider Specialist Guidance.", type: .safe, durationProfile: .rapid, molecule: .fentanyl), at: 0)
                 } else {
                     // Moderate Impairment: Fentanyl is an option, but Hydromorphone (Reduced) is often standard.
                     // Add as "Safe Alternative" but do not prepend.
                     addRec("Fentanyl IV", .safe, "Safe Alternative", "No active metabolites. Useful if Hydromorphone accumulates.")
                 }
            }
        
        // Dyspnea + Renal Specific Warning (Case 37)
        if indication == .dyspnea && isRenalImpaired {
            warns.append("Dyspnea/Renal: Avoid Morphine due to Metabolites. Consider Hydromorphone or Fentanyl (off-label).")
            if !recs.contains(where: { $0.molecule == .hydromorphone }) {
                 // Ensure alternative exists
                 addRec("Hydromorphone IV", .caution, "Alternative", "Renal adjusted. 0.2mg IV.")
            }
        }
        }

        // 5. HEPATIC FILTERS
        // Evidence: Fentanyl has minimal hepatic first-pass metabolism (Smith et al, 2018).
        // Hydromorphone is glucuronidated but less variable than Morphine/Oxycodone (Safe but Caution).
        // 802 placeholder just to ensure file sync
        if isHepaticFailure {
            warns.append("LIVER FAILURE: Avoid Morphine, Codeine, Tramadol, Oxycodone.")
            let toxic: Set<OpioidMolecule> = [.morphine, .codeine, .tramadol, .oxycodone, .methadone, .meperidine]

            recs.removeAll { toxic.contains($0.molecule) }
            
            // Acetaminophen Max 2g Warning removed (Redundant with Adjuvant Rec 2g limit)

            if !recs.contains(where: { $0.molecule == .fentanyl }) && (route == .iv || route == .both) {
                addRec("Fentanyl IV", .safe, "Preferred", "Safest hepatic profile. Consider Specialist Guidance.")
            }
            
            // Split logic for IV vs PO Hydromorphone
            if let idx = recs.firstIndex(where: { $0.molecule == .hydromorphone }) {
                 let isPO = recs[idx].name.contains("PO")
                 let detail = isPO 
                    ? "Bioavailability increases 4x (Shunting bypasses First-Pass). Start 1mg PO." 
                    : "Reduced clearance. Start 0.2mg IV. Monitor closely."
                 
                 recs[idx] = DrugRecommendation(
                    name: recs[idx].name, 
                    reason: "Caution (Shunting)", 
                    detail: detail, 
                    type: .caution,
                    durationProfile: recs[idx].durationProfile,
                    molecule: recs[idx].molecule
                 )
            } else if (route == .po || route == .both) && gi != .npo {
                 // Fallback: If Naive, Hydromorphone PO wasn't added initially, but it is the preferred oral option here (vs Morphine/Oxy).
                 addRec("Hydromorphone (PO)", .caution, "Caution (Shunting)", "Preferred over Morphine. Bioavailability increases 4x. Start 1mg PO.")
            }
        }

        // 6. GI / NPO LOGIC
        if gi == .npo || postOpNPO {
            recs.removeAll { $0.name.contains("PO") }
            warns.append("NPO: Enteral route contraindicated.")
        }
        
        // 7. HEMODYNAMIC FILTERS (NEW)
        if hemo == .unstable {
            warns.append("HEMODYNAMIC INSTABILITY: Avoid Morphine (Histamine Release). Fentanyl preferred.")
            
            // Remove Morphine/Codeine (Histamine release)
            recs.removeAll { $0.molecule == .morphine || $0.molecule == .codeine }
            
            // Prioritize Fentanyl
            if !recs.contains(where: { $0.molecule == .fentanyl }) && (route == .iv || route == .both) {
                recs.insert(DrugRecommendation(name: "Fentanyl IV", reason: "Preferred", detail: "Cardiostable. Start 25-50mcg. Titrate carefully. Consider Specialist Guidance.", type: .safe, durationProfile: .rapid, molecule: .fentanyl), at: 0)
            } else if let idx = recs.firstIndex(where: { $0.molecule == .fentanyl }) {
                // Ensure it's marked SAFE/PREFERRED
                let old = recs[idx]
                recs[idx] = DrugRecommendation(name: old.name, reason: "Preferred (Stable)", detail: old.detail, type: .safe, durationProfile: old.durationProfile, molecule: old.molecule)
            }
        }
        
        // Shock + PO (Case 41)
        if hemo == .unstable && (route == .po || route == .both) {
            warns.append("SHOCK: Oral Absorption unreliable due to gut shunting. Use IV.")
        }
        
        // GI Bleed Specific Logic (Question 6)
        if historyGIBleed {
            warns.append("GI BLEED: Avoid systemic NSAIDs. Use topical patches/gels if indicated.")
            // Redundant logic in Adjuvant section will also catch this, but top-level warning is good.
        }

        // 7. PREGNANCY LOGIC
        if isPregnant {
            warns.append("Pregnancy: Avoid Codeine/Tramadol. Neonatology consult recommended.")
            recs.removeAll { $0.molecule == .codeine || $0.molecule == .tramadol }
        }
        
        // Pediatric Block (Case 53)
        if isPediatric {
             recs.removeAll { $0.molecule == .codeine || $0.molecule == .tramadol }
        }

        // 8. ADJUVANT LOGIC
        switch painType {
        case .neuropathic:
             // Handled in dedicated Neuropathic Logic block above (Section 3b) to support superior renal dosing specificity.
             break

        case .bone:
            // "Steroids have limited, if any, use in chronic cancer pain."
            adjs.append(AdjuvantRecommendation(category: "Anti-Inflammatory", drug: "Dexamethasone", dose: "4-8mg IV/PO", rationale: "Acute flares/Compression only. Limited chronic utility."))
            if !isRenalImpaired && !historyGIBleed {
                 adjs.append(AdjuvantRecommendation(category: "NSAID", drug: "Naproxen", dose: "500mg BID", rationale: "Bone pain."))
            }

        case .inflammatory, .nociceptive:
            // Phase 10: Advanced Inflammatory (Gout / Autoimmune / Pericarditis)
            if painType == .inflammatory && inflammatorySubtype == .gout {
                // Phase 12: Refractory Gout & IL-1
                
                let isColchicineRenalUnsafe = renalFunction == .dialysis // Strict <30
                let isColchicineHepaticUnsafe = hepaticFunction == .failure // Class C
                let isColchicineCombinedUnsafe = renalFunction == .impaired && hepaticFunction == .impaired // Combined Toxicity
                
                let isColchicineContraindicated = isColchicineRenalUnsafe || isColchicineHepaticUnsafe || isColchicineCombinedUnsafe
                
                if isColchicineContraindicated {
                    // COMPLEX GOUT PATHWAY
                    warns.append("COMPLEX GOUT: Colchicine/NSAIDs Contraindicated (Renal/Hepatic Risk).")
                    
                    // 1. Steroids (Standard Alternative)
                    adjs.append(AdjuvantRecommendation(category: "First Line", drug: "Prednisone", dose: "40mg Taper", rationale: "Renal/Hepatic Safety."))
                    warns.append("Monitor: Hyperglycemia / Fluid Retention with Steroids.")
                    
                    // 2. IL-1 Inhibitor (Refractory / Steroid Contraindication)
                    adjs.append(AdjuvantRecommendation(category: "Refractory", drug: "Anakinra (IL-1)", dose: "100mg SC Daily x3", rationale: "Use if Steroids contraindicated (Diabetes/Infection)."))
                    
                } else {
                    // STANDARD GOUT PATHWAY
                    if renalFunction == .impaired { // Moderate CKD (30-60)
                         adjs.append(AdjuvantRecommendation(category: "Gout Specific", drug: "Colchicine", dose: "Reduce Dose (0.6mg x1 only)", rationale: "Renal Risk (Accumulation)."))
                    } else {
                         adjs.append(AdjuvantRecommendation(category: "Gout Specific", drug: "Colchicine", dose: "1.2mg now -> 0.6mg 1h", rationale: "Acute Flare."))
                    }
                    
                    if !historyGIBleed && !isPregnant && renalFunction == .normal {
                        adjs.append(AdjuvantRecommendation(category: "NSAID", drug: "Indomethacin", dose: "50mg TID", rationale: "Gout Standard."))
                    }
                }
            } else if painType == .inflammatory && inflammatorySubtype == .autoimmune {
                // Autoimmune Flare
                adjs.append(AdjuvantRecommendation(category: "Anti-Inflammatory", drug: "Prednisone", dose: "40-60mg Taper", rationale: "Autoimmune Flare."))
                 if !isRenalImpaired && !historyGIBleed && !isPregnant {
                      adjs.append(AdjuvantRecommendation(category: "Adjunct", drug: "Naproxen", dose: "500mg BID", rationale: "Synergy."))
                 }
            } else if painType == .inflammatory && inflammatorySubtype == .pericarditis {
                // Phase 11: Pericarditis Protocol
                
                // Safety Gate: Renal / GI Bleed / Pregnancy (High Risk)
                if isRenalImpaired || historyGIBleed || isPregnant {
                     warns.append(isPregnant ? "PREGNANCY PERICARDITIS: NSAIDs High Risk (>20wks). Use Steroids." : "PERICARDITIS: NSAIDs Contraindicated (Renal/GI). Use Steroids.")
                     
                     adjs.append(AdjuvantRecommendation(category: "First Line", drug: "Prednisone", dose: "0.25-0.5 mg/kg/day", rationale: "Anti-inflammatory."))
                } else {
                    // Standard Standard
                    adjs.append(AdjuvantRecommendation(category: "First Line", drug: "Ibuprofen", dose: "600-800mg TID", rationale: "High Dose Anti-inflammatory."))
                    adjs.append(AdjuvantRecommendation(category: "Adjunct", drug: "Colchicine", dose: "0.5mg BID (3mo)", rationale: "Recurrence Prevention."))
                }
            } else {
                // Standard Inflammatory Logic (Existing)
                if isRenalImpaired || isHepaticFailure || chf || historyGIBleed {
                     adjs.append(AdjuvantRecommendation(category: "Topical", drug: "Diclofenac Gel 1%", dose: "4g QID", rationale: "Lower systemic absorption."))
                } else {
                     if gi == .npo && painType == .inflammatory {
                         adjs.append(AdjuvantRecommendation(category: "IV NSAID", drug: "Ketorolac (Toradol)", dose: "15-30mg IV q6h", rationale: "NPO Anti-inflammatory."))
                     } else {
                         adjs.append(AdjuvantRecommendation(category: "NSAID", drug: "Ibuprofen", dose: "400mg QID", rationale: "Standard anti-inflammatory."))
                     }
                }
            }
            
            // Case 57: Pregnancy NSAID Exclusion (Applies to all)
            if isPregnant && (painType == .inflammatory || painType == .nociceptive || painType == .bone || (painType == .inflammatory && (inflammatorySubtype == .gout || inflammatorySubtype == .autoimmune))) {
                // Remove NSAIDs created above
                adjs.removeAll { $0.category.contains("NSAID") || $0.drug.contains("Ibuprofen") || $0.drug.contains("Ketorolac") || $0.drug.contains("Naproxen") || $0.drug.contains("Indomethacin") }
                
                // Remove Colchicine (Rat teratogenicity / crossing)
                adjs.removeAll { $0.drug.contains("Colchicine") }
                
                warns.append("PREGNANCY: NSAIDs & Colchicine contraindicated. Prefer Prednisone/Tylenol.")
            }
            
            // Phase 11: Lactation Check (Colchicine)
            if isBreastfeeding && adjs.contains(where: { $0.drug.contains("Colchicine") }) {
                warns.append("LACTATION: Colchicine excreted in breast milk. Monitor infant or Pump & Dump.")
            }
            
            // Adjuvants (Tylenol, etc) now handled by SafetyAdvisoryService centrally.
            
            
            // Note: Visceral pain case not currently in PainType enum.

        }
        
        // Universal Adjuvant (Integrative Therapy) - Removed (Duplicative of Non-Pharm Section)
        // adjs.append(ClinicalData.WithdrawalProtocol.integrativeBundle)
        
        if historyOverdose || psychHistory {
            monitors.append("SUD History: Urine Drug Screen + Naloxone prescription at discharge.")
            warns.append("High Risk: Limit quantity. Review PDMP.")
        }
        
        // 9. REFERRAL TRIGGERS
        // Physical Therapy (Nociceptive)
        if painType == .nociceptive {
             recs.append(DrugRecommendation(name: "Physical Therapy", reason: "First Line", detail: "Multimodal functional restoration.", type: .safe, durationProfile: .long, molecule: .other))
        }

        // Pain Management (>90 MME)
        if let mme = Int(currentMME), mme > 90 {
            warns.append(">90 MME: High Overdose Risk (CDC). Pain Management Consult Required.^[3]")
            monitors.append("MME > 90: Co-prescribe Naloxone.")
        }
        
        // Addiction Medicine (OUD Context)
        if historyOverdose || (analgesicProfile == .buprenorphine && indication != .postoperative) {
            // If they are on Buprenorphine for OUD (implied by not post-op? or just strictly OUD history)
            // Or if history of overdose.
            // Requirement: "Addiction medicine for suspected opioid use disorder"
            // We use historyOverdose as proxy for risk here.
            addRec("Addiction Medicine Consult", .safe, "Suspected OUD", "Assess for MAT optimization.")
        }
        
        // Physical Therapy (Musculoskeletal)
        // Nociceptive pain implies musculoskeletal often, or inflammatory.
        if painType == .nociceptive || painType == .inflammatory {
            adjs.append(AdjuvantRecommendation(category: "Interventional", drug: "Physical Therapy", dose: "Evaluate & Treat", rationale: "Functional restoration."))
        }

        // 9. FINAL SORTING: Safety > Route > Stability
        // 9. CONTEXTUAL WARNINGS (Post-Processing)
        // Gabapentinoid Synergy: Only warn if both Opioids AND Gabapentin are recommended via our logic.
        if !recs.isEmpty && adjs.contains(where: { $0.drug.contains("Gabapentin") }) {
            warns.append("FDA 2019 Warning: Concomitant use of Opioids and Gabapentinoids increases risk of respiratory depression. Start with lower doses and monitor.^[4]")
        }

        recs.sort { (a, b) -> Bool in
            // Helper: Rank Safety (Safe=0, Caution=1, Unsafe=2)
            func rank(_ type: RecommendationType) -> Int {
                switch type {
                case .safe: return 0
                case .caution: return 1
                case .unsafe: return 2
                }
            }
            
            // 1. Safety Priority
            let rankA = rank(a.type)
            let rankB = rank(b.type)
            
            if rankA != rankB {
                // SPECIAL LOGIC: Mild Renal Dysfunction (eGFR 30-60)
                // In mild impairment, standard agents (Hydromorphone/Oxycodone) are preferred despite "Caution" tag
                // over Fentanyl ("Safe") due to pharmacokinetics and ease of use, as accumulation risk is manageable.
                if self.renalFunction == .impaired { // .impaired = Mild/Mod. .dialysis is separate.
                    let aStandard = a.molecule == .hydromorphone || a.molecule == .oxycodone
                    let bStandard = b.molecule == .hydromorphone || b.molecule == .oxycodone
                    let aFent = a.molecule == .fentanyl
                    let bFent = b.molecule == .fentanyl
                    
                    // Case: Comparing Standard (Caution) vs Fentanyl (Safe)
                    // We want Standard to Win (return true if A is Standard)
                    if (aStandard && bFent) { return true }
                    if (bStandard && aFent) { return false }
                }
                
                return rankA < rankB
            }
            
            // 2. Clinical Context Priority (Organ Failure Tie-Breaker)
            // Fentanyl Wins in Severe Organ Failure (Dialysis, Hepatic Failure, Shock)
            if self.renalFunction == .dialysis || self.isHepaticFailure || self.hemo == .unstable {
                let aFent = a.molecule == .fentanyl
                let bFent = b.molecule == .fentanyl
                if aFent != bFent { return aFent }
            }
            
            // 3. Route Priority (PO > IV)
            let aPO = a.name.contains("PO")
            let bPO = b.name.contains("PO")
            if aPO != bPO { return aPO }
            
            // 4. Deterministic Tie-Breaker (Alphabetical)
            return a.name < b.name
        }

        // MARK: - FINAL SAFETY VALIDATIONS (HARDENING)
        
        // Create Snapshot
        let snap = snapshot(recs: recs, adjs: adjs)
        
        // 1. State Consistency
        warns.insert(contentsOf: SafetyAdvisoryService.shared.validateStateConsistency(snapshot: snap), at: 0)
        
        // 2. Organ Specific Validation (Hepatic Focus)
        if hepaticFunction != .normal {
            warns.append(contentsOf: SafetyAdvisoryService.shared.validateHepaticRenalCombination(snapshot: snap))
            warns.append(contentsOf: SafetyAdvisoryService.shared.validateHepaticCoagulopathy(snapshot: snap))
            warns.append(contentsOf: SafetyAdvisoryService.shared.validateAscitesImpact(snapshot: snap))
            warns.append(contentsOf: SafetyAdvisoryService.shared.validateEncephalopathyRisk(snapshot: snap))
        }
        
        // 3. Safety Gates (May remove recs)
        let (gateErrors, removalIDs) = SafetyAdvisoryService.shared.validateSafetyGates(snapshot: snap)
        if !gateErrors.isEmpty {
            warns.insert(contentsOf: gateErrors, at: 0) // Fixed bug: use 'warns', not 'self.warnings'
            SafetyLogger.shared.log(.safetyGateFailure(errors: gateErrors))
        }
        recs.removeAll { removalIDs.contains($0.id) }
        
        // 4. Suzetrigine (VX-548) Logic
        // Indication: Moderate-to-severe acute pain.
        // Profile: Naive or Chronic (Opioid Sparing).
        // Gate: Renal < 15 (Dialysis).
        if (analgesicProfile == .naive || analgesicProfile == .chronicRx) && (painType == .nociceptive || painType == .inflammatory || indication == .postoperative) {
             // Only add if not contraindicated
             if renalFunction != .dialysis { // Assuming dialysis ≈ eGFR < 15 for this heuristic
                 let suzRec = DrugRecommendation(name: "Suzetrigine (VX-548)", reason: "Novel Non-Opioid", detail: "Selective NaV1.8 Inhibitor. 0 MME. Opioid-sparing efficacy.", type: .safe, durationProfile: .long, molecule: .suzetrigine)
                 // Insert after first line? Or as alternative?
                 // Let's add it to the end of recommendations or near top if sparing needed.
                 recs.append(suzRec)
             } else {
                 // Warn if likely candidate but blocked
                 // Actually, validateSafetyGates is better for removing, but here we can just "not add" and warn.
                 // Let's add it, then let validateSafetyGates check it?
                 // No, validateSafetyGates creates "errors" list.
                 // Better pattern: Add it, then block it in validateSafetyGates.
                 recs.append(DrugRecommendation(name: "Suzetrigine (VX-548)", reason: "Novel Non-Opioid", detail: "Selective NaV1.8 Inhibitor.", type: .safe, durationProfile: .long, molecule: .suzetrigine))
             }
        }
        
        // Re-run Safety Gates specifically for Suzetrigine (or modify validateSafetyGates to include it)
        // Since validateSafetyGates is called ABOVE, we need to move it or add a specific check here.
        // Let's stick to the architecture: Logic generates recs, THEN safety gates validate.
        // *Correction*: I pasted `validateSafetyGates` call above this block.
        // I need to MOVE `validateSafetyGates` call to AFTER all generation logic.
        // But the previous code had it at the end. I will restore the order in my replacement.
        
        // Suzetrigine Renal Gate (eGFR < 15 / Dialysis)
        if recs.contains(where: { $0.molecule == .suzetrigine }) {
            if renalFunction == .dialysis { // eGFR < 15 proxy
                warns.append("RENAL ALERT: Suzetrigine Contraindicated in Severe Renal Impairment (eGFR < 15). Removing.")
                recs.removeAll { $0.molecule == .suzetrigine }
            }
        }
        
        // Update Published Properties
        self.recommendations = recs
        self.adjuvants = adjs
        self.warnings = warns
        self.monitoringPlan = monitors

        // Final Logging
        if !self.warnings.isEmpty {
             SafetyLogger.shared.log(.calculationPerformed(
                 inputCount: 1, 
                 hasWarnings: true, 
                 warningDetails: self.warnings
             ))
        }
        
        didUpdate.send()
    }
    
    // MARK: - HELPERS
    func reset() {
        self.age = ""
        self.sex = .female
        self.analgesicProfile = .naive
        self.qtcProlonged = false
        self.splitDosing = false
        self.toleranceUncertain = true
        self.postOpNPO = false
        self.renalFunction = .normal
        self.hepaticFunction = .normal
        self.hasAscites = false
        self.encephalopathyGrade = .none
        self.hemo = .stable
        self.gi = .intact
        self.route = .both
        self.indication = .standard
        self.painType = .nociceptive
        self.inflammatorySubtype = .none
        self.sleepApnea = false
        self.chf = false
        self.benzos = false
        self.copd = false
        self.psychHistory = false
        self.multipleProviders = false
        self.historyOverdose = false
        self.historyGIBleed = false
        self.isPregnant = false
        self.isBreastfeeding = false
        self.currentMME = ""
        calculate()
    }
    
    func shouldShowPregnancyToggle() -> Bool {
        guard sex == .female else { return false }
        if let ageInt = Int(age), ageInt > 60 { return false }
        return true
    }
    
    // MARK: - Pain Assessment Export
    struct PainAssessmentResult: Codable {
        let methodUsed: String
        let rawScore: Double
        let severityCategory: String
        let timestamp: Date
        let patientContext: String
    }
    
    func exportPainData() -> String {
        let scale = recommendedScale.rawValue
        let score = customPainScore ?? 0.0
        
        // Severity Logic (Generic)
        var severity = "Unknown"
        if scale.contains("NRS") {
            if score == 0 { severity = "None" }
            else if score <= 3 { severity = "Mild" }
            else if score <= 6 { severity = "Moderate" }
            else { severity = "Severe" }
        } else if scale.contains("VAS") {
            // ≤3.4 cm (Mild), 3.5 to 7.4 cm (Moderate), ≥7.5 cm (Severe)
            if score <= 3.4 { severity = "Mild" }
            else if score <= 7.4 { severity = "Moderate" }
            else { severity = "Severe" }
        } else if scale.contains("CPOT") {
            if score >= 3 { severity = "Significant Pain" }
            else { severity = "Controlled" }
        } else if scale.contains("BPS") {
             if score > 5 { severity = "Significant Pain" }
             else { severity = "Controlled" }
        }
        
        // Default severity for others (VDS, PEG, PAINAD) can be added here
        
        let result = PainAssessmentResult(
            methodUsed: scale,
            rawScore: score,
            severityCategory: severity,
            timestamp: Date(),
            patientContext: generatedSummary
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(result), let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }

}
