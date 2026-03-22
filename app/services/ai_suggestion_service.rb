# AiSuggestionService
# OpenAI API を使って「今日の5分行動」を生成するサービスクラス。
# OPENAI_API_KEY が未設定の場合はモックテキストを返すので、開発環境でもAPIキーなしで動作する。
# CronController（LINE通知時）と AiSuggestionsController（Web画面でのボタン押下時）から呼ばれる。
class AiSuggestionService
  # OPENAI_API_KEY が未設定のときに返すモックテキスト（開発・テスト環境用）
  MOCK  = "【5分行動】\nメモ帳を開き、この目標をなぜ叶えたいのか1文だけ書く。\n\n【なぜ効果的か】\n理由を言語化することで脳が行動へのスイッチを入れる。"
  # 使用するOpenAIモデル（環境変数で切り替え可能、デフォルトは gpt-4.1-mini）
  MODEL = ENV.fetch("OPENAI_MODEL", "gpt-4.1-mini")

  # ===== メインの呼び出しメソッド =====
  # want: 提案対象のWantオブジェクト
  # user: 対象ユーザー（現在は使用していないが将来的なカスタマイズ用に受け取る）
  def self.call(want, user)
    # APIキーが設定されていない場合はモックを返す（開発環境での動作確認用）
    return MOCK unless ENV["OPENAI_API_KEY"].present?

    # OpenAI クライアントを初期化して Responses API を呼び出す
    client = OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])
    res = client.responses.create(
      model: MODEL,
      input: build_prompt(want, user)  # プロンプトを組み立てて送信
    )
    res.output_text  # 生成されたテキストを返す
  rescue => e
    # API呼び出しに失敗した場合はエラーをログに記録してモックを返す（アプリを止めない）
    Rails.logger.error("AiSuggestionService error: #{e.message}")
    MOCK
  end

  # ===== プロンプトの組み立て =====
  # Wantのタイトル・目標日・メモを埋め込み、AIに具体的な5分行動を生成させる
  def self.build_prompt(want, user)
    # 目標日が設定されていれば「目標日: ○年○月○日」と表示、なければ「未設定」
    target_info = want.target_date ? "目標日：#{want.target_date.strftime('%Y年%m月%d日')}" : "目標日：未設定"
    # メモが記入されていれば追加情報としてプロンプトに含める
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
  # build_prompt はクラス内部からのみ呼ばれるため private にする
  private_class_method :build_prompt
end
