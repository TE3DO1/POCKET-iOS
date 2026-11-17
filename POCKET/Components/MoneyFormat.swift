import Foundation

enum MoneyFormat {
    static func amount(_ cents: Int, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "bg_BG")
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "\(Double(cents) / 100.0) \(currency)"
    }
}
