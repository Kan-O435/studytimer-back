require 'net/http'
require 'uri'
require 'json'

class GeminiFeedbackService
  GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

  def initialize(api_key:)
    @api_key = api_key
  end

  def generate_feedback(sessions)
    prompt = build_prompt(sessions)
    uri = URI("#{GEMINI_API_URL}?key=#{@api_key}")

    response = Net::HTTP.post(uri, {
      contents: [{ parts: [{ text: prompt }] }]
    }.to_json, { "Content-Type" => "application/json" })

    json = JSON.parse(response.body)
    json.dig("candidates", 0, "content", "parts", 0, "text")
  rescue => e
    Rails.logger.error("Gemini Error: #{e.message}")
    nil
  end

  private

  def build_prompt(sessions)
    <<~PROMPT
      以下はユーザーが1週間で記録した学習セッションのデータです。
      各日付、学習時間、評価、コメントが含まれています。

      この情報をもとに1週間の学習の総括フィードバックを300字以内で生成してください。
      特に学習が少ない日があれば少し厳しめのコメントも含めてください。

      セッション情報：
      #{sessions.map { |s| "#{s[:date]} - #{s[:duration]}分 - 評価: #{s[:rating] || "なし"} - #{s[:comment] || "コメントなし"}" }.join("\n")}
    PROMPT
  end
end
