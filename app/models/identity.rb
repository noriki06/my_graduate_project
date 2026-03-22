# Identity モデル
# SNSログイン（Google / GitHub / LINE）のアカウント情報を保存するテーブル。
# 1ユーザーが複数のSNSでログインできるよう、User と1対多の関係になっている。
# User.from_omniauth では Identity.find_by(provider, uid) で既存ユーザーを検索する。
class Identity < ApplicationRecord
  # Identity はユーザーに紐づく（ユーザーが削除されれば連鎖削除される）
  belongs_to :user

  # provider（"google_oauth2" / "github" / "line"）と uid（SNS上のユーザーID）は必須
  # DBには (provider, uid) のユニークインデックスも設定されている
  validates :provider, :uid, presence: true
end
