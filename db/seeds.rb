# ===== デモユーザー =====
demo = User.find_or_initialize_by(email: User::DEMO_EMAIL)
demo.name       = "デモユーザー"
demo.birthday   = nil
demo.target_age = 84
demo.password   = "demo1234" if demo.new_record?
demo.save!

# wants を毎回リセットして最新データを保証
demo.wants.destroy_all

wants_data = [
  # ── 達成済み ──
  {
    title: "富士山に登る",
    memo: "日本最高峰から日の出を見る夢を叶えた！",
    target_date: Date.new(2022, 8, 1),
    achieved_at: DateTime.new(2022, 8, 12, 5, 30, 0),
    achievement_note: "山頂から見た日の出は一生忘れられない景色だった。足はガクガクだったけど最高に達成感があった！",
    published: true
  },
  {
    title: "沖縄の海でシュノーケリング",
    memo: "透明度抜群の海でカラフルな魚を見たい",
    target_date: Date.new(2023, 7, 1),
    achieved_at: DateTime.new(2023, 7, 20, 10, 0, 0),
    achievement_note: "ウミガメと一緒に泳げた！あの感動は言葉にできない。",
    published: true
  },
  {
    title: "ひとり旅でヨーロッパへ",
    memo: "パリ・ローマ・バルセロナを2週間かけて旅する",
    target_date: Date.new(2021, 9, 1),
    achieved_at: DateTime.new(2021, 9, 10, 9, 0, 0),
    achievement_note: "言葉も文化も違う場所で、自分だけの時間を過ごした。人生観が変わった旅だった。",
    published: true
  },
  # ── やりたいこと ──
  {
    title: "世界一周旅行",
    memo: "1年かけて30カ国を旅したい。南米・アフリカ・中東にも行く。",
    target_date: Date.new(2030, 1, 1),
    published: true
  },
  {
    title: "フルマラソンを完走する",
    memo: "東京マラソンに出場して42.195kmを完走したい。今は週3回練習中。",
    target_date: Date.new(2026, 3, 1),
    published: true
  },
  {
    title: "自分のビジネスを始める",
    memo: "好きなことを仕事にして、自由に働く。カフェかゲストハウスかまだ迷ってる。",
    target_date: Date.new(2028, 1, 1),
    published: false
  },
  {
    title: "オーロラを見る",
    memo: "フィンランドのロヴァニエミで本物のオーロラを肉眼で見たい。",
    target_date: Date.new(2027, 1, 1),
    published: true
  },
  {
    title: "本を出版する",
    memo: "自分の旅と人生経験をまとめたエッセイ本を書く。",
    target_date: Date.new(2029, 1, 1),
    published: false
  },
  {
    title: "スカイダイビングに挑戦",
    memo: "空から飛び降りる恐怖と解放感を体験したい。グアムが候補。",
    target_date: Date.new(2026, 9, 1),
    published: true
  },
  {
    title: "家族でハワイ旅行",
    memo: "両親と兄弟全員でハワイに行く。家族みんなが元気なうちに。",
    target_date: Date.new(2027, 8, 1),
    published: true
  }
]

wants_data.each do |data|
  demo.wants.create!(
    title:            data[:title],
    memo:             data[:memo],
    target_date:      data[:target_date],
    published:        data[:published],
    achieved_at:      data.fetch(:achieved_at, nil),
    achievement_note: data.fetch(:achievement_note, nil)
  )
end

puts "✅ デモユーザー作成完了: #{demo.email}"
puts "   wants: #{demo.wants.count}件（達成: #{demo.wants.where.not(achieved_at: nil).count}件）"
