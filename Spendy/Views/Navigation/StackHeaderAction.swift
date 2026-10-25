import Foundation

/// An action supplied by the page currently using a stack's shared header.
struct StackHeaderAction {
    let id: String
    let title: String
    let symbol: String
    let perform: () -> Void
}
