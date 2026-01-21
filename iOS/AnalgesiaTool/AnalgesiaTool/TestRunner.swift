#if CLI
import Foundation
import SwiftUI

@main
@MainActor
struct ValidationRunner {
    static func main() {
        print("Starting Validation Engine...")
        let report = ClinicalValidationEngine.shared.runStressTest()
        print(report)
    }
}
#endif
