class Admin::WantsController < Admin::BaseController
  def index
    @wants = Want.includes(:user).order(created_at: :desc).page(params[:page]).per(30)
  end

  def destroy
    want = Want.find(params[:id])
    want.destroy!
    redirect_to admin_wants_path, notice: "投稿を削除しました。"
  end
end
