class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :load_recent_questions, unless: -> { request.format.json? }

  private

  def load_recent_questions
    @recent_questions = Question.where.not(confidence: "pending").order(created_at: :desc).limit(10)
  end
end
