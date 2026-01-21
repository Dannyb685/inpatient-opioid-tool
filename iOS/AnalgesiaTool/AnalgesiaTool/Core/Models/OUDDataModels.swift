import Foundation
import SwiftUI

// MARK: - MODELS

struct AberrantBehavior: Identifiable, Hashable {
    let id = UUID()
    let behavior: String
    let category: BehaviorCategory
    let action: String
}

enum BehaviorCategory: String, CaseIterable, Hashable {
    case yellowFlag = "Yellow Flag (Pacing/Minor)"
    case redFlag = "Red Flag (Diversion/Illegal)"
}

struct DSMCriterion: Identifiable, Hashable {
    let id: Int
    let text: String
    let isPhysiological: Bool // Flags Tolerance and Withdrawal for medical supervision logic
}

struct ClinicalReferenceItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String?
}

struct ClinicalReferenceCategory: Identifiable {
    let id: String
    let title: String
    let icon: String
    let items: [ClinicalReferenceItem]
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
            ClinicalReferenceItem(title: "Heroin/Fentanyl (Bag)", value: "$5 - $10", subtitle: "90-200+ MME (Service Unit)"),
            ClinicalReferenceItem(title: "Bundle (10-14 Bags)", value: "$40 - $100", subtitle: "Philly Bundle = 14 Bags"),
            ClinicalReferenceItem(title: "Brick (5 Bundles)", value: "$200 - $450", subtitle: "Wholesale vs Retail"),
            ClinicalReferenceItem(title: "Counterfeit Pill (M30)", value: "$1 - $5", subtitle: "Fentanyl/Xylazine (No Oxy)"),
            ClinicalReferenceItem(title: "Buprenorphine (8mg)", value: "$5 - $20", subtitle: "Survival Economy (No High)"),
            ClinicalReferenceItem(title: "Gabapentin (Johnny)", value: "$0.50 - $3.00", subtitle: "Potentiator / Utility"),
            ClinicalReferenceItem(title: "Xanax (Press)", value: "$3 - $5", subtitle: "Bromazolam / Fentanyl Risk")
        ]),
        ClinicalReferenceCategory(id: "tox", title: "Urine Toxicology", icon: "flask", items: [
            ClinicalReferenceItem(title: "Heroin (6-MAM)", value: "6-8 hours", subtitle: "Rapid metabolism"),
            ClinicalReferenceItem(title: "Morphine/Codeine", value: "2-3 days", subtitle: "Standard screen"),
            ClinicalReferenceItem(title: "Fentanyl", value: "1-3 days", subtitle: "Requires specific assay"),
            ClinicalReferenceItem(title: "Methadone", value: "3-14 days", subtitle: "Long elimination half-life")
        ]),
        ClinicalReferenceCategory(id: "counseling", title: "Counseling", icon: "person.2.wave.2", items: [
            ClinicalReferenceItem(title: "O.A.R.S.", value: "Core Skills", subtitle: "Open questions, Affirmations, Reflections, Summaries"),
            ClinicalReferenceItem(title: "R.U.L.E.", value: "Principles", subtitle: "Resist righting reflex, Understand, Listen, Empower"),
            ClinicalReferenceItem(title: "D.A.R.N. - C", value: "Change Talk", subtitle: "Desire, Ability, Reason, Need, Commitment"),
            ClinicalReferenceItem(title: "F.R.A.M.E.S.", value: "Intervention", subtitle: "Feedback, Responsibility, Advice, Menu, Empathy, Self-Efficacy")
        ]),
        ClinicalReferenceCategory(id: "palliative", title: "Palliative Conversion", icon: "cross.case", items: [
            ClinicalReferenceItem(title: "Morphine PO : IV", value: "3:1", subtitle: "Standard starting ratio"),
            ClinicalReferenceItem(title: "Hydromorphone PO : IV", value: "5:1", subtitle: "Approximate"),
            ClinicalReferenceItem(title: "Morphine : Hydrocodone", value: "1:1", subtitle: "Oral equivalence")
        ]),
        ClinicalReferenceCategory(id: "withdraw", title: "Withdrawal Scales", icon: "list.clipboard", items: [
            ClinicalReferenceItem(title: "COWS Mild", value: "5 - 12", subtitle: "Symptomatic treatment"),
            ClinicalReferenceItem(title: "COWS Moderate", value: "13 - 24", subtitle: "Consider induction"),
            ClinicalReferenceItem(title: "COWS Severe", value: "25 - 36", subtitle: "Urgent management"),
            ClinicalReferenceItem(title: "COWS Extreme", value: "> 36", subtitle: "High risk")
        ])
    ]
    
    // MARK: - Aberrant Behavior (ASCO Guidelines)
    static let aberrantBehaviors: [AberrantBehavior] = [
        // Yellow Flags (Minor/Pacing)
        AberrantBehavior(behavior: "Requesting early refills (1-2 days)", category: .yellowFlag, action: "Re-educate, Pill Count, Monitor intervals"),
        AberrantBehavior(behavior: "Unsanctioned dose escalation (1-2 extra)", category: .yellowFlag, action: "Discuss safety, Warning, Reduce dispense quantity"),
        AberrantBehavior(behavior: "Missed appointments (occasional)", category: .yellowFlag, action: "Re-schedule, Discuss adherence barriers"),
        AberrantBehavior(behavior: "Sedation/Slurring during visit", category: .yellowFlag, action: "Hold dose, Assess for other substances, PDMP check"),
        
        // Red Flags (Major/Diversion)
        AberrantBehavior(behavior: "Urine Negative for Prescribed Opioid", category: .redFlag, action: "Suspect Diversion. Confirm w/ GC/MS. Restrict supply."),
        AberrantBehavior(behavior: "Urine Positive for Illicit Drugs (Cocaine/Heroin)", category: .redFlag, action: "SUD Concern. Refer to Addiction Medicine. Tighten monitoring."),
        AberrantBehavior(behavior: "Prescription Forgery / Alteration", category: .redFlag, action: "Immediate Halt. Security/Police report if necessary. Discharge."),
        AberrantBehavior(behavior: "Selling Medications / Diversion", category: .redFlag, action: "Immediate Halt. Discharge. Report to authorities."),
        AberrantBehavior(behavior: "Lost/Stolen Prescriptions (Repeated)", category: .redFlag, action: "Do not replace. Require police report. Restrict supply.")
    ]
    
    
    // Cancer / Palliative Context (ASCO 2016 / NCCN 2025)
    // Goal: Maintain pain control, increase monitoring. AVOID TAPER unless diversion.
    static let cancerActionSteps: [String] = [
        "1. **Reassess**: Check PDMP & Urine Tox today to rule out diversion.",
        "2. **RESTRUCTURE (Don't Taper)**: Switch to weekly dispensing. Increase visit frequency.",
        "3. **Safe Storage**: Emphasize lockbox use. Consider caregiver control.",
        "4. **No Taper**: Do not taper unless diversion is confirmed or safety is compromised."
    ]
    
    // Non-Cancer Chronic Pain (CDC 2022)
    // Goal: Harm reduction. Taper if risks > benefits.
    static let nonCancerActionSteps: [String] = [
        "1. **Reassess**: Check PDMP & Urine Tox today.",
        "2. **TIGHTEN**: Switch to weekly dispensing. Count pills.",
        "3. **CONSIDER TAPER**: Initiation of slow taper (10%/month) if adherence fails.",
        "4. **Naloxone**: Mandatory co-prescription."
    ]
}
