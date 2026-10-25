import Observation

/// Navigation actions supplied by the page currently at the top of Analytics.
@Observable
final class AnalyticsNavigationHeaderState {
    var title = "Analytics"
    var subtitle: String?
    var isVisible = false
    var onBack: (() -> Void)?
    var onEdit: (() -> Void)?
    var primaryAction: StackHeaderAction?
    var menuItems: [AnalyticsNavigationHeaderMenuItem] = []
    var menuLabel = "Options"
    var menuIdentifier = "analytics-stack-options"
    var menuValue = ""

    var hasActions: Bool {
        !menuItems.isEmpty || primaryAction != nil || onEdit != nil
    }

    func show(title: String, subtitle: String? = nil, isVisible: Bool = true,
              onBack: @escaping () -> Void, onEdit: (() -> Void)? = nil,
              menuItems: [AnalyticsNavigationHeaderMenuItem] = [],
              menuLabel: String = "Options", menuIdentifier: String = "analytics-stack-options",
              menuValue: String = "", primaryAction: StackHeaderAction? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.isVisible = isVisible
        self.onBack = onBack
        self.onEdit = onEdit
        self.primaryAction = primaryAction
        self.menuItems = menuItems
        self.menuLabel = menuLabel
        self.menuIdentifier = menuIdentifier
        self.menuValue = menuValue
    }
}
