class User < ApplicationRecord
  has_many :wants, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :name, presence: true
  validates :birthday, presence: true
  validate :birthday_must_be_yyyymmdd

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
