import FirebaseAuth
import FirebaseFirestore
import Foundation

/// users/{uid}/encounters の読み取り。書き込みは Functions が返書生成時に行う
/// (.claude/rules/firestore-rules.md)
enum EncountersStore {
  /// 出会った偉人の一覧を取得する。
  /// 起動時の匿名サインインが完了していなくても、空の星図を正常結果として確定させないよう認証を確保してから読む
  static func fetchEncounters() async throws -> [Encounter] {
    let uid = try await FirebaseSetup.ensureAnonymousUser()
    let snapshot = try await Firestore.firestore()
      .collection("users")
      .document(uid)
      .collection("encounters")
      .getDocuments()
    return try snapshot.documents.map { document in
      try Firestore.Decoder().decode(Encounter.self, from: document.data())
    }
  }
}
