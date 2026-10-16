import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            if let policy = PrivacyPolicyDocument.current {
                VStack(alignment: .leading, spacing: 24) {
                    Text(policy.title).font(.largeTitle.bold())
                    Text("Last updated \(policy.updated)")
                        .font(.footnote)
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text(policy.intro)
                    ForEach(policy.sections.filter { $0.scope != "website" }) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title).font(.title3.bold()).accessibilityAddTraits(.isHeader)
                            ForEach(section.paragraphs, id: \.self) { Text($0) }
                            ForEach(section.links ?? [], id: \.url) { link in
                                Link(link.title, destination: link.url).underline()
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact").font(.title3.bold()).accessibilityAddTraits(.isHeader)
                        Text("Spendy is developed by \(policy.developer).")
                        if let email = policy.contactEmail,
                           let url = URL(string: "mailto:\(email)") {
                            Link(email, destination: url).underline()
                        } else {
                            Text("A dedicated privacy contact will be provided before public release.")
                        }
                        Text("Please do not send banking passwords, full card numbers, or your complete financial ledger when asking a privacy question.")
                    }
                }
                .font(.body)
                .textSelection(.enabled)
                .padding(20)
                .accessibilityIdentifier("privacy-policy-document")
            } else {
                ContentUnavailableView("Privacy policy unavailable", systemImage: "doc.text",
                    description: Text("Please try again after updating Spendy."))
            }
        }
        .foregroundStyle(SpendyColors.textPrimary)
        .tint(SpendyColors.textPrimary)
        .background(SpendyColors.settingsBackground.ignoresSafeArea())
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
