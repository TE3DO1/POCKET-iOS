import Foundation
import SwiftData
import FirebaseFirestore

/// Syncs transactions for one Firebase UID. Existing local records without
/// cloudID remain local until a separate, explicit migration is implemented.
@MainActor
enum CloudTransactionSync {
    static func start(uid: String, context: ModelContext) -> ListenerRegistration {
        let collection = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("transactions")

        return collection.addSnapshotListener { snapshot, error in
            if let error {
                print("POCKET Firestore listener error: \(error.localizedDescription)")
                return
            }
            guard let snapshot else { return }

            // The listener usually calls back on the main queue on Apple SDKs.
            // Explicitly hop to the main actor before touching SwiftData.
            Task { @MainActor in
                do {
                    let current = try context.fetch(FetchDescriptor<MoneyTransaction>())
                    var ids = Set(current.compactMap(\.cloudID))
                    let remoteIDs = Set(snapshot.documents.map(\.documentID))

                    for doc in snapshot.documents where !ids.contains(doc.documentID) {
                        let data = doc.data()
                        guard let title = data["title"] as? String,
                              let centsNumber = data["cents"] as? NSNumber,
                              let kindRaw = data["kind"] as? String,
                              let kind = TransactionKind(rawValue: kindRaw),
                              let dateNumber = data["date"] as? NSNumber else { continue }

                        let rawCents = centsNumber.int64Value
                        guard rawCents > 0, rawCents <= Int.max else { continue }
                        let rawCategory = (data["category"] as? String) ?? "Други"
                        let category = TransactionCategory(rawValue:
                            rawCategory == "Друго" ? "Други" : rawCategory) ?? .other
                        let date = Date(timeIntervalSince1970:
                            TimeInterval(dateNumber.int64Value) / 1000.0)
                        context.insert(MoneyTransaction(
                            title: title,
                            amountInCents: Int(rawCents),
                            kind: kind,
                            category: category,
                            date: date,
                            cloudID: doc.documentID
                        ))
                        ids.insert(doc.documentID)
                    }
                    try context.save()

                    // Avoid treating an incomplete offline cache as the server's
                    // full dataset, and avoid migrating older local entries.
                    if !snapshot.metadata.isFromCache {
                        for entry in current {
                            guard let id = entry.cloudID, !remoteIDs.contains(id) else { continue }
                            upload(entry, uid: uid)
                        }
                    }
                } catch {
                    print("POCKET local sync error: \(error.localizedDescription)")
                }
            }
        }
    }

    static func upload(_ entry: MoneyTransaction, uid: String) {
        guard let id = entry.cloudID else { return }
        let milliseconds = Int64(entry.date.timeIntervalSince1970 * 1000)
        Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("transactions")
            .document(id)
            .setData([
                "title": entry.title,
                "cents": entry.amountInCents,
                "kind": entry.kindRaw,
                "category": entry.categoryRaw,
                "date": milliseconds
            ]) { error in
                if let error {
                    print("POCKET cloud upload error: \(error.localizedDescription)")
                }
            }
    }
}
