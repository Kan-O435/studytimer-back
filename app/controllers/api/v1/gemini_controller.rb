class Api::V1::GeminiController < ApplicationController
  def summary
    learning_log = params[:learning_log]
    unless learning_log.present?
      render json: { error: "learning_logパラメータが必要です" }, status: :bad_request and return
    end

    prompt_text = <<~PROMPT
      以下の学習記録を元に、一週間の総括とコメントを日本語で簡潔に作成してください。

      学習記録:
      #{learning_log}
    PROMPT

    begin
      client = GeminiClient.new
      summary_text = client.generate_text(prompt_text)
      render json: { summary: summary_text }
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
