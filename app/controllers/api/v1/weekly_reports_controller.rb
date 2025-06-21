class Api::V1::WeeklyReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    user = current_user

    # クエリパラメータから week_offset を取得（なければ0＝今週）
    week_offset = params[:week_offset].to_i

    # 週の始まりと終わりを計算（例：week_offset = 1 なら先週）
    end_of_week = Date.current.beginning_of_week - 7 * week_offset.days + 6.days
    start_of_week = end_of_week - 6.days

    recent_sessions = user.timer_sessions
                          .includes(:review, :task)
                          .where(started_at: start_of_week.beginning_of_day..end_of_week.end_of_day)
                          .order(started_at: :asc)

    weekly_data_hash = {}

    (0..6).each do |i|
      date_obj = start_of_week + i.days
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
      daily_data[:ratings] << session.review.score if session.review&.score

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

    sorted_weekly_data = weekly_data.sort_by { |data| data[:date] }

    render json: {
      data: sorted_weekly_data,
      summary: nil # 将来的に要約なども返す場合に備えて
    }
  end
end
