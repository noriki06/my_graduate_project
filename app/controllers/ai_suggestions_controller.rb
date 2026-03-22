# AiSuggestionsController
# AI による「今日の5分行動」提案を生成して保存するコントローラ。
# wants/index ページのボタンから POST /ai_suggestion が呼ばれる（Turbo Frame 対応）。
class AiSuggestionsController < ApplicationController
  # ログインしていないユーザーはAI提案を受けられない
  before_action :authenticate_user!

  # ===== AI提案の生成と保存 =====
  def create
    # スコアリング（urgency + recency）で最も優先度の高いWantを選定する
    # notify_enabled: true のWantを優先し、なければ全未達成Wantからランダム選択
    @want = Want.select_for_suggestion(current_user)

    if @want
      # OpenAI API を呼び出して5分行動を生成する
      # API_KEY が未設定の場合はモックテキストを返す（AiSuggestionService 内で制御）
      suggestion_text = AiSuggestionService.call(@want, current_user)

      # 生成した提案をDBに保存する
      # (user_id, suggested_on) のユニーク制約により1日1件のみ保存される
      @daily = current_user.daily_action_suggestions.create!(
        want: @want,
        suggested_action: suggestion_text,
        suggested_on: Date.current
      )
    else
      # Wantが1件もない場合（未達成Wantが存在しない場合）にフラグを立てる
      # ビューでメッセージを切り替えるために使用する
      @no_wants_at_all = current_user.wants.empty?
    end
    # Turbo Frame id="ai-suggestion" のレスポンスとして create.html.erb をレンダリング
  end
end
