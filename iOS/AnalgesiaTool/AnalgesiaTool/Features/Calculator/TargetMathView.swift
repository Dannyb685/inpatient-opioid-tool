import SwiftUI

struct TargetMathView: View {
    let target: TargetDose
    let calculatorStore: CalculatorStore
    @Environment(\.presentationMode) var presentationMode
    
    // Derived
    var inputMME: Double {
        return Double(calculatorStore.resultMME) ?? 0.0
    }
    
    var reductionAmt: Double {
        return inputMME * (calculatorStore.reduction / 100.0)
    }
    
    var reducedMME: Double {
        return inputMME - reductionAmt
    }
    
    var calculatedDose: Double {
        if target.factor == 0 { return 0 }
        return reducedMME / target.factor
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // HEADER
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calculation for:")
                                .font(.caption).bold()
                                .foregroundColor(ClinicalTheme.textSecondary)
                            Text("\(target.drug) \(target.route)")
                                .font(.title2).bold()
                                .foregroundColor(ClinicalTheme.teal500)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    
                    // FORMULA CARD
                    VStack(spacing: 0) {
                        Text("MATH LOGIC")
                            .font(.caption).bold()
                            .foregroundColor(ClinicalTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(ClinicalTheme.backgroundMain.opacity(0.5))
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // 1. Total MME
                            MathRow(label: "Total Daily MME", value: String(format: "%.1f", inputMME), unit: "MME")
                            
                            // 2. Reduction
                            MathRow(label: "Reduction (\(Int(calculatorStore.reduction))%)", value: String(format: "- %.1f", reductionAmt), unit: "MME", isNegative: true)
                            
                            Divider()
                            
                            // 3. Reduced MME
                            MathRow(label: "Reduced MME", value: String(format: "%.1f", reducedMME), unit: "MME", highlight: true)
                            
                            // 4. Factor Divisor
                            HStack {
                                Text("÷ Conversion Factor")
                                    .font(.subheadline)
                                    .foregroundColor(ClinicalTheme.textSecondary)
                                Spacer()
                                Text("\(String(format: "%.1f", target.factor))")
                                    .font(.subheadline).bold()
                                    .foregroundColor(ClinicalTheme.textPrimary)
                            }
                            .padding(.vertical, 4)
                            
                            Divider()
                            
                            // 5. Result
                            HStack(alignment: .top) {
                                Text("= Estimated Target")
                                    .font(.headline)
                                    .foregroundColor(ClinicalTheme.teal500)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(String(format: "%.1f", calculatedDose)) \(target.unit)")
                                        .font(.title3).bold()
                                        .foregroundColor(ClinicalTheme.teal500)
                                    
                                    if let original = target.originalDaily {
                                        Text("Rounded from \(original)") 
                                            .font(.caption)
                                            .foregroundColor(ClinicalTheme.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .background(ClinicalTheme.backgroundCard)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ClinicalTheme.cardBorder, lineWidth: 1))
                    
                    // CLINICAL NOTES
                    if !target.ratioLabel.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CLINICAL ADJUSTMENTS")
                                .font(.caption).bold()
                                .foregroundColor(ClinicalTheme.textSecondary)
                            
                            HStack(alignment: .top) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(ClinicalTheme.blue500)
                                Text(target.ratioLabel)
                                    .font(.subheadline)
                                    .foregroundColor(ClinicalTheme.textPrimary)
                            }
                            .padding()
                            .background(ClinicalTheme.blue500.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Calculation Logic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}

// Math Helper
struct MathRow: View {
    let label: String
    let value: String
    let unit: String
    var isNegative: Bool = false
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(highlight ? .headline : .subheadline)
                .foregroundColor(ClinicalTheme.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .font(highlight ? .headline : .subheadline)
                    .bold()
                    .foregroundColor(isNegative ? ClinicalTheme.rose500 : ClinicalTheme.textPrimary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(ClinicalTheme.textSecondary)
            }
        }
    }
}
