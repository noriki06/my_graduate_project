module NotificationSettingsHelper
  # LINE_ADD_FRIEND_URL が画像URL（.png等）ならそのまま返す
  # テキストURL（https://line.me/...）なら rqrcode でQR生成して data URI を返す
  def line_qr_src
    url = ENV["LINE_ADD_FRIEND_URL"].presence
    return nil unless url

    return url if url.match?(/\.(png|jpg|jpeg|gif|svg)/i)

    qr  = RQRCode::QRCode.new(url)
    png = qr.as_png(size: 180, border_modules: 4)
    "data:image/png;base64,#{Base64.strict_encode64(png.to_s)}"
  rescue => e
    Rails.logger.error("line_qr_src error: #{e.message}")
    nil
  end
end
