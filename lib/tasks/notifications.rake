namespace :notifications do
  desc "LINE通知を対象ユーザーに送信する（毎時 cron から実行）"
  task send: :environment do
    now          = Time.current
    current_hour = now.hour
    current_wday = now.wday  # 0=日曜, 1=月曜, ...

    users = User
      .where(notification_enabled: true)
      .where.not(line_user_id: nil)
      .where(notification_hour: current_hour)

    Rails.logger.info("[Notification] 対象候補: #{users.count} 件 (#{now})")

    users.each do |user|
      should_notify =
        case user.notification_frequency
        when "daily"  then true
        when "weekly" then user.notification_day_of_week == current_wday
        else false
        end

      next unless should_notify

      all_wants = user.wants.where(achieved_at: nil)
      next if all_wants.empty?

      # notify_enabled: true の want を優先、なければ全件から選ぶ
      priority_wants = all_wants.where(notify_enabled: true)
      wants = priority_wants.any? ? priority_wants : all_wants

      # 今日の AI 提案があればそのアクション文、なければ want タイトルのみ
      suggestion = user.daily_action_suggestions.find_by(suggested_on: Date.current)

      # 提案の want が優先対象に含まれていればそれを使う、なければ優先対象からランダム
      want = if suggestion&.want && wants.exists?(id: suggestion.want_id)
               suggestion.want
      else
               wants.sample
      end
      next if want.nil?

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

      LineNotificationService.new.push(user.line_user_id, message)
      Rails.logger.info("[Notification] 送信: user=#{user.id} want=#{want.id}")
    end

    Rails.logger.info("[Notification] 完了")
  end
end
