class BirthdaysController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_birthday_present, only: %i[edit update]

  def edit; end

  def update
    date = parsed_birthday
    unless date
      current_user.errors.add(:birthday, "はYYYYMMDD（例: 19900102）で入力してください")
      return render :edit, status: :unprocessable_entity
    end

    if current_user.update(birthday: date)
      redirect_to onboarding_result_path, notice: "生年月日を登録しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def parsed_birthday
    input = params.dig(:user, :birthday).to_s
    normalized = input.gsub(/[^\d]/, "")
    return nil if normalized.blank?

    Date.strptime(normalized, "%Y%m%d")
  rescue ArgumentError, TypeError
    nil
  end

  def redirect_if_birthday_present
    redirect_to wants_path if current_user.birthday.present?
  end
end
