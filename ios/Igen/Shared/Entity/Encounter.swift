import Foundation

/// 偉人図鑑 (星図) の出会い状態。users/{uid}/encounters ドキュメントのデコード先
struct Encounter: Codable, Hashable, Identifiable {
  var personId: String
  var person: LetterPerson
  var lastQuoteId: String?
  var createdAt: Date?
  var updatedAt: Date?

  var id: String {
    personId
  }
}
