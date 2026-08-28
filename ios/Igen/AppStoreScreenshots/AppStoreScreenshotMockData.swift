#if DEBUG
  import Foundation

  /// スクショ用の固定データ。格言・原文・出典・人物は名言 DB (backend/functions/src/data/quotes.json, persons.json) と
  /// 同じ実データを使い、出典のない文言を混入させない (documents/PROJECT.md リスク 1)。
  /// 返書の地の文 (相談・ひとこと・意味と文脈・結び) だけ撮影用に書き下ろす
  enum AppStoreScreenshotMockData {
    static let seneca = LetterPerson(
      id: "seneca",
      name: LocalizedText(ja: "セネカ", en: "Seneca"),
      born: -4,
      died: 65,
      title: LocalizedText(ja: "ストア派の哲学者・政治家", en: "Stoic philosopher and statesman"),
      bio: LocalizedText(ja: "古代ローマの哲学者。", en: "Roman Stoic philosopher.")
    )

    static let confucius = LetterPerson(
      id: "confucius",
      name: LocalizedText(ja: "孔子", en: "Confucius"),
      born: -551,
      died: -479,
      title: LocalizedText(ja: "儒家の祖・思想家", en: "Founder of Confucianism"),
      bio: LocalizedText(
        ja: "春秋時代の中国の思想家。その言行は弟子たちによって『論語』にまとめられた。",
        en: "Chinese thinker of the Spring and Autumn period. His sayings were compiled by his disciples into the Analects."
      )
    )

    static let basho = LetterPerson(
      id: "basho",
      name: LocalizedText(ja: "松尾芭蕉", en: "Matsuo Basho"),
      born: 1644,
      died: 1694,
      title: LocalizedText(ja: "俳人", en: "Haiku poet"),
      bio: LocalizedText(
        ja: "江戸前期の俳人。紀行文『おくのほそ道』で知られる。",
        en: "Haiku poet of the early Edo period, known for the travel narrative 'Oku no Hosomichi'."
      )
    )

    static func senecaLetter(language: String) -> Letter {
      Letter(
        id: "screenshot-seneca",
        concern: language == "ja"
          ? "新しい仕事に挑戦するのが怖い。失敗したらと思うと、一歩が踏み出せない"
          : "I'm scared to take on a new job. The thought of failing keeps me from taking the first step",
        language: language,
        quoteId: "seneca-non-quia-difficilia",
        quote: LetterQuote(
          kind: "quote",
          text: LocalizedText(
            ja: "難しいから挑めないのではない。挑まないから難しくなるのだ。",
            en: "It is not because things are difficult that we do not dare; it is because we do not dare that they are difficult."
          ),
          original: "Non quia difficilia sunt non audemus, sed quia non audemus difficilia sunt.",
          originalLanguage: "la",
          source: LetterQuoteSource(
            work: LocalizedText(ja: "倫理書簡集 (ルキリウスへの手紙)", en: "Moral Letters to Lucilius"),
            detail: LocalizedText(ja: "第104書簡 26節", en: "Letter 104, section 26"),
            origTitle: "Epistulae morales ad Lucilium",
            year: LocalizedText(ja: "65年頃", en: "c. 65 AD")
          )
        ),
        personId: seneca.id,
        person: seneca,
        oneliner: language == "ja"
          ? "その一歩をためらう夜もあるでしょう。"
          : "There are nights when that single step feels heavy.",
        meaning: language == "ja"
          ? "この言葉は、困難の多くが踏み出さないことから生まれると説いています。挑む前の不安は、挑んだあとの難しさよりも大きく見えるものです。"
          : "Seneca teaches that most difficulties are born from not stepping forward. The fear before the attempt looms larger than the difficulty after it.",
        closing: language == "ja"
          ? "あなたの挑戦を、星々とともに見守っています。"
          : "The stars and I are watching over your challenge.",
        consultedAt: date("2026-08-27T22:10:00+09:00")
      )
    }

    static func confuciusLetter(language: String) -> Letter {
      Letter(
        id: "screenshot-confucius",
        concern: language == "ja"
          ? "仕事で同じミスを繰り返してしまい、自分が嫌になる"
          : "I keep making the same mistakes at work and I'm starting to hate myself for it",
        language: language,
        quoteId: "confucius-kachite-aratamezaru",
        quote: LetterQuote(
          kind: "quote",
          text: LocalizedText(
            ja: "過ちを犯して改めない、それこそを過ちという。",
            en: "To make a mistake and not correct it: this is what is truly called a mistake."
          ),
          original: "過而不改、是謂過矣。",
          originalLanguage: "zh",
          source: LetterQuoteSource(
            work: LocalizedText(ja: "論語", en: "The Analects"),
            detail: LocalizedText(ja: "衛霊公第十五", en: "Book 15 (Wei Ling Gong)"),
            origTitle: "論語",
            year: LocalizedText(ja: "紀元前5世紀頃", en: "c. 5th century BC")
          )
        ),
        personId: confucius.id,
        person: confucius,
        oneliner: language == "ja"
          ? "同じつまずきに、二度目の痛みを覚えている夜ですね。"
          : "It is the second sting of the same stumble that keeps you up tonight.",
        meaning: language == "ja"
          ? "孔子は、過ちそのものではなく、過ちに気づいて改めないことを本当の過ちと呼びました。繰り返しに気づいたあなたは、もう改めはじめています。"
          : "Confucius called the real mistake not the error itself, but failing to correct it once noticed. By noticing the pattern, you have already begun to change it.",
        closing: language == "ja"
          ? "次に同じ場面が来たとき、今夜の気づきがあなたを支えます。"
          : "When the same moment comes again, tonight's awareness will hold you up.",
        consultedAt: date("2026-08-24T23:30:00+09:00")
      )
    }

    static func bashoLetter(language: String) -> Letter {
      Letter(
        id: "screenshot-basho",
        concern: language == "ja"
          ? "30歳になって、このまま時間だけが過ぎていく気がして焦る"
          : "I just turned 30 and feel anxious that time is simply slipping past me",
        language: language,
        quoteId: "basho-tsukihi-wa-hakutai",
        quote: LetterQuote(
          kind: "quote",
          text: LocalizedText(
            ja: "月日は永遠の旅人であり、来ては去る年もまた旅人である。",
            en: "The days and months are travelers of a hundred generations, and the years that come and go are travelers too."
          ),
          original: "月日は百代の過客にして、行きかふ年も又旅人也",
          originalLanguage: "ja",
          source: LetterQuoteSource(
            work: LocalizedText(ja: "おくのほそ道", en: "Oku no Hosomichi (The Narrow Road to the Deep North)"),
            detail: LocalizedText(ja: "冒頭", en: "Opening passage"),
            origTitle: "おくのほそ道",
            year: LocalizedText(ja: "1702年刊", en: "published 1702")
          )
        ),
        personId: basho.id,
        person: basho,
        oneliner: language == "ja"
          ? "流れていく時間に、置いていかれるような気持ちなのですね。"
          : "It feels as if time is walking on without you.",
        meaning: language == "ja"
          ? "芭蕉は、月日そのものを旅人と見ました。時間は過ぎ去るものではなく、あなたと並んで歩く道連れです。"
          : "Basho saw the months and days themselves as travelers. Time is not something that leaves you behind; it is a companion walking the same road.",
        closing: language == "ja"
          ? "焦りもまた、旅の途中の景色のひとつです。"
          : "Even this restlessness is one of the views along the way.",
        consultedAt: date("2026-08-19T21:05:00+09:00")
      )
    }

    /// 振り返り画面に並べる返書 (新しい順)
    static func letters(language: String) -> [Letter] {
      [senecaLetter(language: language), confuciusLetter(language: language), bashoLetter(language: language)]
    }

    /// 星図に灯す出会い済みの偉人
    static let encounters: [Encounter] = [
      Encounter(personId: seneca.id, person: seneca, lastQuoteId: "seneca-non-quia-difficilia"),
      Encounter(personId: confucius.id, person: confucius, lastQuoteId: "confucius-kachite-aratamezaru"),
      Encounter(personId: basho.id, person: basho, lastQuoteId: "basho-tsukihi-wa-hakutai"),
    ]

    /// ホーム画面の入力カードに入れておく相談文
    static func homeDraft(language: String) -> String {
      language == "ja"
        ? "最近、眠る前に考えごとが止まらない。明日の会議のことばかり浮かんで、なかなか寝つけない。"
        : "Lately I can't stop thinking before I fall asleep. Tomorrow's meeting keeps running through my head."
    }

    private static func date(_ iso8601: String) -> Date {
      ISO8601DateFormatter().date(from: iso8601)!
    }
  }
#endif
