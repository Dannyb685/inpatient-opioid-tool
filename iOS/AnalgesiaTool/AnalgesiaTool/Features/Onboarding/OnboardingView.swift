import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasAcceptedLiability_v1") private var hasAccepted: Bool = false
    
    @State private var isToggleOn: Bool = false
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                
                // Icon
                Image(systemName: "cross.case.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.red)
                    .padding(.top, 40)
                    .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Header
                VStack(spacing: 12) {
                    Text("Clinical Decision Support")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Opioid Precision Tool")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Legal Text Scroll
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        disclaimerPoint(icon: "stethoscope", title: "Licensed Provider Use Only", text: "By using this Application, you represent and warrant that you are a validly licensed healthcare professional in good standing in your jurisdiction. This Application is NOT intended for use by patients or the general public.")
                        
                        disclaimerPoint(icon: "exclamationmark.triangle", title: "No Medical Advice", text: "THIS APPLICATION IS AN EDUCATIONAL TOOL ONLY. It does NOT provide medical advice, diagnosis, or treatment. It is not a substitute for the independent professional judgment of a healthcare provider.")
                        
                        disclaimerPoint(icon: "hand.raised.fill", title: "Clinical Variability", text: "Algorithms used in this Application do NOT account for individual patient history, comorbidities, polypharmacy, genetics, or risk of misuse. Outputs may be inappropriate for specific clinical scenarios.")
                        
                        Text("By continuing, you acknowledge that you have independently verified all inputs and outputs.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding()
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Agreement
                HStack {
                    Toggle("", isOn: $isToggleOn)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                    
                    Text("I am a licensed clinician and I accept full responsibility for patient care.")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 24)
                
                // Button
                Button(action: {
                    withAnimation {
                        hasAccepted = true
                        isPresented = false
                    }
                }) {
                    Text("Agree & Continue")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isToggleOn ? Color.blue : Color.gray.opacity(0.5))
                        .cornerRadius(14)
                }
                .disabled(!isToggleOn)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    opacity = 1.0
                }
            }
        }
    }
    
    func disclaimerPoint(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.body)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isPresented: .constant(true))
    }
}
