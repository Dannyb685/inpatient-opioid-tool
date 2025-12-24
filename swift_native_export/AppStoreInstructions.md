# How to Build the Native iOS App

1. **Open Xcode**: Launch Xcode and select "Create a new Xcode project".
2. **Select App**: Choose "App" under the iOS tab and click Next.
3. **Configure Project**:
    * **Product Name**: Analgesia Tool
    * **Interface**: SwiftUI
    * **Language**: Swift
    * **Organization Identifier**: com.danbergholz
4. **Create Files**:
    * Create `ClinicalLogic.swift` and paste the provided code.
    * Replace `ContentView.swift` with the provided code.
5. **Add Privacy Manifest (Required)**:
    * Drag `PrivacyInfo.xcprivacy` from the export folder into the Xcode project navigator.
6. **Add App Icon**:
    * Located in `assets/app_icon_medical_precision.png`.
    * Drag and drop the PNG into the 1024x1024 slot in Assets.
7. **Run**: Select a simulator and press Cmd+R.
8. **Archive**: Select "Any iOS Device" and go to `Product > Archive`.
