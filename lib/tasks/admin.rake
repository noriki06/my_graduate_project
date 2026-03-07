namespace :admin do
  desc "ADMIN_EMAIL 環境変数で指定したユーザーに管理者権限を付与する"
  task grant: :environment do
    email = ENV["ADMIN_EMAIL"]

    if email.blank?
      puts "ADMIN_EMAIL が未設定のためスキップします"
      next
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "ユーザーが見つかりません: #{email}"
      next
    end

    if user.admin?
      puts "すでに管理者です: #{email}"
      next
    end

    user.update!(admin: true)
    puts "管理者権限を付与しました: #{email}"
  end
end
