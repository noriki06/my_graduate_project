# Comment モデル
# 公開 Want の詳細ページに投稿されるコメントを表す。
# コメントは誰でも（ログインしていれば）投稿でき、投稿したユーザー本人のみ削除できる。
class Comment < ApplicationRecord
  # コメントはWantに紐づく（Wantが削除されれば連鎖削除される）
  belongs_to :want
  # コメントはユーザーに紐づく（ユーザーが削除されれば連鎖削除される）
  belongs_to :user

  # コメント本文は必須（空文字での投稿を禁止）
  validates :content, presence: true
end
