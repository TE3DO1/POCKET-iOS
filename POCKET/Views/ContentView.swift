import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Начало", systemImage: "house.fill") }
            TransactionsView()
                .tabItem { Label("Транзакции", systemImage: "list.bullet.rectangle") }
            AnalyticsView()
                .tabItem { Label("Анализи", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape.fill") }
        }
        .tint(.indigo)
    }
}
