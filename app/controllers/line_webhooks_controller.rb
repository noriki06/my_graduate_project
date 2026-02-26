class LineWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def callback
    body = request.raw_post

    unless valid_signature?(body, request.headers["X-Line-Signature"])
      head :forbidden
      return
    end

    events = JSON.parse(body)["events"] || []
    events.each { |event| handle_event(event) }

    head :ok
  end

  private

  def valid_signature?(body, signature)
    return false if signature.blank?

    secret = ENV["LINE_CHANNEL_SECRET"].to_s
    digest = OpenSSL::HMAC.digest("SHA256", secret, body)
    expected = Base64.strict_encode64(digest)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  def handle_event(event)
    return unless event["type"] == "message" && event["message"]["type"] == "text"

    text          = event["message"]["text"].strip
    line_user_id  = event["source"]["userId"]
    reply_token   = event["replyToken"]

    # 6桁の数字であればリンクコードとして処理
    if text.match?(/\A\d{6}\z/)
      user = User.find_by(line_link_token: text)

      if user
        user.update!(line_user_id: line_user_id, line_link_token: nil)
        send_reply(reply_token, "LINE連携が完了しました！\n設定した時間にやりたいことの通知をお届けします。")
      else
        send_reply(reply_token, "コードが正しくありません。\nアプリの通知設定画面から新しいコードを発行してください。")
      end
    end
  end

  def send_reply(reply_token, text)
    token = ENV["LINE_CHANNEL_ACCESS_TOKEN"].to_s
    return if token.blank?

    body = {
      replyToken: reply_token,
      messages: [ { type: "text", text: text } ]
    }.to_json

    uri = URI("https://api.line.me/v2/bot/message/reply")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"]  = "application/json"
    request["Authorization"] = "Bearer #{token}"
    request.body = body

    http.request(request)
  end
end
