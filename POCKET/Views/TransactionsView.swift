import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MoneyTransaction.date, order: .reverse) private var transactions: [MoneyTransaction]
    @AppStorage("currency") private var currency = "EUR"
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction, currency: currency)
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if transactions.isEmpty {
                    ContentUnavailableView("Няма транзакции", systemImage: "list.bullet", description: Text("Натисни +, за да добавиш първата."))
                }
            }
            .navigationTitle("Транзакции")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Добави транзакция")
                }
            }
            .sheet(isPresented: $showingAdd) { AddTransactionView() }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(transactions[index]) }
    }
}
