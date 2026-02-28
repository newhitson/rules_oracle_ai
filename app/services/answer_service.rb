class AnswerService
  MODEL = "gpt-4o-mini"

  def self.call(question:, rule_sections:)
    new.call(question:, rule_sections:)
  end

  def call(question:, rule_sections:)
    client = OpenAI::Client.new
    response = client.chat(parameters: { model: MODEL, messages: build_messages(question, rule_sections) })
    answer = response.dig("choices", 0, "message", "content")
    sources = rule_sections.map { |s| { section_number: s[:section_number], title: s[:title] } }
    { answer: answer, sources: sources }
  end

  private

  def build_messages(question, rule_sections)
    rules_text = rule_sections.map { |s| "#{s[:section_number]}. #{s[:title]}\n#{s[:content]}" }.join("\n\n")
    [
      { role: "system", content: "You are a Magic: The Gathering rules expert. Answer the question using the provided rules." },
      { role: "user", content: "Question: #{question}\n\nRelevant rules:\n#{rules_text}" }
    ]
  end
end
