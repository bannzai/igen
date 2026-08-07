import FirebaseAuth
import FirebaseFirestore
import Foundation

/// users/{uid}/letters の読み取り。クライアントは自分のデータの read のみ
/// (書き込みは Functions 経由。.claude/rules/firestore-rules.md)
enum LettersStore {
  /// 1 ページの取得件数。1 画面に収まる枚数の数倍にして、初期表示コストと追加取得の頻度のバランスを取る
  static let pageSize = 20

  /// 自分の返書を新しい順に 1 ページぶん取得する。
  /// 起動時の匿名サインインが完了していなくても、空の履歴を正常結果として確定させないよう認証を確保してから読む。
  /// cursor に前ページの返り値を渡すと続きを取得する。返り値の cursor が nil なら最後のページ
  static func fetchLetters(
    cursor: DocumentSnapshot?
  ) async throws -> (letters: [Letter], cursor: DocumentSnapshot?) {
    let uid = try await FirebaseSetup.ensureAnonymousUser()
    var query: Query = Firestore.firestore()
      .collection("users")
      .document(uid)
      .collection("letters")
      .order(by: "createdAt", descending: true)
      .limit(to: pageSize)
    if let cursor {
      query = query.start(afterDocument: cursor)
    }
    let snapshot = try await query.getDocuments()
    // ページサイズ未満なら最後のページ (次のカーソルを返さない)
    return (
      letters: try snapshot.documents.map(decodeLetter(document:)),
      cursor: snapshot.documents.count < pageSize ? nil : snapshot.documents.last
    )
  }

  /// 特定の偉人からもらった返書を新しい順に取得する (星図のプロフィール表示用)。
  /// 全返書の取得を避け、その人物のぶんだけ読む
  static func fetchLetters(personId: String) async throws -> [Letter] {
    let uid = try await FirebaseSetup.ensureAnonymousUser()
    let snapshot = try await Firestore.firestore()
      .collection("users")
      .document(uid)
      .collection("letters")
      .whereField("personId", isEqualTo: personId)
      .order(by: "createdAt", descending: true)
      .getDocuments()
    return try snapshot.documents.map(decodeLetter(document:))
  }

  private static func decodeLetter(document: QueryDocumentSnapshot) throws -> Letter {
    // ドキュメント id はフィールドとして保存していないため、デコード前に差し込む
    try Firestore.Decoder()
      .decode(
        Letter.self,
        from: document.data().merging(["id": document.documentID]) { _, new in new }
      )
  }
}
