import SwiftUI

// MARK: - 日期篩選器
struct DateFilterView: View {
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    @Environment(\.dismiss) private var dismiss
    
    @State private var isFilterEnabled = false
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle("啟用日期篩選", isOn: $isFilterEnabled)
                        .tint(.blue)
                } header: {
                    Text("篩選設定")
                }
                
                if isFilterEnabled {
                    Section {
                        DatePicker(
                            "開始日期",
                            selection: $tempStartDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        
                        DatePicker(
                            "結束日期",
                            selection: $tempEndDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        
                        // 顯示日期範圍摘要
                        HStack {
                            Text("篩選範圍")
                                .foregroundColor(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(DateFormatter.displayFormat.string(from: tempStartDate))
                                    .font(.caption)
                                Text("至")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(DateFormatter.displayFormat.string(from: tempEndDate))
                                    .font(.caption)
                            }
                        }
                        
                        // 快速選擇選項
                        VStack(alignment: .leading, spacing: 8) {
                            Text("快速選擇")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                QuickFilterButton(title: "今日") {
                                    let today = Date()
                                    tempStartDate = Calendar.current.startOfDay(for: today)
                                    tempEndDate = Calendar.current.endOfDay(for: today) ?? today
                                }
                                
                                QuickFilterButton(title: "本週") {
                                    let today = Date()
                                    tempStartDate = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
                                    tempEndDate = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.end ?? today
                                }
                                
                                QuickFilterButton(title: "本月") {
                                    let today = Date()
                                    tempStartDate = Calendar.current.dateInterval(of: .month, for: today)?.start ?? today
                                    tempEndDate = Calendar.current.dateInterval(of: .month, for: today)?.end ?? today
                                }
                                
                                QuickFilterButton(title: "上月") {
                                    let today = Date()
                                    let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today) ?? today
                                    tempStartDate = Calendar.current.dateInterval(of: .month, for: lastMonth)?.start ?? today
                                    tempEndDate = Calendar.current.dateInterval(of: .month, for: lastMonth)?.end ?? today
                                }
                                
                                QuickFilterButton(title: "近7天") {
                                    let today = Date()
                                    tempStartDate = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
                                    tempEndDate = Calendar.current.endOfDay(for: today) ?? today
                                }
                                
                                QuickFilterButton(title: "近30天") {
                                    let today = Date()
                                    tempStartDate = Calendar.current.date(byAdding: .day, value: -29, to: today) ?? today
                                    tempEndDate = Calendar.current.endOfDay(for: today) ?? today
                                }
                            }
                        }
                        
                    } header: {
                        Text("日期範圍")
                    } footer: {
                        if tempStartDate > tempEndDate {
                            Text("⚠️ 開始日期不能晚於結束日期")
                                .foregroundColor(.red)
                        } else {
                            let dayCount = Calendar.current.dateComponents([.day], from: tempStartDate, to: tempEndDate).day ?? 0
                            Text("已選擇 \(dayCount + 1) 天的交易記錄")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 重置選項
                Section {
                    Button("清除所有篩選", role: .destructive) {
                        isFilterEnabled = false
                        tempStartDate = Date()
                        tempEndDate = Date()
                    }
                }
            }
            .navigationTitle("日期篩選")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("套用") {
                        applyFilter()
                    }
                    .disabled(isFilterEnabled && tempStartDate > tempEndDate)
                }
            }
        }
        .onAppear {
            initializeFilterSettings()
        }
    }
    
    private func initializeFilterSettings() {
        if let start = startDate, let end = endDate {
            isFilterEnabled = true
            tempStartDate = start
            tempEndDate = end
        } else {
            isFilterEnabled = false
            tempStartDate = Date()
            tempEndDate = Date()
        }
    }
    
    private func applyFilter() {
        if isFilterEnabled {
            startDate = Calendar.current.startOfDay(for: tempStartDate)
            endDate = Calendar.current.endOfDay(for: tempEndDate)
        } else {
            startDate = nil
            endDate = nil
        }
        dismiss()
    }
}

// MARK: - 快速篩選按鈕
struct QuickFilterButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DateFilterView(
        startDate: .constant(nil),
        endDate: .constant(nil)
    )
}
