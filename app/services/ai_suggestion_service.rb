class AiSuggestionService
  MOCK = "【5分行動】\nメモ帳を開き、この目標をなぜ叶えたいのか1文だけ書く。\n\n【なぜ効果的か】\n理由を言語化することで脳が行動へのスイッチを入れる。"
  MODEL = ENV.fetch("ANTHROPIC_MODEL", "claude-3-5-haiku-latest")

  def self.call(want, user)
    return MOCK unless ENV["ANTHROPIC_API_KEY"].present?

    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages(
      model: MODEL,
      max_tokens: 300,
      messages: [ { role: "user", content: build_prompt(want, user) } ]
    )
    response.content.first.text
  rescue => e
    Rails.logger.error("AiSuggestionService error: #{e.message}")
    MOCK
  end

  def self.build_prompt(want, user)
    target_info = want.target_date ? "目標日：#{want.target_date.strftime('%Y年%m月%d日')}" : "目標日：未設定"
    memo_info   = want.memo.present? ? "メモ：#{want.memo}" : ""

    <<~PROMPT
      あなたは「やりたいことリスト」を実現させるコーチです。
      以下のやりたいことに対して、今日すぐできる「5分行動」を1つ提案してください。

      やりたいこと：#{want.title}
      #{target_info}
      #{memo_info}

      フォーマット：
      【5分行動】
      （具体的なアクション）

      【なぜ効果的か】
      （1〜2文で説明）

      ※ 日本語で回答してください。
    PROMPT
  end
  private_class_method :build_prompt
end
