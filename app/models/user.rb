# User モデル
# アプリの利用者1人を表す。Devise による認証 + SNSログイン（omniauth）に対応。
# 生年月日（birthday）と目標寿命（target_age）からライフゲージを計算する。
class User < ApplicationRecord
  # ===== アソシエーション =====
  has_many :wants, dependent: :destroy                    # ユーザーの「やりたいこと」一覧
  has_many :likes, dependent: :destroy                    # ユーザーが押したいいね
  has_many :comments, dependent: :destroy                 # ユーザーが投稿したコメント
  has_many :identities, dependent: :destroy               # SNSログイン情報（provider + uid）
  has_many :daily_action_suggestions, dependent: :destroy # AI提案の履歴

  # ===== Devise 設定 =====
  # - database_authenticatable: メール＋パスワード認証
  # - registerable: 新規登録・退会
  # - recoverable: パスワードリセット
  # - rememberable: ログイン状態を保持するRemember me
  # - validatable: email・パスワードの基本バリデーション
  # - omniauthable: SNSログイン（Google / GitHub / LINE）
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :github, :line ]

  # ===== SNSログイン用クラスメソッド =====
  # OmniAuth の認証情報（auth ハッシュ）からユーザーを取得または新規作成する。
  # ① 既存のSNS紐づけ（Identity）がある → そのユーザーを返す
  # ② メールが一致する既存ユーザーがいる → そのユーザーにSNSを追加
  # ③ 誰もいない → 新規ユーザーを作成してSNSを紐づける
  def self.from_omniauth(auth)
    provider = auth.provider
    uid      = auth.uid.to_s
    email    = auth.info.email&.downcase

    # ① すでにこのSNS(provider+uid)で紐づいている user がいるならそれを返す
    if (identity = Identity.find_by(provider: provider, uid: uid))
      return identity.user
    end

    # ② emailが取れるなら email一致ユーザーを探す（既存ユーザーにSNSを追加）
    user = email.present? ? User.find_by(email: email) : nil

    # ③ いなければ新規作成（emailがない場合はプレースホルダーアドレスを使用）
    user ||= User.create! do |u|
      u.email    = email.presence || "#{uid}@#{provider}.placeholder"
      u.name     = auth.info.name.presence || auth.info.nickname.presence || "ユーザー"
      u.password = Devise.friendly_token[0, 20]  # ランダムなパスワードを自動生成
    end

    # ④ SNSアカウントを Identity テーブルに紐付け（次回以降①で見つかるようになる）
    user.identities.create!(provider: provider, uid: uid)

    # ⑤ LINEログイン時はline_user_idも自動セット（通知連携のため）
    #    LINE Login と LINE Messaging API は同一 provider 配下なら userId が共通
    #    → LINE でログインすれば通知連携も自動で完了する
    if provider == "line" && user.line_user_id.blank?
      user.update!(line_user_id: uid)
    end

    user
  end

  # ===== バリデーション =====
  validates :name, presence: true  # 表示名は必須
  NOTIFICATION_FREQUENCIES = %w[daily weekly].freeze
  validates :notification_frequency, inclusion: { in: NOTIFICATION_FREQUENCIES }  # 通知頻度は daily か weekly のみ
  validates :notification_hour, inclusion: { in: 0..23 }                           # 通知時刻は0〜23時
  validates :notification_day_of_week, inclusion: { in: 0..6 }, allow_nil: true   # 曜日は0（日）〜6（土）、日次なら nil
  validates :target_age, numericality: { only_integer: true, greater_than_or_equal_to: 50, less_than_or_equal_to: 150 }  # 目標寿命は50〜150歳

  # ===== 定数 =====
  DEFAULT_TARGET_AGE = 84          # 目標寿命のデフォルト値（日本の平均寿命付近）
  DEMO_EMAIL = "demo@lifegauge.com" # デモユーザーの固定メールアドレス
  DAYS_IN_YEAR = 365.2425           # うるう年を考慮した1年あたりの日数

  # 誕生日が未来の日付になっていないかチェックする
  validate :birthday_cannot_be_in_future, if: -> { birthday.present? }

  # ===== インスタンスメソッド =====

  # 現在の年齢を計算する（誕生日を過ぎていなければ1引く）
  # birthday が nil の場合は nil を返す
  def age
    return nil if birthday.nil?

    today = Date.current
    a = today.year - birthday.year
    a -= 1 if today < birthday + a.years  # 今年の誕生日をまだ迎えていなければ−1
    a
  end

  # 誕生日から今日までの日数（ライフゲージの分子に使う）
  def lived_days
    return nil if birthday.nil?
    (Date.current - birthday).to_i
  end

  # target_age（目標寿命）に対応する総日数（ライフゲージの分母に使う）
  def total_life_days
    (target_age * DAYS_IN_YEAR).to_i
  end

  # 登録しているWantの総数
  def wants_count
    wants.count
  end

  # 達成済みのWantの数（achieved_at が nil でないもの）
  def achieved_count
    wants.where.not(achieved_at: nil).count
  end

  # Want の達成率（%）を整数で返す
  # wants_count がゼロの場合は0を返す（ゼロ除算防止）
  def achievement_rate
    return 0 if wants_count.zero?
    (achieved_count.to_f / wants_count * 100).round
  end

  # ライフゲージの進捗率（%）を小数点1桁で返す
  # lived_days / total_life_days を 0〜100 にクランプして計算
  def life_progress_rate
    return nil if birthday.nil?
    progress = (lived_days.to_f / total_life_days) * 100
    progress.clamp(0, 100).round(1)
  end

  # 目標寿命を迎える日付（birthday + target_age 年）
  def life_end_date
    return nil if birthday.nil?
    birthday + target_age.years
  end

  # 目標寿命まで残り何日かを返す（過去になっていれば0）
  def remaining_life_days
    return 0 if birthday.nil?
    [ (life_end_date - Date.current).to_i, 0 ].max
  end

  # 目標寿命まで残り何秒かを返す（カウントダウン表示用）
  def remaining_life_seconds
    return 0 if birthday.nil?
    end_at = life_end_date.end_of_day.in_time_zone
    [ (end_at - Time.current).to_i, 0 ].max
  end

  # デモユーザーかどうかを判定する
  # デモユーザーは投稿・編集・削除などの操作ができない
  def demo?
    email == DEMO_EMAIL
  end

  # LINE連携済みかどうかを判定する（line_user_id が存在すれば連携済み）
  def line_linked?
    line_user_id.present?
  end

  # LINEリンク用の6桁コードをランダムに生成して保存する
  # ユーザーはこのコードをLINEボットに送ることで連携を完了できる
  def generate_line_link_token!
    token = format("%06d", rand(1_000_000))  # 000000〜999999 のゼロ埋め6桁
    update!(line_link_token: token)
    token
  end

  protected

  # SNSログインユーザーはパスワードが不要（identities がある場合はスキップ）
  # メール登録ユーザーは通常通りパスワードが必要
  def password_required?
    identities.empty? ? super : false
  end

  private

  # 誕生日が今日より後の日付になっていないか確認するバリデーション
  def birthday_cannot_be_in_future
    errors.add(:birthday, "は未来の日付にできません") if birthday > Date.current
  end
end
