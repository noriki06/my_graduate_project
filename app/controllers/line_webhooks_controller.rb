# LineWebhooksController
# LINEプラットフォームからのWebhookイベントを受け取り処理するコントローラ。
# 主な役割：ユーザーがLINEボットに送った6桁のリンクコードを受信し、
#           アプリのユーザーとLINEアカウントを紐づける。
class LineWebhooksController < ApplicationController
  # LINE からのリクエストは CSRF トークンを持たないため、CSRF検証をスキップする
  # 代わりに X-Line-Signature ヘッダーを使ってリクエストの正当性を確認する
  skip_before_action :verify_authenticity_token

  # ===== Webhook 受信エンドポイント =====
  # POST /line_webhook に LINE プラットフォームからイベントが届く
  def callback
    body = request.raw_post  # 生のリクエストボディ（署名検証に使う）

    # LINEの署名検証：Channel Secret を使って HMAC-SHA256 で署名を検証する
    # 署名が一致しない場合は 403 Forbidden を返して処理を中断する
    unless valid_signature?(body, request.headers["X-Line-Signature"])
      head :forbidden
      return
    end

    # イベントリストを取得して1件ずつ処理する
    events = JSON.parse(body)["events"] || []
    events.each { |event| handle_event(event) }

    # LINE プラットフォームには必ず 200 OK を返す（タイムアウトエラーを防ぐため）
    head :ok
  end

  private

  # LINE の署名検証メソッド
  # Channel Secret をキーに X-Line-Signature ヘッダーの値と比較する
  # ActiveSupport::SecurityUtils.secure_compare でタイミング攻撃を防いでいる
  def valid_signature?(body, signature)
    return false if signature.blank?

    secret = ENV["LINE_CHANNEL_SECRET"].to_s
    # HMAC-SHA256 でダイジェストを計算し、Base64 エンコードする
    digest = OpenSSL::HMAC.digest("SHA256", secret, body)
    expected = Base64.strict_encode64(digest)
    # 定数時間比較で署名を検証（タイミング攻撃対策）
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  # 各Webhookイベントを処理する
  # テキストメッセージかつ6桁数字の場合のみリンクコードとして処理する
  def handle_event(event)
    # テキストメッセージ以外のイベント（フォロー、スタンプなど）は無視する
    return unless event["type"] == "message" && event["message"]["type"] == "text"

    text          = event["message"]["text"].strip   # ユーザーが送ったテキスト
    line_user_id  = event["source"]["userId"]        # LINE上のユーザーID
    reply_token   = event["replyToken"]              # 返信用トークン（5秒以内に使う必要あり）

    # 6桁の数字であればリンクコードとして処理する
    if text.match?(/\A\d{6}\z/)
      # line_link_token が一致するユーザーを検索する
      user = User.find_by(line_link_token: text)

      if user
        # 見つかった場合：line_user_id を保存してリンクコードをクリアする（使い捨て）
        user.update!(line_user_id: line_user_id, line_link_token: nil)
        send_reply(reply_token, "LINE連携が完了しました！\n設定した時間にやりたいことの通知をお届けします。")
      else
        # コードが一致しない、または期限切れの場合
        send_reply(reply_token, "コードが正しくありません。\nアプリの通知設定画面から新しいコードを発行してください。")
      end
    end
    # 6桁数字以外のメッセージは無視する（応答しない）
  end

  # LINE Reply API を使って返信を送る
  # Reply Token は5秒以内に1回だけ使用できる
  def send_reply(reply_token, text)
    token = ENV["LINE_CHANNEL_ACCESS_TOKEN"].to_s
    return if token.blank?  # アクセストークンが未設定なら何もしない

    body = {
      replyToken: reply_token,
      messages: [ { type: "text", text: text } ]
    }.to_json

    # LINE Reply API に HTTPS POST リクエストを送る
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
