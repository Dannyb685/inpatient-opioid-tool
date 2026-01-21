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
    
    /// Hides keyboard
    func hideKeyboard() {
        UIApplication.shared.endEditing()
    }
    
    /// Binds a tap gesture to the background to dismiss keyboard
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            self.hideKeyboard()
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
