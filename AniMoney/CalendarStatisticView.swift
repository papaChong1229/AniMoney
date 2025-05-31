// HomePageView.swift (或者你實際的檔案名稱 CalendarStatisticView.swift)

import SwiftUI
import SwiftData

struct CalendarStatisticView: View {
    @EnvironmentObject var dataController: DataController
    
    @State private var selectedDateFromCalendar: Date = Date()
    
    // 用於 DateFilterView 的日期範圍選擇
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?
    @State private var showingDateFilterSheet = false
    
    // 決定當前顯示的是單日還是範圍
    private var isDateRangeSelected: Bool {
        filterStartDate != nil && filterEndDate != nil
    }

    // 計算屬性：獲取要顯示的交易 (可能是單日或日期範圍)
    private var transactionsForDisplay: [Transaction] {
        let calendar = Calendar.current
        if let startDate = filterStartDate, let endDate = filterEndDate {
            // 日期範圍模式
            // 確保 endDate 包含當天結束時間
            let adjustedEndDate = calendar.endOfDay(for: endDate)
            return dataController.transactions.filter { transaction in
                transaction.date >= calendar.startOfDay(for: startDate) && transaction.date <= adjustedEndDate!
            }
        } else {
            // 單日模式 (來自月曆)
            return dataController.transactions.filter { transaction in
                calendar.isDate(transaction.date, inSameDayAs: selectedDateFromCalendar)
            }
        }
    }
    
    // 計算屬性：將要顯示的交易按 Category 分組並計算總額
    private var spendingByCategoryForDisplay: [(category: Category, totalAmount: Int)] {
        let grouped = Dictionary(grouping: transactionsForDisplay) { $0.category }
        
        return grouped.map { (category, transactionsInCat) in
            let total = transactionsInCat.reduce(0) { $0 + $1.amount }
            return (category: category, totalAmount: total)
        }
        .filter { $0.totalAmount > 0 }
        .sorted { $0.category.name < $1.category.name }
    }
    
    // 列表標題
    private var listHeaderTitle: String {
        if let startDate = filterStartDate, let endDate = filterEndDate {
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) { // 如果範圍是同一天
                // 先格式化日期，再插入字符串
                let formattedDate = DateFormatter.longDate.string(from: startDate)
                return "\(formattedDate) 消費總覽"
            } else {
                // 先格式化日期，再插入字符串
                let formattedStartDate = DateFormatter.shortDate.string(from: startDate)
                let formattedEndDate = DateFormatter.shortDate.string(from: endDate)
                return "\(formattedStartDate) - \(formattedEndDate) 消費總覽"
            }
        } else {
            // 先格式化日期，再插入字符串
            let formattedDate = DateFormatter.longDate.string(from: selectedDateFromCalendar)
            return "\(formattedDate) 消費總覽"
        }
    }

    // 當前選中的日期或範圍的描述，用於空狀態
    private var currentSelectionDescription: String {
        if let startDate = filterStartDate, let endDate = filterEndDate {
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                // 先格式化日期，再插入字符串
                let formattedDate = DateFormatter.longDate.string(from: startDate)
                return "\(formattedDate)"
            } else {
                // 先格式化日期，再插入字符串
                let formattedStartDate = DateFormatter.shortDate.string(from: startDate)
                let formattedEndDate = DateFormatter.shortDate.string(from: endDate)
                return "從 \(formattedStartDate) 到 \(formattedEndDate)"
            }
        } else {
            // 先格式化日期，再插入字符串
            let formattedDate = DateFormatter.longDate.string(from: selectedDateFromCalendar)
            return "\(formattedDate)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 月曆選擇部分 和 日期範圍篩選按鈕
            HStack {
                Text("") // 可以替換成更合適的標題
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button {
                    showingDateFilterSheet = true
                } label: {
                    Image(systemName: isDateRangeSelected ? "calendar.circle.fill" : "calendar.circle")
                        .font(.title2)
                        .foregroundColor(isDateRangeSelected ? .blue : .secondary)
                }
                .padding(.trailing)
            }
            .padding(.top)
            .padding(.bottom, 8)

            DatePicker(
                "通過月曆選擇單日", // 這個標籤不會顯示，因為 .labelsHidden()
                selection: $selectedDateFromCalendar,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden() // 隱藏 DatePicker 的標籤
            .padding(.horizontal)
            .padding(.bottom)
            .onChange(of: selectedDateFromCalendar) { oldValue, newValue in
                print("Calendar date selected: \(newValue). Clearing date range filter.")
                filterStartDate = nil
                filterEndDate = nil
            }

            Divider()

            // MARK: - 消費統計顯示部分
            if transactionsForDisplay.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass") // 或其他合適的圖標
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    Text("此選擇無消費記錄")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(currentSelectionDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    Section(header: Text(listHeaderTitle)) {
                        ForEach(spendingByCategoryForDisplay, id: \.category.id) { spending in
                            NavigationLink(destination: CategorySpecificTransactionsView(
                                category: spending.category,
                                initialStartDate: filterStartDate ?? Calendar.current.startOfDay(for: selectedDateFromCalendar), // 傳遞當前有效的篩選日期
                                initialEndDate: filterEndDate ?? Calendar.current.endOfDay(for: selectedDateFromCalendar)     // 如果範圍為nil，則傳遞月曆選定日期
                            ).environmentObject(dataController)) {
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
                        }
                        
                        // 顯示總計 (基於 transactionsForDisplay)
                        let totalForDisplay = transactionsForDisplay.reduce(0) { $0 + $1.amount }
                        if spendingByCategoryForDisplay.count > 1 || (spendingByCategoryForDisplay.count == 1 && totalForDisplay > 0) {
                            HStack {
                                Text(isDateRangeSelected ? "期間總計" : "當日總計")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("$\(totalForDisplay)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("消費日曆統計")
        .sheet(isPresented: $showingDateFilterSheet) {
            DateFilterView(
                startDate: $filterStartDate,
                endDate: $filterEndDate
            )
            .onDisappear {
                // 當 DateFilterView 關閉後，如果 filterStartDate/endDate 有值，
                // 我們可以認為用戶選擇了日期範圍模式。
                // 如果用戶在 DateFilterView 中清除了篩選，則 filterStartDate/endDate 會是 nil。
                if filterStartDate != nil || filterEndDate != nil {
                    print("Date filter applied/changed. Start: \(String(describing: filterStartDate)), End: \(String(describing: filterEndDate))")
                    // selectedDateFromCalendar 可以不用改變，因為我們現在優先使用 filterStartDate/EndDate
                } else {
                    print("Date filter cleared.")
                }
            }
        }
    }
}
