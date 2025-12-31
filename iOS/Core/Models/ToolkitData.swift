import Foundation

struct ToolkitData {
    // --- SOS Score Data ---
    static let sosInputs = ["Surgery Type", "Length of Stay", "Preoperative Opioid Exposure", "Psychiatric Comorbidity"]
    
    // --- PEG Scale Data ---
    static let pegQuestions = [
        "What is your average pain intensity in the past week?",
        "How has pain interfered with your enjoyment of life?",
        "How has pain interfered with your general activity?"
    ]
    
    // --- Brief Intervention (FRAMES) ---
    static let framesData = [
        ("F", "Feedback", "Provide personalized feedback on the risks of their substance use."),
        ("R", "Responsibility", "Emphasize that change is their own responsibility and choice."),
        ("A", "Advice", "Give clear, non-judgmental advice to cut back or abstain."),
        ("M", "Menu", "Offer a menu of options for change (taper, treatment, counseling)."),
        ("E", "Empathy", "Use an empathetic, warm, reflective counseling style."),
        ("S", "Self-Efficacy", "Reinforce their ability (self-efficacy) to make changes.")
    ]
    
    // --- Visual Aids ---
    static let drinkEquivalents = [
        ("Beer (5%)", "12 oz", "1 Standard Drink"),
        ("Malt Liquor (7%)", "8-9 oz", "1 Standard Drink"),
        ("Wine (12%)", "5 oz", "1 Standard Drink"),
        ("Hard Liquor (40%)", "1.5 oz", "1 Standard Drink"),
        ("Pint of Liquor", "375 ml", "8.5 Standard Drinks"),
        ("Fifth of Liquor", "750 ml", "17 Standard Drinks"),
        ("Handle of Liquor", "1.75 L", "39 Standard Drinks")
    ]
    
    static let streetOpioidTerms = [
        ("Oxycodone", "Percs, Oxy, Roxy, Blues, Hillbilly Heroin, Kickers"),
        ("Hydrocodone", "Vikes, Norco, Hydro, Watson, 357s"),
        ("Heroin / Fentanyl", "Dope, H, Smack, China White, Fetty, Baggies, Tar"),
        ("Codeine / Promethazine", "Lean, Sizzurp, Purple Drank, Syrup"),
        ("Benzodiazepines", "Bars, Xannies, Ladders, Z-Bars, Footballs")
    ]
}
