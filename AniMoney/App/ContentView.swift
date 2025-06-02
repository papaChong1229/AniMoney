import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var dataController: DataController
    
    @State private var selectedTab = 0
    @State private var isPresentingAdd = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomePageView()
                .tag(0)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            MainFinanceManagementView()
                .tag(1)
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Classification")
                }

            // ← 這裡改成＋號圖示
            Color.clear
                .tag(2)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                    Text("")  // 空字串隱藏文字
                }
                .disabled(true)  // 本身不切換到這個 page

            NavigationStack {
                CalendarStatisticView()
            }
            .tag(3)
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Statistics")
            }
            

            NavigationStack {
                SettingView()
            }
            .tag(4)
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Setting")
            }
        }
        // 監聽分頁變化
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                // 點到＋號
                isPresentingAdd = true
                // 還原到上一個選項
                selectedTab = oldValue
            }
        }
        // 彈出 AddTransactionView
        .sheet(isPresented: $isPresentingAdd) {
            AddTransactionView()
                .environmentObject(dataController)
        }
    }
}

#Preview {
    ContentView()
}
