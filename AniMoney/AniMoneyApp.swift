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
    @StateObject private var dataController = try! DataController()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataController)
        }
    }
}



