//
//  CurrencyService.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/6/1.
//

import Foundation
import SwiftUI

// MARK: - 支援的貨幣枚舉
enum Currency: String, CaseIterable, Identifiable {
    case twd = "TWD"  // 台幣 (基準貨幣)
    case jpy = "JPY"  // 日圓
    case usd = "USD"  // 美元
    case krw = "KRW"  // 韓圓
    case cny = "CNY"  // 人民幣
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .twd: return "台幣 (TWD)"
        case .jpy: return "日圓 (JPY)"
        case .usd: return "美元 (USD)"
        case .krw: return "韓圓 (KRW)"
        case .cny: return "人民幣 (CNY)"
        }
    }
    
    var symbol: String {
        switch self {
        case .twd: return "🇹🇼 NT$"
        case .jpy: return "🇯🇵 JPY¥"
        case .usd: return "🇺🇸 USD$"
        case .krw: return "🇰🇷 KRW₩"
        case .cny: return "🇨🇳 CNY¥"
        }
    }
    
    var flag: String {
        switch self {
        case .twd: return "🇹🇼"
        case .jpy: return "🇯🇵"
        case .usd: return "🇺🇸"
        case .krw: return "🇰🇷"
        case .cny: return "🇨🇳"
        }
    }
}

// MARK: - 匯率響應模型 (fawazahmed0 API)
struct ExchangeRateResponse: Codable {
    let date: String
    let twd: [String: Double]
}

// MARK: - 貨幣轉換服務
@MainActor
class CurrencyService: ObservableObject {
    static let shared = CurrencyService()
    
    @Published var exchangeRates: [String: Double] = [:]
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiURL = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/twd.json"
    private let cacheKey = "ExchangeRatesCache"
    private let lastUpdateKey = "LastExchangeRateUpdate"
    
    private init() {
        loadCachedRates()
    }
    
    // MARK: - 載入快取的匯率
    private func loadCachedRates() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let rates = try? JSONDecoder().decode([String: Double].self, from: data) {
            self.exchangeRates = rates
        }
        
        if let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date {
            self.lastUpdated = lastUpdate
        }
    }
    
    // MARK: - 快取匯率
    private func cacheRates() {
        if let data = try? JSONEncoder().encode(exchangeRates) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
        if let lastUpdated = lastUpdated {
            UserDefaults.standard.set(lastUpdated, forKey: lastUpdateKey)
        }
    }
    
    // MARK: - 獲取最新匯率
    func fetchExchangeRates() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let url = URL(string: apiURL)!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 檢查 HTTP 狀態碼
            if let httpResponse = response as? HTTPURLResponse {
                print("API HTTP 狀態碼: \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
            }
            
            // 除錯：列印部分原始回應
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API 原始回應: \(jsonString.prefix(200))...")
            }
            
            let jsonResponse = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            
            // 轉換格式並過濾我們需要的貨幣
            var filteredRates: [String: Double] = [:]
            for currency in ["USD", "JPY", "KRW", "CNY"] {
                if let rate = jsonResponse.twd[currency.lowercased()] {
                    filteredRates[currency] = rate
                }
            }
            
            if !filteredRates.isEmpty {
                exchangeRates = filteredRates
                lastUpdated = Date()
                cacheRates()
                print("✅ 匯率更新成功: \(filteredRates)")
            } else {
                throw NSError(domain: "CurrencyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法獲取有效的匯率資料"])
            }
            
        } catch {
            print("❌ 匯率獲取失敗: \(error)")
            
            // 如果網路失敗，使用硬編碼的近似匯率
            useHardcodedRates()
            errorMessage = "網路連線問題，使用離線匯率"
        }
        
        isLoading = false
    }
    
    // MARK: - 使用硬編碼匯率作為備用方案
    private func useHardcodedRates() {
        let hardcodedRates = [
            "USD": 0.031,    // 1 TWD ≈ 0.031 USD
            "JPY": 4.6,      // 1 TWD ≈ 4.6 JPY
            "KRW": 42.0,     // 1 TWD ≈ 42 KRW
            "CNY": 0.22      // 1 TWD ≈ 0.22 CNY
        ]
        
        exchangeRates = hardcodedRates
        lastUpdated = Date()
        cacheRates()
        errorMessage = nil  // 清除錯誤訊息，因為我們有可用的匯率
        print("⚠️ 使用硬編碼匯率作為備用方案")
    }
    
    // MARK: - 貨幣轉換：將任意貨幣轉換為台幣
    func convertToTWD(amount: Double, from currency: Currency) -> Double {
        guard amount > 0 else { return 0 }
        
        // 如果已經是台幣，直接返回
        if currency == .twd {
            return amount
        }
        
        // 從台幣基準的匯率中獲取轉換率
        guard let rate = exchangeRates[currency.rawValue], rate > 0 else {
            print("⚠️ 找不到 \(currency.rawValue) 的匯率，使用1:1轉換")
            return amount
        }
        
        // 計算轉換後的台幣金額
        let convertedAmount = amount / rate
        
        print("💱 貨幣轉換: \(amount) \(currency.rawValue) = \(String(format: "%.2f", convertedAmount)) TWD (匯率: \(rate))")
        
        return convertedAmount
    }
    
    // MARK: - 獲取顯示用的匯率資訊
    func getDisplayRate(for currency: Currency) -> String {
        guard currency != .twd else { return "1.0000" }
        guard let rate = exchangeRates[currency.rawValue] else { return "載入中..." }
        return String(format: "%.4f", rate)
    }
    
    // MARK: - 檢查匯率是否需要更新 (超過1小時自動更新)
    func shouldUpdateRates() -> Bool {
        guard let lastUpdate = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdate) > 3600 // 1小時
    }
    
    // MARK: - 自動更新匯率
    func updateRatesIfNeeded() async {
        if shouldUpdateRates() {
            await fetchExchangeRates()
        }
    }
}

// MARK: - 貨幣格式化器
extension Currency {
    func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        // 日圓和韓圓通常不顯示小數，其他貨幣顯示到小數點後兩位
        formatter.maximumFractionDigits = (self == .jpy || self == .krw) ? 0 : 2
        
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "\(symbol)\(formattedNumber)"
    }
}
