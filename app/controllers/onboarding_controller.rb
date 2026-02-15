class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_no_birthday

  def result
    @life_progress = current_user.life_progress_rate || 0

    @remaining_days    = current_user.remaining_life_days
    @remaining_seconds = current_user.remaining_life_seconds

    @weekends_left  = (@remaining_days / 7.0).floor
    @birthdays_left = (@remaining_days / 365.0).floor
    @family_meetings_left = (@remaining_days / 30.0).floor
    @trips_left     = (@weekends_left / 22.0).floor

    @die_with_zero_message = "人生の最後に残るのは、集めたお金ではなく、積み上げた思い出だ"
  end

  private

  def redirect_if_no_birthday
    redirect_to edit_birthday_path if current_user.birthday.blank?
  end
end
