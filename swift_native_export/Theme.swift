import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var isDarkMode: Bool = true
}

struct ClinicalTheme {
    // Dynamic Colors based on ThemeManager
    static var slate900: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.08, green: 0.10, blue: 0.13) : Color(red: 0.95, green: 0.96, blue: 0.97) } // Dark: Slate900 | Light: Slate50
    static var slate800: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.12, green: 0.15, blue: 0.18) : Color.white } // Dark: Slate800 | Light: White
    static var slate700: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.20, green: 0.24, blue: 0.28) : Color(red: 0.88, green: 0.91, blue: 0.94) } // Dark: Slate700 | Light: Slate200
    
    static var slate500: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.39, green: 0.45, blue: 0.55) : Color(red: 0.39, green: 0.45, blue: 0.55) } // Muted Text (Same)
    static var slate400: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.58, green: 0.64, blue: 0.72) : Color(red: 0.40, green: 0.45, blue: 0.50) } // Secondary (Darken for light mode)
    static var slate300: Color { ThemeManager.shared.isDarkMode ? Color(red: 0.80, green: 0.84, blue: 0.88) : Color(red: 0.10, green: 0.13, blue: 0.17) } // Text (Invert)
    
    // Accents (Keep roughly same, maybe adjust readability)
    static var teal500: Color  { ThemeManager.shared.isDarkMode ? Color(red: 0.08, green: 0.75, blue: 0.72) : Color(red: 0.06, green: 0.60, blue: 0.58) } // Darker Teal for light bg
    static let amber500 = Color(red: 0.96, green: 0.64, blue: 0.15)
    static let rose500  = Color(red: 0.94, green: 0.25, blue: 0.33)
}

struct ClinicalCardModifier: ViewModifier {
    // Need to observe updates if utilizing binding? 
    // Actually, accessing the computed var inside body causes re-evaluation if the view redraws.
    // We rely on the View hierarchy to redraw when ThemeManager changes.
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(ClinicalTheme.slate800)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ClinicalTheme.slate700, lineWidth: 1)
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
