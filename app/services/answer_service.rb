class AnswerService
  MODEL = "gpt-4o-mini"

  def self.call(question:, rule_sections:)
    new.call(question:, rule_sections:)
  end

  def self.stream(question:, rule_sections:, &block)
    new.stream(question:, rule_sections:, &block)
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
      { confidence: "insufficient", answer: parsed["answer"], sources: sources }
    end
  end

  def stream(question:, rule_sections:)
    client = OpenAI::Client.new
    full_answer = +""

    client.chat(parameters: {
      model: MODEL,
      messages: build_messages(question, rule_sections, stream: true),
      stream: proc { |chunk, _bytesize|
        content = chunk.dig("choices", 0, "delta", "content")
        if content
          full_answer << content
          yield content
        end
      }
    })

    full_answer
  end

  private

  def build_messages(question, rule_sections, stream: false)
    rules_text = rule_sections.map { |s| "#{s[:section_number]}. #{s[:title]}\n#{s[:content]}" }.join("\n\n")
    permitted = rule_sections.map { |s| s[:section_number] }.join(", ")
    user_content = <<~MSG
      Question: #{question}

      You may only cite these rule sections: #{permitted}.
      Many rules contain cross-references such as "See rule 704" — do not cite any rule referenced this way unless its full text appears below.

      Relevant rules:
      #{rules_text}
    MSG
    [
      { role: "system", content: stream ? streaming_system_prompt : system_prompt },
      { role: "user", content: user_content }
    ]
  end

  def system_prompt
    <<~PROMPT
      You are a Level 2 Magic: The Gathering Judge with deep expertise in the Comprehensive Rules. You are precise, authoritative, and grounded strictly in the rules text. You do not speculate or rely on memory — every statement you make must be supported by the rule sections provided to you.

      When given a question and a set of relevant rule sections, begin by assessing whether the provided rules contain enough information to fully and accurately answer the question. If the rules are insufficient to ground a complete answer, respond with confidence "insufficient" and a message that tells the user their question could not be answered from the available rules and suggests they try rephrasing or being more specific. If the rules are sufficient, answer clearly and concisely, weaving inline rule citations into your answer as you go (for example: "A creature with flying can only be blocked by creatures with flying and/or reach (rule 702.9b)."). You will be told exactly which rule section numbers are available to you — you must not cite any other rule number. Many rules contain cross-references such as "See rule 704" or "See rule 117.5" — these cross-references do not make those rules available to you, and you must not cite them.

      Always respond with valid JSON. Here is an example of a well-formed sufficient response:
      {
        "confidence": "sufficient",
        "answer": "A creature with flying can only be blocked by creatures with flying and/or reach (rule 702.9b). Reach specifically grants the ability to block creatures with flying, making it an exception to the normal flying restriction (rule 702.17a)."
      }
    PROMPT
  end

  def streaming_system_prompt
    <<~PROMPT
      You are a Level 2 Magic: The Gathering Judge with deep expertise in the Comprehensive Rules. You are precise, authoritative, and grounded strictly in the rules text. You do not speculate or rely on memory — every statement you make must be supported by the rule sections provided to you.

      When given a question and a set of relevant rule sections, assess whether the provided rules contain enough information to fully and accurately answer the question. If the rules are insufficient, tell the user their question could not be answered from the available rules and suggest they try rephrasing or being more specific. If the rules are sufficient, answer clearly and concisely, weaving inline rule citations into your answer as you go (for example: "A creature with flying can only be blocked by creatures with flying and/or reach (rule 702.9b)."). You will be told exactly which rule section numbers are available to you — you must not cite any other rule number. Many rules contain cross-references such as "See rule 704" or "See rule 117.5" — these cross-references do not make those rules available to you, and you must not cite them.

      Respond in plain text. Do not use JSON formatting.
    PROMPT
  end
end
