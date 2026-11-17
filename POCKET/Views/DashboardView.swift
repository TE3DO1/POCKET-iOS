import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \MoneyTransaction.date, order: .reverse) private var transactions: [MoneyTransaction]
    @AppStorage("currency") private var currency = "EUR"
    @State private var showingAdd = false

    private var balance: Int { transactions.reduce(0) { $0 + $1.signedCents } }
    private var monthExpenses: Int {
        transactions.filter { $0.kind == .expense && Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amountInCents }
    }
    private var monthIncome: Int {
        transactions.filter { $0.kind == .income && Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amountInCents }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Общ баланс", systemImage: "wallet.pass.fill")
                            .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                        Text(MoneyFormat.amount(balance, currency: currency))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.6).lineLimit(1)
                        Text("Изчислен от въведените транзакции")
                            .font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(LinearGradient(colors: [.indigo, .blue], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 24))

                    HStack(spacing: 12) {
                        statCard("Приходи", cents: monthIncome, color: .green, symbol: "arrow.down.left")
                        statCard("Разходи", cents: monthExpenses, color: .orange, symbol: "arrow.up.right")
                    }
                    Text("Последни транзакции").font(.title3.bold())
                    if transactions.isEmpty {
                        ContentUnavailableView("Все още няма транзакции", systemImage: "tray", description: Text("Добави първия си приход или разход."))
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(transactions.prefix(5)) { item in
                                TransactionRow(transaction: item, currency: currency)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("POCKET")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title3) }
                        .accessibilityLabel("Добави транзакция")
                }
            }
            .sheet(isPresented: $showingAdd) { AddTransactionView() }
        }
    }

    private func statCard(_ title: String, cents: Int, color: Color, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).font(.caption).foregroundStyle(.secondary)
            Text(MoneyFormat.amount(cents, currency: currency))
                .font(.headline).minimumScaleFactor(0.7).lineLimit(1)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
