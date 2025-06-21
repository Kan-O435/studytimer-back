require 'rails_helper'

RSpec.describe "Api::V1::Reviews", type: :request do
  let(:user) { create(:user).tap(&:confirm)}
  # devise_token_auth を使用するため、リクエストヘッダーに含める認証情報を生成
  before do
    post '/auth/sign_in', params: { email: user.email, password: user.password }
    @auth_headers = response.headers.slice('client', 'access-token', 'uid', 'expiry', 'token-type')
  end

  # let を使って @auth_headers を参照
  let(:auth_headers) { @auth_headers }


  describe "GET /api/v1/reviews" do
    context "認証済みのユーザーの場合" do
      it "自身のレビュー一覧を返すこと" do
        # テストデータとして、同じユーザーに紐づくレビューを複数作成
        # FactoryBotでtimer_sessionも自動で作成される
        create_list(:review, 3, user: user)

        get api_v1_reviews_path, headers: auth_headers
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
      end
    end

    context "未認証のユーザーの場合" do
      it "401 Unauthorized を返すこと" do
        get api_v1_reviews_path # auth_headers を含めない
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/reviews" do
    let!(:timer_session) { create(:timer_session, user: user) }

    context "認証済みのユーザーの場合" do
      context "有効なパラメータの場合" do
        let(:valid_attributes) { attributes_for(:review, timer_session_id: timer_session.id) }

        it "新しいレビューを作成できること" do
          expect do
            post api_v1_reviews_path, params: { review: valid_attributes }, headers: auth_headers
          end.to change(Review, :count).by(1)
          expect(response).to have_http_status(:created)
        end
      end

      context "無効なパラメータの場合" do
        # score が必須なので、nil を指定
        let(:invalid_attributes) { attributes_for(:review, score: nil, timer_session_id: timer_session.id) }

        it "レビューを作成できず、エラーを返すこと" do
          expect do
            post api_v1_reviews_path, params: { review: invalid_attributes }, headers: auth_headers
          end.not_to change(Review, :count)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "未認証のユーザーの場合" do
      let(:valid_attributes) { attributes_for(:review, timer_session_id: timer_session.id) }

      it "401 Unauthorized を返すこと" do
        post api_v1_reviews_path, params: { review: valid_attributes } # auth_headers を含めない
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/reviews/:id" do
    let!(:review) { create(:review, user: user) }

    context "認証済みのユーザーの場合" do
      context "自身のレビューの場合" do
        it "レビューの詳細を返すこと" do
          get api_v1_review_path(review), headers: auth_headers
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['id']).to eq(review.id)
        end
      end

      context "他人のレビューの場合" do
        let!(:other_user) { create(:user) }
        let!(:other_review) { create(:review, user: other_user) }

        it "404 Not Found を返すこと" do
          get api_v1_review_path(other_review), headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "未認証のユーザーの場合" do
      it "401 Unauthorized を返すこと" do
        get api_v1_review_path(review)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
