// SettingView.swift

import SwiftUI

// 可以定義一些設定相關的枚舉或結構
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "系統預設"
    case light = "淺色模式"
    case dark = "深色模式"
    var id: String { self.rawValue }
}

struct SettingView: View {
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled: Bool = true
        
    // 用於持久化的 AppStorage
    @AppStorage("selectedAppThemeRawValue_v2") private var storedThemeRawValue: String = AppTheme.system.rawValue
    
    // 用於 Picker 的 @State 變數，並在 onAppear 和 onChange 中與 AppStorage 同步
    @State private var pickerSelectedTheme: AppTheme = .system
    
    @State private var showingAboutPage = false

    var body: some View {
        Form { // Form 提供了標準的設定頁面佈局
            Section(header: Text("通知設定")) {
                Toggle("啟用推播通知", isOn: $isNotificationsEnabled)
                    .tint(.blue) // 自定義 Toggle 顏色
            }

            Section(header: Text("外觀")) {
                Picker("App 主題", selection: $pickerSelectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
            }
            
            Section(header: Text("帳戶")) {
                Button(action: {
                    // 執行登出操作
                    print("執行登出...")
                }) {
                    Text("登出帳號")
                        .foregroundColor(.red) // 登出按鈕通常用紅色
                }
            }

            Section(header: Text("關於")) {
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                        Text("關於 \(Bundle.main.appName)") // 動態獲取 App 名稱
                    }
                }
            }
            
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
    }
}

// MARK: - 輔助的 "關於" 頁面
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.gift.fill") // 或你的 App 圖標
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("\(Bundle.main.appName)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("版本 \(Bundle.main.appVersion) (Build \(Bundle.main.appBuild))")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("© \(Calendar.current.component(.year, from: Date())) \(Bundle.main.companyName). \n保留所有權利。")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            if let appUrl = URL(string: "https://www.example.com") { // 替換成你的網站
                Link("訪問我們的網站", destination: appUrl)
                    .font(.headline)
            }
            
        }
        .padding()
        .navigationTitle("關於") // 如果是通過 NavigationLink 進入
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bundle 擴展以方便獲取 App 信息
extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    }

    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    var companyName: String {
        // 通常公司名稱不會直接在 Info.plist 中，你可能需要硬編碼或從其他地方獲取
        return "papaChong"
    }
}
