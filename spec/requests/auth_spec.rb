require 'rails_helper'

RSpec.describe "Auth API", type: :request do
  let!(:user) {
    User.create!(
      email: "test@example.com",
      password: "password",
      confirmed_at: Time.current # ← これでOK
    )
  }

  describe "POST /auth/sign_in" do
    context "正しいログイン情報" do
      it "ログインできる" do
        post "/auth/sign_in", params: {
          email: "test@example.com",
          password: "password"
        }

        expect(response).to have_http_status(:ok)
        expect(response.headers).to include("access-token", "client", "uid")
      end
    end

    context "間違ったログイン情報" do
      it "ログインに失敗する" do
        post "/auth/sign_in", params: {
          email: "test@example.com",
          password: "wrong"
        }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["errors"]).to include("Invalid login credentials. Please try again.")
      end
    end
  end
end
