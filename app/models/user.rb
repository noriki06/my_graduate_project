class User < ApplicationRecord
  has_many :wants, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true

  # 誕生日は「後で入力」なので update のときだけ必須にする
  validates :birthday, presence: true, on: :update
  validate :birthday_must_be_yyyymmdd, if: -> { birthday.present? }

  AVERAGE_LIFE_SPAN = 84.0

  def age
    return nil if birthday.nil?

    today = Date.current
    age = today.year - birthday.year
    age -= 1 if today < birthday + age.years
    age
  end

  def life_progress_rate
    return nil if age.nil?

    ((age / AVERAGE_LIFE_SPAN) * 100).round(1)
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
