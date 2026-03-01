class AnswerService
  MODEL = "gpt-4o-mini"

  def self.call(question:, rule_sections:)
    new.call(question:, rule_sections:)
  end

  def call(question:, rule_sections:)
    client = OpenAI::Client.new
    response = client.chat(parameters: {
      model: MODEL,
      messages: build_messages(question, rule_sections),
      response_format: { type: "json_object" }
    })

    parsed = JSON.parse(response.dig("choices", 0, "message", "content"))
    sources = rule_sections.map { |s| { section_number: s[:section_number], title: s[:title], content: s[:content] } }

    if parsed["confidence"] == "sufficient"
      { confidence: "sufficient", answer: parsed["answer"], sources: sources }
    else
      { confidence: "insufficient", message: parsed["message"], sources: [] }
    end
  end

  private

  def build_messages(question, rule_sections)
    rules_text = rule_sections.map { |s| "#{s[:section_number]}. #{s[:title]}\n#{s[:content]}" }.join("\n\n")
    [
      { role: "system", content: system_prompt },
      { role: "user", content: "Question: #{question}\n\nRelevant rules:\n#{rules_text}" }
    ]
  end

  def system_prompt
    <<~PROMPT
      You are a Level 2 Magic: The Gathering Judge with deep expertise in the Comprehensive Rules. You are precise, authoritative, and grounded strictly in the rules text. You do not speculate or rely on memory — every statement you make must be supported by the rule sections provided to you.

      When given a question and a set of relevant rule sections, begin by assessing whether the provided rules contain enough information to fully and accurately answer the question. If the rules are insufficient to ground a complete answer, respond with confidence "insufficient" and a message that tells the user their question could not be answered from the available rules and suggests they try rephrasing or being more specific. If the rules are sufficient, answer clearly and concisely, weaving inline rule citations into your answer as you go (for example: "A creature with flying can only be blocked by creatures with flying and/or reach (rule 702.9b).").

      Always respond with valid JSON. Here is an example of a well-formed sufficient response:
      {
        "confidence": "sufficient",
        "answer": "A creature with flying can only be blocked by creatures with flying and/or reach (rule 702.9b). Reach specifically grants the ability to block creatures with flying, making it an exception to the normal flying restriction (rule 702.17a)."
      }
    PROMPT
  end
end
