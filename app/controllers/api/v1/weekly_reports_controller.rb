# app/controllers/api/v1/weekly_reports_controller.rb
require 'net/http'
require 'uri'
require 'json'

class Api::V1::WeeklyReportsController < ApplicationController
  before_action :authenticate_user! # DeviseTokenAuthの認証済みユーザーのみアクセス可

  def index
    user = current_user

    # パラメータで週のオフセット指定（0: 今週、1:先週、など）
    week_offset = params[:week_offset].to_i

    # --- 週の期間計算の修正 ---
    # Time.zone.now を使用して、アプリケーションのタイムゾーン設定を考慮
    # Railsのconfig.active_support.beginning_of_week設定に従う
    
    # 週の始まりと終わりを計算
    # 例: config.active_support.beginning_of_week = :monday の場合
    #   今日が2025-06-22 (日) の場合:
    #   Time.zone.now.beginning_of_week => 2025-06-16 00:00:00 +0900 (月曜日)
    #   Time.zone.now.end_of_week => 2025-06-22 23:59:59 +0900 (日曜日)
    
    start_of_week_calculated = Time.zone.now.beginning_of_week - week_offset.weeks
    end_of_week_calculated = Time.zone.now.end_of_week - week_offset.weeks

    # データ取得の終了日を今日（Time.zone.now）か、計算した週の終わりか、いずれか早い方にする
    # これにより、未来のデータを含めずに、今日までのデータが確実に含まれる
    actual_data_end_time = [Time.zone.now, end_of_week_calculated].min

    # クエリに使う範囲は beginning_of_day..end_of_day を確実に適用
    query_start_time = start_of_week_calculated.beginning_of_day
    query_end_time = actual_data_end_time.end_of_day
    # --- ここまで週の期間計算の修正 ---

    # 週の期間内に開始したTimerSessionを取得（レビュー・タスクも一緒に読み込み）
    recent_sessions = user.timer_sessions
                          .includes(:review, :task)
                          .where(started_at: query_start_time..query_end_time)
                          .order(:started_at)

    # 1週間の日ごとの空データを用意
    weekly_data_hash = {}
    # 検索対象の週の7日間を全て初期化
    (0..6).each do |i|
      # ここでは日付オブジェクトとして扱い、後に文字列に変換
      date_obj = start_of_week_calculated.to_date + i.days
      date_key = date_obj.strftime("%Y-%m-%d")
      
      weekly_data_hash[date_key] = {
        # 日付表示形式はLambdaに送るデータに含める
        date: date_obj.strftime("%Y年%m月%d日 (%a)"),
        total_duration_minutes: 0,
        ratings_for_average: [], # 平均評価計算用の一時的な配列名を変更
        sessions: []
      }
    end

    # セッションごとに日付ごとのデータに集約
    recent_sessions.each do |session|
      # session.started_at は DateTime オブジェクトなので to_date で日付部分のみ取得
      date_str = session.started_at.to_date.strftime("%Y-%m-%d")
      
      # weekly_data_hashに存在しない日付（週の範囲外）のセッションはスキップ
      # これは通常起こらないはずだが、念のため
      next unless weekly_data_hash[date_str]

      daily_data = weekly_data_hash[date_str]
      daily_data[:total_duration_minutes] += session.duration_minutes.to_i # nil対策でto_i

      # レビューが存在し、scoreがある場合のみratings_for_averageに追加
      if session.review&.score.present? 
        daily_data[:ratings_for_average] << session.review.score 
      end

      daily_data[:sessions] << {
        id: session.id,
        task_title: session.task&.title || '（タスクなし）', # タスクがない場合を考慮
        duration_minutes: session.duration_minutes.to_i, # nil対策
        rating: session.review&.score, # レビューが存在しない場合はnil
        comment: session.review&.comment # レビューが存在しない場合はnil
      }
    end

    # 最終的な weekly_data を構築（ratings_for_averageを削除し、average_ratingを計算）
    # 日付キーでソートしてからmapすることで、確実に日付順になる
    sorted_weekly_data = weekly_data_hash.keys.sort.map do |date_key|
      data = weekly_data_hash[date_key]
      
      # 平均評価の計算
      if data[:ratings_for_average].any?
        data[:average_rating] = (data[:ratings_for_average].sum.to_f / data[:ratings_for_average].size).round(1)
      else
        data[:average_rating] = nil # 評価がない場合はnil
      end
      
      # 一時的な ratings_for_average キーを削除して新しいハッシュとして返す
      data.except(:ratings_for_average) 
    end

    # LLM要約呼び出し
    # Lambda関数は {"data": [...]} の形式を期待しているため、そのように送る
    llm_summary = call_llm_api(sorted_weekly_data)

    # JSONレスポンス返却
    render json: {
      data: sorted_weekly_data,
      summary: llm_summary
    }
  end

  private

  def call_llm_api(weekly_data_for_lambda)
    request_body = {
      data: weekly_data_for_lambda # Lambdaの期待するキー名に合わせる
    }.to_json

    # LambdaのAPI Gatewayエンドポイント
    uri = URI.parse("https://oxe9emrp95.execute-api.ap-southeast-2.amazonaws.com/dev/weekly_report")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true # HTTPSの場合

    req = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    req.body = request_body

    # 送信内容をRailsログに出力
    Rails.logger.info("Sending to Lambda (size: #{request_body.bytesize} bytes): #{request_body}") 

    res = http.request(req)

    if res.is_a?(Net::HTTPSuccess)
      begin
        json_response = JSON.parse(res.body)
        # Lambdaからの応答をRailsログに出力
        Rails.logger.info("Received from Lambda: #{json_response}") 
        
        # Lambdaのレスポンスが 'summary' キーを持つことを想定
        if json_response.is_a?(Hash) && json_response['summary'].is_a?(String)
          return json_response['summary']
        else
          Rails.logger.warn("LLM API応答形式が不正: summaryキーが見つからないか文字列ではありません。Raw body: #{res.body}")
          return "LLMからの要約が取得できませんでした。" # よりユーザーフレンドリーなメッセージ
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