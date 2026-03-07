class CronController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_cron_token

  def send_notifications
    now          = Time.current
    current_hour = now.hour
    current_wday = now.wday

    users = User
      .where(notification_enabled: true)
      .where.not(line_user_id: [ nil, "" ])
      .where(notification_hour: current_hour)

    Rails.logger.info("[Cron] 対象候補: #{users.count} 件 (#{now})")

    sent    = 0
    skipped = 0

    users.each do |user|
      should_notify =
        case user.notification_frequency
        when "daily"  then true
        when "weekly" then user.notification_day_of_week == current_wday
        else false
        end

      unless should_notify
        skipped += 1
        next
      end

      all_wants = user.wants.where(achieved_at: nil)
      if all_wants.empty?
        skipped += 1
        next
      end

      priority_wants = all_wants.where(notify_enabled: true)
      wants = priority_wants.any? ? priority_wants : all_wants

      suggestion = user.daily_action_suggestions.find_by(suggested_on: Date.current)

      want = if suggestion&.want && wants.exists?(id: suggestion.want_id)
               suggestion.want
             else
               wants.sample
             end

      if want.nil?
        skipped += 1
        next
      end

      action_text =
        if suggestion&.suggested_action.present?
          suggestion.suggested_action
        else
          "このwantに向けて今日1歩踏み出してみよう！"
        end

      message = <<~MSG.strip
        📌 今日の5分アクション

        「#{want.title}」
        → #{action_text}

        ライフゲージより
      MSG

      begin
        LineNotificationService.new.push(user.line_user_id, message)
        Rails.logger.info("[Cron] 送信: user=#{user.id} want=#{want.id}")
        sent += 1
      rescue => e
        Rails.logger.error("[Cron] 失敗: user=#{user.id} error=#{e.class} #{e.message}")
        skipped += 1
      end
    end

    render json: { ok: true, sent: sent, skipped: skipped, at: now.iso8601 }
  end

  private

  def verify_cron_token
    expected = ENV["CRON_SECRET_TOKEN"]
    provided = request.headers["X-Cron-Token"] || params[:token]

    unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, provided.to_s)
      render json: { error: "unauthorized" }, status: :unauthorized
    end
  end
end
