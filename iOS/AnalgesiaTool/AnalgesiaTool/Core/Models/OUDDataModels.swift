import Foundation
import SwiftUI

// MARK: - MODELS

struct DSMCriterion: Identifiable, Hashable {
    let id: Int
    let text: String
    let mnemonic: String // 6 Cs: Control, Cravings, Consequences, Compulsion, Hazardous, Physiology
    let isPhysiological: Bool // Flags Tolerance and Withdrawal for medical supervision logic
}

struct OUDReferenceItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String?
}

struct OUDReferenceCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
    let items: [OUDReferenceItem]
}

struct AdjuvantRecommendation: Identifiable, Hashable {
    let id = UUID()
    let category: String
    let drug: String
    let dose: String
    let rationale: String
}

// MARK: - Static Data Repository
struct OUDStaticData {
    static let dsmCriteria: [DSMCriterion] = [
        DSMCriterion(id: 1, text: "Opioids taken in larger amounts/longer than intended", mnemonic: "Control", isPhysiological: false),
        DSMCriterion(id: 2, text: "Persistent desire or unsuccessful efforts to cut down", mnemonic: "Control", isPhysiological: false),
        DSMCriterion(id: 3, text: "Great deal of time spent obtaining, using, or recovering", mnemonic: "Compulsion", isPhysiological: false),
        DSMCriterion(id: 4, text: "Craving, or a strong desire or urge to use opioids", mnemonic: "Cravings", isPhysiological: false),
        DSMCriterion(id: 5, text: "Recurrent use resulting in failure to fulfill major obligations", mnemonic: "Consequences", isPhysiological: false),
        DSMCriterion(id: 6, text: "Continued use despite persistent/recurrent social problems", mnemonic: "Consequences", isPhysiological: false),
        DSMCriterion(id: 7, text: "Important social, occupational, or recreational activities given up", mnemonic: "Consequences", isPhysiological: false),
        DSMCriterion(id: 8, text: "Recurrent use in situations in which it is physically hazardous", mnemonic: "Hazardous", isPhysiological: false),
        DSMCriterion(id: 9, text: "Continued use despite knowledge of physical/psychological problem", mnemonic: "Hazardous", isPhysiological: false),
        DSMCriterion(id: 10, text: "Tolerance (need for increased amounts or diminished effect)", mnemonic: "Physiology", isPhysiological: true),
        DSMCriterion(id: 11, text: "Withdrawal (syndrome or taking to relieve symptoms)", mnemonic: "Physiology", isPhysiological: true)
    ]
    
    // Updated Toolbox Categories (v2.1 Refactor)
    static let toolboxCategories: [OUDReferenceCategory] = [
        // 2. Reference & Toolbox (Existing)
        OUDReferenceCategory(id: "street", title: "Street Metrics", icon: "dollarsign.circle", items: [
            OUDReferenceItem(title: "Heroin/Fentanyl (Bag)", value: "$5 - $10", subtitle: "90-200+ MME (Service Unit)"),
            OUDReferenceItem(title: "Bundle (10-14 Bags)", value: "$40 - $100", subtitle: "Philly Bundle = 14 Bags"),
            OUDReferenceItem(title: "Brick (5 Bundles)", value: "$200 - $450", subtitle: "Wholesale vs Retail"),
            OUDReferenceItem(title: "Counterfeit Pill (M30)", value: "$1 - $5", subtitle: "Fentanyl/Xylazine (No Oxy)"),
            OUDReferenceItem(title: "Buprenorphine (8mg)", value: "$5 - $20", subtitle: "Survival Economy (No High)"),
            OUDReferenceItem(title: "Gabapentin (Johnny)", value: "$0.50 - $3.00", subtitle: "Potentiator / Utility"),
            OUDReferenceItem(title: "Xanax (Press)", value: "$3 - $5", subtitle: "Bromazolam / Fentanyl Risk")
        ]),
        OUDReferenceCategory(id: "symptom", title: "Symptom Mgmt", icon: "cross.case", items: [
            OUDReferenceItem(title: "COWS Mild (5-12)", value: "Supportive", subtitle: "Hydroxyzine, Clonidine"),
            OUDReferenceItem(title: "COWS Mod (13-24)", value: "Induction", subtitle: "Buprenorphine Threshold"),
            OUDReferenceItem(title: "COWS Severe (>24)", value: "Urgent", subtitle: "Full Agonist Taper?"),
            OUDReferenceItem(title: "Anxiety/Restlessness", value: "Clonidine", subtitle: "0.1mg q8h PRN"),
            OUDReferenceItem(title: "Nausea/Vomiting", value: "Ondansetron", subtitle: "4mg q6h PRN"),
            OUDReferenceItem(title: "Diarrhea", value: "Loperamide", subtitle: "4mg load -> 2mg")
        ]),
        OUDReferenceCategory(id: "counseling", title: "Counseling", icon: "bubble.left.and.bubble.right", items: [
            OUDReferenceItem(title: "OARS", value: "Core Skills", subtitle: "Open Qs, Affirm, Reflect, Summarize"),
            OUDReferenceItem(title: "Change Talk", value: "DARN-C", subtitle: "Desire, Ability, Reasons, Need"),
            OUDReferenceItem(title: "Harm Reduction", value: "Safety", subtitle: "Never Use Alone, Test Doses"),
            OUDReferenceItem(title: "Naloxone", value: "Education", subtitle: "Intranasal Administration")
        ]),
        OUDReferenceCategory(id: "tox", title: "Urine Toxicology", icon: "flask", items: [
            OUDReferenceItem(title: "Heroin (6-MAM)", value: "6-8 hours", subtitle: "Rapid metabolism"),
            OUDReferenceItem(title: "Morphine/Codeine", value: "2-3 days", subtitle: "Standard screen"),
            OUDReferenceItem(title: "Fentanyl", value: "1-3 days", subtitle: "Requires specific assay"),
            OUDReferenceItem(title: "Methadone", value: "3-14 days", subtitle: "Long elimination half-life")
        ]),
        OUDReferenceCategory(id: "palliative", title: "Palliative Conversion", icon: "cross.case", items: [
            OUDReferenceItem(title: "Morphine PO : IV", value: "3:1", subtitle: "Standard starting ratio"),
            OUDReferenceItem(title: "Hydromorphone PO : IV", value: "5:1", subtitle: "Approximate"),
            OUDReferenceItem(title: "Morphine : Hydrocodone", value: "1:1", subtitle: "Oral equivalence")
        ])
    ]
    static let workupItems: [WorkupItem] = [
        WorkupItem(id: UUID(), title: "Urine Toxicology (UTOX)", isRequired: true),
        WorkupItem(id: UUID(), title: "Pregnancy Test (hCG)", isRequired: true),
        WorkupItem(id: UUID(), title: "Liver Function Costs (LFTs)", isRequired: true),
        WorkupItem(id: UUID(), title: "Infectious Disease Panel (HIV, Hep C)", isRequired: true),
        WorkupItem(id: UUID(), title: "PDMP (Prescription Database) Check", isRequired: true),
        WorkupItem(id: UUID(), title: "TB Screen", isRequired: false),
        WorkupItem(id: UUID(), title: "Hep A/B Vaccination Status", isRequired: false),
        WorkupItem(id: UUID(), title: "STI Screen (Syphilis/Gc/Ct)", isRequired: false)
    ]
}

struct WorkupItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let isRequired: Bool
}
