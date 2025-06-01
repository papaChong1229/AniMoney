//
//  SubcategoryTransactionRow.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/31.
//

import SwiftUI

// MARK: - 交易列表項目
struct SubcategoryTransactionRow: View {
    let transaction: Transaction
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 日期圓形標籤
            VStack {
                Text(dayFormatter.string(from: transaction.date))
                    .font(.headline)
                    .fontWeight(.bold)
                Text(monthFormatter.string(from: transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 44, height: 44)
            .background(Color.blue.opacity(0.1))
            .clipShape(Circle())
            
            // 交易內容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("$\(transaction.amount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(timeFormatter.string(from: transaction.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if transaction.hasPhotos {
                        HStack {
                            Image(systemName: "photo.fill")
                                .font(.caption2)
                            Text("\(transaction.photoCount) 張照片") // 顯示照片數量
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                
                if let project = transaction.project {
                    HStack {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(project.name)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
