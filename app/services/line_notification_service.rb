# LineNotificationService
# LINE Messaging API の Push Message を使ってユーザーにメッセージを送るサービスクラス。
# CronController から呼ばれ、指定した LINE ユーザーIDにテキストメッセージをプッシュ通知する。
# Push Message はユーザーがボットをフォローしていれば任意のタイミングで送信できる。
class LineNotificationService
  # LINE Push Message API のエンドポイント
  API_URL = "https://api.line.me/v2/bot/message/push"

  # ===== メッセージ送信メソッド =====
  # line_user_id: 送信先の LINE ユーザーID（users.line_user_id に保存されている）
  # text: 送信するテキストメッセージ
  def push(line_user_id, text)
    token = ENV["LINE_CHANNEL_ACCESS_TOKEN"]

    # アクセストークンが未設定の場合は何もしない（開発環境や設定ミス時のフォールバック）
    if token.blank?
      Rails.logger.info("[LineNotificationService] LINE_CHANNEL_ACCESS_TOKEN が未設定のためスキップ: #{line_user_id}")
      return
    end

    # LINE Messaging API のリクエストボディを組み立てる
    # messages は配列で複数送れるが、ここでは1件のテキストメッセージのみ送信する
    body = {
      to: line_user_id,                            # 送信先のLINEユーザーID
      messages: [ { type: "text", text: text } ]   # テキストメッセージ1件
    }.to_json

    # Net::HTTP を使って HTTPS POST リクエストを送る
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true  # LINE API は HTTPS 必須

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"]  = "application/json"          # JSONで送信
    request["Authorization"] = "Bearer #{token}"           # Bearer トークン認証
    request.body = body

    response = http.request(request)

    # 200 OK 以外のレスポンスはエラーとしてログに記録する
    #（例外は発生させず、呼び出し元で rescue している）
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[LineNotificationService] 送信失敗: #{response.code} #{response.body}")
    end

    response
  end
end
