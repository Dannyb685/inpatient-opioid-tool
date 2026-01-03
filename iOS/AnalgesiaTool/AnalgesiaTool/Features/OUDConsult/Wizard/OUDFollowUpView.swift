import SwiftUI

struct OUDFollowUpView: View {
    @ObservedObject var store: OUDConsultStore
    @State private var daysToClinic: Double = 3
    @State private var dailyDose: Double = 16
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Checklist
                VStack(alignment: .leading, spacing: 16) {
                    Text("Discharge Checklist").font(.headline)
                    ForEach(store.dischargeChecklist, id: \.self) { item in
                        HStack { Image(systemName: "square"); Text(item) }
                    }
                    if store.hasSedativeUse {
                        HStack { 
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            Text("Counsel: Respiratory Depression (Sedatives)").font(.caption).bold() 
                        }
                    }
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground)).cornerRadius(12)
                
                // Bridge Calculator
                if store.recommendedProtocol != .fullAgonist {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Bridge Prescription").font(.headline)
                        
                        HStack { Text("Days until appt:"); Spacer(); Text("\(Int(daysToClinic)) days").bold() }
                        Slider(value: $daysToClinic, in: 1...7, step: 1)
                        
                        HStack { Text("Daily Dose:"); Spacer(); Text("\(Int(dailyDose)) mg").bold() }
                        Stepper("", value: $dailyDose, step: 2)
                        
                        Divider()
                        
                        HStack {
                            Text("Total Dispense:").font(.headline).foregroundColor(.blue)
                            Spacer()
                            Text("\(Int(daysToClinic * dailyDose)) mg").font(.title2).bold()
                        }
                    }
                    .padding().background(Color.white).cornerRadius(12).shadow(radius: 1)
                }
                
                Button("End Consult") { store.reset() }.padding(.top)
            }
            .padding()
        }
        .navigationTitle("Discharge")
    }
}
