require 'net/http'
require 'uri'
require 'json'

class GeminiClient
  GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

  def initialize
    @api_key = ENV['GEMINI_API_KEY']
  end

  def generate_weekly_summary(prompt)
    uri = URI.parse("#{GEMINI_ENDPOINT}?key=#{@api_key}")

    headers = { 'Content-Type': 'application/json' }
    body = {
      contents: [
        {
          parts: [{ text: prompt }]
        }
      ]
    }

    response = Net::HTTP.post(uri, body.to_json, headers)
    parsed = JSON.parse(response.body)

    parsed.dig("candidates", 0, "content", "parts", 0, "text")
  rescue => e
    Rails.logger.error("Gemini API error: #{e.message}")
    nil
  end
end
