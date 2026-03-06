class User < ApplicationRecord
  has_many :wants, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_many :daily_action_suggestions, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :github, :line ]

  def self.from_omniauth(auth)
    provider = auth.provider
    uid      = auth.uid.to_s
    email    = auth.info.email&.downcase

    # ① すでにこのSNS(provider+uid)で紐づいている user がいるならそれ
    if (identity = Identity.find_by(provider: provider, uid: uid))
      return identity.user
    end

    # ② emailが取れるなら email一致ユーザーを探す（既存ユーザーにSNSを追加）
    user = email.present? ? User.find_by(email: email) : nil

    # ③ いなければ新規作成
    user ||= User.create! do |u|
      u.email    = email.presence || "#{uid}@#{provider}.placeholder"
      u.name     = auth.info.name.presence || auth.info.nickname.presence || "ユーザー"
      u.password = Devise.friendly_token[0, 20]
    end

    # ④ SNSアカウントを紐付け
    user.identities.create!(provider: provider, uid: uid)

    # ⑤ LINEログイン時はline_user_idも自動セット（通知連携のため）
    #    LINE Login と LINE Messaging API は同一 provider 配下なら userId が共通
    if provider == "line" && user.line_user_id.blank?
      user.update!(line_user_id: uid)
    end

    user
  end

  validates :name, presence: true

  NOTIFICATION_FREQUENCIES = %w[daily weekly].freeze
  validates :notification_frequency, inclusion: { in: NOTIFICATION_FREQUENCIES }
  validates :notification_hour, inclusion: { in: 0..23 }
  validates :notification_day_of_week, inclusion: { in: 0..6 }
  validates :target_age, numericality: { only_integer: true, greater_than_or_equal_to: 50, less_than_or_equal_to: 150 }

  DEFAULT_TARGET_AGE = 84
  DEMO_EMAIL = "demo@lifegauge.com"
  DAYS_IN_YEAR = 365.2425

  validate :birthday_cannot_be_in_future, if: -> { birthday.present? }

  def age
    return nil if birthday.nil?

    today = Date.current
    a = today.year - birthday.year
    a -= 1 if today < birthday + a.years
    a
  end

  def lived_days
    return nil if birthday.nil?
    (Date.current - birthday).to_i
  end

  def total_life_days
    (target_age * DAYS_IN_YEAR).to_i
  end

  def wants_count
    wants.count
  end

  def achieved_count
    wants.where.not(achieved_at: nil).count
  end

  def achievement_rate
    return 0 if wants_count.zero?
    (achieved_count.to_f / wants_count * 100).round
  end

  def life_progress_rate
    return nil if birthday.nil?
    progress = (lived_days.to_f / total_life_days) * 100
    progress.clamp(0, 100).round(1)
  end

  def life_end_date
    return nil if birthday.nil?
    birthday + target_age.years
  end

  def remaining_life_days
    return 0 if birthday.nil?
    [ (life_end_date - Date.current).to_i, 0 ].max
  end

  def remaining_life_seconds
    return 0 if birthday.nil?
    end_at = life_end_date.end_of_day.in_time_zone
    [ (end_at - Time.current).to_i, 0 ].max
  end

  def demo?
    email == DEMO_EMAIL
  end

  def line_linked?
    line_user_id.present?
  end

  def generate_line_link_token!
    token = format("%06d", rand(1_000_000))
    update!(line_link_token: token)
    token
  end

  protected

  def password_required?
    identities.empty? ? super : false
  end

  private

  def birthday_cannot_be_in_future
    errors.add(:birthday, "は未来の日付にできません") if birthday > Date.current
  end
end
