# spec/factories/timer_sessions.rb
FactoryBot.define do
  factory :timer_session do
    user
    started_at { 1.hour.ago }
    ended_at { Time.current }
    duration_minutes { 25 }
    # task { nil }  # 必要であればコメント解除
  end
end
