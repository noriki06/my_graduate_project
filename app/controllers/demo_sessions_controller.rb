# DemoSessionsController
# デモモードでアプリを体験するための一時的なログイン機能を担当する。
# デモユーザー（demo@lifegauge.com）としてログインし、アプリの雰囲気を確認できる。
# デモユーザーは投稿・編集・削除などの書き込み操作はできない（check_not_demo で制御）。
class DemoSessionsController < ApplicationController
  # ===== デモログイン =====
  def create
    # DEMO_EMAIL でデモ専用ユーザーを検索する
    demo = User.find_by(email: User::DEMO_EMAIL)
    unless demo
      # デモユーザーが見つからない場合（初期データが投入されていない環境など）
      return redirect_to new_user_session_path, alert: "デモユーザーが見つかりません。管理者にお問い合わせください。"
    end

    # 毎回オンボーディングフロー（生年月日入力）から体験させるために birthday を nil にリセットする
    demo.update!(birthday: nil)

    # Devise の sign_in を使ってデモユーザーとしてセッションを開始する
    sign_in(demo)

    # 生年月日入力画面から体験を開始する（ライフゲージの設定フローを体験させるため）
    redirect_to edit_birthday_path, notice: "デモモードで体験中です。投稿・編集はできません。"
  end
end
