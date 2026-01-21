import Foundation

enum SafetyEvent {
    case alertShown(id: String, context: String)
    case alertOverridden(id: String, rationale: String?)
    case calculationPerformed(inputCount: Int, hasWarnings: Bool, warningDetails: [String])
    case actionTaken(action: String, context: String)
    case safetyGateFailure(errors: [String])
}

class SafetyLogger {
    static let shared = SafetyLogger()
    
    private init() {}
    
    func log(_ event: SafetyEvent) {
        #if DEBUG
        print("[SafetyLogger] \(eventDescription(event))")
        #endif
        // Production: Send to HIPAA-compliant analytics
    }
    
    private func eventDescription(_ event: SafetyEvent) -> String {
        switch event {
        case .alertShown(let id, let context):
            return "ALERT SHOWN: \(id) | Context: \(context)"
        case .alertOverridden(let id, let rationale):
            return "ALERT OVERRIDDEN: \(id) | Rationale: \(rationale ?? "None")"
        case .calculationPerformed(let count, let hasWarnings, let details):
            return "CALCULATION: Inputs=\(count) | Warnings=\(hasWarnings) | \(details)"
        case .actionTaken(let action, let context):
            return "ACTION TAKEN: \(action) | Context: \(context)"
        case .safetyGateFailure(let errors):
            return "Safety Gate Applied: \(errors.joined(separator: "; "))"
        }
    }
}
