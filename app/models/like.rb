# Like モデル
# ユーザーが公開 Want に押した「いいね」を表す。
# 1ユーザーが同じWantに複数回いいねできないようにユニーク制約を設けている。
class Like < ApplicationRecord
  # いいねはWantに紐づく（Wantが削除されれば連鎖削除される）
  belongs_to :want
  # いいねはユーザーに紐づく（ユーザーが削除されれば連鎖削除される）
  belongs_to :user

  # 同じユーザーが同じWantに2回以上いいねできないようにするDB + アプリレベルの制約
  # DBには (user_id, want_id) のユニークインデックスも設定されている
  validates :user_id, uniqueness: { scope: :want_id }
end
