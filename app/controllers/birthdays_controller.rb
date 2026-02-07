class BirthdaysController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_birthday_present, only: %i[edit update]

  def edit
  end

  def update
    if current_user.update(birthday_params)
      redirect_to onboarding_result_path, notice: "生年月日を登録しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def birthday_params
    b = params.require(:user).permit(:birthday)
    normalized = b[:birthday].to_s.gsub(/[^\d]/, "") # 数字以外全部除去
    b[:birthday] = normalized
    b
  end

  def redirect_if_birthday_present
    redirect_to wants_path if current_user.birthday.present?
  end
end
