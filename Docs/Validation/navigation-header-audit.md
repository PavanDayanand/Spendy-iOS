# Navigation header audit

## Transparent custom headers

Custom headers keep their existing sticky buttons without a background bar or
material layer. `SpendyPinnedHeaderLayout` measures the controls and reserves
initial scroll spacing, allowing content to pass underneath the transparent header.

This applies to transaction and subscription details, All Transactions, spending
breakdown, custom category/account analytics, creation and editing forms,
profile editing, currency/icon/entity pickers, dashboard configuration, converter,
receipt report, voice review and expanded recent activity.

Analytics keeps its original transparent sticky period/filter controls while
its heading scrolls away. Budget and Subscriptions scroll their headings while
their action buttons stay fixed. Subscriptions uses the plain adaptive background.

## Existing native headers

Settings and its native navigation pages keep their system-managed header
behavior. No custom blur is added to those screens.

## Fixed and embedded content

Keypads, calendar controls, onboarding, embedded charts and camera controls
keep their existing layouts without an added header background.
