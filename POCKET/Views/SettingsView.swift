import SwiftUI

struct SettingsView: View {
    @AppStorage("currency") private var currency = "EUR"

    var body: some View {
        NavigationStack {
            Form {
                Section("Предпочитания") {
                    Picker("Валута", selection: $currency) {
                        Text("Евро (EUR)").tag("EUR")
                        Text("Лев (BGN)").tag("BGN")
                        Text("Долар (USD)").tag("USD")
                    }
                }
                Section("За приложението") {
                    LabeledContent("Приложение", value: "POCKET")
                    LabeledContent("Версия", value: "1.0")
                    Text("Всички транзакции се пазят локално на устройството.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Смяната на валутата променя само символа и формата. Не конвертира записаните суми.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Настройки")
        }
    }
}
