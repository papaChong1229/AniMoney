//
//  ProjectTransactionRow.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/31.
//

import SwiftUI

// MARK: - 專案交易列表項目
struct ProjectTransactionRow: View {
    let transaction: Transaction
    
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
            .background(Color.purple.opacity(0.1))
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
                            .background(Color.purple.opacity(0.7))
                            .clipShape(Capsule())
                        
                        Text(transaction.subcategory.name)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple)
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
                
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .padding(.top, 2)
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
