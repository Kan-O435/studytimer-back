FactoryBot.define do
  factory :task do
    title { "サンプルタスク" }
    association :user
  end
end