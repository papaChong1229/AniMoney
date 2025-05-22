import SwiftUI
import SwiftData

struct ContentView: View {
    // 直接用 @Query 拿現有的 Category & Project
    @Query(sort: \Category.order, order: .forward) private var categories: [Category]
    @Query(sort: \Project.order, order: .forward)   private var projects:   [Project]

    // SwiftData 的 ModelContext
    @Environment(\.modelContext) private var modelContext
    
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

            CategoryManagerView()
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

            StatisticsView()
                .tag(3)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Statistics")
                }

            SettingView()
                .tag(4)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Setting")
                }
        }
        .onAppear {
            seedDefaultDataIfNeeded()
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
        }
    }
    
    /// 如果沒有任何 Category/Project，就一次插入預設資料
    private func seedDefaultDataIfNeeded() {
        guard categories.isEmpty, projects.isEmpty else {
            return
        }
        // 建立預設的大類與小類
        let food = Category(
            name: "食品酒水",
            order: 0,
            subcategories: [
                Subcategory(name: "早餐", order: 0),
                Subcategory(name: "午餐", order: 1),
                Subcategory(name: "晚餐", order: 2),
                Subcategory(name: "點心", order: 3),
            ]
        )
        let transport = Category(
            name: "交通出行",
            order: 1,
            subcategories: [
                Subcategory(name: "公車", order: 0),
                Subcategory(name: "捷運", order: 1),
                Subcategory(name: "計程車", order: 2),
            ]
        )
        // 預設專案
        let projA = Project(name: "專案 A", order: 0)
        let projB = Project(name: "專案 B", order: 1)

        // 把它們插入 ModelContext → SwiftData 會自動存檔
        modelContext.insert(food)
        modelContext.insert(transport)
        modelContext.insert(projA)
        modelContext.insert(projB)
    }
}

#Preview {
    ContentView()
}
