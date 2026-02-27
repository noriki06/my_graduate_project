class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  def update
    if current_user.update(profile_params)
      redirect_to wants_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :birthday)
  end
end
