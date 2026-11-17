import SwiftUI
import SwiftData

private enum EmeraldStyle {
    static let background = Color(red: 0.035, green: 0.075, blue: 0.065)
    static let surface = Color(red: 0.075, green: 0.14, blue: 0.12)
    static let green = Color(red: 0.34, green: 0.90, blue: 0.65)
    static let muted = Color(red: 0.64, green: 0.73, blue: 0.68)
}

private enum EmeraldAction: String, Identifiable {
    case expense, income, transfer, cards
    var id: String { rawValue }
}

private struct PocketCard: Identifiable, Codable {
    var id = UUID()
    var nickname: String
    var bank: String
    var last4: String
}

struct EmeraldDashboardView: View {
    @Query(sort: \MoneyTransaction.date, order: .reverse)
    private var transactions: [MoneyTransaction]
    @AppStorage("currency") private var currency = "EUR"
    @State private var selectedAction: EmeraldAction?
    @State private var cards: [PocketCard] = []

    private var balance: Int { transactions.reduce(0) { $0 + $1.signedCents } }
    private var income: Int {
        transactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amountInCents }
    }
    private var expenses: Int {
        transactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amountInCents }
    }

    private func money(_ cents: Int) -> String {
        (Double(cents) / 100).formatted(.currency(code: currency))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("МОИТЕ ФИНАНСИ")
                            .font(.caption.weight(.semibold))
                            .tracking(2)
                            .foregroundStyle(EmeraldStyle.muted)
                        Text("Общ баланс")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.85))
                        Text(money(balance))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                        HStack(spacing: 12) {
                            balancePill("Приходи", amount: money(income), symbol: "arrow.down.left")
                            balancePill("Разходи", amount: money(expenses), symbol: "arrow.up.right")
                        }
                        .padding(.top, 12)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.05, green: 0.32, blue: 0.22), EmeraldStyle.surface],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ), in: RoundedRectangle(cornerRadius: 26)
                    )

                    HStack(spacing: 12) {
                        actionButton("Разход", symbol: "arrow.up.right", action: .expense)
                        actionButton("Приход", symbol: "arrow.down.left", action: .income)
                        actionButton("Превод", symbol: "arrow.left.arrow.right", action: .transfer)
                    }

                    HStack {
                        Text("Моите карти").font(.title3.bold())
                        Spacer()
                        Button("Добави") { selectedAction = .cards }
                            .foregroundStyle(EmeraldStyle.green)
                    }
                    if let card = cards.first {
                        cardPreview(card)
                            .onTapGesture { selectedAction = .cards }
                    } else {
                        Button { selectedAction = .cards } label: {
                            Label("Добави карта (само последни 4 цифри)", systemImage: "creditcard")
                                .frame(maxWidth: .infinity, minHeight: 95)
                        }
                        .foregroundStyle(EmeraldStyle.green)
                        .background(EmeraldStyle.surface, in: RoundedRectangle(cornerRadius: 20))
                    }

                    HStack {
                        Text("Последни транзакции").font(.title3.bold())
                        Spacer()
                        NavigationLink("Всички") { ContentView() }
                            .foregroundStyle(EmeraldStyle.green)
                    }
                    if transactions.isEmpty {
                        Text("Все още нямаш транзакции.")
                            .foregroundStyle(EmeraldStyle.muted)
                            .padding()
                    } else {
                        VStack(spacing: 0) {
                            ForEach(transactions.prefix(6)) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: item.category.symbol)
                                        .foregroundStyle(EmeraldStyle.green)
                                        .frame(width: 38, height: 38)
                                        .background(.white.opacity(0.06), in: Circle())
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.title).fontWeight(.medium)
                                        Text(item.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(EmeraldStyle.muted)
                                    }
                                    Spacer()
                                    Text(money(item.signedCents))
                                        .foregroundStyle(item.kind == .income ? EmeraldStyle.green : .white)
                                        .fontWeight(.semibold)
                                }
                                .padding(12)
                                Divider().overlay(.white.opacity(0.08))
                            }
                        }
                        .background(EmeraldStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                    }

                    Text("Балансът е изчислен от записите в POCKET, не от банкова сметка.")
                        .font(.caption)
                        .foregroundStyle(EmeraldStyle.muted)
                }
                .padding(18)
            }
            .background(EmeraldStyle.background)
            .foregroundStyle(.white)
            .navigationTitle("POCKET")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(EmeraldStyle.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: loadCards)
            .sheet(item: $selectedAction) { action in
                switch action {
                case .expense:
                    EmeraldEntryView(kind: .expense)
                case .income:
                    EmeraldEntryView(kind: .income)
                case .transfer:
                    TransferNotesView()
                case .cards:
                    EmeraldCardsView(cards: $cards, saveCards: saveCards)
                }
            }
        }
        .tint(EmeraldStyle.green)
    }

    private func balancePill(_ title: String, amount: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(EmeraldStyle.muted)
            Text(amount).font(.subheadline.bold()).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    private func actionButton(_ title: String, symbol: String, action: EmeraldAction) -> some View {
        Button { selectedAction = action } label: {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.title3.bold())
                    .frame(width: 45, height: 45)
                    .background(EmeraldStyle.green.opacity(0.15), in: Circle())
                Text(title).font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(EmeraldStyle.surface, in: RoundedRectangle(cornerRadius: 19))
        }
        .buttonStyle(.plain)
    }

    private func cardPreview(_ card: PocketCard) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(card.bank).font(.headline)
                Spacer()
                Image(systemName: "creditcard.fill").font(.title2)
            }
            Text("••••  ••••  ••••  \(card.last4)")
                .font(.title3.monospacedDigit().weight(.semibold))
            Text(card.nickname).font(.subheadline)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color(red: 0.04, green: 0.48, blue: 0.31),
                                    Color(red: 0.02, green: 0.19, blue: 0.17)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 23)
        )
    }

    private func loadCards() {
        guard let data = UserDefaults.standard.data(forKey: "pocket_cards_v1"),
              let decoded = try? JSONDecoder().decode([PocketCard].self, from: data) else { return }
        cards = decoded
    }

    private func saveCards() {
        guard let data = try? JSONEncoder().encode(cards) else { return }
        UserDefaults.standard.set(data, forKey: "pocket_cards_v1")
    }
}

private struct EmeraldCardsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var cards: [PocketCard]
    let saveCards: () -> Void
    @State private var bank = ""
    @State private var nickname = ""
    @State private var last4 = ""

    private var canSave: Bool {
        !bank.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        last4.count == 4 && last4.allSatisfy { $0.isNumber }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Запазени карти") {
                    if cards.isEmpty { Text("Няма добавени карти") }
                    ForEach(cards) { card in
                        VStack(alignment: .leading) {
                            Text(card.nickname).font(.headline)
                            Text("\(card.bank) •••• \(card.last4)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        cards.remove(atOffsets: indexSet)
                        saveCards()
                    }
                }
                Section("Добави карта") {
                    TextField("Банка (например DSK)", text: $bank)
                    TextField("Име на картата", text: $nickname)
                    TextField("Само последните 4 цифри", text: $last4)
                        .keyboardType(.numberPad)
                        .onChange(of: last4) { _, newValue in
                            last4 = String(newValue.filter { $0.isNumber }.prefix(4))
                        }
                    Button("Запази картата") {
                        cards.append(PocketCard(nickname: nickname, bank: bank, last4: last4))
                        saveCards()
                        bank = ""; nickname = ""; last4 = ""
                    }
                    .disabled(!canSave)
                }
                Section {
                    Text("Тук не се съхраняват пълен номер, CVV или PIN. Това не е метод за плащане.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Моите карти")
            .toolbar { Button("Готово") { dismiss() } }
        }
    }
}

private struct EmeraldEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let kind: TransactionKind
    @State private var title = ""
    @State private var amount = ""
    @State private var category: TransactionCategory = .other
    @State private var errorText = ""

    private var cents: Int? {
        let cleaned = amount.replacingOccurrences(of: ",", with: ".")
        let parts = cleaned.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2, let whole = Int(parts[0]), whole >= 0 else { return nil }
        let fraction = parts.count == 2 ? String(parts[1]) : ""
        guard fraction.count <= 2, fraction.allSatisfy(\.isNumber),
              let minor = Int(fraction.padding(toLength: 2, withPad: "0", startingAt: 0)),
              whole <= (Int.max - minor) / 100 else { return nil }
        let value = whole * 100 + minor
        return value > 0 ? value : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Описание", text: $title)
                TextField("Сума", text: $amount).keyboardType(.decimalPad)
                Picker("Категория", selection: $category) {
                    ForEach(TransactionCategory.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                if !errorText.isEmpty { Text(errorText).foregroundStyle(.red) }
            }
            .navigationTitle(kind.rawValue)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отказ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Запази") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cents == nil)
                }
            }
        }
    }

    private func save() {
        guard let cents else { return }
        context.insert(MoneyTransaction(title: title, amountInCents: cents,
                                        kind: kind, category: category))
        do { try context.save(); dismiss() }
        catch { errorText = "Записът не бе успешен. Опитай отново." }
    }
}

private struct TransferNotesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var from = ""
    @State private var to = ""
    @State private var amount = ""
    @State private var notes: [String] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Локална бележка за превод") {
                    TextField("От сметка/карта", text: $from)
                    TextField("Към сметка/карта", text: $to)
                    TextField("Сума", text: $amount).keyboardType(.decimalPad)
                    Button("Запази бележката") {
                        let note = "\(Date.now.formatted(date: .numeric, time: .omitted)): \(from) → \(to), \(amount)"
                        notes.insert(note, at: 0)
                        UserDefaults.standard.set(notes, forKey: "pocket_transfer_notes_v1")
                        from = ""; to = ""; amount = ""
                    }
                    .disabled(from.isEmpty || to.isEmpty || amount.isEmpty)
                }
                Section("История на бележките") {
                    ForEach(notes, id: \.self) { note in Text(note) }
                        .onDelete { indexes in
                            notes.remove(atOffsets: indexes)
                            UserDefaults.standard.set(notes, forKey: "pocket_transfer_notes_v1")
                        }
                }
                Section {
                    Text("Това НЕ изпраща пари и НЕ променя баланса. Няма банкова интеграция.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Превод")
            .toolbar { Button("Готово") { dismiss() } }
            .onAppear {
                notes = UserDefaults.standard.stringArray(forKey: "pocket_transfer_notes_v1") ?? []
            }
        }
    }
}
