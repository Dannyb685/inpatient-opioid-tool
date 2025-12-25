import SwiftUI

struct ClinicalTheme {
    static let slate900 = Color(red: 0.08, green: 0.10, blue: 0.13) // Background
    static let slate800 = Color(red: 0.12, green: 0.15, blue: 0.18) // Surface/Card
    static let slate700 = Color(red: 0.20, green: 0.24, blue: 0.28) // Border/Highlight
    static let slate500 = Color(red: 0.39, green: 0.45, blue: 0.55) // Muted Text
    static let slate400 = Color(red: 0.58, green: 0.64, blue: 0.72) // Secondary Text
    static let slate300 = Color(red: 0.80, green: 0.84, blue: 0.88) // Primary/Bright Text
    static let teal500  = Color(red: 0.08, green: 0.75, blue: 0.72) // Action/Safe
    static let amber500 = Color(red: 0.96, green: 0.64, blue: 0.15) // Warning/Caution
    static let rose500  = Color(red: 0.94, green: 0.25, blue: 0.33) // Danger/High
}

struct ClinicalCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(ClinicalTheme.slate800)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ClinicalTheme.slate700, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func clinicalCard() -> some View {
        self.modifier(ClinicalCardModifier())
    }
    
    func slateBackground() -> some View {
        self.background(ClinicalTheme.slate900.ignoresSafeArea())
    }
}
