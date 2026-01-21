import Foundation
import SwiftUI

// MARK: - Safety Badge Model

struct SafetyBadge: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let color: Color
    let icon: String // SF Symbol Name
    let priority: Int // 0 = Low, 1 = Warning, 2 = Critical
}

// MARK: - Badge Service (Single Source of Truth)

class BadgeService {
    static let shared = BadgeService()
    
    /// Generates appropriate safety badges for a given drug based on the patient context.
    /// This unifies logic previously split between ReferenceView and DrugMonographView.
    func generateBadges(for drug: DrugData, context: AssessmentStore) -> [SafetyBadge] {
        var badges: [SafetyBadge] = []
        
        // 1. Renal Safety
        if context.renalFunction.isImpaired {
            if drug.renalSafety == "Unsafe" {
                // High Risk
                badges.append(SafetyBadge(label: "Renal Alert", color: ClinicalTheme.rose500, icon: "exclamationmark.triangle.fill", priority: 2))
            } else if drug.id == "hydromorphone" || drug.id == "oxycodone" {
                // Preferred Agents
                badges.append(SafetyBadge(label: "Renal Preferred", color: ClinicalTheme.teal500, icon: "checkmark.shield.fill", priority: 0))
            }
        }
        
        // 2. Hepatic Safety
        if context.hepaticFunction != .normal {
            if drug.hepaticSafety == "Unsafe" {
                badges.append(SafetyBadge(label: "Hepatic Alert", color: ClinicalTheme.rose500, icon: "cross.case.fill", priority: 2))
            }
            // Hydrocodone (APAP Combo Risk)
            if drug.id == "hydrocodone" && context.hepaticFunction == .failure {
                badges.append(SafetyBadge(label: "Avoid Combo (APAP)", color: ClinicalTheme.rose500, icon: "exclamationmark.triangle.fill", priority: 2))
            }
        }
        
        // 3. Naive Safety (Fentanyl Patch)
        if context.analgesicProfile == .naive && drug.id == "fentanyl_patch" {
            badges.append(SafetyBadge(label: "Contraindicated (Naive)", color: ClinicalTheme.rose500, icon: "hand.raised.fill", priority: 2))
        }
        
        // 4. Pregnancy Safety
        if context.isPregnant && (drug.id == "codeine" || drug.id == "tramadol") {
            badges.append(SafetyBadge(label: "Avoid (Pregnancy)", color: ClinicalTheme.rose500, icon: "exclamationmark.triangle.fill", priority: 2))
        }

        // 5. Lactation Safety
        if context.isBreastfeeding && (drug.id == "codeine" || drug.id == "tramadol" || drug.id == "meperidine") {
            badges.append(SafetyBadge(label: "Avoid (Lactation)", color: ClinicalTheme.rose500, icon: "drop.fill", priority: 2))
        }
        
        // 6. Naltrexone Blockade
        if context.analgesicProfile == .naltrexone && (drug.type.contains("Agonist") || drug.type.contains("Phenylpiperidine")) {
            badges.append(SafetyBadge(label: "Blocked / Ineffective", color: ClinicalTheme.rose500, icon: "nosign", priority: 2))
        }
        
        // 7. Meperidine (Elderly)
        if drug.id == "meperidine" && (Int(context.age) ?? 0) >= 65 {
            badges.append(SafetyBadge(label: "Avoid (Beers Criteria)", color: ClinicalTheme.rose500, icon: "person.fill.xmark", priority: 2))
        }
        
        // 8. Methadone (QTc)
        if drug.id == "methadone" && context.qtcProlonged {
            badges.append(SafetyBadge(label: "Contraindicated (QTc)", color: ClinicalTheme.rose500, icon: "heart.slash.fill", priority: 2))
        }
        
        return badges
    }
}
