class User < ApplicationRecord
  has_many :wants, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true

  AVERAGE_LIFE_SPAN_YEARS = 84
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
    (AVERAGE_LIFE_SPAN_YEARS * DAYS_IN_YEAR).to_i
  end

  def life_progress_rate
    return nil if birthday.nil?
    progress = (lived_days.to_f / total_life_days) * 100
    progress.clamp(0, 100).round(1)
  end

  def life_end_date
    return nil if birthday.nil?
    birthday + AVERAGE_LIFE_SPAN_YEARS.years
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

  private

  def birthday_cannot_be_in_future
    errors.add(:birthday, "は未来の日付にできません") if birthday > Date.current
  end
end
