module Api
  module V1
    class ReviewsController < ApplicationController
      include DeviseTokenAuth::Concerns::SetUserByToken

      before_action :authenticate_user!

      def create
        timer_session = current_api_v1_user.timer_sessions.find_by(id: review_params[:timer_session_id])

        unless timer_session
          render json: { errors: ['指定されたタイマーセッションが見つからないか、アクセスする権限がありません。'] }, status: :not_found
          return
        end

        @review = timer_session.build_review(review_params.except(:timer_session_id))

        if @review.save
          render json: @review, status: :created
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def index
        @reviews = current_api_v1_user.reviews
          .includes(:timer_session)
          .order(created_at: :desc)
        render json: @reviews
      end

      def show
        @review = current_api_v1_user.reviews.find_by(id: params[:id])
        if @review
          render json: @review
        else
          render json: { error: "Not found" }, status: :not_found
        end
      end

      private

      def review_params
        raw = params.require(:review).permit(:rating, :comment, :timer_session_id)
        raw[:score] = raw.delete(:rating) if raw[:rating] # rating → score に変換
        raw
      end

    end
  end
end