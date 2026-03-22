# ProfilesController
# ユーザー自身のプロフィール（名前・メール・生年月日・目標寿命）を編集するコントローラ。
# デモユーザーは更新操作を行えない。
class ProfilesController < ApplicationController
  # ログインしていないユーザーはアクセス不可
  before_action :authenticate_user!
  # デモユーザーはプロフィールを更新できない
  before_action :check_not_demo, only: [ :update ]

  # ===== プロフィール編集フォームの表示 =====
  # current_user をビューで参照するだけなので処理なし
  def edit; end

  # ===== プロフィールの保存 =====
  def update
    if current_user.update(profile_params)
      # 更新成功後はWant一覧に戻る
      redirect_to wants_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # プロフィールフォームで受け付けるパラメータのホワイトリスト
  # target_age（目標寿命）を変更するとライフゲージの計算に即座に反映される
  def profile_params
    params.require(:user).permit(:name, :email, :birthday, :target_age)
  end
end
