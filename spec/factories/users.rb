FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test#{n}@example.com" }
    password { "password" }
    name { "テストユーザー" }
    birthday { Date.new(1995, 1, 1) }
  end
end
