//
//  SpendyApp.swift
//  Spendy
//
//  Created by Pavan D on 19/8/26.
//

import SwiftUI

@main
struct SpendyApp: App {
    @State private var store = ExpenseStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(store.colorScheme)
        }
    }
}
