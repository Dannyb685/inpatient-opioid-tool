#if CLI
import Foundation
import SwiftUI

// Mock Theme for CLI to satisfy logic dependencies without UIKit
struct ClinicalTheme {
    static var textPrimary: Color { .primary }
    static var textSecondary: Color { .secondary }
    static var textMuted: Color { .gray }
    static var backgroundMain: Color { .white }
    static var backgroundCard: Color { .white }
    static var backgroundInput: Color { .gray }
    static var divider: Color { .gray }
    static var cardBorder: Color { .gray }
    
    static var teal500: Color { .teal }
    static var amber500: Color { .yellow }
    static var rose500: Color { .red }
    static var purple500: Color { .purple }
    static var blue500: Color { .blue }
    
    // Legacy mapping
    static var slate900: Color { .black }
    static var slate800: Color { .gray }
    static var slate700: Color { .gray }
    static var slate500: Color { .gray }
    static var slate400: Color { .gray }
    static var slate300: Color { .gray }
}

// Mock Modifiers for CLI
struct ClinicalCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.padding()
    }
}

extension View {
    func clinicalCard() -> some View {
        self.modifier(ClinicalCardModifier())
    }
}

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
