//
//  HomePageView.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import SwiftUI
import SwiftData

struct HomePageView: View {
  // 用 @Query 自動 fetch
  @Query(sort: \Transaction.date, order: .forward)
  private var transactions: [Transaction]

  var body: some View {
    List(transactions) { tx in
      Text("\(tx.category.name) / \(tx.subcategory.name): \(tx.amount)")
    }
  }
}


#Preview {
    HomePageView()
}
