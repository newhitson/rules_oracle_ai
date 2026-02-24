class QuestionsController < ApplicationController
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

    render json: { results: results }
  end
end
