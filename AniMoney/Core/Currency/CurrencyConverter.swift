//
//  CurrencyConverter.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/6/1.
//

import SwiftUI

// MARK: - 簡單的貨幣轉換器組件
struct CurrencyConverterCard: View {
    @StateObject private var currencyService = CurrencyService.shared
    @State private var inputAmount: String = ""
    @State private var fromCurrency: Currency = .usd // 保持美元作為預設
    @State private var toCurrency: Currency = .twd
    
    private var convertedAmount: Double {
        guard let amount = Double(inputAmount), amount > 0 else { return 0 }
        
        if fromCurrency == .twd {
            // 從台幣轉換到其他貨幣
            if let rate = currencyService.exchangeRates[toCurrency.rawValue], rate > 0 {
                return amount * rate
            }
        } else if toCurrency == .twd {
            // 從其他貨幣轉換到台幣
            return currencyService.convertToTWD(amount: amount, from: fromCurrency)
        } else {
            // 兩種外幣之間的轉換（通過台幣中轉）
            let twdAmount = currencyService.convertToTWD(amount: amount, from: fromCurrency)
            if let rate = currencyService.exchangeRates[toCurrency.rawValue], rate > 0 {
                return twdAmount * rate
            }
        }
        
        return 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 標題
            HStack {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .foregroundColor(.blue)
                Text("貨幣轉換器")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // 來源貨幣
            VStack(alignment: .leading, spacing: 8) {
                Text("從")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("來源貨幣", selection: $fromCurrency) {
                        ForEach(Currency.allCases) { currency in
                            HStack {
                                Text(currency.flag)
                                Text(currency.rawValue)
                            }
                            .tag(currency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100)
                    
                    TextField("金額", text: $inputAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            // 箭頭和交換按鈕
            HStack {
                Spacer()
                Button(action: {
                    let temp = fromCurrency
                    fromCurrency = toCurrency
                    toCurrency = temp
                }) {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            
            // 目標貨幣
            VStack(alignment: .leading, spacing: 8) {
                Text("到")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("目標貨幣", selection: $toCurrency) {
                        ForEach(Currency.allCases) { currency in
                            HStack {
                                Text(currency.flag)
                                Text(currency.rawValue)
                            }
                            .tag(currency)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 100)
                    
                    Text(convertedAmount > 0 ? toCurrency.formatAmount(convertedAmount) : "0")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // 匯率資訊
            if fromCurrency != toCurrency {
                Divider()
                
                HStack {
                    Text("匯率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if currencyService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        let rateText = getRateDisplayText()
                        Text(rateText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .task {
            await currencyService.updateRatesIfNeeded()
        }
    }
    
    private func getRateDisplayText() -> String {
        if fromCurrency == .twd {
            guard let rate = currencyService.exchangeRates[toCurrency.rawValue] else {
                return "載入中..."
            }
            return "1 TWD = \(String(format: "%.4f", rate)) \(toCurrency.rawValue)"
        } else if toCurrency == .twd {
            guard let rate = currencyService.exchangeRates[fromCurrency.rawValue] else {
                return "載入中..."
            }
            return "1 \(fromCurrency.rawValue) = \(String(format: "%.4f", 1/rate)) TWD"
        } else {
            // 兩種外幣之間
            guard let fromRate = currencyService.exchangeRates[fromCurrency.rawValue],
                  let toRate = currencyService.exchangeRates[toCurrency.rawValue] else {
                return "載入中..."
            }
            let crossRate = toRate / fromRate
            return "1 \(fromCurrency.rawValue) = \(String(format: "%.4f", crossRate)) \(toCurrency.rawValue)"
        }
    }
}

// MARK: - 匯率狀態指示器
struct ExchangeRateStatusView: View {
    @StateObject private var currencyService = CurrencyService.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: currencyService.isLoading ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                .foregroundColor(currencyService.isLoading ? .orange : .green)
                .symbolEffect(.rotate, isActive: currencyService.isLoading)
            
            if currencyService.isLoading {
                Text("更新匯率中...")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if let lastUpdated = currencyService.lastUpdated {
                Text("匯率已更新 \(DateFormatter.timeOnly.string(from: lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("載入匯率中...")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - 預覽
struct CurrencyConverterCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CurrencyConverterCard()
            ExchangeRateStatusView()
        }
        .padding()
    }
}
