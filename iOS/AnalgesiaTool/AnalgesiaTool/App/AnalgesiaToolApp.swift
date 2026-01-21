import SwiftUI

@main
struct AnalgesiaToolApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var assessmentStore = AssessmentStore()
    @StateObject private var citationRegistry = CitationRegistry()
    
    // Legal Guardrail Persistence
    @AppStorage("hasAcceptedLiability_v1") private var hasAcceptedLiability: Bool = false
    @State private var showOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environmentObject(assessmentStore) // Inject global store
                .environment(\.citationService, citationRegistry)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    // Check liability acceptance on launch
                    if !hasAcceptedLiability {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView(isPresented: $showOnboarding)
                }
        }
    }
}
