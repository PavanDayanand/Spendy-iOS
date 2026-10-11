# Navigation header audit

Custom pinned headers use `SpendyPinnedHeaderLayout` or `spendyBarBackground`.
The background is SwiftUI's adaptive `.bar` material, with no fixed black fill,
custom tint, or opacity. Native navigation bars remain system-managed.

The layout measures its header and reserves that height in the scroll content.
This keeps the initial content clear while allowing it to scroll beneath the bar.
The material layer does not handle taps or appear in accessibility navigation.

## Custom scrolling headers updated

- Recent activity (expanded state; collapsed state still shows three rows)
- All Transactions
- Spending by Category / Account breakdown
- Category / Account analytics when opened with the custom Home header
- New / Edit category, account, folder, subscription and profile
- Currency and icon pickers
- Transaction category and account pickers
- Transaction and subscription details
- Dashboard configuration
- Currency converter
- Receipt scan report
- Voice transaction review

## Existing native headers retained

Settings, Categories, Accounts from Settings, category/account analytics from
Settings, Backup & Restore, Widgets, insight and notification preferences,
Spendy Insights, spending explanations, period selection and breakdown filters.
The internal insight and graphics demo galleries also retain native headers.

## Screens without scrolling under a pinned bar

The Home summary, tab-root subscription heading and Monthly Receipt heading
scroll with their content. Add/Edit Transaction, Account Balance, Edit Budget,
calendar selection and the listening HUD use fixed controls; their content does
not scroll beneath a title bar. Onboarding only scrolls its page inside a clipped
accessibility viewport. Embedded cards and horizontal color/icon rails are not
navigation headers. Camera scanning controls stay over the camera surface.

## Main page headers

Analytics uses transparent sticky period/filter controls while its title scrolls
away. Budget and Subscriptions also scroll their headings while keeping their
action buttons fixed over a transparent background. Accounts keeps its plain
existing header without a material background. Subscriptions uses the adaptive app background
instead of the mesh gradient. The bar treatment is scoped to scrolling sheets
and detail screens.
