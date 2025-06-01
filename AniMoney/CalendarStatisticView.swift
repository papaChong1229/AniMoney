// CalendarStatisticView.swift - 更新版本，加入圖表功能

import SwiftUI
import SwiftData
import Charts

// 圖表顯示類型枚舉
enum ChartDisplayType: String, CaseIterable {
    case list = "清單"
    case barChart = "長條圖"
    case pieChart = "圓餅圖"
    
    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .barChart: return "chart.bar.fill"
        case .pieChart: return "chart.pie.fill"
        }
    }
}

struct CalendarStatisticView: View {
    @EnvironmentObject var dataController: DataController
    
    @State private var selectedDateFromCalendar: Date = Date()
    
    // 用於 DateFilterView 的日期範圍選擇
    @State private var filterStartDate: Date?
    @State private var filterEndDate: Date?
    @State private var showingDateFilterSheet = false
    
    // 圖表顯示類型狀態
    @State private var selectedChartType: ChartDisplayType = .list
    
    // 決定當前顯示的是單日還是範圍
    private var isDateRangeSelected: Bool {
        filterStartDate != nil && filterEndDate != nil
    }

    // 計算屬性：獲取要顯示的交易 (可能是單日或日期範圍)
    private var transactionsForDisplay: [Transaction] {
        let calendar = Calendar.current
        if let startDate = filterStartDate, let endDate = filterEndDate {
            // 日期範圍模式
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
        .sorted { $0.totalAmount > $1.totalAmount } // 按金額大小排序
    }
    
    // 列表標題
    private var listHeaderTitle: String {
        if let startDate = filterStartDate, let endDate = filterEndDate {
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                let formattedDate = DateFormatter.longDate.string(from: startDate)
                return "\(formattedDate) 消費總覽"
            } else {
                let formattedStartDate = DateFormatter.shortDate.string(from: startDate)
                let formattedEndDate = DateFormatter.shortDate.string(from: endDate)
                return "\(formattedStartDate) - \(formattedEndDate) 消費總覽"
            }
        } else {
            let formattedDate = DateFormatter.longDate.string(from: selectedDateFromCalendar)
            return "\(formattedDate) 消費總覽"
        }
    }

    // 當前選中的日期或範圍的描述，用於空狀態
    private var currentSelectionDescription: String {
        if let startDate = filterStartDate, let endDate = filterEndDate {
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
                let formattedDate = DateFormatter.longDate.string(from: startDate)
                return "\(formattedDate)"
            } else {
                let formattedStartDate = DateFormatter.shortDate.string(from: startDate)
                let formattedEndDate = DateFormatter.shortDate.string(from: endDate)
                return "從 \(formattedStartDate) 到 \(formattedEndDate)"
            }
        } else {
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
                "通過月曆選擇單日",
                selection: $selectedDateFromCalendar,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.bottom)
            .onChange(of: selectedDateFromCalendar) { oldValue, newValue in
                print("Calendar date selected: \(newValue). Clearing date range filter.")
                filterStartDate = nil
                filterEndDate = nil
            }

            Divider()

            // MARK: - 圖表類型切換按鈕
            if !transactionsForDisplay.isEmpty {
                HStack {
                    Text("顯示方式")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.leading)
                    
                    Spacer()
                    
                    HStack(spacing: 0) {
                        ForEach(ChartDisplayType.allCases, id: \.self) { chartType in
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedChartType = chartType
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: chartType.icon)
                                        .font(.caption)
                                    Text(chartType.rawValue)
                                        .font(.caption2)
                                }
                                .foregroundColor(selectedChartType == chartType ? .white : .blue)
                                .frame(width: 60, height: 50)
                                .background(
                                    selectedChartType == chartType ?
                                    Color.blue : Color.blue.opacity(0.1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.trailing)
                }
                .padding(.vertical, 12)
            }

            // MARK: - 消費統計顯示部分
            if transactionsForDisplay.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
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
                // 根據選擇的圖表類型顯示不同的內容
                Group {
                    switch selectedChartType {
                    case .list:
                        CategoryListView(
                            headerTitle: listHeaderTitle,
                            spendingData: spendingByCategoryForDisplay,
                            transactionsForDisplay: transactionsForDisplay,
                            isDateRangeSelected: isDateRangeSelected,
                            dataController: dataController,
                            filterStartDate: filterStartDate,
                            filterEndDate: filterEndDate,
                            selectedDateFromCalendar: selectedDateFromCalendar
                        )
                    case .barChart:
                        CategoryBarChartView(
                            headerTitle: listHeaderTitle,
                            spendingData: spendingByCategoryForDisplay,
                            totalAmount: transactionsForDisplay.reduce(0) { $0 + $1.amount }
                        )
                    case .pieChart:
                        CategoryPieChartView(
                            headerTitle: listHeaderTitle,
                            spendingData: spendingByCategoryForDisplay,
                            totalAmount: transactionsForDisplay.reduce(0) { $0 + $1.amount }
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
                if filterStartDate != nil || filterEndDate != nil {
                    print("Date filter applied/changed. Start: \(String(describing: filterStartDate)), End: \(String(describing: filterEndDate))")
                } else {
                    print("Date filter cleared.")
                }
            }
        }
    }
}

// MARK: - 分離出來的列表檢視
struct CategoryListView: View {
    let headerTitle: String
    let spendingData: [(category: Category, totalAmount: Int)]
    let transactionsForDisplay: [Transaction]
    let isDateRangeSelected: Bool
    let dataController: DataController
    let filterStartDate: Date?
    let filterEndDate: Date?
    let selectedDateFromCalendar: Date
    
    var body: some View {
        List {
            Section(header: Text(headerTitle)) {
                ForEach(spendingData, id: \.category.id) { spending in
                    NavigationLink(destination: CategorySpecificTransactionsView(
                        category: spending.category,
                        initialStartDate: filterStartDate ?? Calendar.current.startOfDay(for: selectedDateFromCalendar),
                        initialEndDate: filterEndDate ?? Calendar.current.endOfDay(for: selectedDateFromCalendar)
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
                
                // 顯示總計
                let totalForDisplay = transactionsForDisplay.reduce(0) { $0 + $1.amount }
                if spendingData.count > 1 || (spendingData.count == 1 && totalForDisplay > 0) {
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

// MARK: - 長條圖檢視
struct CategoryBarChartView: View {
    let headerTitle: String
    let spendingData: [(category: Category, totalAmount: Int)]
    let totalAmount: Int
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 標題區域
                VStack(alignment: .leading, spacing: 8) {
                    Text(headerTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("總支出：$\(totalAmount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(spendingData.count) 個類別")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // 長條圖
                if #available(iOS 16.0, *) {
                    Chart(spendingData, id: \.category.id) { spending in
                        BarMark(
                            x: .value("類別", spending.category.name),
                            y: .value("金額", spending.totalAmount)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let intValue = value.as(Int.self) {
                                    Text("$\(intValue)")
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let stringValue = value.as(String.self) {
                                    Text(stringValue)
                                        .font(.caption2)
                                        .rotationEffect(.degrees(-45))
                                }
                            }
                        }
                    }
                    .frame(height: 250)
                    .padding(.horizontal)
                } else {
                    // iOS 15 相容性 - 使用手動繪製的長條圖
                    ManualBarChartView(spendingData: spendingData)
                        .frame(height: 250)
                        .padding(.horizontal)
                }
                
                // 詳細數據列表
                LazyVStack(spacing: 8) {
                    ForEach(spendingData, id: \.category.id) { spending in
                        HStack {
                            // 色塊指示器
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                            
                            Text(spending.category.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$\(spending.totalAmount)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                let percentage = totalAmount > 0 ? (Double(spending.totalAmount) / Double(totalAmount)) * 100 : 0
                                Text("\(String(format: "%.1f", percentage))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - 圓餅圖檢視
struct CategoryPieChartView: View {
    let headerTitle: String
    let spendingData: [(category: Category, totalAmount: Int)]
    let totalAmount: Int
    
    // 顏色陣列
    private let colors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink, .yellow, .cyan, .indigo, .mint
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 標題區域
                VStack(alignment: .leading, spacing: 8) {
                    Text(headerTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("總支出：$\(totalAmount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(spendingData.count) 個類別")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // 圓餅圖
                if #available(iOS 17.0, *) {
                    Chart(spendingData, id: \.category.id) { spending in
                        SectorMark(
                            angle: .value("金額", spending.totalAmount),
                            innerRadius: .ratio(0.4),
                            angularInset: 2
                        )
                        .foregroundStyle(colors[spendingData.firstIndex(where: { $0.category.id == spending.category.id }) ?? 0 % colors.count])
                        .opacity(0.8)
                    }
                    .frame(height: 300)
                    .padding(.horizontal)
                } else {
                    // iOS 16 及以下版本的相容性實作
                    ManualPieChartView(spendingData: spendingData, colors: colors)
                        .frame(height: 300)
                        .padding(.horizontal)
                }
                
                // 圖例
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(spendingData.enumerated()), id: \.element.category.id) { index, spending in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colors[index % colors.count])
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spending.category.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                HStack {
                                    Text("$\(spending.totalAmount)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                    
                                    let percentage = totalAmount > 0 ? (Double(spending.totalAmount) / Double(totalAmount)) * 100 : 0
                                    Text("(\(String(format: "%.1f", percentage))%)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - 手動繪製的長條圖 (iOS 15 相容性)
struct ManualBarChartView: View {
    let spendingData: [(category: Category, totalAmount: Int)]
    
    private var maxAmount: Int {
        spendingData.map(\.totalAmount).max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(spendingData, id: \.category.id) { spending in
                VStack(spacing: 4) {
                    // 金額標籤
                    Text("$\(spending.totalAmount)")
                        .font(.caption2)
                        .foregroundColor(.primary)
                    
                    // 長條
                    Rectangle()
                        .fill(Color.blue.gradient)
                        .frame(width: 40, height: CGFloat(spending.totalAmount) / CGFloat(maxAmount) * 200)
                        .cornerRadius(4)
                    
                    // 類別名稱
                    Text(spending.category.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(-45))
                        .frame(width: 40, height: 20)
                        .clipped()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 手動繪製的圓餅圖 (iOS 16 相容性)
struct ManualPieChartView: View {
    let spendingData: [(category: Category, totalAmount: Int)]
    let colors: [Color]
    
    private var totalAmount: Int {
        spendingData.reduce(0) { $0 + $1.totalAmount }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.8
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                ForEach(Array(spendingData.enumerated()), id: \.element.category.id) { index, spending in
                    let startAngle = startAngle(for: index)
                    let endAngle = endAngle(for: index)
                    
                    Path { path in
                        path.move(to: center)
                        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                    }
                    .fill(colors[index % colors.count])
                    .opacity(0.8)
                }
            }
        }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let previousTotal = spendingData.prefix(index).reduce(0) { $0 + $1.totalAmount }
        return .degrees(Double(previousTotal) / Double(totalAmount) * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let previousTotal = spendingData.prefix(index + 1).reduce(0) { $0 + $1.totalAmount }
        return .degrees(Double(previousTotal) / Double(totalAmount) * 360 - 90)
    }
}
