//
//  CurrencyInfoView.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/6/1.
//

import SwiftUI

struct CurrencyInfoView: View {
    @StateObject private var currencyService = CurrencyService.shared
    @State private var showingRefreshAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - 更新狀態區域
                Section(header: Text("匯率狀態")) {
                    HStack {
                        Image(systemName: currencyService.isLoading ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                            .foregroundColor(currencyService.isLoading ? .orange : .green)
                            .symbolEffect(.rotate, isActive: currencyService.isLoading)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currencyService.isLoading ? "更新中..." : "匯率已更新")
                                .font(.headline)
                            
                            if let lastUpdated = currencyService.lastUpdated {
                                Text("上次更新：\(DateFormatter.dateTimeShort.string(from: lastUpdated))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("尚未載入匯率資料")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        Button("重新整理") {
                            Task {
                                await currencyService.fetchExchangeRates()
                            }
                        }
                        .disabled(currencyService.isLoading)
                        .buttonStyle(.bordered)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                    
                    // 錯誤訊息
                    if let errorMessage = currencyService.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                // MARK: - 匯率列表
                Section(header: Text("目前匯率 (以台幣為基準)")) {
                    ForEach(Currency.allCases) { currency in
                        CurrencyRateRow(currency: currency, currencyService: currencyService)
                    }
                }
                
                // MARK: - 說明區域
                Section(header: Text("使用說明")) {
                    VStack(alignment: .leading, spacing: 12) {
                        ExplanationRow(
                            icon: "globe.asia.australia.fill",
                            title: "多幣種支援",
                            description: "支援台幣、美元、日圓、韓圓、人民幣五種貨幣輸入"
                        )
                        
                        ExplanationRow(
                            icon: "arrow.left.arrow.right.circle.fill",
                            title: "自動轉換",
                            description: "所有外幣金額會自動轉換為台幣儲存"
                        )
                        
                        ExplanationRow(
                            icon: "clock.arrow.2.circlepath",
                            title: "即時匯率",
                            description: "匯率資料每小時自動更新，確保準確性"
                        )
                        
                        ExplanationRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "匯率來源",
                            description: "數據來源於可靠的金融機構和央行"
                        )
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("貨幣匯率")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await currencyService.fetchExchangeRates()
            }
        }
        .task {
            await currencyService.updateRatesIfNeeded()
        }
    }
}

// MARK: - 匯率行組件
struct CurrencyRateRow: View {
    let currency: Currency
    let currencyService: CurrencyService
    
    var body: some View {
        HStack(spacing: 12) {
            // 國旗和貨幣符號
            HStack(spacing: 8) {
                Text(currency.flag)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(currency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 匯率顯示
            VStack(alignment: .trailing, spacing: 2) {
                if currency == .twd {
                    Text("1.0000")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("基準貨幣")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Group {
                        if currencyService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if let rate = currencyService.exchangeRates[currency.rawValue] {
                            Text(String(format: "%.4f", rate))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        } else {
                            Text("載入中...")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("1 TWD")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 說明行組件
struct ExplanationRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - 日期格式化器擴展
extension DateFormatter {
    static let dateTimeShort: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - 預覽
struct CurrencyInfoView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyInfoView()
    }
}
