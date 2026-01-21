import SwiftUI

struct OUDRiskAssessmentView: View {
    @ObservedObject var store: OUDConsultStore
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 1. Risk Factors & Toxicology
                VStack(alignment: .leading, spacing: 12) {
                    Text("Toxicology & History").font(.headline)
                    
                    // Dynamic Substance List
                    if store.entries.isEmpty {
                        Text("No substances selected.")
                            .font(.caption).italic().foregroundColor(.secondary)
                    } else {
                        ForEach(store.entries) { entry in
                            HStack {
                                Image(systemName: "pills.fill")
                                VStack(alignment: .leading) {
                                    Text(entry.type.rawValue).font(.subheadline).bold()
                                    Text("\(entry.quantity, specifier: "%.1f") \(entry.unit) • \(entry.route.rawValue)").font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    if let index = store.entries.firstIndex(of: entry) {
                                        store.entries.remove(at: index)
                                        let gen = UIImpactFeedbackGenerator(style: .medium); gen.impactOccurred()
                                    }
                                }) {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Quick Add Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            QuickAddButton(symbol: "exclamationmark.triangle.fill", label: "Fentanyl", color: .purple) {
                                store.entries.append(SubstanceEntry(type: .streetFentanylPowder, quantity: 1, unit: "g", route: .intranasal, lastUseHoursAgo: 12))
                            }
                            QuickAddButton(symbol: "capsule.fill", label: "Oxy/Hydro", color: .orange) {
                                store.entries.append(SubstanceEntry(type: .oxycodone, quantity: 30, unit: "mg", route: .oral, lastUseHoursAgo: 6))
                            }
                            QuickAddButton(symbol: "cross.case.fill", label: "Benzos", color: .red) {
                                store.entries.append(SubstanceEntry(type: .benzodiazepinesStreet, quantity: 2, unit: "mg", route: .oral, lastUseHoursAgo: 4))
                            }
                            QuickAddButton(symbol: "ant.fill", label: "Xylazine", color: .gray) {
                                store.entries.append(SubstanceEntry(type: .xylazineAdulterant, quantity: 1, unit: "trace", route: .intravenous, lastUseHoursAgo: 12))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                    
                    Toggle("Pregnancy", isOn: $store.isPregnant)
                    Toggle("Breastfeeding", isOn: $store.isBreastfeeding)
                    Toggle("Liver Failure (Child-Pugh C)", isOn: $store.hasLiverFailure)
                    Toggle("Renal Failure (Dialysis / <30)", isOn: $store.hasRenalFailure)
                    Toggle("ER / Inpatient Setting", isOn: $store.erSetting)
                    Divider()
                    Toggle("Skin Ulcers (Xylazine Marker)", isOn: $store.hasUlcers)
                }

                .padding()
                .background(ClinicalTheme.backgroundCard)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))

                // 2. Score Dashboard
                HStack {
                    VStack(alignment: .leading) {
                        Text("COWS Score").font(.caption).bold().foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            Text("\(store.cowsScore)").font(.system(size: 34, weight: .bold)).foregroundColor(scoreColor)
                            Button(action: {
                                store.copyCOWSAssessment()
                                let gen = UINotificationFeedbackGenerator(); gen.notificationOccurred(.success)
                            }) {
                                Image(systemName: "doc.on.doc").font(.subheadline).foregroundColor(ClinicalTheme.teal500)
                            }
                        }
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
                    store.generateClinicalPlan()
                    store.currentPhase = .action
                    store.path.append(ConsultPhase.action)
                }) {
                    Text("Generate Protocol")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()

                        .background(ClinicalTheme.teal500)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: ClinicalTheme.teal500.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding()
            }
        }
    }
    
    var scoreColor: Color {
        switch store.cowsScore {
        case 0...4: return .green
        case 5...12: return .yellow
        case 13...24: return .orange
        case 25...Int.max: return .red
        default: return .gray
        }
    }
}

// Subcomponent: The Horizontal Scroll Grid
struct COWSGrid: View {
    @ObservedObject var store: OUDConsultStore
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(store.cowsItems) { item in
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
                                        Text(option.1).font(.caption2).lineLimit(2).minimumScaleFactor(0.8).multilineTextAlignment(.center)
                                    }
                                    .padding(4)
                                    .frame(width: 110, height: 65)
                                    .background(store.cowsSelections[item.id] == option.0 ? ClinicalTheme.teal500 : ClinicalTheme.backgroundInput)
                                    .foregroundColor(store.cowsSelections[item.id] == option.0 ? .white : ClinicalTheme.textPrimary)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(store.cowsSelections[item.id] == option.0 ? ClinicalTheme.teal500 : ClinicalTheme.cardBorder, lineWidth: 1))
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

struct QuickAddButton: View {
    let symbol: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let gen = UIImpactFeedbackGenerator(style: .medium); gen.impactOccurred()
            action()
        }) {
            VStack {
                Image(systemName: symbol).font(.headline)
                Text(label).font(.caption2).bold()
            }
            .padding(10)
            .frame(width: 80, height: 60)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(10)
        }
    }
}
