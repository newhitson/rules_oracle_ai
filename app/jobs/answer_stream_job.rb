class AnswerStreamJob < ApplicationJob
  def perform(question_id, rules)
    question = Question.find(question_id)
    stream_name = "question_#{question.id}"

    full_answer = AnswerService.stream(
      question: question.text,
      rule_sections: rules.map(&:symbolize_keys)
    ) do |chunk|
      Turbo::StreamsChannel.broadcast_append_to(
        stream_name,
        target: "answer_text",
        html: chunk
      )
    end

    confidence = full_answer.match?(/insufficient|cannot .* answer|not enough/i) ? "insufficient" : "sufficient"
    question.update!(answer: full_answer, confidence: confidence)

    sources = rules.map { |s| s.slice("section_number", "title", "content").symbolize_keys }
    Turbo::StreamsChannel.broadcast_replace_to(
      stream_name,
      target: "sources",
      partial: "questions/sources",
      locals: { sources: sources }
    )
  end
end
