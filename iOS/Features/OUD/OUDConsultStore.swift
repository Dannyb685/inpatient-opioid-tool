import Foundation
import SwiftUI
import Combine

@MainActor
class OUDConsultStore: ObservableObject {
    // MARK: - State
    @Published var selectedCriteria: Set<Int> = []
    @Published var isMedicallySupervised: Bool = false
    @Published var nidaScreenResult: String? = nil
    @Published var hasNaloxonePlan: Bool = false
    
    // MARK: - Computed Logic
    var dsmCount: Int {
        if isMedicallySupervised {
            // Exclude criteria 10 (Tolerance) and 11 (Withdrawal) per DSM-5
            // for patients taking opioids under appropriate medical supervision
            let physiologicalIds = [10, 11]
            return selectedCriteria.filter { !physiologicalIds.contains($0) }.count
        } else {
            return selectedCriteria.count
        }
    }
    
    var severityClassification: (title: String, color: Color) {
        switch dsmCount {
        case 0...1:
            return ("No Diagnosis", .gray)
        case 2...3:
            return ("Mild OUD", .yellow)
        case 4...5:
            return ("Moderate OUD", .orange)
        case 6...11:
            return ("Severe OUD", .red)
        default:
            return ("Indeterminate", .gray)
        }
    }
    
    var showNaloxoneAlert: Bool {
        return dsmCount >= 2 && !hasNaloxonePlan
    }
    
    // MARK: - Clinical Note Generator
    var generatedClinicalNote: String {
        let activeCriteria = OUDStaticData.dsmCriteria
            .filter { selectedCriteria.contains($0.id) }
            .filter { !(isMedicallySupervised && $0.isPhysiological) }
            .map { "• \($0.text)" }
            .joined(separator: "\n")
            
        let excludedCriteria = OUDStaticData.dsmCriteria
            .filter { selectedCriteria.contains($0.id) }
            .filter { isMedicallySupervised && $0.isPhysiological }
            .map { "• \($0.text) (EXCLUDED)" }
            .joined(separator: "\n")
        
        let exclusionNote = isMedicallySupervised 
            ? "\n*Physiological dependence excluded per DSM-5 Medical Supervision exception." 
            : ""
            
        var criteriaBlock = "Criteria Met:\n\(activeCriteria.isEmpty ? "(None)" : activeCriteria)"
        if !excludedCriteria.isEmpty {
            criteriaBlock += "\n\nExcluded Features (Medical Supervision):\n\(excludedCriteria)"
        }
            
        return """
        *** OUD Risk Assessment (DSM-5 Criteria) ***
        Diagnosis: \(severityClassification.title) (\(dsmCount)/11 Criteria Met)
        
        \(criteriaBlock)\(exclusionNote)
        
        Plan:
        \(hasNaloxonePlan ? "Naloxone plan established." : "Naloxone plan pending.")
        """
    }
    
    // MARK: - Intents
    func toggleCriterion(_ id: Int) {
        if selectedCriteria.contains(id) {
            selectedCriteria.remove(id)
        } else {
            selectedCriteria.insert(id)
        }
    }
    
    func reset() {
        selectedCriteria.removeAll()
        isMedicallySupervised = false
        hasNaloxonePlan = false
        nidaScreenResult = nil
    }
}
