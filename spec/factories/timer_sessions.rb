# spec/factories/timer_sessions.rb
FactoryBot.define do
  factory :timer_session do
    started_at { Time.current - 1.hour } # デフォルト値
    duration_minutes { 25 } # デフォルト値
    user # userファクトリと関連付ける
    # task { nil } # taskはnullableなのでデフォルトはnilでもOK
  end
end

