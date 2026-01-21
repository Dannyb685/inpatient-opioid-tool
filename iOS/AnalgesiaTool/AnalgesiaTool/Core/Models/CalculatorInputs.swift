
import Foundation

// MARK: - Calculator Data Protocol (DTO)
// This protocol decouples the CalculatorStore from the AssessmentStore.
// The Calculator simply requests "inputs" conforming to this contract.

protocol CalculatorInputs {
    var renalFunction: RenalStatus { get }
    var hepaticFunction: HepaticStatus { get }
    var painType: PainType { get }
    var isPregnant: Bool { get }
    var isBreastfeeding: Bool { get }
    var age: String { get }
    var benzos: Bool { get }
    var sleepApnea: Bool { get }
    var historyOverdose: Bool { get }
    var analgesicProfile: AnalgesicProfile { get }
    
    // Additional Risk Factors
    var sex: Sex { get }
    var chf: Bool { get }
    var copd: Bool { get }
    var psychHistory: Bool { get }
    var currentMME: String { get } // To check for >100 MME risk
}
