class Api::V1::TimerSessionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_timer_session, only: [:show,:update]

    def create
       @timer_session = current_user.timer_sessions.build(timer_session_params)

        if @timer_session.save
            render json: @timer_session,status: :created
        else
            render json: {errors: @timer_session.errors.full_messages},status: :unprocessable_entity
        end
    end

    def update
        if @timer_session.update(timer_session_params)
            render json: @timer_session
        else
            render json: {errors: @timer_session.errors.full_messages}, status: :unprocessable_entity
        end
    end

    def index
        @timer_sessions=current_user.timer_sessions.order(started_at: :desc)
        render json: @timer_sessions
    end

    def show
        render json: @timer_session
    end

    private

    def set_timer_session
        @timer_session = current_user.timer_sessions.find_by(id: params[:id])
        unless @timer_session
            render json: {error: "Timer session not found or not authorized"},status: :not_found
        end
    end

    def timer_session_params
        params.require(:timer_session).permit(:started_at,:ended_at,:duration_minutes,:task_id)
    end

end
