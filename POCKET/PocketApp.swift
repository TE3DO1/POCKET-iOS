import SwiftUI
import SwiftData
import FirebaseCore

@main
struct PocketApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AuthGateView()
        }
        .modelContainer(for: MoneyTransaction.self)
    }
}
