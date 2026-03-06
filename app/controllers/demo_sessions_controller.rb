class DemoSessionsController < ApplicationController
  def create
    demo = User.find_by(email: User::DEMO_EMAIL)
    unless demo
      return redirect_to new_user_session_path, alert: "デモユーザーが見つかりません。管理者にお問い合わせください。"
    end

    demo.update!(birthday: nil)
    sign_in(demo)
    redirect_to edit_birthday_path, notice: "デモモードで体験中です。投稿・編集はできません。"
  end
end
