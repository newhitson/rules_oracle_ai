class QuestionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    if params[:text].blank?
      render json: { error: "text is required" }, status: :unprocessable_content
      return
    end

    results = CompRulesEmbedding.search(params[:text]).map do |rule|
      {
        section_number: rule.section_number,
        title: rule.title,
        top_level_section: rule.top_level_section,
        content: rule.content,
        similarity: 1 - rule.neighbor_distance
      }
    end

    answer_result = AnswerService.call(question: params[:text], rule_sections: results)

    render json: { results: results, answer: answer_result[:answer], sources: answer_result[:sources] }
  end
end
