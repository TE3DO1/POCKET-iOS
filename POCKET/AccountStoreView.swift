import SwiftUI
import SwiftData
import Foundation

/// Each Firebase UID has its own local SwiftData database.
struct AccountStoreView<Content: View>: View {
    let uid: String
    @ViewBuilder let content: () -> Content
    @State private var container: ModelContainer?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let container {
                content()
                    .modelContainer(container)
            } else if let errorMessage {
                ContentUnavailableView(
                    "Не мога да отворя данните",
                    systemImage: "exclamationmark.shield",
                    description: Text(errorMessage)
                )
            } else {
                ProgressView("Отваряне на профила...")
            }
        }
        .task(id: uid) {
            container = nil
            errorMessage = nil
            do {
                let schema = Schema([MoneyTransaction.self])
                let directory = URL.applicationSupportDirectory
                    .appending(path: "PocketAccounts", directoryHint: .isDirectory)
                try FileManager.default.createDirectory(
                    at: directory, withIntermediateDirectories: true
                )
                let safeUID = uid.filter { $0.isASCII && $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
                let databaseURL = directory.appending(path: "account-\(safeUID).sqlite")
                let configuration = ModelConfiguration(
                    "POCKET-\(safeUID)",
                    schema: schema,
                    url: databaseURL,
                    cloudKitDatabase: .none
                )
                container = try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                errorMessage = "Не са изтрити записи. Опитай да рестартираш приложението. \(error.localizedDescription)"
            }
        }
    }
}
