class NotificationSettingsController < ApplicationController
  before_action :authenticate_user!

  def edit; end

  def update
    attrs = notification_setting_params.to_h
    attrs[:notification_day_of_week] = nil if attrs[:notification_frequency] == "daily"

    if current_user.update(attrs)
      redirect_to edit_notification_setting_path, notice: "通知設定を保存しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def generate_line_link_token
    current_user.generate_line_link_token!
    redirect_to edit_notification_setting_path, notice: "LINEリンクコードを発行しました"
  end

  def unlink_line
    current_user.update!(line_user_id: nil, line_link_token: nil)
    redirect_to edit_notification_setting_path, notice: "LINE連携を解除しました"
  end

  private

  def notification_setting_params
    params.require(:user).permit(
      :notification_enabled,
      :notification_frequency,
      :notification_hour,
      :notification_day_of_week
    )
  end
end
