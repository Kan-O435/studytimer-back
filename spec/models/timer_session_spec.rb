# ./spec/models/timer_session_spec.rb
RSpec.describe TimerSession, type: :model do
  let!(:user) { create(:user) } # ユーザーをlet!で定義

  it "有効な属性を持つ場合は有効であること" do
    # duration の代わりに duration_minutes を使う
    timer_session = build(:timer_session, user: user, duration_minutes: 60)
    expect(timer_session).to be_valid
  end

  it "duration_minutes がない場合は無効であること" do
    # duration の代わりに duration_minutes を使う
    timer_session = build(:timer_session, user: user, duration_minutes: nil)
    expect(timer_session).not_to be_valid
    # エラーメッセージも duration ではなく duration_minutes をチェックする
    expect(timer_session.errors[:duration_minutes]).to include("can't be blank")
  end
end