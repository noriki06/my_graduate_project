class Like < ApplicationRecord
  belongs_to :want
  belongs_to :user

  validates :user_id, uniqueness: { scope: :want_id }
end
