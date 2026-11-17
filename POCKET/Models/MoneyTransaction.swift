import Foundation
import SwiftData

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense = "Разход"
    case income = "Приход"
    var id: String { rawValue }
}

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Храна"
    case shopping = "Пазаруване"
    case transport = "Транспорт"
    case bills = "Сметки"
    case entertainment = "Забавления"
    case health = "Здраве"
    case salary = "Заплата"
    case other = "Други"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .food: "fork.knife"
        case .shopping: "bag"
        case .transport: "car"
        case .bills: "bolt"
        case .entertainment: "gamecontroller"
        case .health: "cross.case"
        case .salary: "banknote"
        case .other: "square.grid.2x2"
        }
    }
}

@Model
final class MoneyTransaction {
    var title: String
    var amountInCents: Int
    var kindRaw: String
    var categoryRaw: String
    var date: Date

    init(title: String, amountInCents: Int, kind: TransactionKind, category: TransactionCategory, date: Date = .now) {
        self.title = title
        self.amountInCents = amountInCents
        self.kindRaw = kind.rawValue
        self.categoryRaw = category.rawValue
        self.date = date
    }

    var kind: TransactionKind { TransactionKind(rawValue: kindRaw) ?? .expense }
    var category: TransactionCategory { TransactionCategory(rawValue: categoryRaw) ?? .other }
    var signedCents: Int { kind == .income ? amountInCents : -amountInCents }
}
