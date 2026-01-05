
import Foundation

extension Double {
    /// Formats a raw dose into a clinically actionable string based on route.
    /// - Parameters:
    ///   - route: The route of administration (IV implies precision, PO implies pill limits).
    ///   - unit: Optional unit string (default "mg").
    /// - Returns: A formatted string (e.g. "1.4 mg" or "1.5 mg").
    func toClinicalString(route: DrugRouteType, unit: String = "mg") -> String {
        
        switch route {
        case .ivPush, .ivDrip, .microgramIO:
            // IV/SubQ/Fentanyl: High precision is possible and often required.
            // Example: 1.432 -> "1.4 mg"
            return String(format: "%.1f %@", self, unit)
            
        case .standardPO:
            // Oral: Must round to practical pill sizes.
            // Logic: Round to nearest 0.5 mg for doses < 10mg, nearest 1.0 mg for > 10mg.
            
            let roundedDose: Double
            
            if self < 10.0 {
                // Round to nearest 0.5 (e.g. 1.4 -> 1.5)
                roundedDose = (self * 2).rounded() / 2
            } else {
                // Round to nearest whole number (e.g. 12.4 -> 12)
                roundedDose = self.rounded()
            }
            
            // Remove decimal if it's a whole number (e.g. "5.0" -> "5")
            let numberFormatter = NumberFormatter()
            numberFormatter.minimumFractionDigits = 0
            numberFormatter.maximumFractionDigits = 1
            let numberString = numberFormatter.string(from: NSNumber(value: roundedDose)) ?? "\(roundedDose)"
            
            return "\(numberString) \(unit)"
            
        case .patch:
            // Patches usually come in fixed increments (12, 25, 50, etc.)
            // For now, simple rounding to integer is safest.
            return String(format: "%.0f %@", self, unit)
        }
    }
}
