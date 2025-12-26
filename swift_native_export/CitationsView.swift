import SwiftUI

struct ReferenceItem: Identifiable {
    let id = UUID()
    let title: String
    let citation: String
    let url: String?
}

struct CitationsView: View {
    let references: [ReferenceItem] = [
        ReferenceItem(
            title: "CDC Clinical Practice Guideline (2022)",
            citation: "Dowell D, Ragan KR, Jones CM, Baldwin GT, Chou R. CDC Clinical Practice Guideline for Prescribing Opioids for Pain — United States, 2022. MMWR Recomm Rep 2022;71(No. RR-3):1–95.",
            url: "https://www.cdc.gov/mmwr/volumes/71/rr/rr7103a1.htm"
        ),
        ReferenceItem(
            title: "PRODIGY Score (Respiratory Depression)",
            citation: "Shafi S, et al. PRODIGY: A Risk Score to Predict Opioid-Induced Respiratory Depression. J Hosp Med. 2018;13(10):734-740. doi:10.12788/jhm.2989",
            url: "https://pubmed.ncbi.nlm.nih.gov/29841979/"
        ),
        ReferenceItem(
            title: "COWS (Withdrawal Scale)",
            citation: "Wesson DR, Ling W. The Clinical Opiate Withdrawal Scale (COWS). J Psychoactive Drugs. 2003;35(2):253-9.",
            url: "https://pubmed.ncbi.nlm.nih.gov/12924748/"
        ),
        ReferenceItem(
            title: "Opioid Risk Tool (ORT)",
            citation: "Webster LR, Webster RM. Predicting aberrant behaviors in opioid-treated patients: preliminary validation of the Opioid Risk Tool. Pain Med. 2005;6(6):432-42.",
            url: "https://pubmed.ncbi.nlm.nih.gov/16336480/"
        ),
        ReferenceItem(
            title: "PEG Scale (Pain/Enjoyment/General)",
            citation: "Krebs EE, et al. Development and initial validation of the PEG, a three-item scale assessing pain intensity and interference. J Gen Intern Med. 2009;24(6):733-8.",
            url: "https://pubmed.ncbi.nlm.nih.gov/19418100/"
        ),
        ReferenceItem(
            title: "WHO ASSIST (Screening)",
            citation: "WHO ASSIST Working Group. The Alcohol, Smoking and Substance Involvement Screening Test (ASSIST): development, reliability and feasibility. Addiction. 2002;97(9):1183-94.",
            url: "https://www.who.int/publications/i/item/978924159938-2"
        ),
        ReferenceItem(
            title: "Equianalgesic Conversions",
            citation: "CMS Opioid Oral Morphine Milligram Equivalent (MME) Conversion Factors (2023). Centers for Medicare & Medicaid Services.",
            url: "https://www.cms.gov/Medicare/Prescription-Drug-Coverage/PrescriptionDrugCovContra/Downloads/Opioid-Morphine-EQ-Conversion-Factors-Aug-2017.pdf"
        ),
        ReferenceItem(
            title: "Journavax (Suzetrigine)",
            citation: "First-in-class oral selective NaV1.8 inhibitor for acute pain. FDA Approved 2025 (Vertex Pharmaceuticals). Non-opioid analgesia for moderate-to-severe acute pain.",
            url: "https://www.vrtx.com/"
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Clinical Guidelines & Tools")) {
                    ForEach(references) { ref in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ref.title)
                                .font(.headline)
                                .foregroundColor(ClinicalTheme.textPrimary)
                            
                            Text(ref.citation)
                                .font(.caption)
                                .foregroundColor(ClinicalTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let urlString = ref.url, let url = URL(string: urlString) {
                                Link(destination: url) {
                                    HStack {
                                        Text("View Source")
                                            .font(.caption).bold()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                    }
                                    .foregroundColor(ClinicalTheme.teal500)
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(footer: Text("This application is for educational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment.")) {
                    EmptyView()
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("References")
            .navigationBarTitleDisplayMode(.inline)
            .background(ClinicalTheme.backgroundMain.edgesIgnoringSafeArea(.all))
        }
    }
}
