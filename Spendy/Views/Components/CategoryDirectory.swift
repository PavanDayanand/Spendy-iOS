import Foundation

struct CategoryDirectorySection: Identifiable {
    let title: String
    let categories: [Category]
    var id: String { title }
}

/// One search and ordering policy for category lists throughout the app.
enum CategoryDirectory {
    private static let familiarFolders = [
        "Everyday Spending", "Transport", "Living", "Personal & Wellness",
        "Salary & Career", "Investments & Other"
    ]

    static func matching(_ categories: [Category], query: String) -> [Category] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return categories }
        return categories.filter {
            $0.label.localizedStandardContains(needle) || $0.folder.localizedStandardContains(needle)
        }
    }

    static func alphabeticalSections(_ categories: [Category], query: String = "") -> [CategoryDirectorySection] {
        let groups = Dictionary(grouping: matching(categories, query: query)) { category in
            let first = category.label.trimmingCharacters(in: .whitespacesAndNewlines).first
            guard let first, first.isLetter else { return "#" }
            return String(first).uppercased()
        }
        return groups.map { key, values in
            CategoryDirectorySection(
                title: key,
                categories: values.sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
            )
        }
        .sorted { $0.title == "#" ? false : ($1.title == "#" || $0.title < $1.title) }
    }

    static func folderSections(_ categories: [Category], query: String = "") -> [CategoryDirectorySection] {
        let groups = Dictionary(grouping: matching(categories, query: query)) { category in
            category.folder.isEmpty ? "Uncategorized" : category.folder
        }
        let keys = groups.keys.sorted { lhs, rhs in
            if lhs == "Uncategorized" { return false }
            if rhs == "Uncategorized" { return true }
            let left = familiarFolders.firstIndex(of: lhs)
            let right = familiarFolders.firstIndex(of: rhs)
            switch (left, right) {
            case let (l?, r?): return l < r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return lhs.localizedStandardCompare(rhs) == .orderedAscending
            }
        }
        return keys.map { key in
            CategoryDirectorySection(
                title: key,
                categories: (groups[key] ?? []).sorted {
                    $0.order == $1.order
                        ? $0.label.localizedStandardCompare($1.label) == .orderedAscending
                        : $0.order < $1.order
                }
            )
        }
    }
}
