class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(created_at: :desc).page(params[:page]).per(30)
  end

  def destroy
    user = User.find(params[:id])
    if user == current_user
      redirect_to admin_users_path, alert: "自分自身は削除できません。"
    else
      user.destroy!
      redirect_to admin_users_path, notice: "ユーザーを削除しました。"
    end
  end
end
