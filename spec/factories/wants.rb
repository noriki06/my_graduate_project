FactoryBot.define do
  factory :want do
    association :user
    title { "海外旅行" }
    memo { "メモ" }
    target_date { Date.today + 30 }
    achieved_at { nil }
    achievement_note { nil }
  end
end
