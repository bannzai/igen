import Foundation
import Testing

@testable import Igen

/// POST /letters のレスポンス契約 (backend/functions/src/store.ts が返す JSON 形状と
/// Letter の Codable の整合) を、実際の名言 DB の値に基づく fixture で検証する
struct IgenAPITests {
  // 人物つきの格言 (diagram なし)。出典の detail・origTitle・year を含む最大構成
  private static let personLetterJSON = """
    {
      "type": "letter",
      "id": "letter-0",
      "letter": {
        "id": "letter-0",
        "consultedAt": 1754739447881,
        "concern": "テスト相談本文",
        "language": "ja",
        "timeZone": "Asia/Tokyo",
        "requestId": "11111111-2222-3333-4444-555555555555",
        "quoteId": "seneca-non-quia-difficilia",
        "quote": {
          "kind": "quote",
          "text": {
            "ja": "難しいから挑めないのではない。挑まないから難しくなるのだ。",
            "en": "It is not because things are difficult that we do not dare; it is because we do not dare that they are difficult."
          },
          "original": "Non quia difficilia sunt non audemus, sed quia non audemus difficilia sunt.",
          "originalLanguage": "la",
          "source": {
            "work": {"ja": "倫理書簡集 (ルキリウスへの手紙)", "en": "Moral Letters to Lucilius"},
            "detail": {"ja": "第104書簡 26節", "en": "Letter 104, section 26"},
            "origTitle": "Epistulae morales ad Lucilium",
            "year": {"ja": "65年頃", "en": "c. 65 AD"}
          }
        },
        "personId": "seneca",
        "person": {
          "id": "seneca",
          "name": {"ja": "セネカ", "en": "Seneca"},
          "born": -4,
          "died": 65,
          "title": {"ja": "ストア派の哲学者・政治家", "en": "Stoic philosopher and statesman"},
          "bio": {"ja": "古代ローマの哲学者。", "en": "Roman Stoic philosopher."},
          "publicDomain": {"confirmed": true}
        },
        "oneliner": "ひとこと",
        "meaning": "意味と文脈",
        "closing": "結び",
        "diagram": null
      }
    }
    """

  // 人物のいないことわざ (person が null で diagram つき)
  private static let proverbLetterJSON = """
    {
      "type": "letter",
      "id": "letter-7",
      "letter": {
        "id": "letter-7",
        "consultedAt": 1754739447881,
        "concern": "テスト相談本文",
        "language": "ja",
        "timeZone": "Asia/Tokyo",
        "requestId": "11111111-2222-3333-4444-555555555555",
        "quoteId": "saio-ga-uma",
        "quote": {
          "kind": "proverb",
          "text": {"ja": "人間万事塞翁が馬。", "en": "Life is like the old man's horse at the frontier."},
          "original": "塞翁失馬",
          "originalLanguage": "zh",
          "source": {
            "work": {"ja": "淮南子", "en": "Huainanzi"},
            "detail": {"ja": "人間訓の故事に由来する故事成語", "en": "Idiom derived from a story"},
            "origTitle": "淮南子",
            "year": {"ja": "紀元前2世紀頃", "en": "c. 2nd century BC"}
          }
        },
        "personId": null,
        "person": null,
        "oneliner": "ひとこと",
        "meaning": "意味と文脈",
        "closing": "結び",
        "diagram": {"metaphor": "たとえ", "meaning": "意味", "usage": "使いどころ"}
      }
    }
    """

  @Test
  func parsesPersonLetterResponse() throws {
    let result = try IgenAPI.parseLetterResponse(
      (statusCode: 200, data: Data(Self.personLetterJSON.utf8))
    )
    guard case .letter(let letter) = result else {
      Issue.record("expected .letter but got \(result)")
      return
    }
    #expect(letter.id == "letter-0")
    #expect(letter.quoteId == "seneca-non-quia-difficilia")
    #expect(letter.person?.name.ja == "セネカ")
    #expect(letter.person?.born == -4)
    #expect(letter.diagram == nil)
    // consultedAt はミリ秒 epoch で届く (backend/functions/src/store.ts)
    #expect(letter.consultedAt == Date(timeIntervalSince1970: 1_754_739_447.881))
  }

  @Test
  func parsesProverbLetterResponse() throws {
    let result = try IgenAPI.parseLetterResponse(
      (statusCode: 200, data: Data(Self.proverbLetterJSON.utf8))
    )
    guard case .letter(let letter) = result else {
      Issue.record("expected .letter but got \(result)")
      return
    }
    #expect(letter.personId == nil)
    #expect(letter.person == nil)
    #expect(letter.diagram?.metaphor == "たとえ")
    #expect(letter.quote.source.year?.ja == "紀元前2世紀頃")
  }

  @Test
  func parsesSafetyResponse() throws {
    let result = try IgenAPI.parseLetterResponse(
      (statusCode: 200, data: Data(#"{"type": "safety"}"#.utf8))
    )
    guard case .safety = result else {
      Issue.record("expected .safety but got \(result)")
      return
    }
  }

  @Test
  func throwsFreeQuotaExceededOn429WithoutErrorCode() {
    do {
      _ = try IgenAPI.parseLetterResponse((statusCode: 429, data: Data()))
      Issue.record("expected freeQuotaExceeded to be thrown")
    } catch IgenAPI.APIError.freeQuotaExceeded {
      // 期待どおり (エラーコードを読めない応答は従来どおりペイウォール誘導に倒す)
    } catch {
      Issue.record("expected freeQuotaExceeded but got \(error)")
    }
  }

  @Test
  func throwsFreeQuotaExceededOn429WithFreeQuotaExceededCode() {
    do {
      _ = try IgenAPI.parseLetterResponse(
        (
          statusCode: 429,
          data: Data(
            #"{"error": {"code": "free_quota_exceeded", "message": "free letters for today are used up"}}"#
              .utf8
          )
        )
      )
      Issue.record("expected freeQuotaExceeded to be thrown")
    } catch IgenAPI.APIError.freeQuotaExceeded {
      // 期待どおり (無料枠切れはペイウォール誘導に使うため、専用エラーであることまで検証する)
    } catch {
      Issue.record("expected freeQuotaExceeded but got \(error)")
    }
  }

  @Test
  func throwsRateLimitedOn429WithRateLimitedCode() {
    do {
      _ = try IgenAPI.parseLetterResponse(
        (
          statusCode: 429,
          data: Data(
            #"{"error": {"code": "rate_limited", "message": "too many letters from this network, try again later"}}"#
              .utf8
          )
        )
      )
      Issue.record("expected rateLimited to be thrown")
    } catch IgenAPI.APIError.rateLimited {
      // 期待どおり (レート制限は購入で解除されないためペイウォールへ誘導しない)
    } catch {
      Issue.record("expected rateLimited but got \(error)")
    }
  }

  @Test
  func throwsInvalidResponseOnUnknownType() {
    #expect(throws: (any Error).self) {
      try IgenAPI.parseLetterResponse(
        (statusCode: 200, data: Data(#"{"type": "unknown"}"#.utf8))
      )
    }
  }
}
