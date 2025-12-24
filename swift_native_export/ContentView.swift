import SwiftUI

struct ContentView: View {
    @StateObject private var logic = ClinicalLogic()
    @State private var showDisclaimer = true
    @State private var showResults = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Patient Profile")) {
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("Age", text: $logic.age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Sex", selection: $logic.sex) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Opioid Naive", isOn: $logic.naive)
                    Toggle("Home Buprenorphine (MAT)", isOn: $logic.mat)
                }
                
                Section(header: Text("Risk Factors")) {
                    Toggle("Sleep Apnea", isOn: $logic.sleepApnea)
                    Toggle("Heart Failure", isOn: $logic.chf)
                    Toggle("Benzos / Sedatives", isOn: $logic.benzos)
                }
                
                Section(header: Text("Clinical Status")) {
                    Picker("Renal", selection: $logic.renal) {
                        Text("Normal").tag("Normal")
                        Text("Impaired").tag("Impaired")
                        Text("Dialysis").tag("Dialysis")
                    }
                    
                    Picker("Hepatic", selection: $logic.hepatic) {
                        Text("Normal").tag("Normal")
                        Text("Impaired").tag("Impaired")
                        Text("Failure").tag("Failure")
                    }
                    
                    Picker("Route Preference", selection: $logic.route) {
                        Text("IV").tag("IV")
                        Text("PO").tag("PO")
                        Text("Both").tag("Both")
                    }
                }
                
                Section {
                    Button(action: {
                        showResults = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Generate Guidance")
                                .bold()
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Analgesia Tool")
            .sheet(isPresented: $showDisclaimer) {
                DisclaimerView(showDisclaimer: $showDisclaimer)
            }
            .sheet(isPresented: $showResults) {
                ResultsView(logic: logic)
            }
        }
    }
}

struct DisclaimerView: View {
    @Binding var showDisclaimer: Bool
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Medical Disclaimer").font(.title).bold()
            Text("This tool is for educational purposes only. dVerify all doses against hospital protocol.").multilineTextAlignment(.center).padding()
            Button("I Accept") { showDisclaimer = false }
                .padding().frame(maxWidth: .infinity).background(Color.blue).foregroundColor(.white).cornerRadius(10)
        }.padding()
    }
}

struct ResultsView: View {
    @ObservedObject var logic: ClinicalLogic
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("PRODIGY Risk")) {
                    HStack {
                        Text("Score")
                        Spacer()
                        Text("\(logic.prodigyScore)").bold()
                    }
                    HStack {
                        Text("Risk Tier")
                        Spacer()
                        Text(logic.prodigyRisk).bold()
                            .foregroundColor(logic.prodigyRisk == "High" ? .red : .primary)
                    }
                }
                
                Section(header: Text("Medication Strategy")) {
                    if logic.recs.isEmpty {
                        Text("No specific filters applied.")
                    } else {
                        ForEach(logic.recs) { rec in
                            VStack(alignment: .leading) {
                                Text(rec.name).font(.headline)
                                Text(rec.detail).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Guidance")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}
