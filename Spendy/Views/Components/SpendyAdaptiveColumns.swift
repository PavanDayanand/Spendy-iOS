import SwiftUI

/// System arrangements avoid the active fold; older OS versions retain two columns.
struct SpendyAdaptiveColumns<Primary: View, Secondary: View>: View {
    var allowsVertical = false
    @ViewBuilder var primary: () -> Primary
    @ViewBuilder var secondary: () -> Secondary

    var body: some View {
        if #available(iOS 27.1, *) {
            ArrangementView(primary: primary, secondary: secondary)
                .arrangementViewStyle(.split.axes(allowsVertical ? Axis.Set.horizontal.union(.vertical) : Axis.Set.horizontal))
        } else {
            GeometryReader { geometry in
                let layout = allowsVertical && geometry.size.height > geometry.size.width
                    ? AnyLayout(VStackLayout(spacing: 20))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: 20))
                layout {
                    primary().frame(maxWidth: .infinity, maxHeight: .infinity)
                    secondary().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}
