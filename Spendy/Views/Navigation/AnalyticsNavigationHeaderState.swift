import Observation

/// Navigation actions supplied by the page currently at the top of Analytics.
@Observable
final class AnalyticsNavigationHeaderState {
    var title = "Analytics"
    var subtitle: String?
    var isVisible = false
    var onBack: (() -> Void)?
    var onEdit: (() -> Void)?

    func show(title: String, subtitle: String? = nil, isVisible: Bool = true,
              onBack: @escaping () -> Void, onEdit: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.isVisible = isVisible
        self.onBack = onBack
        self.onEdit = onEdit
    }
}
