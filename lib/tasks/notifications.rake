namespace :notifications do
  desc "LINE通知を対象ユーザーに送信する（毎時 cron から実行）"
  task send: :environment do
    now          = Time.current
    current_hour = now.hour
    current_wday = now.wday

    debug_user = User.find_by(email: "gohira06@gmail.com")
    Rails.logger.info("[Debug] user_id=#{debug_user&.id}")
    Rails.logger.info("[Debug] line_user_id_present=#{debug_user&.line_user_id.present?}")
    Rails.logger.info("[Debug] notification_enabled=#{debug_user&.notification_enabled}")
    Rails.logger.info("[Debug] notification_hour=#{debug_user&.notification_hour}")
    Rails.logger.info("[Debug] notification_frequency=#{debug_user&.notification_frequency}")
    Rails.logger.info("[Debug] notification_day_of_week=#{debug_user&.notification_day_of_week}")
    Rails.logger.info("[Debug] now=#{now}")
    Rails.logger.info("[Debug] current_hour=#{current_hour}")
    Rails.logger.info("[Debug] current_wday=#{current_wday}")

    users = User
      .where(notification_enabled: true)
      .where.not(line_user_id: [ nil, "" ])
      .where(notification_hour: current_hour)

    Rails.logger.info("[Notification] 対象候補: #{users.count} 件 (#{now})")

    users.each do |user|
      should_notify =
        case user.notification_frequency
        when "daily"  then true
        when "weekly" then user.notification_day_of_week == current_wday
        else false
        end

      unless should_notify
        Rails.logger.info("[Notification] skip user=#{user.id} reason=frequency")
        next
      end

      all_wants = user.wants.where(achieved_at: nil)
      if all_wants.empty?
        Rails.logger.info("[Notification] skip user=#{user.id} reason=no_wants")
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
        Rails.logger.info("[Notification] skip user=#{user.id} reason=no_want_selected")
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
        Rails.logger.info("[Notification] 送信: user=#{user.id} want=#{want.id}")
      rescue => e
        Rails.logger.error("[Notification] 失敗: user=#{user.id} error=#{e.class} #{e.message}")
      end
    end

    Rails.logger.info("[Notification] 完了")
  end
end
