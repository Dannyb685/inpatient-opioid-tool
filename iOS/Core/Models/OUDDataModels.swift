import Foundation
import SwiftUI

// MARK: - MODELS

struct DSMCriterion: Identifiable, Hashable {
    let id: Int
    let text: String
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

    static let toolboxCategories: [OUDReferenceCategory] = [
        OUDReferenceCategory(id: "street", title: "Street Pricing", icon: "dollarsign.circle", items: [
            OUDReferenceItem(title: "Heroin/Fentanyl (Bag)", value: "$5 - $10", subtitle: "90-200+ MME (Service Unit)"),
            OUDReferenceItem(title: "Bundle (10-14 Bags)", value: "$40 - $100", subtitle: "Philly Bundle = 14 Bags"),
            OUDReferenceItem(title: "Brick (5 Bundles)", value: "$200 - $450", subtitle: "Wholesale vs Retail"),
            OUDReferenceItem(title: "Counterfeit Pill (M30)", value: "$1 - $5", subtitle: "Fentanyl/Xylazine (No Oxy)"),
            OUDReferenceItem(title: "Buprenorphine (8mg)", value: "$5 - $20", subtitle: "Survival Economy (No High)"),
            OUDReferenceItem(title: "Gabapentin (Johnny)", value: "$0.50 - $3.00", subtitle: "Potentiator / Utility"),
            OUDReferenceItem(title: "Xanax (Press)", value: "$3 - $5", subtitle: "Bromazolam / Fentanyl Risk")
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
        ]),
        OUDReferenceCategory(id: "withdraw", title: "Withdrawal Scales", icon: "list.clipboard", items: [
            OUDReferenceItem(title: "COWS Mild", value: "5 - 12", subtitle: "Symptomatic treatment"),
            OUDReferenceItem(title: "COWS Moderate", value: "13 - 24", subtitle: "Consider induction"),
            OUDReferenceItem(title: "COWS Severe", value: "25 - 36", subtitle: "Urgent management"),
            OUDReferenceItem(title: "COWS Extreme", value: "> 36", subtitle: "High risk")
        ])
    ]
}
