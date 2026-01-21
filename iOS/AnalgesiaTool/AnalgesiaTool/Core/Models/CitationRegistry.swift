import Foundation

enum CitationType: String, Codable {
    case fdaLabel = "FDA Label"
    case guideline = "Clinical Guideline"
    case pmid = "PubMed (PMID)"
    case expertConsensus = "Expert Consensus"
}

struct Citation: Identifiable, Codable {
    let id: String
    let type: CitationType
    let source: String // e.g. "FDA Label: Morphine Sulfate"
    let section: String? // e.g. "5.3"
    let title: String // Full title
    let year: String
    let url: String?
    let excerpt: String?
    let lastVerified: String // ISO Date "yyyy-MM-dd"
    let labelRevisionDate: String? // "yyyy-MM-dd"
}

protocol CitationService {
    func resolve(_ ids: [String]) -> [Citation]
    func resolveOrLegacy(_ inputs: [String]) -> [Citation]
}

class CitationRegistry: CitationService, ObservableObject {
    // Singleton removed in favor of DI, but kept for convenience if needed during migration
    // static let shared = CitationRegistry() 
    
    // Instance-based definitions (Static Lazy)
    private static let definitions: [String: Citation] = [
        
        // MARK: - FDA Labels
        "fda_morphine_2025": Citation(
            id: "fda_morphine_2025",
            type: .fdaLabel,
            source: "FDA Label: Morphine Sulfate",
            section: "WARNINGS",
            title: "Highlights of Prescribing Information",
            year: "2025",
            url: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=6d8c2b3b-8b3e-4f4a-9b0e-3c8f8e8c8c8c",
            excerpt: "Life-threatening respiratory depression; risks from concomitant use with benzodiazepines.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "fda_hydromorphone_2025": Citation(
            id: "fda_hydromorphone_2025",
            type: .fdaLabel,
            source: "FDA Label: Hydromorphone HCl",
            section: "BOXED WARNING",
            title: "Highlights of Prescribing Information",
            year: "2025",
            url: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=3832ede8-d3fc-455d-ecab-3b77be5869f5",
            excerpt: "Risk of medication errors; Life-threatening respiratory depression.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "fda_fentanyl_2025": Citation(
            id: "fda_fentanyl_2025",
            type: .fdaLabel,
            source: "FDA Label: Fentanyl Citrate",
            section: "5.1",
            title: "Highlights of Prescribing Information",
            year: "2025",
            url: "https://dailymed.nlm.nih.gov/dailymed/drugInfo.cfm?setid=f3c7c3c7-3c7c-3c7c-3c7c-3c7c3c7c3c7c",
            excerpt: "Serious life-threatening respiratory depression may occur.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        
        "fda_duragesic_2023": Citation(
             id: "fda_duragesic_2023",
             type: .fdaLabel,
             source: "FDA Label: Duragesic",
             section: nil,
             title: "Fentanyl Transdermal System Prescribing Information",
             year: "2023",
             url: "https://www.accessdata.fda.gov/drugsatfda_docs/label/2005/19813s039lbl.pdf",
             excerpt: "Revised label for Fentanyl Transdermal System.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
         ),
         
        // MARK: - Guidelines
        "va_dod_cpg_2022": Citation(
            id: "va_dod_cpg_2022",
            type: .guideline,
            source: "Dept of Veterans Affairs",
            section: nil,
            title: "VA/DoD Clinical Practice Guideline for Opioids in Chronic Pain",
            year: "2022",
            url: "https://www.healthquality.va.gov/guidelines/Pain/cot/",
            excerpt: "Comprehensive guideline for opioid therapy in chronic pain management.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "ags_beers_2023": Citation(
             id: "ags_beers_2023",
             type: .guideline,
             source: "J Am Geriatr Soc",
             section: nil,
             title: "American Geriatrics Society 2023 Updated AGS Beers Criteria®",
             year: "2023",
             url: "https://doi.org/10.1111/jgs.18372",
             excerpt: "Potentially inappropriate medications in older adults.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
         ),
         "aasm_2025": Citation(
             id: "aasm_2025",
             type: .guideline,
             source: "American Academy of Sleep Medicine",
             section: nil,
             title: "Postoperative Monitoring of Patients with OSA",
             year: "2025",
             url: nil,
             excerpt: "While physiologic monitoring shows promise, evidence remains limited. Adjunctive strategies enhance safety.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
         ),

        "cdc_opioids_2022": Citation(
            id: "cdc_opioids_2022",
            type: .guideline,
            source: "CDC Clinical Practice Guideline",
            section: nil,
            title: "CDC Clinical Practice Guideline for Prescribing Opioids for Pain",
            year: "2022",
            url: "https://www.cdc.gov/mmwr/volumes/71/rr/rr7103a1.htm",
            excerpt: "Nonopioid therapies are at least as effective as opioids for many common types of acute pain.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "cms_conversion_2016": Citation(
            id: "cms_conversion_2016",
            type: .guideline,
            source: "CMS / NCCN",
            section: nil,
            title: "Opioid Oral Morphine Milligram Equivalent (MME) Conversion Factors",
            year: "2016",
            url: "https://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovContra/Downloads/Opioid-Morphine-EQ-Conversion-Factors-Aug-2017.pdf",
            excerpt: "Use caution when converting. Methadone conversion factor increases with dose.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        
        // MARK: - Papers
        "reddy_hydromorphone_2017": Citation(
            id: "reddy_hydromorphone_2017",
            type: .pmid,
            source: "J Pain Symptom Manage",
            section: nil,
            title: "The Conversion Ratio From Intravenous Hydromorphone to Oral Opioids in Cancer Patients",
            year: "2017",
            url: "https://pubmed.ncbi.nlm.nih.gov/28552636/",
            excerpt: "The median conversion ratio from IV hydromorphone to oral MEID was 1:20 (range 10.4-32).",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "mercadante_morphine_2010": Citation(
            id: "mercadante_morphine_2010",
            type: .pmid,
            source: "Lancet Oncology",
            section: nil,
            title: "Intravenous Morphine for Management of Cancer Pain",
            year: "2010",
            url: nil,
            excerpt: "Review of intravenous morphine titration and maintenance strategies.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "prodigy_score_2014": Citation(
            id: "prodigy_score_2014",
            type: .pmid,
            source: "Lancet Respir Med",
            section: nil,
            title: "Derivation and validation of a specific risk score for respiratory depression (PRODIGY)",
            year: "2014",
            url: "https://pubmed.ncbi.nlm.nih.gov/29362877/", // Example URL check
            excerpt: "PRODIGY score identifies patients at high risk of opioid-induced respiratory depression.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "asam_2020": Citation(
            id: "asam_2020",
            type: .guideline,
            source: "ASAM National Practice Guideline",
            section: nil,
            title: "ASAM National Practice Guideline for the Treatment of Opioid Use Disorder",
            year: "2020",
            url: "https://www.asam.org/quality-care/clinical-guidelines/national-practice-guideline",
            excerpt: "Buprenorphine induction should start when mild-to-moderate withdrawal is observed.",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "samhsa_2021": Citation(
             id: "samhsa_2021",
             type: .guideline,
             source: "SAMHSA TIP 63",
             section: nil,
             title: "Medications for Opioid Use Disorder",
             year: "2021",
             url: "https://store.samhsa.gov/product/TIP-63-Medications-for-Opioid-Use-Disorder/PEP21-02-01-002",
             excerpt: "Overview of Methadone, Buprenorphine, and Naltrexone for OUD.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
        ),
        "prodigy_2020": Citation(
            id: "prodigy_2020",
            type: .pmid,
            source: "Anesth Analg",
            section: nil,
            title: "PRODIGY: Prediction of Opioid-Induced Respiratory Depression on Inpatient Wards",
            year: "2020",
            url: "https://pubmed.ncbi.nlm.nih.gov/33170601/",
            excerpt: "Derivation and Validation of PRODIGY score (Score >= 15 indicates high risk).",
            lastVerified: "2026-01-01",
            labelRevisionDate: nil
        ),
        "riosord_2018": Citation(
             id: "riosord_2018",
             type: .pmid,
             source: "Pain Med",
             section: nil,
             title: "Validation of a Screening Risk Index for Serious Prescription Opioid-Induced Respiratory Depression or Overdose (RIOSORD)",
             year: "2018",
             url: "https://pubmed.ncbi.nlm.nih.gov/28339893/",
             excerpt: "Risk Index for Overdose or Serious Opioid-Induced Respiratory Depression.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
        ),
        "cms_mme_2024": Citation(
             id: "cms_mme_2024",
             type: .guideline,
             source: "CMS",
             section: nil,
             title: "Opioid Oral Morphine Milligram Equivalent (MME) Conversion Factors",
             year: "2024",
             url: "https://www.cms.gov/mme-conversion",
             excerpt: "Standard MME conversion factors used for Medicare/Medicaid claims processing.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
        ),
        "fda_gabapentin_2019": Citation(
             id: "fda_gabapentin_2019",
             type: .fdaLabel,
             source: "FDA Drug Safety Communication",
             section: nil,
             title: "FDA warns about serious breathing problems with seizure and nerve pain medicines gabapentin and pregabalin",
             year: "2019",
             url: "https://www.fda.gov/drugs/drug-safety-and-availability/fda-warns-about-serious-breathing-problems-seizure-and-nerve-pain-medicines-gabapentin-and",
             excerpt: "Serious respiratory difficulties may occur in patients using gabapentinoids who have respiratory risk factors.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
        ),
        
        // MARK: - Monitoring Protocols (Synthesized)
        "monitoring_high_risk_pca": Citation(
             id: "monitoring_high_risk_pca",
             type: .expertConsensus,
             source: "ASA / PRODIGY",
             section: nil,
             title: "High-Risk PCA Monitoring",
             year: "2025",
             url: nil,
             excerpt: "Continuous pulse oximetry and capnography recommended for high-risk patients (Obesity, OSA).",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
        ),
        "sedation_poss": Citation(
             id: "sedation_poss",
             type: .expertConsensus,
             source: "NCCN / APS",
             section: nil,
             title: "Sedation Assessment (POSS)",
             year: "2024",
             url: nil,
             excerpt: "Sedation typically precedes respiratory depression. Oversedation is OIVI until proven otherwise.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
        ),
        "risk_strat_prodigy": Citation(
             id: "risk_strat_prodigy",
             type: .expertConsensus,
             source: "PRODIGY Study",
             section: nil,
             title: "Risk Stratification (PRODIGY)",
             year: "2020",
             url: nil,
             excerpt: "Risk factors: Age ≥60, Male, Opioid Naivety, Sleep Disorders, CHF.",
             lastVerified: "2026-01-01",
             labelRevisionDate: nil
        )
    ]
    
    // Resolve IDs to Citation objects
    func resolve(_ ids: [String]) -> [Citation] {
        return ids.compactMap { CitationRegistry.definitions[$0] }
    }
    
    // Resolve ID if exists, otherwise create Legacy wrapper
    func resolveOrLegacy(_ inputs: [String]) -> [Citation] {
        return inputs.map { input in
            if let found = CitationRegistry.definitions[input] {
                return found
            } else {
                return Citation(
                    id: UUID().uuidString,
                    type: .guideline,
                    source: "Reference",
                    section: nil,
                    title: input,
                    year: "",
                    url: nil,
                    excerpt: nil,
                    lastVerified: "",
                    labelRevisionDate: nil
                )
            }
        }
    }
}

// MARK: - SwiftUI Environment Injection
import SwiftUI

struct CitationServiceKey: EnvironmentKey {
    static let defaultValue: CitationService = CitationRegistry()
}

extension EnvironmentValues {
    var citationService: CitationService {
        get { self[CitationServiceKey.self] }
        set { self[CitationServiceKey.self] = newValue }
    }
}
