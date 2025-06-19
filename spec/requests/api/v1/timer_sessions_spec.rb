require 'rails_helper'

RSpec.describe 'Api::V1::TimerSessions API', type: :request do
  # 各テストグループ/コンテキストで新しいユニークなユーザーをFactoryBotで作成
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) } # 他のユーザーも作成

  # 認証ヘッダーを生成し、テスト実行前に設定するためのヘルパー
  let(:authenticated_headers) do
    post '/auth/sign_in', params: { email: user.email, password: user.password }
    response.headers.slice('access-token', 'client', 'uid')
  end

  # POST /api/v1/timer_sessions
  describe 'POST /api/v1/timer_sessions' do
    context '認証済みの場合' do
      let!(:auth_headers) { authenticated_headers }

      context '有効なパラメータの場合' do
        let(:valid_attributes) do
          { timer_session: { started_at: Time.current, duration_minutes: 25 } }
        end

        it '新しいタイマーセッションを作成すること' do
          expect {
            post api_v1_timer_sessions_path, params: valid_attributes, headers: auth_headers
          }.to change(TimerSession, :count).by(1)

          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response['user_id']).to eq(user.id)
          expect(json_response['duration_minutes']).to eq(25)
          expect(json_response['started_at']).to be_present
          expect(json_response['ended_at']).to be_nil # 作成時はended_atはnil
        end

        it 'タスクID付きでタイマーセッションを作成すること' do
          task = create(:task, user: user) # ユーザーに紐づくタスクを作成
          valid_attributes_with_task = { timer_session: { started_at: Time.current, duration_minutes: 25, task_id: task.id } }

          expect {
            post api_v1_timer_sessions_path, params: valid_attributes_with_task, headers: auth_headers
          }.to change(TimerSession, :count).by(1)

          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response['task_id']).to eq(task.id)
        end
      end

      context '無効なパラメータの場合' do
        let(:invalid_attributes) do
          { timer_session: { started_at: nil, duration_minutes: 0 } } # started_atがnil, duration_minutesが0
        end

        it 'タイマーセッションを作成せず、エラーを返すこと' do
          expect {
            post api_v1_timer_sessions_path, params: invalid_attributes, headers: auth_headers
          }.not_to change(TimerSession, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include("Started at can't be blank")
          expect(json_response['errors']).to include("Duration minutes must be greater than 0")
        end
      end
    end

    context '未認証の場合' do
      let(:valid_attributes) { { timer_session: { started_at: Time.current, duration_minutes: 25 } } }

      it '401 Unauthorizedを返すこと' do
        post api_v1_timer_sessions_path, params: valid_attributes # ヘッダーなしでリクエスト
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # PATCH /api/v1/timer_sessions/:id
  describe 'PATCH /api/v1/timer_sessions/:id' do
    let!(:timer_session) { create(:timer_session, user: user, started_at: 1.hour.ago, duration_minutes: 25) }

    context '認証済みの場合' do
      let!(:auth_headers) { authenticated_headers }

      context '自分のタイマーセッションを有効なパラメータで更新する場合' do
        let(:new_ended_at) { Time.current }
        let(:update_attributes) { { timer_session: { ended_at: new_ended_at } } }

        it 'タイマーセッションを更新すること' do
          patch api_v1_timer_session_path(timer_session), params: update_attributes, headers: auth_headers
          expect(response).to have_http_status(:ok)
          timer_session.reload
          # 精度の問題があるため、数秒程度の誤差は許容する
          expect(timer_session.ended_at).to be_within(5.seconds).of(new_ended_at)
        end
      end

      context '他のユーザーのタイマーセッションを更新しようとした場合' do
        let!(:other_timer_session) { create(:timer_session, user: other_user) }
        let(:update_attributes) { { timer_session: { ended_at: Time.current } } }

        it '404 Not Foundを返すこと' do
          patch api_v1_timer_session_path(other_timer_session), params: update_attributes, headers: auth_headers
          expect(response).to have_http_status(:not_found)
          other_timer_session.reload
          expect(other_timer_session.ended_at).to be_nil # 変更されていないこと
        end
      end

      context '存在しないタイマーセッションを更新しようとした場合' do
        let(:update_attributes) { { timer_session: { ended_at: Time.current } } }

        it '404 Not Foundを返すこと' do
          patch api_v1_timer_session_path(99999), params: update_attributes, headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context '未認証の場合' do
      let(:update_attributes) { { timer_session: { ended_at: Time.current } } }

      it '401 Unauthorizedを返すこと' do
        patch api_v1_timer_session_path(timer_session), params: update_attributes # ヘッダーなし
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # GET /api/v1/timer_sessions
  describe 'GET /api/v1/timer_sessions' do
    context '認証済みの場合' do
      let!(:auth_headers) { authenticated_headers }
      let!(:my_session1) { create(:timer_session, user: user, started_at: 2.hours.ago, ended_at: 1.hour.ago) }
      let!(:my_session2) { create(:timer_session, user: user, started_at: 30.minutes.ago) }
      let!(:other_session) { create(:timer_session, user: other_user) }

      it '自分のタイマーセッション一覧を返すこと' do
        get api_v1_timer_sessions_path, headers: auth_headers
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response.size).to eq(2)
        expect(json_response.map { |s| s['id'] }).to match_array([my_session1.id, my_session2.id])
        expect(json_response.map { |s| s['id'] }).not_to include(other_session.id)

        # started_at の降順で返されることを確認 (order(started_at: :desc)を設定した場合)
        expect(json_response[0]['id']).to eq(my_session2.id)
        expect(json_response[1]['id']).to eq(my_session1.id)
      end
    end

    context '未認証の場合' do
      it '401 Unauthorizedを返すこと' do
        get api_v1_timer_sessions_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # GET /api/v1/timer_sessions/:id
  describe 'GET /api/v1/timer_sessions/:id' do
    let!(:timer_session) { create(:timer_session, user: user) }

    context '認証済みの場合' do
      let!(:auth_headers) { authenticated_headers }

      context '自分のタイマーセッションを取得する場合' do
        it 'タイマーセッションを返すこと' do
          get api_v1_timer_session_path(timer_session), headers: auth_headers
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['id']).to eq(timer_session.id)
          expect(json_response['user_id']).to eq(user.id)
        end
      end

      context '他のユーザーのタイマーセッションを取得しようとした場合' do
        let!(:other_timer_session) { create(:timer_session, user: other_user) }

        it '404 Not Foundを返すこと' do
          get api_v1_timer_session_path(other_timer_session), headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end

      context '存在しないタイマーセッションを取得しようとした場合' do
        it '404 Not Foundを返すこと' do
          get api_v1_timer_session_path(99999), headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context '未認証の場合' do
      it '401 Unauthorizedを返すこと' do
        get api_v1_timer_session_path(timer_session)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end