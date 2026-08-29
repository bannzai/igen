import Testing

/// CI が失敗を検出できることを確かめるための一時的なテスト。検証後に削除する。
@Test func ciFailureProbe() {
  #expect(Bool(false), "CI がテスト失敗を検出できるかの確認用")
}
