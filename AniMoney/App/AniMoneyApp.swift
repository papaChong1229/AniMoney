//
//  AniMoneyApp.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct AniMoneyApp: App {
    @StateObject private var dataController = try! DataController()
    
    // 讀取主題設定
    @AppStorage("selectedAppThemeRawValue") private var storedThemeRawValue: String = AppTheme.system.rawValue
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: storedThemeRawValue) ?? .system
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataController)
                .preferredColorScheme(selectedTheme.colorScheme) // 全域主題設定
                .onAppear {
                    // App 啟動時設置通知代理
                    setupNotifications()
                }
        }
    }
    
    private func setupNotifications() {
        // 設置通知中心代理
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // 清除啟動時的 badge
        clearBadge()
    }
    
    private func clearBadge() {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("清除 badge 失敗: \(error.localizedDescription)")
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}

// MARK: - 通知代理
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // 當 App 在前台時收到通知
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 即使在前台也顯示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 用戶點擊通知時
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 處理通知點擊事件
        if response.notification.request.identifier == "dailyAccountingReminder" {
            // 可以在這裡添加打開特定頁面的邏輯
            print("用戶點擊了記帳提醒通知")
            
            // 清除 badge
            clearBadgeOnClick()
        }
        
        completionHandler()
    }
    
    private func clearBadgeOnClick() {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("清除 badge 失敗: \(error.localizedDescription)")
                }
            }
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}
