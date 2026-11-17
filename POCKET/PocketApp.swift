import SwiftUI
import SwiftData

@main
struct PocketApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: MoneyTransaction.self)
    }
}
