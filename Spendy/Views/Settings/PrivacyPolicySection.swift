import Foundation

struct PrivacyPolicySection: Decodable, Identifiable {
    let id: String
    let title: String
    let scope: String
    let paragraphs: [String]
    let links: [PrivacyPolicyLink]?
}
