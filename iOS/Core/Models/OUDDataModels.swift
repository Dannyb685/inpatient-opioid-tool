import Foundation
import SwiftUI

// MARK: - MODELS

struct DSMCriterion: Identifiable, Hashable {
    let id: Int
    let text: String
    let isPhysiological: Bool // Flags Tolerance and Withdrawal for medical supervision logic
}

struct ReferenceItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String?
}

struct ClinicalReferenceCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
    let items: [ReferenceItem]
}

// MARK: - Static Data Repository
struct OUDStaticData {
    static let dsmCriteria: [DSMCriterion] = [
        DSMCriterion(id: 1, text: "Opioids taken in larger amounts/longer than intended", isPhysiological: false),
        DSMCriterion(id: 2, text: "Persistent desire or unsuccessful efforts to cut down", isPhysiological: false),
        DSMCriterion(id: 3, text: "Great deal of time spent obtaining, using, or recovering", isPhysiological: false),
        DSMCriterion(id: 4, text: "Craving, or a strong desire or urge to use opioids", isPhysiological: false),
        DSMCriterion(id: 5, text: "Recurrent use resulting in failure to fulfill major obligations", isPhysiological: false),
        DSMCriterion(id: 6, text: "Continued use despite persistent/recurrent social problems", isPhysiological: false),
        DSMCriterion(id: 7, text: "Important social, occupational, or recreational activities given up", isPhysiological: false),
        DSMCriterion(id: 8, text: "Recurrent use in situations in which it is physically hazardous", isPhysiological: false),
        DSMCriterion(id: 9, text: "Continued use despite knowledge of physical/psychological problem", isPhysiological: false),
        DSMCriterion(id: 10, text: "Tolerance (need for increased amounts or diminished effect)", isPhysiological: true),
        DSMCriterion(id: 11, text: "Withdrawal (syndrome or taking to relieve symptoms)", isPhysiological: true)
    ]

    static let toolboxCategories: [ClinicalReferenceCategory] = [
        ClinicalReferenceCategory(id: "street", title: "Street Pricing", icon: "dollarsign.circle", items: [
            ReferenceItem(title: "Heroin (Bag/Stamp)", value: "$5 - $20", subtitle: "Highly variable purity"),
            ReferenceItem(title: "Oxycodone (Pressed)", value: "$1/mg (approx)", subtitle: "High fentanyl risk"),
            ReferenceItem(title: "Fentanyl (Pressed Blue)", value: "$10 - $30", subtitle: "Per tablet"),
            ReferenceItem(title: "Buprenorphine (Street)", value: "$5 - $20", subtitle: "Per 8mg strip")
        ]),
        ClinicalReferenceCategory(id: "tox", title: "Urine Toxicology", icon: "flask", items: [
            ReferenceItem(title: "Heroin (6-MAM)", value: "6-8 hours", subtitle: "Rapid metabolism"),
            ReferenceItem(title: "Morphine/Codeine", value: "2-3 days", subtitle: "Standard screen"),
            ReferenceItem(title: "Fentanyl", value: "1-3 days", subtitle: "Requires specific assay"),
            ReferenceItem(title: "Methadone", value: "3-14 days", subtitle: "Long elimination half-life")
        ]),
        ClinicalReferenceCategory(id: "palliative", title: "Palliative Conversion", icon: "cross.case", items: [
            ReferenceItem(title: "Morphine PO : IV", value: "3:1", subtitle: "Standard starting ratio"),
            ReferenceItem(title: "Hydromorphone PO : IV", value: "5:1", subtitle: "Approximate"),
            ReferenceItem(title: "Morphine : Hydrocodone", value: "1:1", subtitle: "Oral equivalence")
        ]),
        ClinicalReferenceCategory(id: "withdraw", title: "Withdrawal Scales", icon: "list.clipboard", items: [
            ReferenceItem(title: "COWS Mild", value: "5 - 12", subtitle: "Symptomatic treatment"),
            ReferenceItem(title: "COWS Moderate", value: "13 - 24", subtitle: "Consider induction"),
            ReferenceItem(title: "COWS Severe", value: "25 - 36", subtitle: "Urgent management"),
            ReferenceItem(title: "COWS Extreme", value: "> 36", subtitle: "High risk")
        ])
    ]
}
