import FirebaseAuth
import FirebaseFirestore
import Foundation

/// users/{uid}/encounters の読み取り。書き込みは Functions が返書生成時に行う
/// (.claude/rules/firestore-rules.md)
enum EncountersStore {
  /// 出会った偉人の一覧を取得する。未サインインなら空
  static func fetchEncounters() async throws -> [Encounter] {
    guard let user = Auth.auth().currentUser else {
      return []
    }
    let snapshot = try await Firestore.firestore()
      .collection("users")
      .document(user.uid)
      .collection("encounters")
      .getDocuments()
    return try snapshot.documents.map { document in
      try Firestore.Decoder().decode(Encounter.self, from: document.data())
    }
  }
}
