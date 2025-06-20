# app/controllers/api/v1/reviews_controller.rb
class Api::V1::ReviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    @review = current_user.reviews.build(review_params)

    if @review.save
      render json: @review, status: :created
    else
      render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    @reviews = current_user.reviews
      .includes(:timer_session)
      .order(created_at: :desc)
    render json: @reviews
  end

  def show
    @review = current_user.reviews.find_by(id: params[:id])
    if @review
      render json: @review
    else
      render json: { error: "Not found" }, status: :not_found
    end
  end

  private

  def review_params
    params.require(:review).permit(:score, :rating, :comment, :timer_session_id)
  end
end
