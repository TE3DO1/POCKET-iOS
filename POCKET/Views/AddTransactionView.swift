import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("currency") private var currency = "EUR"
    @State private var title = ""
    @State private var amount = ""
    @State private var kind: TransactionKind = .expense
    @State private var category: TransactionCategory = .food
    @State private var date = Date()
    @State private var showError = false

    private var parsedCents: Int? {
        let cleaned = amount.replacingOccurrences(of: ",", with: ".")
        let parts = cleaned.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, let whole = Int(parts[0]), whole >= 0 else { return nil }
        let fraction = parts.count == 2 ? String(parts[1]) : ""
        guard fraction.count <= 2, fraction.allSatisfy(\.isNumber),
              let fractional = Int(fraction.padding(toLength: 2, withPad: "0", startingAt: 0)),
              whole <= (Int.max - fractional) / 100 else { return nil }
        let cents = whole * 100 + fractional
        return cents > 0 ? cents : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Тип", selection: $kind) {
                    ForEach(TransactionKind.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented)
                TextField("Описание", text: $title)
                HStack {
                    TextField("Сума", text: $amount).keyboardType(.decimalPad)
                    Text(currency).foregroundStyle(.secondary)
                }
                Picker("Категория", selection: $category) {
                    ForEach(TransactionCategory.allCases) { Text($0.rawValue).tag($0) }
                }
                DatePicker("Дата", selection: $date, displayedComponents: .date)
            }
            .navigationTitle("Нова транзакция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отказ") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Запази") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedCents == nil)
                }
            }
            .alert("Неуспешно записване", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: { Text("Опитай отново.") }
        }
    }

    private func save() {
        guard let cents = parsedCents else { return }
        context.insert(MoneyTransaction(title: title.trimmingCharacters(in: .whitespacesAndNewlines), amountInCents: cents, kind: kind, category: category, date: date))
        do { try context.save(); dismiss() }
        catch { showError = true }
    }
}
