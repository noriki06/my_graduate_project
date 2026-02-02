class User < ApplicationRecord
  has_many :wants, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true
  validates :birthday, presence: true
  validate :birthday_must_be_yyyymmdd

  AVERAGE_LIFE_SPAN = 84.0

  # 年齢を計算
  def age
    return nil if birthday.nil?

    today = Date.current
    age = today.year - birthday.year
    age -= 1 if today < birthday + age.years
    age
  end

  # 人生進捗率（%）
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
