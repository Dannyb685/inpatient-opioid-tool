#if canImport(UIKit)
import UIKit
#endif
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
    // Accents - Matched to Web Clinical Design (Tailwind)
    // For Dark Mode, we lighten them slightly for legibility, but keep the core brand hue.
    static var teal500: Color  { ThemeManager.shared.isDarkMode ? Color(red: 0.16, green: 0.82, blue: 0.76) : Color(red: 0.05, green: 0.58, blue: 0.53) } // #0d9488 (Teal 600)
    static var amber500: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.99, green: 0.85, blue: 0.38) : Color(red: 0.85, green: 0.55, blue: 0.00) } // #d97706 (Amber 600)
    static var rose500: Color  { ThemeManager.shared.isDarkMode ? Color(red: 0.98, green: 0.44, blue: 0.52) : Color(red: 0.88, green: 0.11, blue: 0.28) } // #e11d48 (Rose 600)
    static var purple500: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.70, green: 0.45, blue: 0.95) : Color(red: 0.55, green: 0.20, blue: 0.80) }
    static var blue500: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.26, green: 0.67, blue: 0.96) : Color(red: 0.00, green: 0.48, blue: 1.00) }
    
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
