import FirebaseAuth
import FirebaseFirestore
import Foundation

/// users/{uid}/letters の読み取り。クライアントは自分のデータの read のみ
/// (書き込みは Functions 経由。.claude/rules/firestore-rules.md)
enum LettersStore {
  /// 1 ページの取得件数。1 画面に収まる枚数の数倍にして、初期表示コストと追加取得の頻度のバランスを取る
  static let pageSize = 20

  /// 自分の返書を新しい順に 1 ページぶん取得する。未サインインなら空。
  /// cursor に前ページの返り値を渡すと続きを取得する。返り値の cursor が nil なら最後のページ
  static func fetchLetters(
    cursor: DocumentSnapshot?
  ) async throws -> (letters: [Letter], cursor: DocumentSnapshot?) {
    guard let user = Auth.auth().currentUser else {
      return (letters: [], cursor: nil)
    }
    var query: Query = Firestore.firestore()
      .collection("users")
      .document(user.uid)
      .collection("letters")
      .order(by: "createdAt", descending: true)
      .limit(to: pageSize)
    if let cursor {
      query = query.start(afterDocument: cursor)
    }
    let snapshot = try await query.getDocuments()
    let letters = try snapshot.documents.map { document in
      // ドキュメント id はフィールドとして保存していないため、デコード前に差し込む
      try Firestore.Decoder()
        .decode(
          Letter.self,
          from: document.data().merging(["id": document.documentID]) { _, new in new }
        )
    }
    // ページサイズ未満なら最後のページ (次のカーソルを返さない)
    return (
      letters: letters,
      cursor: snapshot.documents.count < pageSize ? nil : snapshot.documents.last
    )
  }
}
