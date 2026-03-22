# DailyActionSuggestion モデル
# AI（OpenAI API）が生成した「今日の5分行動」の提案を保存するテーブル。
# (user_id, suggested_on) にユニーク制約があり、1日に1ユーザーにつき1件のみ作成される。
# 通知時刻にすでに提案が存在する場合は再生成せず、保存済みの内容をLINEに送る。
class DailyActionSuggestion < ApplicationRecord
  # 誰に対する提案かを示す（ユーザーが削除されれば連鎖削除）
  belongs_to :user
  # どのWantに対する提案かを示す（Wantが削除されれば連鎖削除）
  belongs_to :want

  # 提案テキストは必須（空で保存されないようにする）
  validates :suggested_action, presence: true
end
