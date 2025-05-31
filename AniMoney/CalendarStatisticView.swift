//
//  HomePageView.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import SwiftUI
import SwiftData

struct CalendarStatisticView: View {
    @EnvironmentObject var dataController: DataController
    
    @State private var selectedDate: Date = Date() // 默認選中今天
    
    // 計算屬性：獲取選定日期的交易
    private var transactionsForSelectedDate: [Transaction] {
        let calendar = Calendar.current
        // 篩選出 selectedDate 當天零點到午夜之間的交易
        return dataController.transactions.filter { transaction in
            calendar.isDate(transaction.date, inSameDayAs: selectedDate)
        }
    }
    
    // 計算屬性：將選定日期的交易按 Category 分組並計算總額
    private var spendingByCategoryForSelectedDate: [(category: Category, totalAmount: Int)] {
        let grouped = Dictionary(grouping: transactionsForSelectedDate) { $0.category }
        
        return grouped.map { (category, transactionsInCat) in
            let total = transactionsInCat.reduce(0) { $0 + $1.amount }
            return (category: category, totalAmount: total)
        }
        .filter { $0.totalAmount > 0 } // 只顯示有消費的類別
        .sorted { $0.category.name < $1.category.name } // 按類別名稱排序
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 月曆選擇部分
            DatePicker(
                "選擇日期",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical) // 顯示為月曆樣式
            .padding(.horizontal)
            .padding(.bottom) // 給月曆下方一些間距

            Divider()

            // MARK: - 消費統計顯示部分
            if transactionsForSelectedDate.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    Text("選定日期無消費記錄")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("\(selectedDate, formatter: DateFormatter.longDate)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    Section(header: Text("\(selectedDate, formatter: DateFormatter.longDate) 消費總覽")) {
                        ForEach(spendingByCategoryForSelectedDate, id: \.category.id) { spending in
                            HStack {
                                Text(spending.category.name)
                                    .font(.headline)
                                Spacer()
                                Text("$\(spending.totalAmount)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // 顯示當日總消費 (可選)
                        if spendingByCategoryForSelectedDate.count > 1 || (spendingByCategoryForSelectedDate.count == 1 && spendingByCategoryForSelectedDate.first!.totalAmount > 0) {
                            //Divider()
                            HStack {
                                Text("當日總計")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("$\(transactionsForSelectedDate.reduce(0) { $0 + $1.amount })")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue) // 或者適合你主題的顏色
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle()) // 或 PlainListStyle()
            }
        }
        .navigationTitle("消費日曆統計") // 如果此視圖在 NavigationStack 中
        .background(Color(.systemGroupedBackground)) // 與 CategoryManagerView 風格一致
    }
}
