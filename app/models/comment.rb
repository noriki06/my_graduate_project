class Comment < ApplicationRecord
  belongs_to :want
  belongs_to :user

  validates :content, presence: true
end
