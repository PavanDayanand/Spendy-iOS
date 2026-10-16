import Foundation

/// A bundled copy of the website policy keeps it available before hosting and offline.
struct PrivacyPolicyDocument: Decodable {
    let title: String
    let updated: String
    let developer: String
    let intro: String
    let contactEmail: String?
    private let privacyPolicyURL: String?
    let sections: [PrivacyPolicySection]

    static let current: PrivacyPolicyDocument? = {
        guard let url = Bundle.main.url(forResource: "privacy-policy", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PrivacyPolicyDocument.self, from: data)
    }()

    var websiteURL: URL? {
        guard let privacyPolicyURL, let url = URL(string: privacyPolicyURL),
              url.scheme == "https", url.host != nil else { return nil }
        return url
    }
}
