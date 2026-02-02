class Want < ApplicationRecord
  belongs_to :user

  def achieved?
    achieved_at.present?
  end
end
