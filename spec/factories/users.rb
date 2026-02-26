FactoryBot.define do
  factory :user do
    email { "test@example.com" }
    password { "password" }
    name { "テストユーザー" }
    birthday { Date.new(1995, 1, 1) } # ← これ追加
  end
end
