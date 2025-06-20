# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { "テストユーザー" }
    email { Faker::Internet.email }
    password { "password" }
    password_confirmation { "password" }
    provider { "email" }
    uid { email }
  end
end
