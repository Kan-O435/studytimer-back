require 'rails_helper'

RSpec.describe User, type: :model do
  it "有効なファクトリでユーザーが作れること" do
    user = User.create(email: "test@example.com", password: "password")
    expect(user).to be_valid
  end

  it "メールアドレスがなければ無効であること" do
    user = User.create(password: "password")
    expect(user).to be_invalid
  end
end
