import SwiftUI

@main
struct AnalgesiaToolApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var assessmentStore = AssessmentStore()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environmentObject(assessmentStore) // Inject global store
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
        }
    }
}
