class DailyActionSuggestion < ApplicationRecord
  belongs_to :user
  belongs_to :want

  validates :suggested_action, presence: true
end
