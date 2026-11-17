import SwiftUI

struct TransactionRow: View {
    let transaction: MoneyTransaction
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category.symbol)
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title).font(.headline)
                Text("\(transaction.category.rawValue) · \(transaction.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            Text(MoneyFormat.amount(transaction.signedCents, currency: currency))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.kind == .income ? Color.green : Color.primary)
        }
        .padding(.vertical, 5)
    }
}
