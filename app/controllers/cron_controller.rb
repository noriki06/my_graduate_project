# CronController
# Google Apps Script（GAS）から毎時呼ばれる通知トリガーエンドポイント。
# 設定した通知時刻に該当するユーザーに対して LINE で AI 5分行動提案を送る。
# 認証: X-Cron-Token ヘッダー or params[:token] で CRON_SECRET_TOKEN と照合する。
class CronController < ApplicationController
  # GAS からのリクエストは CSRF トークンを持たないためスキップする
  skip_before_action :verify_authenticity_token
  # 全アクションの前にトークン認証を行う（未認証は 401 を返す）
  before_action :verify_cron_token

  # ===== LINE通知の一括送信 =====
  def send_notifications
    now          = Time.current
    current_hour = now.hour   # 現在の時刻（0〜23）
    current_wday = now.wday   # 現在の曜日（0=日〜6=土）

    # 通知対象ユーザーを絞り込む条件:
    # - notification_enabled: true（通知ON）
    # - line_user_id が設定済み（LINE連携済み）
    # - notification_hour が現在時刻と一致（毎時呼ばれるので該当時刻のユーザーのみ）
    users = User
      .where(notification_enabled: true)
      .where.not(line_user_id: [ nil, "" ])
      .where(notification_hour: current_hour)

    Rails.logger.info("[Cron] 対象候補: #{users.count} 件 (#{now})")

    sent    = 0  # 送信成功数
    skipped = 0  # スキップ数（送信対象外・エラー）

    users.each do |user|
      # 通知頻度のチェック
      # - daily: 毎日送る → 常に true
      # - weekly: 週1回 → 設定した曜日のみ true
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

      # 未達成のWantが1件もない場合はスキップ（送る内容がない）
      all_wants = user.wants.where(achieved_at: nil)
      if all_wants.empty?
        skipped += 1
        next
      end

      # notify_enabled: true のWantを優先する（なければ全未達成Wantから選ぶ）
      priority_wants = all_wants.where(notify_enabled: true)
      wants = priority_wants.any? ? priority_wants : all_wants

      # 今日すでにAI提案が生成されていれば再利用する（APIコストを節約）
      suggestion = user.daily_action_suggestions.find_by(suggested_on: Date.current)

      # 提案のWantが送信対象に含まれていればそれを使い、なければランダム選択
      want = if suggestion&.want && wants.exists?(id: suggestion.want_id)
               suggestion.want
      else
               wants.sample
      end

      if want.nil?
        skipped += 1
        next
      end

      # 提案テキストが未生成の場合のみ OpenAI API を呼び出す
      unless suggestion&.suggested_action.present?
        generated = AiSuggestionService.call(want, user)
        suggestion = user.daily_action_suggestions.create!(
          want: want,
          suggested_action: generated,
          suggested_on: Date.current
        )
      end

      # LINE に送るメッセージを組み立てる
      message = <<~MSG.strip
        ⚡ 今日の5分行動

        「#{want.title}」

        #{suggestion.suggested_action}

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

    # GAS 側で結果を確認できるように JSON で返す
    render json: { ok: true, sent: sent, skipped: skipped, at: now.iso8601 }
  end

  private

  # トークン認証：X-Cron-Token ヘッダーまたは params[:token] と CRON_SECRET_TOKEN を照合する
  # secure_compare でタイミング攻撃を防いでいる
  # トークンが一致しない場合は 401 Unauthorized を返して処理を停止する
  def verify_cron_token
    expected = ENV["CRON_SECRET_TOKEN"]
    provided = request.headers["X-Cron-Token"] || params[:token]

    unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, provided.to_s)
      render json: { error: "unauthorized" }, status: :unauthorized
    end
  end
end
