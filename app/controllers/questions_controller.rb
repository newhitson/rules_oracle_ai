class QuestionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  rate_limit to: 50, within: 24.hours, only: :create,
             with: -> { render json: { error: "rate limit exceeded" }, status: :too_many_requests }

  def new
  end

  def create
    if params[:text].blank?
      respond_to do |format|
        format.json { render json: { error: "text is required" }, status: :unprocessable_content }
        format.html { @error = "Please enter a question."; render :new, status: :unprocessable_content }
      end
      return
    end

    rules = CompRulesEmbedding.search(params[:text]).map do |rule|
      {
        section_number: rule.section_number,
        title: rule.title,
        top_level_section: rule.top_level_section,
        content: rule.content,
        similarity: 1 - rule.neighbor_distance
      }
    end

    answer_result = AnswerService.call(question: params[:text], rule_sections: rules)

    Question.create!(
      text: params[:text],
      confidence: answer_result[:confidence],
      answer: answer_result[:answer],
      message: answer_result[:message],
      sources: answer_result[:sources]
    )

    respond_to do |format|
      format.json { render json: { answer: answer_result[:answer], sources: answer_result[:sources] } }
      format.html do
        @question_text = params[:text]
        @answer = answer_result[:answer]
        @sources = answer_result[:sources]
        render :new
      end
    end
  end
end
