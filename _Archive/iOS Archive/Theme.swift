import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var isDarkMode: Bool = false
    
    private init() {}
}

struct ClinicalTheme {
    // MARK: - Semantic Colors (Use these in Views)
    
    // Text
    static var textPrimary: Color { Color(UIColor.label) }
    static var textSecondary: Color { Color(UIColor.secondaryLabel) }
    static var textMuted: Color { Color(UIColor.placeholderText) }
    
    // Backgrounds
    static var backgroundMain: Color { Color(UIColor.systemGroupedBackground) }
    static var backgroundCard: Color { Color(UIColor.secondarySystemGroupedBackground) } // White in Light, Dark Grey in Dark
    static var backgroundInput: Color { Color(UIColor.tertiarySystemFill) }
    
    // UI Elements
    static var divider: Color { Color(UIColor.separator) }
    static var cardBorder: Color { Color(UIColor.opaqueSeparator) }
    
    // Accents
    static var teal500: Color  { ThemeManager.shared.isDarkMode ? Color(red: 0.08, green: 0.75, blue: 0.72) : Color(red: 0.00, green: 0.55, blue: 0.55) }
    static var amber500: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.96, green: 0.64, blue: 0.15) : Color(red: 0.85, green: 0.55, blue: 0.00) }
    static var rose500: Color  { ThemeManager.shared.isDarkMode ? Color(red: 0.94, green: 0.25, blue: 0.33) : Color(red: 0.85, green: 0.15, blue: 0.25) }
    static var purple500: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.70, green: 0.45, blue: 0.95) : Color(red: 0.55, green: 0.20, blue: 0.80) }
    
    // Legacy mapping (Deprecated)
    static var slate900: Color { backgroundMain }
    static var slate800: Color { backgroundCard }
    static var slate700: Color { divider }
    static var slate500: Color { textMuted }
    static var slate400: Color { textSecondary }
    static var slate300: Color { textPrimary }
}

struct ClinicalCardModifier: ViewModifier {
    // Need to observe updates if utilizing binding? 
    // Actually, accessing the computed var inside body causes re-evaluation if the view redraws.
    // We rely on the View hierarchy to redraw when ThemeManager changes.
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(ClinicalTheme.backgroundCard)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ClinicalTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
