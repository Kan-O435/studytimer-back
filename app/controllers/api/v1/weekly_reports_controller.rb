require 'net/http'
require 'uri'
require 'json'

class Api::V1::WeeklyReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    user = current_user

    week_offset = params[:week_offset].to_i
    
    start_of_week_calculated = Time.zone.now.beginning_of_week - week_offset.weeks
    end_of_week_calculated = Time.zone.now.end_of_week - week_offset.weeks

    actual_data_end_time = [Time.zone.now, end_of_week_calculated].min

    query_start_time = start_of_week_calculated.beginning_of_day
    query_end_time = actual_data_end_time.end_of_day

    recent_sessions = user.timer_sessions
                          .includes(:review, :task)
                          .where(started_at: query_start_time..query_end_time)
                          .order(:started_at)

    weekly_data_hash = {}
 
    (0..6).each do |i|

      date_obj = start_of_week_calculated.to_date + i.days
      date_key = date_obj.strftime("%Y-%m-%d")
      
      weekly_data_hash[date_key] = {

        date: date_obj.strftime("%Y年%m月%d日 (%a)"),
        total_duration_minutes: 0,
        ratings_for_average: [],
        sessions: []
      }
    end

    recent_sessions.each do |session|

      date_str = session.started_at.to_date.strftime("%Y-%m-%d")

      next unless weekly_data_hash[date_str]

      daily_data = weekly_data_hash[date_str]
      daily_data[:total_duration_minutes] += session.duration_minutes.to_i

      if session.review&.score.present? 
        daily_data[:ratings_for_average] << session.review.score 
      end

      daily_data[:sessions] << {
        id: session.id,
        task_title: session.task&.title || '（タスクなし）',
        duration_minutes: session.duration_minutes.to_i,
        rating: session.review&.score,
        comment: session.review&.comment
      }
    end

    sorted_weekly_data = weekly_data_hash.keys.sort.map do |date_key|
      data = weekly_data_hash[date_key]

      if data[:ratings_for_average].any?
        data[:average_rating] = (data[:ratings_for_average].sum.to_f / data[:ratings_for_average].size).round(1)
      else
        data[:average_rating] = nil
      end

      data.except(:ratings_for_average) 
    end

    llm_summary = call_llm_api(sorted_weekly_data)

    render json: {
      data: sorted_weekly_data,
      summary: llm_summary
    }
  end

  private

  def call_llm_api(weekly_data_for_lambda)
    request_body = {
      data: weekly_data_for_lambda
    }.to_json

    uri = URI.parse("https://oxe9emrp95.execute-api.ap-southeast-2.amazonaws.com/dev/weekly_report")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    req.body = request_body

    Rails.logger.info("Sending to Lambda (size: #{request_body.bytesize} bytes): #{request_body}") 

    res = http.request(req)

    if res.is_a?(Net::HTTPSuccess)
      begin
        json_response = JSON.parse(res.body)

        Rails.logger.info("Received from Lambda: #{json_response}") 

        if json_response.is_a?(Hash) && json_response['summary'].is_a?(String)
          return json_response['summary']
        else
          Rails.logger.warn("LLM API応答形式が不正: summaryキーが見つからないか文字列ではありません。Raw body: #{res.body}")
          return "LLMからの要約が取得できませんでした。"
        end
      rescue JSON::ParserError => e
        Rails.logger.warn("LLM APIレスポンスのJSONパース失敗: #{e.message}, Raw body: #{res.body}")
        return "LLMからの要約の解析に失敗しました。"
      end
    else
      Rails.logger.warn("LLM APIリクエスト失敗: HTTP Status #{res.code}, Body: #{res.body}")
      return "LLMからの要約の取得に失敗しました。(HTTP #{res.code})"
    end
  rescue StandardError => e
    Rails.logger.error("LLM APIリクエスト中に予期せぬ例外が発生: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}") # エラーを詳細にログ
    return "LLM要約サービスとの通信中にエラーが発生しました。"
  end
end