# spec/requests/api/v1/weekly_reports_spec.rb

require 'rails_helper'

RSpec.describe 'Api::V1::WeeklyReports', type: :request do
  # FactoryBotでユーザーを生成し、メール認証を完了させる (必要に応じて)
  let(:user) { create(:user).tap(&:confirm) }
  # devise_token_authの認証ヘッダーを生成
  let!(:auth_headers) { user.create_new_auth_token }

  # テストデータ準備: 過去7日間のテストデータを作成
  before do
    # FactoryBotを使いテストデータを準備
    # 例: 3日前のセッション
    create(:timer_session, user: user, started_at: 3.days.ago.beginning_of_day + 1.hour,
                           ended_at: 3.days.ago.beginning_of_day + 2.hours, duration_minutes: 60)
    # 3日前の別のセッションで評価あり
    session_with_review = create(:timer_session, user: user, started_at: 3.days.ago.beginning_of_day + 3.hours,
                                               ended_at: 3.days.ago.beginning_of_day + 3.hours + 30.minutes, duration_minutes: 30)
    # ここを 'rating: 5' から 'score: 5' に変更
    create(:review, timer_session: session_with_review, score: 5, comment: "とても集中できた！")

    # 1日前のセッション
    create(:timer_session, user: user, started_at: 1.day.ago.beginning_of_day + 9.hours,
                           ended_at: 1.day.ago.beginning_of_day + 9.hours + 45.minutes, duration_minutes: 45)
    # 今日のセッションで評価あり
    today_session = create(:timer_session, user: user, started_at: Date.current.beginning_of_day + 10.hours,
                                           ended_at: Date.current.beginning_of_day + 11.hours, duration_minutes: 60)
    # ここを 'rating: 4' から 'score: 4' に変更
    create(:review, timer_session: today_session, score: 4, comment: "まずまず")
  end

  describe 'GET /api/v1/weekly_reports' do
    context '認証済みユーザーの場合' do
      before do
        get api_v1_weekly_reports_path, headers: auth_headers
      end

      it 'HTTPステータスコード200を返すこと' do
        expect(response).to have_http_status(:ok) # 200 OK
      end

      it 'Content-TypeがJSONであること' do
        expect(response.content_type).to include('application/json')
      end

      it '週次レポートデータが返されること' do
        json_response = JSON.parse(response.body)
        expect(json_response).to be_an(Array)
        expect(json_response.length).to be_between(1, 7).inclusive # データがある日数分（最大7日）

        # 今日と3日前のデータが存在することを確認
        today_data = json_response.find { |data| data['date'].include?(Date.current.strftime("%Y年%m月%d日")) }
        three_days_ago_data = json_response.find { |data| data['date'].include?((Date.current - 3.days).strftime("%Y年%m月%d日")) }

        expect(today_data).to be_present
        expect(today_data['total_duration_minutes']).to eq(60)
        expect(today_data['average_rating']).to eq(4.0)
        expect(today_data['llm_feedback']).to be_nil # 現在nilなので
        expect(today_data['sessions']).to be_an(Array)
        expect(today_data['sessions'].first['task_title']).to be_present # タスクタイトルがあること

        expect(three_days_ago_data).to be_present
        expect(three_days_ago_data['total_duration_minutes']).to eq(90) # 60 + 30
        expect(three_days_ago_data['average_rating']).to eq(5.0) # 評価が5のセッションのみ
        expect(three_days_ago_data['sessions']).to be_an(Array)
        expect(three_days_ago_data['sessions'].length).to eq(2) # 2つのセッション
      end

      it 'データがない日はdurationが0で返されること' do
        # 2日前 (今日から2日前) のデータは作成していないので、total_duration_minutesが0であることを確認
        two_days_ago_data = JSON.parse(response.body).find { |data| data['date'].include?((Date.current - 2.days).strftime("%Y年%m月%d日")) }
        expect(two_days_ago_data).to be_present
        expect(two_days_ago_data['total_duration_minutes']).to eq(0)
        expect(two_days_ago_data['average_rating']).to be_nil # 評価がないのでnil
        expect(two_days_ago_data['llm_feedback']).to be_nil
        expect(two_days_ago_data['sessions']).to be_empty
      end

      # 必要であれば、日付範囲フィルタリングのテストも追加できます
      # 例: 特定の期間をクエリパラメータで指定した場合など
    end

    context '認証されていないユーザーの場合' do
      before do
        # 認証ヘッダーなしでリクエスト
        get api_v1_weekly_reports_path
      end

      it 'HTTPステータスコード401 Unauthorizedを返すこと' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'エラーメッセージを返すこと' do
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include('You need to sign in or sign up before continuing.')
      end
    end
  end
end