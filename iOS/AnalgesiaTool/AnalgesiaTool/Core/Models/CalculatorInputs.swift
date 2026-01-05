
import Foundation

// MARK: - Calculator Data Protocol (DTO)
// This protocol decouples the CalculatorStore from the AssessmentStore.
// The Calculator simply requests "inputs" conforming to this contract.

protocol CalculatorInputs {
    var renalFunction: RenalStatus { get }
    var hepaticFunction: HepaticStatus { get }
    var painType: PainType { get }
    var isPregnant: Bool { get }
    var age: String { get } // String in AssessmentStore ("45")
    var benzos: Bool { get }
    var sleepApnea: Bool { get }
    var historyOverdose: Bool { get }
    var analgesicProfile: AnalgesicProfile { get }
}
