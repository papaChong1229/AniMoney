// SettingView.swift - 更新版本

import SwiftUI
import UserNotifications

struct SettingView: View {
    @EnvironmentObject var dataController: DataController
    
    // 通知設定
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled: Bool = false
    @AppStorage("notificationHour") private var notificationHour: Int = 20 // 預設晚上8點
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
    
    // 主題設定
    @AppStorage("selectedAppThemeRawValue") private var storedThemeRawValue: String = AppTheme.system.rawValue
    @State private var pickerSelectedTheme: AppTheme = .system
    
    // 刪除確認狀態
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteSuccess = false
    
    // 通知權限狀態
    @State private var notificationPermissionDenied = false
    
    private var selectedTheme: AppTheme {
        AppTheme(rawValue: storedThemeRawValue) ?? .system
    }
    
    private var notificationTime: Date {
        var components = DateComponents()
        components.hour = notificationHour
        components.minute = notificationMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        Form {
            // 通知設定區域
            Section(header: Text("通知設定")) {
                Toggle("啟用記帳提醒", isOn: $isNotificationsEnabled)
                    .tint(.blue)
                    .onChange(of: isNotificationsEnabled) { _, newValue in
                        if newValue {
                            requestNotificationPermission()
                        } else {
                            removeAllNotifications()
                        }
                    }
                
                if isNotificationsEnabled {
                    DatePicker(
                        "提醒時間",
                        selection: Binding(
                            get: { notificationTime },
                            set: { newDate in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                notificationHour = components.hour ?? 20
                                notificationMinute = components.minute ?? 0
                                scheduleNotification()
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!isNotificationsEnabled)
                    
                    Text("每天 \(String(format: "%02d:%02d", notificationHour, notificationMinute)) 提醒您記帳")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 外觀設定
            Section(header: Text("外觀")) {
                Picker("App 主題", selection: $pickerSelectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .onChange(of: pickerSelectedTheme) { _, newValue in
                    storedThemeRawValue = newValue.rawValue
                }
            }
            
            // 數據管理
            Section(header: Text("數據管理")) {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("刪除所有交易記錄")
                            .foregroundColor(.red)
                    }
                }
            }

            // 關於應用
            Section(header: Text("關於")) {
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("關於 \(Bundle.main.appName)")
                    }
                }
            }
            
            // App 版本
            Section(header: Text("App 版本")) {
                HStack {
                    Text("版本號")
                    Spacer()
                    Text("\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("設定")
        .onAppear {
            // 同步主題選擇
            pickerSelectedTheme = selectedTheme
            
            // 如果通知已啟用，確保有權限
            if isNotificationsEnabled {
                checkNotificationPermission()
            }
        }
        .alert("通知權限被拒絕", isPresented: $notificationPermissionDenied) {
            Button("前往設定") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("取消", role: .cancel) {
                isNotificationsEnabled = false
            }
        } message: {
            Text("請在系統設定中開啟通知權限，以接收記帳提醒。")
        }
        .alert("確認刪除", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("刪除", role: .destructive) {
                deleteAllTransactions()
            }
        } message: {
            Text("此操作將永久刪除所有交易記錄，且無法復原。您確定要繼續嗎？")
        }
        .alert("刪除完成", isPresented: $showingDeleteSuccess) {
            Button("確認") { }
        } message: {
            Text("所有交易記錄已成功刪除。")
        }
        .preferredColorScheme(selectedTheme.colorScheme) // 應用主題
    }
    
    // MARK: - 通知相關方法
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    scheduleNotification()
                } else {
                    notificationPermissionDenied = true
                    isNotificationsEnabled = false
                }
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus != .authorized {
                    isNotificationsEnabled = false
                }
            }
        }
    }
    
    private func scheduleNotification() {
        // 移除現有通知
        removeAllNotifications()
        
        guard isNotificationsEnabled else { return }
        
        // 創建通知內容
        let content = UNMutableNotificationContent()
        content.title = "記帳提醒"
        content.body = "別忘了記錄今天的支出哦！💰"
        content.sound = .default
        content.badge = 1 // 這個 API 在 iOS 16+ 中仍然有效
        
        // 設定每日重複的時間觸發器
        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 創建請求
        let request = UNNotificationRequest(
            identifier: "dailyAccountingReminder",
            content: content,
            trigger: trigger
        )
        
        // 添加通知請求
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知設定失敗: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    isNotificationsEnabled = false
                }
            } else {
                print("每日記帳提醒已設定：\(notificationHour):\(String(format: "%02d", notificationMinute))")
            }
        }
    }
    
    private func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // 清除 badge - 使用新的 API 並保持向後相容性
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
    
    // MARK: - 數據管理方法
    private func deleteAllTransactions() {
        // 獲取所有交易
        let allTransactions = dataController.transactions
        
        // 刪除所有交易
        for transaction in allTransactions {
            dataController.deleteTransaction(transaction)
        }
        
        // 顯示成功消息
        showingDeleteSuccess = true
        
        print("已刪除 \(allTransactions.count) 筆交易記錄")
    }
}

// MARK: - 關於頁面
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "app.gift.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("\(Bundle.main.appName)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("版本 \(Bundle.main.appVersion) (Build \(Bundle.main.appBuild))")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Text("功能特色")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .center, spacing: 12) {
                        FeatureRow(icon: "chart.bar.fill", title: "統計圖表", description: "多種圖表檢視方式")
                        FeatureRow(icon: "calendar.circle.fill", title: "日曆統計", description: "按日期檢視支出")
                        FeatureRow(icon: "bell.fill", title: "智能提醒", description: "每日記帳提醒")
                        FeatureRow(icon: "folder.fill", title: "專案管理", description: "追蹤特定項目支出")
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 底部版權資訊
                VStack(spacing: 8) {
                    Text("© \(Calendar.current.component(.year, from: Date())) \(Bundle.main.companyName)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("感謝您使用我們的記帳應用")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 40) // 增加底部間距，確保內容不會太貼底
            }
            .padding()
        }
        .navigationTitle("關於")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 功能特色行（置中版本）
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            // 圖標
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title2)
                .frame(width: 32, height: 32)
            
            // 標題和描述
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Bundle 擴展
extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        object(forInfoDictionaryKey: "CFBundleName") as? String ?? "AniMoney"
    }

    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    var companyName: String {
        return "papaChong"
    }
}
