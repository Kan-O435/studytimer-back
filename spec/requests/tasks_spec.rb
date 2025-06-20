# spec/requests/tasks_spec.rb
require 'rails_helper'

RSpec.describe 'Tasks API', type: :request do
  # FactoryBot でユーザーを作成
  let(:user) { create(:user).tap(&:confirm)}

  # 認証ヘッダーを格納するインスタンス変数
  # 各テストが実行される前にユーザーをログインさせ、トークンを取得します
  before do
    # Devise Token Auth のログインエンドポイントを叩く
    # params には、FactoryBot で作成したユーザーのメールアドレスとパスワードを使用します
    post '/auth/sign_in', params: { email: user.email, password: user.password }

    # レスポンスヘッダーから認証トークン情報を抽出します
    # これらのキーは devise_token_auth が返すヘッダー名に対応しています
    @auth_headers = response.headers.slice('client', 'access-token', 'uid', 'expiry', 'token-type')

    # --- デバッグ用の出力（一時的に追加） ---
    # 認証ヘッダーが正しく取得できているか確認するために使います
    puts "DEBUG: Tasks API - Generated Auth Headers: #{@auth_headers.inspect}"
    puts "DEBUG: Tasks API - Initial Login Response Status: #{response.status}"
    puts "DEBUG: Tasks API - Initial Login Response Body: #{response.body}"
    # --- デバッグ用の出力ここまで ---
  end

  # let を使って @auth_headers を各テスト内で 'auth_headers' として利用可能にします
  let(:auth_headers) { @auth_headers }

  # 有効な属性と無効な属性の定義
  let(:valid_attributes) { attributes_for(:task, user: user) } # user_id も含めるか、Factoryに紐付け設定
  let(:invalid_attributes) { attributes_for(:task, title: nil, user: user) } # 例えばタイトルがnilの場合

  # --- GET /tasks ---
  describe 'GET /tasks' do
    context '認証済みの場合' do
      it 'ユーザーのタスク一覧を返すこと' do
        # テストに必要なデータをセットアップ
        create_list(:task, 3, user: user) # ユーザーに紐付くタスクを3つ作成
        create_list(:task, 2) # 他のユーザーのタスク（このテストでは取得されないはず）

        get tasks_path, headers: auth_headers
        # --- デバッグ用の出力（一時的に追加） ---
        puts "DEBUG: Tasks API GET - Response Status: #{response.status}"
        puts "DEBUG: Tasks API GET - Response Body: #{response.body}"
        # --- デバッグ用の出力ここまで ---
        expect(response).to have_http_status(:ok)
        expect(json_response.count).to eq(3) # レスポンスのJSONに含まれるタスクの数が3であることを確認
        expect(json_response.first['user_id']).to eq(user.id) # ユーザーのタスクであることを確認
      end
    end

    context '未認証の場合' do
      it '401 Unauthorized を返すこと' do
        get tasks_path # ヘッダーなし
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # --- POST /tasks ---
  describe 'POST /tasks' do
    context '認証済みの場合' do
      context '有効なパラメータの場合' do
        it '新しいタスクを作成すること' do
          expect {
            post tasks_path, params: { task: valid_attributes }, headers: auth_headers
          }.to change(Task, :count).by(1)
          expect(response).to have_http_status(:created) # または :ok, アプリケーションの挙動による
          expect(json_response['title']).to eq(valid_attributes[:title])
        end
      end

      context '無効なパラメータの場合' do
        it 'タスクを作成せず、エラーを返すこと' do
          expect {
            post tasks_path, params: { task: invalid_attributes }, headers: auth_headers
          }.to change(Task, :count).by(0)
          expect(response).to have_http_status(:unprocessable_entity)
          # エラーメッセージがJSONで返されることを期待する場合
          # expect(json_response['title']).to include("can't be blank")
        end
      end
    end

    context '未認証の場合' do
      it '401 Unauthorized を返すこと' do
        post tasks_path, params: { task: valid_attributes } # ヘッダーなし
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # --- Helper Methods for JSON parsing (もし無ければ追加) ---
  def json_response
    JSON.parse(response.body)
  end
end