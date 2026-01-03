import SwiftUI

struct OUDRiskAssessmentView: View {
    @ObservedObject var store: OUDConsultStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Risk Factors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Clinical Context").font(.headline)
                    Picker("Substance", selection: $store.substanceType) {
                        Text("Short Acting").tag("Short Acting")
                        Text("Fentanyl").tag("Fentanyl")
                        Text("Methadone").tag("Methadone")
                    }
                    .pickerStyle(.segmented)
                    
                    Toggle("Pregnancy", isOn: $store.isPregnant)
                    Toggle("Liver Failure / Acute Pain", isOn: $store.hasLiverFailure)
                    Toggle("ER / Inpatient Setting", isOn: $store.erSetting)
                    Toggle("Benzo / Alcohol Use", isOn: $store.hasSedativeUse)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // 2. Score Dashboard
                HStack {
                    VStack(alignment: .leading) {
                        Text("COWS Score").font(.caption).bold().foregroundColor(.secondary)
                        Text("\(store.cowsScore)").font(.system(size: 34, weight: .bold)).foregroundColor(scoreColor)
                    }
                    Spacer()
                    Text(store.withdrawalSeverity).font(.headline)
                        .padding(8).background(scoreColor.opacity(0.15))
                        .foregroundColor(scoreColor).cornerRadius(8)
                }
                .padding(.horizontal)
                
                // 3. Tappable Grid
                COWSGrid(store: store)
                
                // 4. Action
                Button(action: {
                    store.currentPhase = .action
                    store.path.append(ConsultPhase.action)
                }) {
                    Text("Generate Protocol")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
    
    var scoreColor: Color {
        switch store.cowsScore {
        case 0...12: return .green; case 13...24: return .orange; default: return .red
        }
    }
}

// Subcomponent: The Horizontal Scroll Grid
struct COWSGrid: View {
    @ObservedObject var store: OUDConsultStore
    
    // Full COWS Data Set
    let items: [COWSItem] = [
        .init(id: 1, title: "Resting Pulse", options: [(0,"<80"), (1,"80-100"), (2,"100-120"), (4,">120")]),
        .init(id: 2, title: "Sweating", options: [(0,"None"), (1,"Chills"), (2,"Flushed"), (3,"Beads"), (4,"Stream")]),
        .init(id: 3, title: "Restlessness", options: [(0,"None"), (1,"Hard to sit"), (3,"Shift"), (5,"Can't sit")]),
        .init(id: 4, title: "Pupil Size", options: [(0,"Normal"), (1,"Large"), (2,"Dilated"), (5,"Rim only")]),
        .init(id: 5, title: "Bone/Joint Aches", options: [(0,"None"), (1,"Mild"), (2,"Severe"), (4,"Rubbing")]),
        .init(id: 6, title: "Runny Nose", options: [(0,"None"), (1,"Moist"), (2,"Running"), (4,"Stream")]),
        .init(id: 7, title: "GI Upset", options: [(0,"None"), (1,"Cramps"), (2,"Nausea"), (3,"Vomit"), (5,"Multi-Epis")]),
        .init(id: 8, title: "Tremor", options: [(0,"None"), (1,"Felt"), (2,"Slight"), (4,"Gross")]),
        .init(id: 9, title: "Yawning", options: [(0,"None"), (1,"1-2x"), (2,"3+ times"), (4,"Freq/Min")]),
        .init(id: 10, title: "Anxiety", options: [(0,"None"), (1,"Reported"), (2,"Obvious"), (4,"Difficult")]),
        .init(id: 11, title: "Gooseflesh", options: [(0,"Smooth"), (3,"Felt"), (5,"Prominent")])
    ]

    var body: some View {
        VStack(spacing: 24) {
            ForEach(items, id: \.id) { item in
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.title).font(.headline).padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(item.options, id: \.0) { option in
                                Button(action: {
                                    store.cowsSelections[item.id] = option.0
                                    let gen = UIImpactFeedbackGenerator(style: .light); gen.impactOccurred()
                                }) {
                                    VStack(spacing: 4) {
                                        Text("\(option.0)").font(.title3).bold()
                                        Text(option.1).font(.caption2).lineLimit(1)
                                    }
                                    .frame(width: 80, height: 60)
                                    .background(store.cowsSelections[item.id] == option.0 ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(store.cowsSelections[item.id] == option.0 ? .white : .primary)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                Divider().padding(.leading)
            }
        }
    }
}
struct COWSItem { let id: Int; let title: String; let options: [(Int, String)] }
