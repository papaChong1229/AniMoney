//
//  AniMoneyApp.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import SwiftUI
import SwiftData

@main
struct AniMoneyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [Category.self, Subcategory.self, Project.self, Transaction.self]
        )
    }
}



