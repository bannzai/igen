import FirebaseAuth
import FirebaseFirestore
import Foundation

/// users/{uid}/letters の読み取り。クライアントは自分のデータの read のみ
/// (書き込みは Functions 経由。.claude/rules/firestore-rules.md)
enum LettersStore {
  /// 自分の返書を新しい順に取得する。未サインインなら空
  static func fetchLetters() async throws -> [Letter] {
    guard let user = Auth.auth().currentUser else {
      return []
    }
    let snapshot = try await Firestore.firestore()
      .collection("users")
      .document(user.uid)
      .collection("letters")
      .order(by: "createdAt", descending: true)
      .getDocuments()
    return try snapshot.documents.map { document in
      // ドキュメント id はフィールドとして保存していないため、デコード前に差し込む
      try Firestore.Decoder()
        .decode(
          Letter.self,
          from: document.data().merging(["id": document.documentID]) { _, new in new }
        )
    }
  }
}
