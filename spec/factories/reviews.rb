# spec/factories/reviews.rb の例
FactoryBot.define do
  factory :review do
    user
    # timer_session を自動で作成して関連付ける
    association :timer_session, factory: :timer_session
    # または、timer_session の factory が user も持っている場合
    # timer_session { association(:timer_session, user: user) }

    score { Faker::Number.between(from: 1, to: 5) }
    comment { Faker::Lorem.sentence }
  end
end

