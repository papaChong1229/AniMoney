import SwiftUI

struct HomePageView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingSearchView = false
    
    // 計算最近的交易（最新的10筆）
    private var recentTransactions: [Transaction] {
        dataController.transactions
            .sorted { $0.date > $1.date }
            .prefix(10)
            .map { $0 }
    }
    
    // 計算今日統計
    private var todayStats: (count: Int, total: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let todayTransactions = dataController.transactions.filter { transaction in
            transaction.date >= today && transaction.date < tomorrow
        }
        
        return (count: todayTransactions.count, total: todayTransactions.reduce(0) { $0 + $1.amount })
    }
    
    // 計算本月統計
    private var monthStats: (count: Int, total: Int) {
        let now = Date()
        let monthInterval = Calendar.current.dateInterval(of: .month, for: now)
        
        let monthTransactions = dataController.transactions.filter { transaction in
            if let interval = monthInterval {
                return transaction.date >= interval.start && transaction.date <= interval.end
            }
            return false
        }
        
        return (count: monthTransactions.count, total: monthTransactions.reduce(0) { $0 + $1.amount })
    }
    
    // 計算各類別本月花費
    private var categorySpending: [(category: Category, amount: Int)] {
        let now = Date()
        let monthInterval = Calendar.current.dateInterval(of: .month, for: now)
        
        let monthTransactions = dataController.transactions.filter { transaction in
            if let interval = monthInterval {
                return transaction.date >= interval.start && transaction.date <= interval.end
            }
            return false
        }
        
        let categoryTotals = Dictionary(grouping: monthTransactions) { $0.category }
            .mapValues { transactions in
                transactions.reduce(0) { $0 + $1.amount }
            }
            .compactMap { (category, amount) -> (category: Category, amount: Int)? in
                guard amount > 0 else { return nil }
                return (category: category, amount: amount)
            }
            .sorted { $0.amount > $1.amount }
        
        return Array(categoryTotals.prefix(5)) // 只顯示前5名
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定義導航欄
            HStack {
                Text("記帳")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showingSearchView = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color(.systemGroupedBackground))
            
            // 主要內容
            ScrollView {
                LazyVStack(spacing: 20) {
                    // 歡迎標題區域
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("歡迎回來！")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("今天是 \(DateFormatter.longDate.string(from: Date()))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // 今日快速統計
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("今日")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(todayStats.count) 筆")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("$\(todayStats.total)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // 月度統計卡片
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("本月概覽")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(DateFormatter.monthYear.string(from: Date()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 20) {
                            // 交易筆數
                            VStack(alignment: .leading, spacing: 4) {
                                Text("交易筆數")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(monthStats.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            // 總支出
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("總支出")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(monthStats.total)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // 平均每日支出
                        if monthStats.count > 0 {
                            let today = Date()
                            let calendar = Calendar.current
                            
                            // 獲取本月的第一天
                            let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
                            
                            // 計算從本月第一天到今天的實際天數
                            let daysPassed = calendar.dateComponents([.day], from: startOfMonth, to: today).day ?? 1
                            let actualDays = max(daysPassed + 1, 1) // +1 因為包含今天，最少為1天
                            
                            let averageDaily = monthStats.total / actualDays
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("平均每日")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("已過 \(actualDays) 天")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .opacity(0.7)
                                }
                                Spacer()
                                Text("$\(averageDaily)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // 類別支出排行
                    if !categorySpending.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("本月支出排行")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(Array(categorySpending.enumerated()), id: \.offset) { index, item in
                                HStack {
                                    // 排名
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .frame(width: 20, height: 20)
                                        .background(rankingColor(for: index))
                                        .clipShape(Circle())
                                    
                                    // 類別名稱
                                    Text(item.category.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    // 金額和比例
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("$\(item.amount)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        if monthStats.total > 0 {
                                            let percentage = (Double(item.amount) / Double(monthStats.total)) * 100
                                            Text("\(String(format: "%.1f", percentage))%")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    
                    // 最近交易
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近交易")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("最新 \(recentTransactions.count) 筆")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if recentTransactions.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("還沒有任何交易記錄")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            ForEach(recentTransactions) { transaction in
                                HomeTransactionRow(transaction: transaction)
                                
                                if transaction.id != recentTransactions.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingSearchView) {
            SearchTransactionsView()
                .environmentObject(dataController)
        }
    }
    
    // 排名顏色
    private func rankingColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow // 金牌
        case 1: return .gray   // 銀牌
        case 2: return .brown  // 銅牌
        default: return .blue  // 其他
        }
    }
}

// MARK: - 首頁交易行組件
struct HomeTransactionRow: View {
    let transaction: Transaction
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 類別圓形圖標
            VStack {
                Text(String(transaction.category.name.prefix(1)))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .frame(width: 28, height: 28)
            .background(Color.blue)
            .clipShape(Circle())
            
            // 交易信息
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(transaction.subcategory.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("$\(transaction.amount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text(transaction.category.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let project = transaction.project {
                        Text("• \(project.name)")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    
                    Spacer()
                    
                    Text(timeFormatter.string(from: transaction.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .padding(.top, 1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HomePageView()
        .environmentObject(try! DataController())
}
