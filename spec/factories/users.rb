FactoryBot.define do
  factory :user do
    name { "テスト太郎" }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
