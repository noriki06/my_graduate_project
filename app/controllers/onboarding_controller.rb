class OnboardingController < ApplicationController
  before_action :authenticate_user!

  def result
    @life_progress = current_user.life_progress_rate || 0

    @remaining_days    = remaining_days_from(current_user)
    @remaining_seconds = remaining_seconds_from(current_user)

    @weekends_left     = (@remaining_days / 7.0).floor

    # 例：年1回の誕生日（＝残り年数）
    @birthdays_left    = (@remaining_days / 365.0).floor

    # 例：家族に月1回会えるとしたら
    @family_meetings_left = (@remaining_days / 30.0).floor

    # 例：旅行（1泊以上）を年5回くらいの雰囲気（＝週末22回に1回）
    @trips_left = (@weekends_left / 22.0).floor

    # トップページの文言を再掲（好きに変更OK）
    @die_with_zero_message = "人生の最後に残るのは、集めたお金ではなく、積み上げた思い出だ"
  end

  private

  def remaining_days_from(user)
    return 0 if user.birthday.blank?

    end_date = user.birthday + 84.years
    [(end_date - Date.current).to_i, 0].max
  end

  # 秒までの“刻一刻”用：今日の残り秒も加味してそれっぽく減るようにする
  def remaining_seconds_from(user)
    return 0 if user.birthday.blank?

    end_at = (user.birthday + 84.years).end_of_day
    seconds = (end_at.to_time - Time.current).to_i
    [seconds, 0].max
  end
end
