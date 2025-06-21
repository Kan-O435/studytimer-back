# app/services/llm_feedback_service.rb
require 'net/http'
require 'uri'
require 'json'

class LlmFeedbackService
  LAMBDA_URL = 'https://oxe9emrp95.execute-api.ap-southeast-2.amazonaws.com/dev/weekly_report'

  def self.get_feedback(weekly_summary:)
    uri = URI.parse(LAMBDA_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = { summary: weekly_summary }.to_json

    response = http.request(request)
    unless response.is_a?(Net::HTTPSuccess)
      raise "LLMリクエストエラー: #{response.code}"
    end

    raw_message = JSON.parse(response.body)['message']

    # 二重引用符付き文字列の場合はもう一度パースして外す
    if raw_message.is_a?(String) && raw_message.start_with?('"') && raw_message.end_with?('"')
      feedback = JSON.parse(raw_message)
    else
      feedback = raw_message
    end

    feedback
  rescue => e
    Rails.logger.error("LLMへのリクエストに失敗しました: #{e.message}")
    nil
  end
end
