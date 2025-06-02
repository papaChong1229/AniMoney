//
//  AppTheme.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/31.
//

import SwiftUI

// App 主題枚舉
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "系統預設"
    case light = "淺色模式"
    case dark = "深色模式"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
