require 'rails_helper'

RSpec.describe 'Tasks API', type: :request do
  # 各テストグループ/コンテキストで新しいユニークなユーザーをFactoryBotで作成
  # FactoryBotのsequence(:email)でメールアドレスの重複問題を解決済み
  let!(:user) { create(:user) }

  # 認証ヘッダーを生成し、テスト実行前に設定するためのヘルパー
  # このメソッドは一度だけ実行し、その結果をキャッシュする
  # リクエストスペックのコンテキスト（self）でpostメソッドが利用可能
  let(:authenticated_headers) do
    # Devise-token-auth のサインインエンドポイント
    post '/auth/sign_in', params: { email: user.email, password: user.password }
    # レスポンスヘッダーから認証情報を抽出
    response.headers.slice('access-token', 'client', 'uid')
  end

  # GET /tasks のテスト
  describe 'GET /tasks' do
    context '認証済みの場合' do
      # このcontext内のテストが実行される前に認証ヘッダーを評価し、利用可能にする
      let!(:auth_headers) { authenticated_headers }

      it 'ユーザーのタスク一覧を返すこと' do
        # 自分のタスクを作成
        task1 = create(:task, user: user, title: 'My Task 1')
        task2 = create(:task, user: user, title: 'My Task 2')

        # 他のユーザーのタスクを作成（メールアドレス重複はFactoryBotで解決済み）
        other_user = create(:user)
        create(:task, user: other_user, title: 'Other User Task')

        # 認証ヘッダーを付けてGETリクエストを送信
        get tasks_path, headers: auth_headers

        # レスポンスの検証
        expect(response).to have_http_status(:ok) # HTTPステータスが200 OKであること
        json_response = JSON.parse(response.body)

        # 自分のタスクのみが返されることを確認
        expect(json_response.size).to eq(2)
        expect(json_response.map { |t| t['id'] }).to match_array([task1.id, task2.id])
        expect(json_response.map { |t| t['title'] }).to include('My Task 1', 'My Task 2')
        expect(json_response.map { |t| t['title'] }).not_to include('Other User Task')
      end
    end

    context '未認証の場合' do
      it '401 Unauthorizedを返すこと' do
        get tasks_path # ヘッダーなしでリクエスト
        expect(response).to have_http_status(:unauthorized) # HTTPステータスが401 Unauthorizedであること
      end
    end
  end

  # POST /tasks のテスト
  describe 'POST /tasks' do
    context '認証済みの場合' do
      let!(:auth_headers) { authenticated_headers }

      context '有効なパラメータの場合' do
        let(:valid_attributes) { { task: { title: 'New Task' } } }

        it '新しいタスクを作成すること' do
          expect {
            post tasks_path, params: valid_attributes, headers: auth_headers
          }.to change(Task, :count).by(1)

          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response['title']).to eq('New Task')
          expect(json_response['user_id']).to eq(user.id)
        end
      end

      context '無効なパラメータの場合' do
        # この行の波括弧 `{` に対応する `}` がファイルの最後まで見つからない、というのがエラーの原因です
        let(:invalid_attributes) { { task: { title: '' } } } # ここで正しく閉じられているか確認！

        it 'タスクを作成せず、エラーを返すこと' do
          expect {
            post tasks_path, params: invalid_attributes, headers: auth_headers
          }.not_to change(Task, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to be_an(Array)
          expect(json_response['errors']).to include("Title can't be blank")
        end
      end
    end # ここも大事な `end` です。`context '認証済みの場合'` を閉じる

    context '未認証の場合' do
      let(:valid_attributes) { { task: { title: 'New Task' } } }

      it '401 Unauthorizedを返すこと' do
        post tasks_path, params: valid_attributes
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end # `describe 'POST /tasks'` を閉じる

  # ... (DELETE /tasks/:id のコードは省略) ...

end # `RSpec.describe 'Tasks API', type: :request do` を閉じる