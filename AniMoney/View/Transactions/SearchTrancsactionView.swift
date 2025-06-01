import SwiftUI

struct SearchTransactionsView: View {
    @EnvironmentObject private var dataController: DataController
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var editingTransaction: Transaction?
    @State private var showingSearchHints = true
    
    // 搜尋結果
    private var searchResults: [Transaction] {
        if searchText.isEmpty {
            return []
        }
        
        return dataController.transactions
            .filter { transaction in
                // 檢查備註是否包含搜尋關鍵字（不區分大小寫）
                if let note = transaction.note {
                    return note.localizedCaseInsensitiveContains(searchText)
                }
                return false
            }
            .sorted { $0.date > $1.date } // 最新的在前面
    }
    
    // 搜尋統計
    private var searchStats: (count: Int, total: Int) {
        let results = searchResults
        return (count: results.count, total: results.reduce(0) { $0 + $1.amount })
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜尋列
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜尋交易備註...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            showingSearchHints = false
                        }
                        .onChange(of: searchText) { _, newValue in
                            if newValue.isEmpty {
                                showingSearchHints = true
                            } else {
                                showingSearchHints = false
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button("清除") {
                            searchText = ""
                            showingSearchHints = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // 內容區域
                if showingSearchHints && searchText.isEmpty {
                    // 搜尋提示和建議
                    SearchHintsView()
                        .background(Color(.systemGroupedBackground))
                } else if searchText.isEmpty {
                    // 空搜尋狀態
                    Spacer()
                    ContentUnavailableView(
                        "輸入關鍵字開始搜尋",
                        systemImage: "magnifyingglass",
                        description: Text("在上方輸入要搜尋的備註內容")
                    )
                    .background(Color(.systemGroupedBackground))
                    Spacer()
                } else if searchResults.isEmpty {
                    // 無搜尋結果
                    Spacer()
                    ContentUnavailableView(
                        "找不到相關交易",
                        systemImage: "magnifyingglass.circle",
                        description: Text("沒有找到備註包含「\(searchText)」的交易記錄")
                    )
                    .background(Color(.systemGroupedBackground))
                    Spacer()
                } else {
                    // 搜尋結果列表
                    List {
                        // 搜尋結果統計
                        Section {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("搜尋結果")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Text("關鍵字：「\(searchText)」")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(searchStats.count) 筆")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    Text("$\(searchStats.total)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // 搜尋結果交易列表
                        Section("交易記錄") {
                            ForEach(searchResults) { transaction in
                                Button {
                                    editingTransaction = transaction
                                } label: {
                                    HStack {
                                        SearchResultRow(transaction: transaction, searchText: searchText)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(Color.clear)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .navigationTitle("搜尋交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $editingTransaction) { transaction in
            EditTransactionView(transaction: transaction)
                .environmentObject(dataController)
        }
    }
}

// MARK: - 搜尋提示頁面
struct SearchHintsView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 搜尋提示
            VStack(alignment: .center, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    Text("搜尋提示")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    SearchTipRow(icon: "note.text", title: "搜尋備註內容", description: "輸入關鍵字來搜尋交易的備註")
                    SearchTipRow(icon: "textformat.abc", title: "不區分大小寫", description: "搜尋時自動忽略大小寫差異")
                    SearchTipRow(icon: "list.bullet.clipboard", title: "即時搜尋", description: "輸入時即時顯示搜尋結果")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            
            // 搜尋範例
            VStack(alignment: .center, spacing: 16) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)
                        .font(.title2)
                    Text("搜尋範例")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    SearchExampleRow(keyword: "午餐", description: "找到所有備註包含「午餐」的交易")
                    SearchExampleRow(keyword: "朋友", description: "搜尋與朋友相關的支出記錄")
                    SearchExampleRow(keyword: "出差", description: "查找出差相關的交易記錄")
                    SearchExampleRow(keyword: "生日", description: "尋找生日禮物或慶祝的花費")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

// MARK: - 搜尋提示行
struct SearchTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 搜尋範例行
struct SearchExampleRow: View {
    let keyword: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("「\(keyword)」")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue)
                .clipShape(Capsule())
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 搜尋結果行
struct SearchResultRow: View {
    let transaction: Transaction
    let searchText: String
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    // 高亮搜尋關鍵字的備註內容
    private func highlightedNote(_ note: String) -> AttributedString {
        var attributedString = AttributedString(note)
        
        // 找到所有匹配的範圍
        let ranges = note.ranges(of: searchText, options: .caseInsensitive)
        
        for range in ranges.reversed() {
            if let attributedRange = Range(range, in: attributedString) {
                attributedString[attributedRange].backgroundColor = .yellow
                attributedString[attributedRange].foregroundColor = .black
            }
        }
        
        return attributedString
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 日期圓形標籤
            VStack {
                Text(dayFormatter.string(from: transaction.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(monthFormatter.string(from: transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 36, height: 36)
            .background(Color.green.opacity(0.1))
            .clipShape(Circle())
            
            // 交易內容
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    // 類別/子類別標籤
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.category.name)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.7))
                            .clipShape(Capsule())
                        
                        Text(transaction.subcategory.name)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(transaction.amount)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(timeFormatter.string(from: transaction.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 高亮顯示的備註內容
                if let note = transaction.note, !note.isEmpty {
                    Text(highlightedNote(note))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .padding(.top, 2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // 專案和照片指示器
                HStack(spacing: 8) {
                    if let project = transaction.project {
                        HStack {
                            Image(systemName: "folder.fill")
                                .font(.caption2)
                            Text(project.name)
                                .font(.caption2)
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                if transaction.hasPhotos {
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.caption2)
                        Text("\(transaction.photoCount) 張附件")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SearchTransactionsView()
        .environmentObject(try! DataController())
}
