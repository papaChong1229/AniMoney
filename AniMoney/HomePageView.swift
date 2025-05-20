//
//  HomePageView.swift
//  AniMoney
//
//  Created by 陳軒崇 on 2025/5/21.
//

import SwiftUI

struct HomePageView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Home Page")
        }
        .padding()
    }
}

#Preview {
    HomePageView()
}
