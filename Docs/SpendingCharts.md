# Spending charts

Implemented 11 October 2026 in the SpendyIOS project.

## Home

The Home summary uses recorded expenses for the selected account, independently of the recent-activity drawer filters. A monochrome amount and comparison sit above a native six-month Swift Charts view. The current month is labelled “To date.” Bar/Line preference persists through the existing setting. Tap or drag to select a month; Reset returns to the current month. The category insight opens Analytics with the same account and month.

The top canvas scrolls when content exceeds its available space, including at accessibility text sizes. Chart tick labels have a bounded text size to prevent collisions; full dates and monetary values remain available through mark labels, selection and a custom audio-graph descriptor.

The information sheet explains inclusion, recorded-data limitations, current and baseline periods, partial periods, and refund semantics. Privacy mode removes the chart, comparison and category insight as well as masking the total.

## Analytics

The existing Day/Week/Month/Year navigation now feeds the recorded-spending chart through the shared snapshot. Future transactions are excluded. Selection shows the bucket amount and transaction count. Show transactions presents only the matching expenses for the selected account, period and optional bucket. Opening transaction details dismisses the list first; existing parent-owned editing behavior is retained.

Category/account breakdown rows now use ranked horizontal bars with exact amounts and shares. Existing entity-analytics navigation remains available from the rows.

## Data rules

SpendingChartSnapshot uses calendar periods and half-open buckets. All accounts use the app's shared currency. Income and transfers are excluded. A refund recorded as income does not reduce the expense total. Current-period comparisons use InsightComparison's matching elapsed time and shorter-period clamp. Missing baseline records never produce an invented percentage or savings claim. Actual data is refreshed on transaction changes; Home also refreshes every minute.

## Verification

SpendingChartSnapshotTests covers account/type/date exclusion, exact month boundaries, partial-period comparisons including fractional seconds, shorter months, missing baselines, year rollover, daylight saving, category ranking and future/historical periods.

SpendingChartUITests covers saved chart styles, info/privacy, drawer-filter isolation, selected months, account-scoped navigation, matching transaction detail, light/dark screenshots and accessibility-sized text.

The simulator uses the isolated `charts` fixture; screenshots contain demo data. User icon and backup changes were left intact.

Validated: Xcode simulator build succeeded; 9 calculation tests, 5 chart UI tests and 2 existing Home/category accessibility-navigation regression tests passed. Final Home screenshots were visually reviewed in light/dark appearance; large text, privacy, selected months and Analytics detail were also reviewed. `git diff --check` passed.

Analytics refinement: Spendy insights now live at the top of About spending, with destination actions deferred until the info sheet dismisses. A native horizontal category/account chart compares amounts; exact amount/share rows retain drill-through. Reading guides explain spending bars, category shares, cash-flow fill, and all three streak calendar states. Streak dates remain visible in filled and outlined cells; incomplete days are distinct and the recorded-data caveat is explicit.

Refinement validation: fresh simulator build, info/legend/streak UI verification, transaction drill-through, and existing remaining-category navigation passed. Category chart, info insights, and streak screenshots were visually reviewed and saved in Design. git diff --check passed.
