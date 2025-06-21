# spec/factories/reviews.rb

FactoryBot.define do
  factory :review do
    association :timer_session

    # ここを rating { 4 } から score { 4 } に変更
    score { 4 } # デフォルト評価
    comment { "テストレビューコメント" }
  end
end