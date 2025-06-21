# ./spec/requests/api/v1/timer_sessions_spec.rb
require 'rails_helper'

RSpec.describe "Api::V1::TimerSessions", type: :request do
  # FactoryBot でユーザーを作成し、確認済みにする
  let(:user) { create(:user).tap(&:confirm) }

  # devise_token_auth を使用しているので、ログインAPIを叩いて認証ヘッダーを取得する
  # これが認証の主要な方法となるため、Deviseのsign_inヘルパーは削除します
  before do
    post '/auth/sign_in', params: { email: user.email, password: user.password }

    # デバッグ出力（必要であればコメントアウトを外す）
    # puts "\n--- DEBUG: TimerSessions API Login Process ---"
    # puts "DEBUG: User Email: #{user.email}, Password: #{user.password}"
    # puts "DEBUG: Initial Login Response Status: #{response.status}"
    # puts "DEBUG: Initial Login Response Body: #{response.body}"
    # puts "DEBUG: Initial Login Response Headers: #{response.headers.inspect}"
    # puts "--- END DEBUG: TimerSessions API Login Process ---\n"

    @auth_headers = response.headers.slice('client', 'access-token', 'uid', 'expiry', 'token-type')
  end

  # let を使って @auth_headers を各テスト内で 'auth_headers' として利用可能にします
  let(:auth_headers) { @auth_headers }

  # --- POST /api/v1/timer_sessions ---
  describe "POST /api/v1/timer_sessions" do
    # 有効なパラメータの定義
    let(:valid_attributes) { attributes_for(:timer_session, user: user) }
    # 無効なパラメータの定義 (duration_minutes を nil に設定)
    let(:invalid_attributes) { attributes_for(:timer_session, duration_minutes: nil, user: user) }

    context "認証済みの場合" do
      context "有効なパラメータの場合" do
        it "新しいタイマーセッションを作成できること" do
          expect {
            post api_v1_timer_sessions_path, params: { timer_session: valid_attributes }, headers: auth_headers
          }.to change(TimerSession, :count).by(1)
          expect(response).to have_http_status(:created) # 一般的に作成成功は201 Created
          # expect(json_response['duration_minutes']).to eq(valid_attributes[:duration_minutes]) # 必要ならレスポンス内容も確認
        end
      end

      context "無効なパラメータの場合" do
        it "タイマーセッションを作成せず、エラーを返すこと" do
          expect {
            # headers: auth_headers を追加
            post api_v1_timer_sessions_path, params: { timer_session: invalid_attributes }, headers: auth_headers
          }.not_to change(TimerSession, :count)
          expect(response).to have_http_status(:unprocessable_entity)
          # 必要ならエラーメッセージの確認も追加
          # expect(json_response['errors']['duration_minutes']).to include("can't be blank")
        end
      end
    end

    context "未認証の場合" do
      it "401 Unauthorized を返すこと" do
        post api_v1_timer_sessions_path, params: { timer_session: valid_attributes } # ヘッダーなし
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # JSONレスポンスをパースするヘルパーメソッド (もし無ければ追加)
  def json_response
    JSON.parse(response.body)
  end
end