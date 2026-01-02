import Foundation
import Combine

struct QuestionViewModel: Identifiable {
    let id: String
    let text: String
    var isYes: Bool = false
}

struct AssistSubstance: Identifiable {
    let id: String
    let name: String
    var usedInPast3Months: Bool = false
    var q1_Frequency: Bool = false // >10 cigs, >4 drinks, or >weekly for others
    var q2_Concern: Bool = false // Failed to stop OR Concern expressed
    var q3_Extra: Bool = false // Tobacco: Within 30mins? Alcohol: Tried to stop?
    
    var riskCategory: String {

        // Logic varies by substance, simplified for MVP based on provided text:
        // Tobacco: 0=Low, 1-2=Mod, 3=High
        // Alcohol: 0-1=Low, 2=Mod, 3-4=High (Wait, max score is 3 here? Let's check logic)
        // User text says "count yes answers".
        // Tobacco: 1, 1a, 1b. (3 questions).
        // Alcohol: 2, 2a, 2b, 2c. (4 questions).
        // Others: 3, 3a, 3b. (3 questions).
        
        switch id {
        case "tobacco":
            let s = (usedInPast3Months ? 1 : 0) + (q1_Frequency ? 1 : 0) + (q3_Extra ? 1 : 0) // q3 is 1b
            if s == 0 { return "Low" }
            if s <= 2 { return "Moderate" }
            return "High"
        case "alcohol":
            let s = (usedInPast3Months ? 1 : 0) + (q1_Frequency ? 1 : 0) + (q3_Extra ? 1 : 0) + (q2_Concern ? 1 : 0)
            if s <= 1 { return "Low" }
            if s == 2 { return "Moderate" }
            return "High"
        default:
            let s = (usedInPast3Months ? 1 : 0) + (q1_Frequency ? 1 : 0) + (q2_Concern ? 1 : 0)
            if s == 0 { return "Low" }
            if s <= 2 { return "Moderate" }
            return "High"
        }
    }
}

class ScreeningStore: ObservableObject {
    @Published var questions: [QuestionViewModel] = [
        QuestionViewModel(id: "d1", text: "Have you used drugs other than those required for medical reasons?"),
        QuestionViewModel(id: "d2", text: "Do you use more than one drug at a time?"),
        QuestionViewModel(id: "d3", text: "Are you unable to get through the week without using drugs?"),
        QuestionViewModel(id: "d4", text: "Have you ever had blackouts or flashbacks as a result of drug use?"),
        QuestionViewModel(id: "d5", text: "Do you ever feel bad or guilty about your drug use?"),
        QuestionViewModel(id: "d6", text: "Does your spouse (or parents) ever complain about your involvement with drugs?"),
        QuestionViewModel(id: "d7", text: "Have you neglected your family because of your use of drugs?"),
        QuestionViewModel(id: "d8", text: "Have you engaged in illegal activities in order to obtain drugs?"),
        QuestionViewModel(id: "d9", text: "Have you ever experienced withdrawal symptoms (felt sick) when you stopped taking drugs?"),
        QuestionViewModel(id: "d10", text: "Have you had medical problems as a result of your drug use (e.g., memory loss, hepatitis, convulsions, bleeding)?")
    ]
    
    var riskScore: Int {
        questions.filter { $0.isYes }.count
    }
    
    var riskLevel: String {
        switch riskScore {
        case 0: return "Low Risk"
        case 1...2: return "Low/Moderate Risk"
        case 3...5: return "Moderate Risk"
        case 6...10: return "Substantial Risk"
        default: return "Unknown"
        }
    }
    
    @Published var assistSubstances: [AssistSubstance] = [
        AssistSubstance(id: "tobacco", name: "Tobacco"),
        AssistSubstance(id: "alcohol", name: "Alcohol"),
        AssistSubstance(id: "cannabis", name: "Cannabis"),
        AssistSubstance(id: "stimulants", name: "Stimulants (Cocaine/Amphetamine)"),
        AssistSubstance(id: "sedatives", name: "Sedatives/Sleeping Meds"),
        AssistSubstance(id: "opioids", name: "Opioids (Street/Rx)"),
        AssistSubstance(id: "other", name: "Other Psychoactive Substances")
    ]
    
    init() {}
}
