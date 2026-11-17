import SwiftUI
import SwiftData
import Charts

private struct CategoryTotal: Identifiable {
    let category: TransactionCategory
    let cents: Int
    var id: String { category.rawValue }
}

private struct DailyTotal: Identifiable {
    let day: Date
    let cents: Int
    var id: Date { day }
}

struct AnalyticsView: View {
    @Query private var transactions: [MoneyTransaction]
    @AppStorage("currency") private var currency = "EUR"
    @State private var selectedMonth = Date()

    private var monthExpenses: [MoneyTransaction] {
        transactions.filter { $0.kind == .expense && Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month) }
    }
    private var categories: [CategoryTotal] {
        Dictionary(grouping: monthExpenses, by: \.category)
            .map { CategoryTotal(category: $0.key, cents: $0.value.reduce(0) { $0 + $1.amountInCents }) }
            .sorted { $0.cents > $1.cents }
    }
    private var days: [DailyTotal] {
        Dictionary(grouping: monthExpenses, by: { Calendar.current.startOfDay(for: $0.date) })
            .map { DailyTotal(day: $0.key, cents: $0.value.reduce(0) { $0 + $1.amountInCents }) }
            .sorted { $0.day < $1.day }
    }
    private var total: Int { monthExpenses.reduce(0) { $0 + $1.amountInCents } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        Text(selectedMonth.formatted(.dateTime.month(.wide).year())).font(.headline)
                        Spacer()
                        Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
                    }
                    .buttonStyle(.bordered)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Разходи за месеца").foregroundStyle(.secondary)
                        Text(MoneyFormat.amount(total, currency: currency))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

                    if monthExpenses.isEmpty {
                        ContentUnavailableView("Няма разходи за този месец", systemImage: "chart.bar")
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Разходи по дни").font(.headline)
                            Chart(days) { item in
                                BarMark(x: .value("Ден", item.day, unit: .day), y: .value("Сума", Double(item.cents) / 100.0))
                                    .foregroundStyle(.indigo.gradient)
                                    .cornerRadius(4)
                            }
                            .frame(height: 210)
                            .animation(.easeInOut(duration: 0.45), value: selectedMonth)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Text("По категории").font(.headline)
                            Chart(categories) { item in
                                SectorMark(angle: .value("Сума", item.cents), innerRadius: .ratio(0.62), angularInset: 2)
                                    .foregroundStyle(by: .value("Категория", item.category.rawValue))
                                    .cornerRadius(4)
                            }
                            .frame(height: 230)
                            .animation(.easeInOut(duration: 0.45), value: selectedMonth)
                            ForEach(categories) { item in
                                HStack {
                                    Label(item.category.rawValue, systemImage: item.category.symbol)
                                    Spacer()
                                    Text(MoneyFormat.amount(item.cents, currency: currency)).fontWeight(.medium)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Анализи")
        }
    }

    private func moveMonth(_ delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: selectedMonth) {
            withAnimation(.easeInOut(duration: 0.35)) { selectedMonth = next }
        }
    }
}
