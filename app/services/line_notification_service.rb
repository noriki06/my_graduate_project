class LineNotificationService
  API_URL = "https://api.line.me/v2/bot/message/push"

  def push(line_user_id, text)
    token = ENV["LINE_CHANNEL_ACCESS_TOKEN"]

    if token.blank?
      Rails.logger.info("[LineNotificationService] LINE_CHANNEL_ACCESS_TOKEN が未設定のためスキップ: #{line_user_id}")
      return
    end

    body = {
      to: line_user_id,
      messages: [ { type: "text", text: text } ]
    }.to_json

    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"]  = "application/json"
    request["Authorization"] = "Bearer #{token}"
    request.body = body

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[LineNotificationService] 送信失敗: #{response.code} #{response.body}")
    end

    response
  end
end
