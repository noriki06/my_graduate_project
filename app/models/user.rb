class User < ApplicationRecord
  has_many :wants, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true

  # 誕生日は「後で入力」なので update のときだけ必須にする
  validates :birthday, presence: true, on: :update
  validate :birthday_must_be_yyyymmdd, if: -> { birthday.present? }

  AVERAGE_LIFE_SPAN_YEARS = 84.0
  DAYS_IN_YEAR = 365.2425

  # 年齢（表示用に残してOK）
  def age
    return nil if birthday.nil?

    today = Date.current
    a = today.year - birthday.year
    a -= 1 if today < birthday + a.years
    a
  end

  # 生きた日数（基礎データ）
  def lived_days
    return nil if birthday.nil?
    (Date.current - birthday).to_i
  end

  # 想定総日数（84年）
  def total_life_days
    (AVERAGE_LIFE_SPAN_YEARS * DAYS_IN_YEAR).to_i
  end

  # 人生進捗率（%）※日数ベースで滑らか
  def life_progress_rate
    return nil if birthday.nil?

    progress = (lived_days.to_f / total_life_days) * 100
    progress.clamp(0, 100).round(1)
  end

  # 残り日数
  def remaining_life_days
    return nil if birthday.nil?

    remaining = total_life_days - lived_days
    [ remaining, 0 ].max
  end

  private

  def birthday_must_be_yyyymmdd
    return if birthday.is_a?(Date)

    begin
      self.birthday = Date.strptime(birthday.to_s, "%Y%m%d")
    rescue ArgumentError, TypeError
      errors.add(:birthday, "はYYYYMMDD形式で入力してください")
    end
  end
end
