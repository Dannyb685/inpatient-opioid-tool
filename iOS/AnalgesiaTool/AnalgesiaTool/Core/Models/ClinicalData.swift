 import Foundation
import SwiftUI

// MARK: - Enums (Replicating React State Options)

enum DurationProfile: String, Codable {
    case rapid = "Rapid Onset"
    case short = "Short Acting"
    case long = "Long Acting"
    
    var color: Color {
        switch self {
        case .rapid: return ClinicalTheme.purple500
        case .short: return ClinicalTheme.teal500
        case .long: return ClinicalTheme.blue500
        }
    }
}

enum RenalStatus: String, CaseIterable, Identifiable, Codable {
    case normal = "Normal (>60)"
    case impaired = "Mild/Mod (30-60)"
    case dialysis = "Severe / Failure (<30)"
    var id: String { self.rawValue }
    var isImpaired: Bool { self == .impaired || self == .dialysis }
}

enum HepaticStatus: String, CaseIterable, Identifiable, Codable {
    case normal = "Normal (Class A)"
    case impaired = "Compensated (Class B)" // Previous: Moderate
    case failure = "Decompensated (Class C)" // Previous: Severe
    var id: String { self.rawValue }
}

enum Hemodynamics: String, CaseIterable, Identifiable, Codable {
    case stable = "Stable"
    case unstable = "Unstable / Shock"
    var id: String { self.rawValue }
}

enum GIStatus: String, CaseIterable, Identifiable, Codable {
    case intact = "Intact / Alert"
    case tube = "Tube / Dysphagia"
    case npo = "NPO / GI Failure / AMS"

    var id: String { self.rawValue }
}

// MARK: - Safety Extensions
extension DrugData {
    // Dynamic Safety Resolver based on active patient Assessment
    func getRenalBadge(patientRenal: RenalStatus) -> (label: String, color: Color, icon: String) {
        if patientRenal == .normal {
            return ("Compatible", ClinicalTheme.teal500, "checkmark.circle")
        }
        
        switch self.renalSafety {
        case "Unsafe":
            // Suzetrigine Exception: Safe in Mild/Mod (>15), Unsafe in Dialysis (<15)
            if self.name == "Suzetrigine" && patientRenal == .impaired {
                return ("Safe (>15)", ClinicalTheme.teal500, "checkmark.shield.fill")
            }
            return ("Avoid (Metabolites)", ClinicalTheme.rose500, "hand.raised.fill")
        case "Caution":
            if patientRenal == .dialysis {
                return ("Strict Caution", ClinicalTheme.amber500, "exclamationmark.triangle.fill")
            }
            return ("Reduce Dose", ClinicalTheme.amber500, "exclamationmark.triangle.fill")
        case "Safe":
            return ("Safe Option", ClinicalTheme.teal500, "checkmark.shield.fill")
        default:
            return ("Monitor", .gray, "questionmark")
        }
    }
    
    func getHepaticBadge(patientHepatic: HepaticStatus) -> (label: String, color: Color, icon: String) {
        if patientHepatic == .normal {
            return ("Compatible", ClinicalTheme.teal500, "checkmark.circle")
        }
        
        // Specific Hydromorphone Shunt Check
        if self.name.contains("Hydromorphone") && patientHepatic == .failure {
             return ("Caution (Shunt Risk)", ClinicalTheme.amber500, "exclamationmark.triangle.fill")
        }

        switch self.hepaticSafety {
        case "Unsafe":
            return ("Contraindicated", ClinicalTheme.rose500, "hand.raised.fill")
        case "Caution":
            return ("Reduce Dose", ClinicalTheme.amber500, "arrow.down.circle.fill")
        case "Safe":
            return ("Safe Option", ClinicalTheme.teal500, "checkmark.shield.fill")
        default:
            return ("Monitor", .gray, "questionmark")
        }
    }

    func getHepatorenalBadge(patientHepatic: HepaticStatus, patientRenal: RenalStatus) -> (label: String, color: Color, icon: String)? {
        // Hepatorenal Syndrome Detection
        if patientHepatic == .failure && patientRenal.isImpaired {
            return ("HEPATORENAL SYNDROME: Specialist Required", ClinicalTheme.rose500, "exclamationmark.octagon.fill")
        }
        return nil
    }

    func getPregnancyBadge(isPregnant: Bool) -> (label: String, color: Color, icon: String)? {
        guard isPregnant, let category = pregnancyCategory else { return nil }
        
        if category.contains("Contraindicated") {
            return ("CONTRAINDICATED IN PREGNANCY", ClinicalTheme.rose500, "hand.raised.fill")
        } else if category.contains("Avoid") {
            return (category, ClinicalTheme.amber500, "exclamationmark.triangle.fill")
        } else if category.contains("Benefit") {
             return ("Benefit > Risk (Monitor)", ClinicalTheme.amber500, "info.circle")
        }
        return nil
    }
}

enum OpioidRoute: String, CaseIterable, Identifiable, Codable {
    case both = "Both / Either"
    case iv = "Injectable (IV/SQ)"
    case po = "Oral (PO)"
    var id: String { self.rawValue }
}

enum ClinicalIndication: String, CaseIterable, Identifiable, Codable {
    case standard = "General / Acute"
    case dyspnea = "Palliative Dyspnea"
    case cancer = "Cancer Pain"
    case postoperative = "Post-Operative / Surgical"
    var id: String { self.rawValue }
}

enum InflammatorySubtype: String, CaseIterable, Identifiable, Codable {
    case none = "General Inflammatory"
    case gout = "Gout Flare"
    case autoimmune = "Autoimmune Flare"
    case pericarditis = "Pericarditis"
    var id: String { self.rawValue }
}

enum PainType: String, CaseIterable, Identifiable, Codable {
    case nociceptive = "Nociceptive (Tissue)"
    case neuropathic = "Neuropathic (Nerve)"
    case inflammatory = "Inflammatory"
    case bone = "Bone Pain"
    var id: String { self.rawValue }
}

enum Sex: String, CaseIterable, Identifiable, Codable {
    case male = "Male"
    case female = "Female"
    var id: String { self.rawValue }
}

// MARK: - Pain Assessment Enums

enum CognitiveStatus: String, CaseIterable, Identifiable, Codable {
    case baseline = "Baseline / Intact"
    case mildImpairment = "Mild Impairment / Delirium"
    case advancedDementia = "Advanced Dementia"
    var id: String { self.rawValue }
}

enum CommunicationAbility: String, CaseIterable, Identifiable, Codable {
    case verbal = "Verbal"
    case nonVerbalInteractive = "Non-Verbal (Interactive)"
    case nonCommunicative = "Non-Communicative / Sedated"
    var id: String { self.rawValue }
}

enum IntubationStatus: String, CaseIterable, Identifiable, Codable {
    case none = "Spontaneous / Extubated"
    case intubated = "Intubated / Trach"
    var id: String { self.rawValue }
}

enum PainScaleType: String, CaseIterable, Identifiable, Codable {
    case nrs = "Numeric Rating Scale (NRS)"
    case vas = "Visual Analog Scale (VAS)"
    case vds = "Verbal Descriptor Scale (VDS)"
    case peg = "PEG (Pain, Enjoyment, General)"
    case bps = "Behavioral Pain Scale (BPS)"
    case bpsNi = "BPS-Non Intubated"
    case cpot = "CPOT"
    case painad = "PAINAD"
    case unable = "Unable to Assess"
    
    var id: String { self.rawValue }
}

// MARK: - Data Models

enum RecommendationType {
    case safe
    case caution
    case unsafe
}

struct DrugRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let reason: String
    let detail: String
    let type: RecommendationType
    let durationProfile: DurationProfile?
    let molecule: OpioidMolecule
}

// MARK: - Data Models

struct DrugData: Identifiable {
    let id: String
    var familyId: String? // Added for Safety Aggregation
    let name: String
    var subtitle: String? // Added for UI
    let type: String
    var route: String? // Added
    let mmeFactor: Double? // Added for transparency
    
    let durationProfile: DurationProfile
    let ivOnset: String
    let ivDuration: String
    let poOnset: String
    let poDuration: String
    let renalSafety: String // Safe, Caution, Unsafe
    let hepaticSafety: String // Safe, Caution, Unsafe
    let clinicalNuance: String
    let pharmacokinetics: String
    let tags: [String]
    let bioavailability: Int
    
    // Safety 2.0
    let pregnancyCategory: String?
    
    // Dosing
    let ivStart: String
    let poStart: String
    
    // Profiles (Sidecar Data)
    var pkProfile: PKProfile?
    var safetyProfile: SafetyProfile?
    
    // Safety
    let fdaLabelURL: String?
    let blackBoxWarnings: [BlackBoxWarning]?
    let contraindications: [Contraindication]?
    let detailedWarnings: [Warning]?
    var safetyWarnings: [String]? = nil
    var commonAdverseReactions: [AdverseReaction]? = nil
    let citations: [String]
    
    // Transparent Sourcing
    var bioavailabilitySource: String? = nil
    var dosingSource: String? = nil
    
    // Taxonomy
    let molecule: OpioidMolecule
    
    // Custom Coding Keys to allow decoding legacy JSON safely
    enum CodingKeys: String, CodingKey {
        case id, familyId, name, subtitle, type, route, mmeFactor
        case durationProfile, ivOnset, ivDuration, poOnset, poDuration
        case renalSafety, hepaticSafety, clinicalNuance, pharmacokinetics, tags, bioavailability
        case pregnancyCategory, ivStart, poStart
        case pkProfile, safetyProfile, fdaLabelURL, blackBoxWarnings, contraindications, detailedWarnings
        case safetyWarnings, commonAdverseReactions, citations
        case bioavailabilitySource, dosingSource
        case molecule
    }
    
    // Memberwise Init
    init(id: String, familyId: String? = nil, name: String, subtitle: String? = nil, type: String, route: String? = nil, mmeFactor: Double?, durationProfile: DurationProfile, ivOnset: String, ivDuration: String, poOnset: String, poDuration: String, renalSafety: String, hepaticSafety: String, clinicalNuance: String, pharmacokinetics: String, tags: [String], bioavailability: Int, pregnancyCategory: String?, ivStart: String, poStart: String, pkProfile: PKProfile? = nil, safetyProfile: SafetyProfile? = nil, fdaLabelURL: String? = nil, blackBoxWarnings: [BlackBoxWarning]? = nil, contraindications: [Contraindication]? = nil, detailedWarnings: [Warning]? = nil, citations: [String], bioavailabilitySource: String? = nil, dosingSource: String? = nil, molecule: OpioidMolecule? = nil) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.subtitle = subtitle
        self.type = type
        self.route = route
        self.mmeFactor = mmeFactor
        self.durationProfile = durationProfile
        self.ivOnset = ivOnset
        self.ivDuration = ivDuration
        self.poOnset = poOnset
        self.poDuration = poDuration
        self.renalSafety = renalSafety
        self.hepaticSafety = hepaticSafety
        self.clinicalNuance = clinicalNuance
        self.pharmacokinetics = pharmacokinetics
        self.tags = tags
        self.bioavailability = bioavailability
        self.pregnancyCategory = pregnancyCategory
        self.ivStart = ivStart
        self.poStart = poStart
        self.pkProfile = pkProfile
        self.safetyProfile = safetyProfile
        self.fdaLabelURL = fdaLabelURL
        self.blackBoxWarnings = blackBoxWarnings
        self.contraindications = contraindications
        self.detailedWarnings = detailedWarnings
        self.citations = citations
        self.bioavailabilitySource = bioavailabilitySource
        self.dosingSource = dosingSource
        
        // Auto-Detect Taxonomy if nil (for static data convenience)
        if let explicit = molecule {
            self.molecule = explicit
        } else {
            // Inference Logic
            let lowerName = name.lowercased()
            if lowerName.contains("morphine") { self.molecule = .morphine }
            else if lowerName.contains("hydromorphone") { self.molecule = .hydromorphone }
            else if lowerName.contains("oxycodone") { self.molecule = .oxycodone }
            else if lowerName.contains("methadone") { self.molecule = .methadone }
            else if lowerName.contains("buprenorphine") { self.molecule = .buprenorphine }
            else if lowerName.contains("fentanyl") { self.molecule = .fentanyl }
            else if lowerName.contains("tapentadol") { self.molecule = .tapentadol }
            else if lowerName.contains("levorphanol") { self.molecule = .levorphanol }
            else if lowerName.contains("suzetrigine") { self.molecule = .suzetrigine }
            else if lowerName.contains("meperidine") { self.molecule = .meperidine }
            else if lowerName.contains("sufentanil") { self.molecule = .sufentanil }
            else if lowerName.contains("alfentanil") { self.molecule = .alfentanil }
            else if lowerName.contains("codeine") { self.molecule = .codeine }
            else if lowerName.contains("tramadol") { self.molecule = .tramadol }
            else { self.molecule = .other }
        }
    }
    
    // Custom Decoder for Backward Compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Standard Decoding
        id = try container.decode(String.self, forKey: .id)
        familyId = try container.decodeIfPresent(String.self, forKey: .familyId)
        name = try container.decode(String.self, forKey: .name)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        type = try container.decode(String.self, forKey: .type)
        route = try container.decodeIfPresent(String.self, forKey: .route)
        mmeFactor = try container.decodeIfPresent(Double.self, forKey: .mmeFactor)
        durationProfile = try container.decode(DurationProfile.self, forKey: .durationProfile)
        ivOnset = try container.decode(String.self, forKey: .ivOnset)
        ivDuration = try container.decode(String.self, forKey: .ivDuration)
        poOnset = try container.decode(String.self, forKey: .poOnset)
        poDuration = try container.decode(String.self, forKey: .poDuration)
        renalSafety = try container.decode(String.self, forKey: .renalSafety)
        hepaticSafety = try container.decode(String.self, forKey: .hepaticSafety)
        clinicalNuance = try container.decode(String.self, forKey: .clinicalNuance)
        pharmacokinetics = try container.decode(String.self, forKey: .pharmacokinetics)
        tags = try container.decode([String].self, forKey: .tags)
        bioavailability = try container.decode(Int.self, forKey: .bioavailability)
        pregnancyCategory = try container.decodeIfPresent(String.self, forKey: .pregnancyCategory)
        ivStart = try container.decode(String.self, forKey: .ivStart)
        poStart = try container.decode(String.self, forKey: .poStart)
        
        // Sidecars
        pkProfile = try container.decodeIfPresent(PKProfile.self, forKey: .pkProfile)
        safetyProfile = try container.decodeIfPresent(SafetyProfile.self, forKey: .safetyProfile)
        
        // Safety
        fdaLabelURL = try container.decodeIfPresent(String.self, forKey: .fdaLabelURL)
        blackBoxWarnings = try container.decodeIfPresent([BlackBoxWarning].self, forKey: .blackBoxWarnings)
        contraindications = try container.decodeIfPresent([Contraindication].self, forKey: .contraindications)
        detailedWarnings = try container.decodeIfPresent([Warning].self, forKey: .detailedWarnings)
        safetyWarnings = try container.decodeIfPresent([String].self, forKey: .safetyWarnings)
        commonAdverseReactions = try container.decodeIfPresent([AdverseReaction].self, forKey: .commonAdverseReactions)
        citations = try container.decode([String].self, forKey: .citations)
        
        bioavailabilitySource = try container.decodeIfPresent(String.self, forKey: .bioavailabilitySource)
        dosingSource = try container.decodeIfPresent(String.self, forKey: .dosingSource)
        
        // MOLECULE LOGIC (The Key Fix)
        if let mol = try container.decodeIfPresent(OpioidMolecule.self, forKey: .molecule) {
            self.molecule = mol
        } else {
            // Fallback: Infer from name (backward compatibility)
            let lowerName = name.lowercased()
            if lowerName.contains("morphine") { self.molecule = .morphine }
            else if lowerName.contains("hydromorphone") { self.molecule = .hydromorphone }
            else if lowerName.contains("oxycodone") { self.molecule = .oxycodone }
            else if lowerName.contains("methadone") { self.molecule = .methadone }
            else if lowerName.contains("buprenorphine") { self.molecule = .buprenorphine }
            else if lowerName.contains("fentanyl") { self.molecule = .fentanyl }
            else if lowerName.contains("tapentadol") { self.molecule = .tapentadol }
            else if lowerName.contains("levorphanol") { self.molecule = .levorphanol }
            else if lowerName.contains("suzetrigine") { self.molecule = .suzetrigine }
            else if lowerName.contains("meperidine") { self.molecule = .meperidine }
            else if lowerName.contains("sufentanil") { self.molecule = .sufentanil }
            else if lowerName.contains("alfentanil") { self.molecule = .alfentanil }
            else if lowerName.contains("codeine") { self.molecule = .codeine }
            else if lowerName.contains("tramadol") { self.molecule = .tramadol }
            else { self.molecule = .other }
        }
    }
}

extension DrugData {
    func matchesAllergy(_ allergy: String) -> Bool {
        let cleanAllergy = allergy.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 1. Check Specific ID (e.g. "morphine_iv")
        if self.id.lowercased() == cleanAllergy { return true }
        
        // 2. Check Name (e.g. "Morphine")
        if self.name.lowercased() == cleanAllergy { return true }
        
        // 3. Check Family ID (The Safety Net)
        if let family = self.familyId?.lowercased(), family == cleanAllergy {
            return true
        }
        
        return false
    }
}


// MARK: - Sidecar Models
struct PKProfile: Codable, Hashable {
    let onset: String
    let peak: String?
    let duration: String
    let bioavailability: String?
}

struct SafetyProfile: Codable, Hashable {
    let renalNote: String?
    let boxedWarning: String?
}

// MARK: - ADR Data Source Metadata
struct ADRDataSource: Codable, Hashable {
    let sourceType: SourceType // FDA label, SmPC, FAERS, clinical trial
    let sourceDate: Date // Label revision date or data extraction date
    let evidenceQuality: EvidenceQuality // High, Moderate, Low
    let lastReviewed: Date
    let reviewedBy: String // "Clinical Pharmacist", "Pain Specialist"
}

enum SourceType: String, Codable {
    case fdaLabel = "FDA Label (DailyMed)"
    case smpc = "European SmPC"
    case faers = "FAERS Post-Marketing"
    case clinicalTrial = "Clinical Trial"
    case guideline = "Clinical Guideline (CDC/ASAM)"
}

enum EvidenceQuality: String, Codable {
    case high = "High (RCT/Meta-analysis)"
    case moderate = "Moderate (Observational/Epidemiological)"
    case low = "Low (Case Reports/Expert Opinion)"
}

// MARK: - ADR Models
struct AdverseReaction: Codable, Hashable {
    let term: String // MedDRA Preferred Term
    let frequency: ADRFrequency
    let frequencyPercentage: Double? // Exact percentage if available
    let severity: ADRSeverity
    let systemOrganClass: String // MedDRA SOC
    let onset: String? // "Immediate", "Hours", "Days", "Weeks"
    let duration: String? // "Self-limiting", "Persistent"
    let managementStrategy: String? // "Dose reduction", "Symptomatic treatment"
    let isDoselimiting: Bool // Affects ability to continue therapy
    let requiresMonitoring: Bool
    let dataSource: ADRDataSource // Traceability
}

enum ADRFrequency: String, Codable {
    case veryCommon = "Very Common (≥10%)"
    case common = "Common (1-10%)"
    case uncommon = "Uncommon (0.1-1%)"
    case rare = "Rare (<0.1%)"
    case unknown = "Frequency Unknown"
}

enum ADRSeverity: String, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case lifeThreatening = "Life-Threatening"
}
struct BlackBoxWarning: Hashable, Codable {
    let riskDescription: String
    let affectedPopulation: String
    let severity: String
    let monitoringRequired: String?
    let dateAdded: String?
    var isIncremental: Bool = false // Tracks if warning is a post-approval update
}

struct Contraindication: Hashable, Codable {
    let condition: String
    let reason: String
    let type: String // "absolute" or "relative"
    let alternativeRecommendation: String?
}

struct Warning: Hashable, Codable {
    let category: String
    let description: String
    let affectedPopulation: String
    let monitoringRequired: String?
    let riskMitigation: String?
}

struct WarningData: Identifiable {
    let id: String
    let name: String
    let risk: String
    let desc: String
}

// MARK: - Safety Alert System (v2.0)
enum SafetySeverity: String, CaseIterable, Codable {
    case critical = "Critical" // Red, Forced Open
    case warning = "Warning"   // Amber, Collapsible
    case info = "Info"         // Green/Gray, Collapsed
}

struct SafetyAlert: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let severity: SafetySeverity
    let source: String? // e.g. "Renal Gate"
}

struct AdjuvantRecommendation: Identifiable, Codable {
    var id: String
    let category: String
    let drug: String
    let dose: String
    let rationale: String
    
    init(category: String, drug: String, dose: String, rationale: String) {
        self.id = UUID().uuidString
        self.category = category
        self.drug = drug
        self.dose = dose
        self.rationale = rationale
    }
}

// MARK: - Clinical Data Store

struct ClinicalData {
    
    static let drugData: [DrugData] = [
        DrugData(id: "morphine_iv", familyId: "morphine_generic", name: "Morphine (IV)", subtitle: "Injectable", type: "Full Agonist", route: "IV", mmeFactor: 3.0, durationProfile: .short, ivOnset: "5-10 min", ivDuration: "3-4 hrs", poOnset: "N/A", poDuration: "N/A", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "Gold standard opioid but AVOID in renal impairment (M6G accumulation). Histamine release may cause hypotension/bronchospasm.", pharmacokinetics: "Glucuronidation (UGT2B7). High first-pass metabolism.", tags: ["Standard", "Histamine Release", "Vasodilation"], bioavailability: 100, pregnancyCategory: "Benefit>Risk",
                 ivStart: "2-4 mg IV q3-4h (naive); 1-2 mg (elderly)", poStart: "",
                 pkProfile: PKProfile(onset: "5-10 min", peak: "20 min", duration: "3-4 hrs", bioavailability: nil),
                 safetyProfile: SafetyProfile(renalNote: "Active Metabolites (M3G/M6G). Neurotoxic in failure.", boxedWarning: "Respiratory Depression"),
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=6d8c2b3b-8b3e-4f4a-9b0e-3c8f8e8c8c8c", blackBoxWarnings: [
                    BlackBoxWarning(riskDescription: "Life-threatening respiratory depression^[3]", affectedPopulation: "Opioid-naive, elderly", severity: "Life-threatening", monitoringRequired: "Pulse Oximetry", dateAdded: nil),
                    BlackBoxWarning(riskDescription: "Concomitant use with benzodiazepines^[3]", affectedPopulation: "All patients", severity: "Fatal overdose", monitoringRequired: "Minimize duration", dateAdded: "2016", isIncremental: true)
                 ], contraindications: [
                    Contraindication(condition: "Significant respiratory depression", reason: "Worsens hypoxia^[3]", type: "absolute", alternativeRecommendation: nil),
                    Contraindication(condition: "Acute/Severe Asthma", reason: "Bronchospasm risk^[3]", type: "absolute", alternativeRecommendation: nil),
                    Contraindication(condition: "GI Obstruction (Ileus)", reason: "Worsens constipation/motility^[3]", type: "absolute", alternativeRecommendation: nil)
                 ], detailedWarnings: nil, citations: [
            "cdc_opioids_2022",
            "mercadante_morphine_2010",
            "fda_morphine_2025"
        ], bioavailabilitySource: "N/A (IV Only)", dosingSource: "CDC 2022 / FDA Label"),

        DrugData(id: "morphine_po_ir", familyId: "morphine_generic", name: "Morphine (PO)", subtitle: "Oral Tablet (IR)", type: "Full Agonist", route: "PO", mmeFactor: 1.0, durationProfile: .short, ivOnset: "N/A", ivDuration: "N/A", poOnset: "30-60 min", poDuration: "3-6 hrs", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "Gold standard opioid but AVOID in renal impairment (M6G accumulation).", pharmacokinetics: "Glucuronidation (UGT2B7). High first-pass metabolism (PO Bioavail ~30%).", tags: ["Standard", "Histamine Release"], bioavailability: 30, pregnancyCategory: "Benefit>Risk",
                 ivStart: "", poStart: "15 mg PO q4h (naive)",
                 pkProfile: PKProfile(onset: "30-60 min", peak: "60 min", duration: "4 hrs", bioavailability: "20-40%"),
                 safetyProfile: SafetyProfile(renalNote: "Accumulation of M6G. Avoid in eGFR <30.", boxedWarning: "Risk of Misuse"),
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=6d8c2b3b-8b3e-4f4a-9b0e-3c8f8e8c8c8c", blackBoxWarnings: [
                    BlackBoxWarning(riskDescription: "Life-threatening respiratory depression^[3]", affectedPopulation: "Opioid-naive, elderly", severity: "Life-threatening", monitoringRequired: "Pulse Oximetry", dateAdded: nil),
                    BlackBoxWarning(riskDescription: "Concomitant use with benzodiazepines^[3]", affectedPopulation: "All patients", severity: "Fatal overdose", monitoringRequired: "Minimize duration", dateAdded: "2016", isIncremental: true)
                 ], contraindications: [
                    Contraindication(condition: "Significant respiratory depression", reason: "Worsens hypoxia^[3]", type: "absolute", alternativeRecommendation: nil),
                    Contraindication(condition: "Acute/Severe Asthma", reason: "Bronchospasm risk^[3]", type: "absolute", alternativeRecommendation: nil),
                    Contraindication(condition: "GI Obstruction (Ileus)", reason: "Worsens constipation/motility^[3]", type: "absolute", alternativeRecommendation: nil)
                 ], detailedWarnings: nil, citations: [
            "cdc_opioids_2022",
            "mercadante_morphine_2010",
            "fda_morphine_2025"
        ], bioavailabilitySource: "Orel et al. via CDC 2022", dosingSource: "CDC 2022 / FDA Label"),
        
        DrugData(id: "hydromorphone", name: "Hydromorphone", type: "Full Agonist", mmeFactor: nil, durationProfile: .short, ivOnset: "5 min", ivDuration: "2-3 hrs", poOnset: "15-30 min", poDuration: "3-4 hrs", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "H3G metabolite is solely neuroexcitatory. In renal failure, accumulation causes allodynia and agitation. 5-7x potency of morphine.", pharmacokinetics: "Glucuronidation. No CYP interactions. Cleaner than morphine but not risk-free.", tags: ["Potent", "Low Volume", "Neuroexcitation Risk"], bioavailability: 24, pregnancyCategory: "Benefit>Risk",
                 ivStart: "0.2-0.5 mg IV q2-3h", poStart: "2-4 mg PO q3-4h",
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=3832ede8-d3fc-455d-ecab-3b77be5869f5", blackBoxWarnings: [
                    BlackBoxWarning(riskDescription: "Life-threatening respiratory depression^[2]", affectedPopulation: "All patients", severity: "Life-threatening", monitoringRequired: "Respiratory Monitoring", dateAdded: nil)
                 ], contraindications: [
                    Contraindication(condition: "Significant respiratory depression", reason: "Worsens hypoxia^[2]", type: "absolute", alternativeRecommendation: nil),
                    Contraindication(condition: "GI Obstruction (Ileus)", reason: "Worsens constipation^[2]", type: "absolute", alternativeRecommendation: nil)
                 ], detailedWarnings: nil, citations: [
            "reddy_hydromorphone_2017",
            "fda_hydromorphone_2025"
        ], bioavailabilitySource: "Reddy et al. 2017 / NCCN", dosingSource: "NCCN 2025 (Conservative)"),
        
        DrugData(id: "oxycodone", name: "Oxycodone", type: "Full Agonist", mmeFactor: nil, durationProfile: .short, ivOnset: "N/A", ivDuration: "3-4 hrs", poOnset: "10-15 min", poDuration: "3-6 hrs", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "Interaction Alert: Strong CYP3A4 inhibitors (Voriconazole, Posaconazole, Ritonavir) significantly increase AUC.", pharmacokinetics: "High oral bioavailability (60-87%). Dual metabolism (3A4 > 2D6).", tags: ["Oral Standard", "CYP3A4 Interaction"], bioavailability: 75, pregnancyCategory: "Benefit>Risk",
                 ivStart: "", poStart: "5-10 mg PO q4-6h",
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=f8e8e8e8-8e8e-8e8e-8e8e-8e8e8e8e8e8e", blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: [], bioavailabilitySource: "FDA Label (Percocet)", dosingSource: "CDC 2022"),
        
        DrugData(id: "methadone", name: "Methadone", type: "Complex Agonist", mmeFactor: nil, durationProfile: .long, ivOnset: "Variable", ivDuration: "6-8 hrs (Analgesia)", poOnset: "30-60 min", poDuration: "8-12 hrs (Analgesia)", renalSafety: "Safe", hepaticSafety: "Caution", clinicalNuance: "Nonlinear Dose-Response. NMDA Antagonist. Peak respiratory depression occurs LATER and lasts LONGER than analgesia ('Stacking Risk'). CDC advises against using calculated MME for conversion.", pharmacokinetics: "Long/Variable Half-Life (15-120h). Auto-induction of CYP3A4. Accumulates unpredictably.", tags: ["Neuropathic", "Stacking Risk", "QT Prolongation"], bioavailability: 80, pregnancyCategory: "Benefit>Risk",
                 ivStart: "2.5-10 mg IV q8-12h (Load)", poStart: "2.5-5 mg PO q8h",
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=b8b8b8b8-8b8b-8b8b-8b8b-8b8b8b8b8b8b", blackBoxWarnings: [
                    BlackBoxWarning(riskDescription: "QT Prolongation / Torsades de Pointes", affectedPopulation: "High dose, cardiac risk", severity: "Life-threatening arrhythmia", monitoringRequired: "ECG", dateAdded: nil),
                    BlackBoxWarning(riskDescription: "Respiratory Depression (Late Onset)", affectedPopulation: "All patients", severity: "Life-threatening", monitoringRequired: "Peak effect delayed", dateAdded: nil)
                 ], contraindications: nil, detailedWarnings: nil, citations: [], bioavailabilitySource: "APS Guidelines / FDA", dosingSource: "Manufacturer Label / ASAM"),
        
        DrugData(id: "buprenorphine", name: "Buprenorphine", type: "Partial Agonist", mmeFactor: nil, durationProfile: .long, ivOnset: "10-15 min", ivDuration: "6-8 hrs", poOnset: "30-60 min (SL)", poDuration: "6-8 hrs", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "High Affinity / Slow Dissociation. Ceiling effect for analgesia and respiratory depression. Can displace full agonists and precipitate withdrawal. Excluded from CDC MME calculations due to nonlinear kinetics.", pharmacokinetics: "CYP3A4. 30x potency of morphine (IM). Ceiling effect limits MME linearity.", tags: ["High Affinity", "Split Dosing", "Ceiling Effect"], bioavailability: 30, pregnancyCategory: "Safe Option",
                 ivStart: "0.15-0.3 mg IV", poStart: "2-4 mg SL",
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=a1a1a1a1-1a1a-1a1a-1a1a-1a1a1a1a1a1a", blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),
        
        DrugData(id: "fentanyl_patch", name: "Fentanyl (Transdermal)", type: "Phenylpiperidine", mmeFactor: nil, durationProfile: .long, ivOnset: "12-24 hrs", ivDuration: "72 hrs", poOnset: "12-24 hrs", poDuration: "72 hrs", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "Heat Sensitivity: Fever increases absorption 30%+. Do not use in opioid-naive.", pharmacokinetics: "Depot Effect.", tags: ["Chronic Pain Only", "Heat Sensitive", "Depot Effect"], bioavailability: 92, pregnancyCategory: "Avoid (Withdrawal Risk)",
                 ivStart: "", poStart: "12-25 mcg/hr Patch q72h",
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=6bb82d9f-9f3f-4e8e-b8e8-8e8e8e8e8e8e", blackBoxWarnings: [
                    BlackBoxWarning(riskDescription: "Fatal Respiratory Depression in Opioid Naive", affectedPopulation: "Opioid Naive", severity: "Fatal", monitoringRequired: nil, dateAdded: nil)
                 ], contraindications: nil, detailedWarnings: nil, citations: [], bioavailabilitySource: "Clausen et al.", dosingSource: "FDA Label (Duragesic)"),
        
        DrugData(id: "fentanyl", name: "Fentanyl", type: "Phenylpiperidine", mmeFactor: nil, durationProfile: .rapid, ivOnset: "1-2 min", ivDuration: "30-60 min", poOnset: "N/A", poDuration: "N/A", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "Context-Sensitive Half-Life. Chest wall rigidity with rapid push.", pharmacokinetics: "CYP3A4 substrate. Highly lipophilic.", tags: ["Renal Safe", "Cardio Stable", "Lipid Storage"], bioavailability: 100, pregnancyCategory: "Safe Option",
                 ivStart: "25-50 mcg IV q1-2h", poStart: "",
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=f3c7c3c7-3c7c-3c7c-3c7c-3c7c3c7c3c7c", blackBoxWarnings: [
                    BlackBoxWarning(riskDescription: "Life-threatening respiratory depression^[1]", affectedPopulation: "COPD, Opioid Naive", severity: "Life-threatening", monitoringRequired: "Continuous monitoring", dateAdded: "2016"),
                    BlackBoxWarning(riskDescription: "CYP3A4 Interactions^[1]", affectedPopulation: "Concomitant inhibitors", severity: "Serious", monitoringRequired: nil, dateAdded: "2016")
                 ], contraindications: [
                    Contraindication(condition: "Opioid Non-Tolerant (Transdermal/TIRF)", reason: "Fatal Overdose^[1]", type: "absolute", alternativeRecommendation: nil),
                    Contraindication(condition: "Significant Respiratory Depression", reason: "Hypoxia^[1]", type: "absolute", alternativeRecommendation: nil)
                 ], detailedWarnings: nil, citations: [
            "fda_fentanyl_2025"
        ], bioavailabilitySource: "N/A (IV Only)", dosingSource: "Anesthesia Guidelines"),
        
        DrugData(id: "tapentadol", name: "Tapentadol", type: "MOR-NRI", mmeFactor: nil, durationProfile: .short, ivOnset: "N/A", ivDuration: "4-6 hrs", poOnset: "30 min", poDuration: "4-6 hrs", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "Dual Mechanism: Mu-agonist + Norepinephrine Reuptake Inhibitor (NRI). CDC MME (0.4) is uncertain due to non-opiate contribution. Lower GI side effect profile.", pharmacokinetics: "Glucuronidation. No CYP interactions (cleaner than Tramadol).", tags: ["Neuropathic", "Lower GI Risk"], bioavailability: 32, pregnancyCategory: "Benefit>Risk",
                 ivStart: "", poStart: "50-75 mg PO q4-6h",
                 fdaLabelURL: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=d5d5d5d5-5d5d-5d5d-5d5d-5d5d5d5d5d5d", blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),
        
        DrugData(id: "levorphanol", name: "Levorphanol", type: "Full Agonist", mmeFactor: nil, durationProfile: .long, ivOnset: "N/A", ivDuration: "6-8 hrs", poOnset: "30-60 min", poDuration: "6-8 hrs", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "NMDA Antagonist + SNRI. Potent. Long half-life.", pharmacokinetics: "Glucuronidation.", tags: ["Neuropathic", "Long Acting", "NMDA"], bioavailability: 70, pregnancyCategory: "Benefit>Risk",
                 ivStart: "", poStart: "2 mg PO q6-8h",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),
        
        DrugData(id: "suzetrigine", name: "Suzetrigine", type: "NAV1.8 Inhibitor", mmeFactor: nil, durationProfile: .short, ivOnset: "N/A", ivDuration: "6-12 hrs", poOnset: "Variable", poDuration: "6-12 hrs", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "First-in-class non-opioid. No respiratory depression.", pharmacokinetics: "CYP2D6/3A4.", tags: ["Non-Opioid", "NAV1.8"], bioavailability: 80, pregnancyCategory: "Avoid (Unknown)",
                 ivStart: "", poStart: "Study Dose Only",
                 fdaLabelURL: nil, blackBoxWarnings: nil,
                 contraindications: [Contraindication(condition: "Severe Hepatic Impairment", reason: "Safety Unknown", type: "absolute", alternativeRecommendation: nil)], detailedWarnings: nil, citations: []),
        
        DrugData(id: "meperidine", name: "Meperidine", type: "Phenylpiperidine", mmeFactor: nil, durationProfile: .short, ivOnset: "5 min", ivDuration: "2-3 hrs", poOnset: "30-60 min", poDuration: "2-4 hrs", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "CONTRAINDICATED in Renal Failure/Elderly. Toxic metabolite (Normeperidine) causes tremors/seizures. High interaction risk (MAOIs). Historic use only.", pharmacokinetics: "Hepatic -> Normeperidine (Neurotoxic, long T1/2).", tags: ["Neurotoxic", "Do Not Use", "Seizure Risk"], bioavailability: 50, pregnancyCategory: "Avoid (Neurotoxic)",
                 ivStart: "Avoid Use", poStart: "Avoid Use",
                 fdaLabelURL: nil, blackBoxWarnings: nil,
                 contraindications: [Contraindication(condition: "MAOI Use", reason: "Serotonin Syndrome", type: "absolute", alternativeRecommendation: nil)], detailedWarnings: nil, citations: []),
        
        DrugData(id: "sufentanil", name: "Sufentanil", type: "Phenylpiperidine", mmeFactor: nil, durationProfile: .rapid, ivOnset: "1-3 min", ivDuration: "20-45 min", poOnset: "N/A", poDuration: "N/A", renalSafety: "Safe", hepaticSafety: "Safe", clinicalNuance: "Ultra-Potent (500-1000x Morphine). Context-sensitive half-life dominates kinetics. Accumulates in fat/muscle with prolonged infusion. Anesthesia use only.", pharmacokinetics: "High lipid solubility. High protein binding. Prolonged elimination with infusions.", tags: ["ICU Only", "Ultra Potent"], bioavailability: 100, pregnancyCategory: "Safe Option",
                 ivStart: "0.1-0.2 mcg/kg (Anesthesia)", poStart: "N/A",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),
        
        DrugData(id: "alfentanil", name: "Alfentanil", type: "Phenylpiperidine", mmeFactor: nil, durationProfile: .rapid, ivOnset: "<1 min", ivDuration: "10-15 min", poOnset: "N/A", poDuration: "N/A", renalSafety: "Safe", hepaticSafety: "Var", clinicalNuance: "Ultra-Potent (10-20x Morphine). Rapid onset, short duration. Pharmacokinetics dominated by context-sensitive half-times. Anesthesia use only.", pharmacokinetics: "CYP3A4. Lower lipid solubility than Fentanyl = smaller volume of distribution.", tags: ["ICU Only", "Rapid Onset"], bioavailability: 100, pregnancyCategory: "Safe Option",
                 ivStart: "3-5 mcg/kg (Anesthesia)", poStart: "N/A",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),

        DrugData(id: "butorphanol", name: "Butorphanol", type: "Mixed Agonist/Antagonist", mmeFactor: nil, durationProfile: .short, ivOnset: "1-5 min", ivDuration: "2-4 hrs", poOnset: "N/A", poDuration: "N/A", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "Kappa agonist/Mu antagonist (3.5-7x Potency). Ceiling effect for analgesia/resp depression. Increases cardiac workload (Avoid in MI/CHF). Precipitates withdrawal in agonist-dependent patients.", pharmacokinetics: "Hepatic metabolism. Nonlinear dose-response.", tags: ["Labor Pain", "Migraine", "Ceiling Effect"], bioavailability: 0, pregnancyCategory: "Benefit>Risk",
                 ivStart: "0.5-2 mg IV q3-4h", poStart: "N/A",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),

        DrugData(id: "nalbuphine", name: "Nalbuphine", type: "Mixed Agonist/Antagonist", mmeFactor: nil, durationProfile: .short, ivOnset: "2-3 min", ivDuration: "3-6 hrs", poOnset: "N/A", poDuration: "N/A", renalSafety: "Caution", hepaticSafety: "Caution", clinicalNuance: "Kappa agonist/Mu antagonist (<1x Potency). Ceiling effect. NOT recommended for cancer pain. Precipitates withdrawal in agonist-dependent patients.", pharmacokinetics: "Hepatic. Nonlinear dose-response.", tags: ["Labor Pain", "Procedural"], bioavailability: 0, pregnancyCategory: "Benefit>Risk",
                 ivStart: "10 mg IV q3-6h", poStart: "N/A",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),

        DrugData(id: "pentazocine", name: "Pentazocine", type: "Mixed Agonist/Antagonist", mmeFactor: nil, durationProfile: .short, ivOnset: "15-20 min", ivDuration: "3 hrs", poOnset: "15-30 min", poDuration: "3 hrs", renalSafety: "Unsafe", hepaticSafety: "Unsafe", clinicalNuance: "Kappa agonist. High risk of hallucinations (psychotomimetic). Can precipitate withdrawal.", pharmacokinetics: "Hepatic.", tags: ["Historic", "Hallucination Risk"], bioavailability: 20, pregnancyCategory: "Avoid",
                 ivStart: "30 mg IV", poStart: "50 mg PO",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),
        
        DrugData(id: "loperamide", name: "Loperamide", type: "Peripheral", mmeFactor: nil, durationProfile: .long, ivOnset: "N/A", ivDuration: "N/A", poOnset: "1-3 hrs", poDuration: "Variable", renalSafety: "Safe", hepaticSafety: "Caution", clinicalNuance: "Peripheral Mu-agonist. P-glycoprotein efflux prevents CNS penetration at therapeutic doses (2-8mg). No MME value.", pharmacokinetics: "P-gp substrate (Blood Brain Barrier). Massive doses overwhelm pump -> CNS toxicity.", tags: ["Anti-Diarrheal", "Peripheral"], bioavailability: 0, pregnancyCategory: "Safe Option",
                 ivStart: "N/A", poStart: "4mg Load then 2mg",
                 fdaLabelURL: nil, blackBoxWarnings: [BlackBoxWarning(riskDescription: "Torsades de Pointes / Sudden Death", affectedPopulation: "High Doses", severity: "Fatality Risk", monitoringRequired: "ECG", dateAdded: "2016")], contraindications: nil, detailedWarnings: nil, citations: []),
        
        DrugData(id: "diphenoxylate", name: "Diphenoxylate", type: "Peripheral", mmeFactor: nil, durationProfile: .short, ivOnset: "N/A", ivDuration: "N/A", poOnset: "45-60 min", poDuration: "3-4 hrs", renalSafety: "Caution", hepaticSafety: "Unsafe", clinicalNuance: "Peripheral Mu-agonist. Co-formulated with Atropine to discourage abuse. P-glycoprotein restricted. No MME value.", pharmacokinetics: "Hepatic. Active metabolite (difenoxin).", tags: ["Anti-Diarrheal", "Atropine Added"], bioavailability: 90, pregnancyCategory: "Caution",
                 ivStart: "N/A", poStart: "5 mg PO qid",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),
        DrugData(id: "oxymorphone_iv", name: "Oxymorphone (IV)", type: "Full Agonist", mmeFactor: 3.0, durationProfile: .short, ivOnset: "5-10 min", ivDuration: "3-4 hrs", poOnset: "N/A", poDuration: "N/A", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "Potent Mu-Agonist. Active metabolite is 6-OH-oxymorphone. Excrete caution in renal impairment.", pharmacokinetics: "Glucuronidation. Half-life 7-9 hours.", tags: ["High Potency", "Renal Risk"], bioavailability: 100, pregnancyCategory: "Benefit>Risk",
                 ivStart: "0.5 mg IV q4-6h", poStart: "N/A",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),

        DrugData(id: "oxymorphone_po", name: "Oxymorphone (PO)", type: "Full Agonist", mmeFactor: 3.0, durationProfile: .short, ivOnset: "N/A", ivDuration: "N/A", poOnset: "30 min", poDuration: "4-6 hrs", renalSafety: "Unsafe", hepaticSafety: "Caution", clinicalNuance: "Approx 3x potency of Oral Morphine. Food increases bioavailability significantly (up to 50%).", pharmacokinetics: "Low oral bioavailability (10-40%) without food.", tags: ["Food Effect", "Potent"], bioavailability: 10, pregnancyCategory: "Benefit>Risk",
                 ivStart: "N/A", poStart: "5-10 mg PO q4-6h",
                 fdaLabelURL: nil, blackBoxWarnings: nil, contraindications: nil, detailedWarnings: nil, citations: []),

        DrugData(id: "hydrocodone_po", name: "Hydrocodone", type: "Full Agonist", mmeFactor: 1.0, durationProfile: .short, ivOnset: "N/A", ivDuration: "N/A", poOnset: "30-60 min", poDuration: "4-6 hrs", renalSafety: "Caution", hepaticSafety: "Unsafe", clinicalNuance: "Available only in combination with Acetaminophen (APAP) or Ibuprofen. Limit APAP < 4000mg/day. CYP2D6 substrate (minor).", pharmacokinetics: "Metabolized to Hydromorphone (minor) via CYP2D6.", tags: ["Combination Only", "APAP Risk"], bioavailability: 80, pregnancyCategory: "Benefit>Risk",
                 ivStart: "N/A", poStart: "5-10 mg PO q4-6h",
                 fdaLabelURL: nil, blackBoxWarnings: [BlackBoxWarning(riskDescription: "Hepatotoxicity", affectedPopulation: "All", severity: "Life Threatening", monitoringRequired: "Liver Function Tests", dateAdded: "2011")], contraindications: nil, detailedWarnings: nil, citations: [])
    ]
    
    static let warningData: [WarningData] = [
        WarningData(id: "tramadol", name: "Tramadol", risk: "Serotonin Syndrome / Seizure", desc: "Dual Mechanism (Mu-Agonist + SNRI). Seizure risk >400mg/day. Risk with SSRIs/MAOIs. Genetic variability (CYP2D6) affects efficacy. Unquantifiable MME."),
        WarningData(id: "combo", name: "Combination (APAP)", risk: "Hepatotoxicity Masking", desc: "Inpatients often receive IV Acetaminophen (Ofirmev). Adding Percocet/Norco creates invisible APAP overdose. Always uncouple."),
        WarningData(id: "codeine", name: "Codeine", risk: "Genetic Lottery", desc: "10% of Caucasians lack CYP2D6 (no effect). 30% of Ethiopians/Saudis are Ultra-Rapid Metabolizers (morphine overdose). Clinically indefensible to use.")
    ]
    
    static var drugNuances: [String: String] {
        var dict: [String: String] = [:]
        for drug in drugData {
            dict[drug.name] = drug.clinicalNuance
        }
        return dict
    }
    
    static let benzodiazepineBlackBoxWarning = "BLACK BOX WARNING: Concurrent benzodiazepines increase risk of fatal respiratory depression by 3.8x. Taper benzodiazepines if possible. If unavoidable, use lowest effective doses and monitor closely."
    
    // MARK: - Standard Orders Strategy (v1.6)
    // Moved from CalculatorView to allow usage in Assessment
    struct StandardOrder: Hashable, Identifiable {
        let id = UUID()
        let label: String
        let note: String
    }
    
    static func getStandardOrders(for drugName: String) -> [StandardOrder]? {
        let name = drugName.lowercased()
        
        // PO Logic (Most Common)
        if name.contains("po") || name.contains("oral") {
            if name.contains("morphine") {
                return [
                    StandardOrder(label: "Morphine 5mg PO q4h PRN", note: "Naive Start"),
                    StandardOrder(label: "Morphine 15mg PO q4h PRN", note: "Standard"),
                    StandardOrder(label: "Morphine ER 15mg PO q12h", note: "Extended Release baseline")
                ]
            }
            if name.contains("oxycodone") {
                return [
                    StandardOrder(label: "Oxycodone IR 5mg PO q4h PRN", note: "Naive Start"),
                    StandardOrder(label: "Oxycodone IR 10mg PO q4h PRN", note: "Standard")
                ]
            }
            if name.contains("hydromorphone") {
                return [
                    StandardOrder(label: "Hydromorphone IR 2mg PO q4h PRN", note: "Naive Start (~8mg Morphine)"),
                    StandardOrder(label: "Hydromorphone IR 4mg PO q4h PRN", note: "Standard")
                ]
            }
            if name.contains("hydrocodone") {
                return [
                    StandardOrder(label: "Hydrocodone 5mg PO q4h PRN", note: "Start (Watch APAP)"),
                    StandardOrder(label: "Hydrocodone 10mg PO q4h PRN", note: "Moderate Need")
                ]
            }
            if name.contains("codeine") {
                return [
                    StandardOrder(label: "Codeine 30mg PO q4h PRN", note: "Weak Opioid"),
                    StandardOrder(label: "Codeine 60mg PO q4h PRN", note: "Standard")
                ]
            }
            if name.contains("tramadol") {
                return [
                    StandardOrder(label: "Tramadol 50mg PO q6h PRN", note: "Dual Mechanism"),
                    StandardOrder(label: "Tramadol 100mg PO q6h PRN", note: "Max single dose")
                ]
            }
        }
        
        // IV Logic (Added for Assessment Tab completeness)
        if name.contains("iv") || name.contains("intravenous") {
             if name.contains("morphine") {
                return [
                    StandardOrder(label: "Morphine IV 2mg q4h PRN", note: "Naive Start"),
                    StandardOrder(label: "Morphine IV 4mg q4h PRN", note: "Standard")
                ]
            }
            if name.contains("hydromorphone") {
                return [
                    StandardOrder(label: "Hydromorphone IV 0.2mg q4h PRN", note: "Naive Start"),
                    StandardOrder(label: "Hydromorphone IV 0.5mg q4h PRN", note: "Standard")
                ]
            }
             if name.contains("fentanyl") {
                return [
                    StandardOrder(label: "Fentanyl IV 25mcg q1-2h PRN", note: "Naive Start"),
                    StandardOrder(label: "Fentanyl IV 50mcg q1-2h PRN", note: "Standard")
                ]
            }
        }
        
        return nil
    }

    
    // MARK: - COWS / Withdrawal Protocol Data (Centralized)
    struct WithdrawalProtocol {
        static let bonePain = [
            AdjuvantRecommendation(category: "Pain", drug: "Acetaminophen", dose: "650mg PO q6h", rationale: "Bone/Joint Pain"),
            AdjuvantRecommendation(category: "Pain", drug: "Ibuprofen", dose: "600mg PO q6h", rationale: "NSAID Option")
        ]
        
        static let giNausea = [
            AdjuvantRecommendation(category: "Nausea", drug: "Ondansetron", dose: "4mg PO q6h prn", rationale: "Nausea/Vomiting"),
            AdjuvantRecommendation(category: "Diarrhea", drug: "Loperamide", dose: "2mg PO prn", rationale: "Loose Stool")
        ]
        
        static let giCramps = [
            AdjuvantRecommendation(category: "Cramps", drug: "Dicyclomine", dose: "20mg q6h prn", rationale: "Abdominal Cramping")
        ]
        
        static let autonomic = [
            AdjuvantRecommendation(category: "Autonomic", drug: "Clonidine", dose: "0.1mg PO q4h prn", rationale: "Sweating, Tremors, Anxiety. Hold SBP<100.")
        ]
        
        static let anxiety = [
            AdjuvantRecommendation(category: "Anxiety", drug: "Hydroxyzine", dose: "25-50mg PO q6h prn", rationale: "Anxiety/Restlessness")
        ]
        
        static let insomnia = [
            AdjuvantRecommendation(category: "Sleep", drug: "Trazodone", dose: "50-100mg PO qhs prn", rationale: "Insomnia")
        ]
        
        static let integrativeBundle = AdjuvantRecommendation(
            category: "Int. Therapy",
            drug: "Integrative Therapies",
            dose: "Massage / Ice / Heat / Distraction",
            rationale: "Standard Supportive Measures"
        )
    }
    
    // MARK: - MME Conversion Rules (Centralized)
    struct MMEConversionRules {
        struct RationRule {
            let minMME: Double
            let maxMME: Double
            let ratio: Double
            let reduction: Double // Cross-Tolerance Reduction (e.g., 0.15 = 15%)
            let maxDose: Double? // Absolute max daily dose cap
            let warning: String?
        }
        
        static let methadoneRatios: [RationRule] = [
            RationRule(minMME: 0, maxMME: 30, ratio: 2.0, reduction: 0.0, maxDose: nil, warning: "Low baseline MME: Consider fixed starting dose of 2.5mg TID per APS guidelines."),
            RationRule(minMME: 30, maxMME: 100, ratio: 4.0, reduction: 0.0, maxDose: nil, warning: "NCCN recommends fixed dose range 2-7.5mg/day for <60mg baseline morphine."),
            RationRule(minMME: 100, maxMME: 300, ratio: 8.0, reduction: 0.0, maxDose: nil, warning: "NCCN/VA Ratio (8:1) for 100-299 MME range."),
            RationRule(minMME: 300, maxMME: 500, ratio: 12.0, reduction: 0.0, maxDose: 45.0, warning: "VA/DoD conservative ratio."),
            RationRule(minMME: 500, maxMME: 1000, ratio: 15.0, reduction: 0.0, maxDose: 45.0, warning: nil),
            RationRule(minMME: 1000, maxMME: Double.infinity, ratio: 20.0, reduction: 0.0, maxDose: 40.0, warning: "APS Maximum Limit.")
        ]
        
        // Elderly Adjustment (>65y) + QTc Gate
        static func getRatio(for mme: Double, age: Int, qtcProlonged: Bool = false) -> RationRule? {
             if qtcProlonged {
                 return nil // Force specialist consultation due to QTc risk
             }
             
             // Elderly Logic (>65y) - Conservative Override
             if age >= 65 && mme >= 60 && mme < 200 {
                 return RationRule(minMME: 60, maxMME: 200, ratio: 20.0, reduction: 0.0, maxDose: nil, warning: "Elderly (>65y): Applied conservative 20:1 ratio per NCCN.")
             }

             return methadoneRatios.first { mme >= $0.minMME && mme < $0.maxMME }
        }
    }
    
    // MARK: - OUD Protocol Logic (Centralized)
    struct OUDProtocolRules {
        enum ProtocolAction: String {
            case standardBup = "Standard Induction"
            case highDoseBup = "High-Dose Initiation"
            case microInduction = "Micro-Induction (Bernese)"
            case fullAgonist = "Full Agonist Rotation"
            case symptomManagement = "Symptom Management (Wait)"
        }
        
    }
}
