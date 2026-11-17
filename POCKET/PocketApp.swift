import SwiftUI
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
    }
}
