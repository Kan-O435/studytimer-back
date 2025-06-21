class Api::V1::WeeklyReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    today = Date.current
    user = current_user

    recent_sessions = user.timer_sessions
                          .includes(:review, :task)
                          .where(started_at: (today - 6.days).beginning_of_day..today.end_of_day)
                          .order(started_at: :asc)

    weekly_data_hash = {}

    (0..6).each do |i|
      date_obj = today - i.days
      date_key = date_obj.strftime("%Y-%m-%d")
      weekly_data_hash[date_key] = {
        date: date_obj.strftime("%Y年%m月%d日 (%a)"),
        total_duration_minutes: 0,
        ratings: [],
        average_rating: nil,
        llm_feedback: nil,
        sessions: []
      }
    end

    recent_sessions.each do |session|
      session_date_str = session.started_at.strftime("%Y-%m-%d")

      next unless weekly_data_hash[session_date_str]

      daily_data = weekly_data_hash[session_date_str]
      daily_data[:total_duration_minutes] += session.duration_minutes

      if session.review&.score
        daily_data[:ratings] << session.review.score
      end

      daily_data[:sessions] << {
        id: session.id,
        task_title: session.task&.title || '（タスクなし）',
        duration_minutes: session.duration_minutes,
        rating: session.review&.score,
        comment: session.review&.comment
      }
    end

    weekly_data = weekly_data_hash.values.map do |data|
      if data[:ratings].any?
        data[:average_rating] = (data[:ratings].sum.to_f / data[:ratings].size).round(1)
      end
      data.delete(:ratings)
      data
    end

    sorted_weekly_data = weekly_data.sort_by { |data| data[:date] }.reverse

    render json: sorted_weekly_data
  end
end
