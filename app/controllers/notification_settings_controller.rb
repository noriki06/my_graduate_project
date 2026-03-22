# NotificationSettingsController
# LINE通知の設定（頻度・時刻・曜日）と LINE連携（リンクコード発行・解除）を管理する。
class NotificationSettingsController < ApplicationController
  # ログインしていないユーザーはアクセス不可
  before_action :authenticate_user!

  # ===== 通知設定フォームの表示 =====
  # @current_user をビューで参照するだけなので処理なし
  def edit; end

  # ===== 通知設定の保存 =====
  def update
    attrs = notification_setting_params.to_h

    # 毎日通知（daily）の場合は曜日設定が不要なので nil にリセットする
    # これにより「毎日送る」設定で曜日が残ったまま weekly に切り替えても問題ない
    attrs[:notification_day_of_week] = nil if attrs[:notification_frequency] == "daily"

    if current_user.update(attrs)
      redirect_to edit_notification_setting_path, notice: "通知設定を保存しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ===== LINEリンクコードの発行 =====
  # 6桁のランダムな数字コードを生成し、line_link_token カラムに保存する。
  # ユーザーはこのコードをLINEボットに送ることでアカウントを連携できる。
  def generate_line_link_token
    current_user.generate_line_link_token!
    redirect_to edit_notification_setting_path, notice: "LINEリンクコードを発行しました"
  end

  # ===== LINE連携の解除 =====
  # line_user_id と line_link_token を nil にすることでLINE連携を解除する。
  # 連携解除後は通知が届かなくなる。
  def unlink_line
    current_user.update!(line_user_id: nil, line_link_token: nil)
    redirect_to edit_notification_setting_path, notice: "LINE連携を解除しました"
  end

  private

  # 通知設定フォームで受け付けるパラメータのホワイトリスト
  def notification_setting_params
    params.require(:user).permit(
      :notification_enabled,       # 通知のON/OFF
      :notification_frequency,     # 頻度（daily / weekly）
      :notification_hour,          # 通知する時刻（0〜23時）
      :notification_day_of_week    # 週次の場合の曜日（0=日〜6=土）
    )
  end
end
