//
//  ContentView.swift
//  Spendy
//
//  Created by Pavan D on 19/8/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
