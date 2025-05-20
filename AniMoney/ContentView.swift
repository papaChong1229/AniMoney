import SwiftUI

struct ContentView: View {
    /// 用來綁定目前選中的分頁
    @State private var selectedTab: Int = 0
    /// 控制 AddTransactionView 是否顯示
    @State private var isPresentingAddTransaction = false
    
    var body: some View {
        ZStack {
            // MARK: 1. 底層 TabView
            TabView(selection: $selectedTab) {
                HomePageView()
                    .tag(0)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }

                CategoryView()
                    .tag(1)
                    .tabItem {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Category")
                    }
                    
                // For tab view format
                Color.clear
                    .tabItem {
                        Image(systemName: "circle.fill")
                            .renderingMode(.template)
                            .opacity(0)
                        Text("")
                    }
                    .disabled(true) // 不可選中

                StatisticsView()
                    .tag(2)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Statistics")
                    }

                SettingView()
                    .tag(3)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Setting")
                    }
            }

            // MARK: 2. 上層浮動加號按鈕
            VStack {
                Spacer()  // 推到最底部
                HStack {
                    Spacer()
                    Button(action: {
                        isPresentingAddTransaction = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    // 把按鈕往上移一點，讓它浮在 TabBar 之上
                    .offset(y: -30)
                    Spacer()
                }
            }
            .ignoresSafeArea(edges: .bottom) // 讓按鈕可以延伸到安全區外
        }
        .sheet(isPresented: $isPresentingAddTransaction) {
            AddTransactionView()
        }
    }
}

#Preview {
    ContentView()
}
