import SwiftUI

extension View {
    func addKeyboardDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.endEditing()
                }
                .foregroundColor(ClinicalTheme.teal500)
                .font(Font.body.weight(.bold))
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
