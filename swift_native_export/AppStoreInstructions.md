# How to Build the Native iOS App

1. **Open Xcode**: Launch Xcode and select "Create a new Xcode project".
2. **Select App**: Choose "App" under the iOS tab and click Next.
3. **Configure Project**:
    * **Product Name**: Analgesia Tool
    * **Interface**: SwiftUI
    * **Language**: Swift
    * **Organization Identifier**: com.danbergholz
4. **Drag and Drop** the following files from the `swift_native_export/` folder into the `PrecisionAnalgesia` group in Xcode:
    * `AnalgesiaToolApp.swift` (Entry Point)
    * `MainTabView.swift` (Root Tab Controller)
    * `Theme.swift` (Medical Dark Mode System)
    * `ClinicalData.swift` (Static Constants)
    * `SegmentedButton.swift` (Custom UI Component)
    * **Stores**:
        * `AssessmentStore.swift`
        * `ScreeningStore.swift`
        * `CalculatorStore.swift`
        * `ToolkitStore.swift`
    * **Views**:
        * `RiskAssessmentView.swift`
        * `ScreeningView.swift`
        * `CalculatorView.swift`
        * `ProtocolsView.swift`
        * `ReferenceView.swift`
        * `ToolkitView.swift`
        * `COWSView.swift`
        * `ProtocolDetailView.swift`
        * `SelectionView.swift`
    * **Data Models**:
        * `ClinicalData.swift`
        * `ProtocolData.swift`
        * `ToolkitData.swift`
    * *Note: Delete ContentView.swift if Xcode created one automatically.*
5. **Add Privacy Manifest (Required)**:
    * Drag `PrivacyInfo.xcprivacy` from the export folder into the Xcode project navigator.
6. **Add Assets**:
    * Drag the `Assets.xcassets` folder from `swift_native_export/` into the Xcode Project Navigator.
    * When prompted, choose "Create folder references" or "Create groups" (Create groups is standard for xcassets).
    * If an empty `Assets.xcassets` already exists in Xcode, replace it or merge contents.
7. **Run**: Select a simulator and press Cmd+R.
8. **Archive**: Select "Any iOS Device" and go to `Product > Archive`.
