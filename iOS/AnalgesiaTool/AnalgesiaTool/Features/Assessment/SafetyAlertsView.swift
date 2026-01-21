import SwiftUI

struct SafetyAlertsView: View {
    let alerts: [SafetyAlert]
    
    // Sort logic: Critical -> Warning -> Info
    var sortedAlerts: [SafetyAlert] {
        alerts.sorted {
            priority(for: $0.severity) > priority(for: $1.severity)
        }
    }
    
    private func priority(for severity: SafetySeverity) -> Int {
        switch severity {
        case .critical: return 3
        case .warning: return 2
        case .info: return 1
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(sortedAlerts) { alert in
                CollapsibleWarningCard(alert: alert)
                    .transition(.opacity.animation(.easeInOut))
            }
        }
    }
}
