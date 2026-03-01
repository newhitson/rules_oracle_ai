require 'rails_helper'

RSpec.describe AnswerService do
  let(:question) { "Can a creature with flying be blocked by a creature with reach?" }
  let(:rule_sections) do
    [
      {
        section_number: "702.9b",
        title: "Flying",
        top_level_section: "Keyword Abilities",
        content: "A creature with flying can't be blocked except by creatures with flying and/or reach.",
        similarity: 0.9
      },
      {
        section_number: "702.17a",
        title: "Reach",
        top_level_section: "Keyword Abilities",
        content: "A creature with reach can block creatures with flying.",
        similarity: 0.8
      }
    ]
  end

  let(:sufficient_answer) { "Yes, a creature with reach can block a creature with flying (rule 702.9b, rule 702.17a)." }
  let(:sufficient_llm_response) do
    { "choices" => [ { "message" => { "content" => JSON.generate({ "confidence" => "sufficient", "answer" => sufficient_answer }) } } ] }
  end

  let(:insufficient_llm_response) do
    { "choices" => [ { "message" => { "content" => JSON.generate({ "confidence" => "insufficient", "message" => "The provided rules don't contain enough information to answer this question." }) } } ] }
  end

  describe '.call' do
    context 'when the LLM has sufficient information' do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(sufficient_llm_response)
      end

      it 'returns confidence: sufficient' do
        result = described_class.call(question: question, rule_sections: rule_sections)
        expect(result[:confidence]).to eq("sufficient")
      end

      it 'returns the answer' do
        result = described_class.call(question: question, rule_sections: rule_sections)
        expect(result[:answer]).to eq(sufficient_answer)
      end

      it 'returns sources with section_number, title, and content' do
        result = described_class.call(question: question, rule_sections: rule_sections)
        expect(result[:sources].first).to eq({
          section_number: "702.9b",
          title: "Flying",
          content: "A creature with flying can't be blocked except by creatures with flying and/or reach."
        })
      end

      it 'returns one source per rule section' do
        result = described_class.call(question: question, rule_sections: rule_sections)
        expect(result[:sources].length).to eq(rule_sections.length)
      end

      it 'does not include similarity in sources' do
        result = described_class.call(question: question, rule_sections: rule_sections)
        result[:sources].each do |source|
          expect(source).not_to have_key(:similarity)
        end
      end
    end

    context 'when the LLM has insufficient information' do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(insufficient_llm_response)
      end

      it 'returns confidence: insufficient' do
        result = described_class.call(question: question, rule_sections: rule_sections)
        expect(result[:confidence]).to eq("insufficient")
      end

      it 'returns a message instead of an answer' do
        result = described_class.call(question: question, rule_sections: rule_sections)
        expect(result[:message]).to be_present
        expect(result).not_to have_key(:answer)
      end

      it 'returns empty sources' do
        result = described_class.call(question: question, rule_sections: rule_sections)
        expect(result[:sources]).to eq([])
      end
    end

    context 'API call parameters' do
      before do
        allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(sufficient_llm_response)
      end

      it 'calls the OpenAI chat endpoint with the correct model' do
        expect_any_instance_of(OpenAI::Client).to receive(:chat).with(
          parameters: hash_including(model: "gpt-4o-mini")
        ).and_return(sufficient_llm_response)

        described_class.call(question: question, rule_sections: rule_sections)
      end

      it 'requests a JSON response format' do
        expect_any_instance_of(OpenAI::Client).to receive(:chat).with(
          parameters: hash_including(response_format: { type: "json_object" })
        ).and_return(sufficient_llm_response)

        described_class.call(question: question, rule_sections: rule_sections)
      end

      it 'includes the question in the user message' do
        expect_any_instance_of(OpenAI::Client).to receive(:chat) do |_, params|
          user_message = params[:parameters][:messages].find { |m| m[:role] == "user" }
          expect(user_message[:content]).to include(question)
          sufficient_llm_response
        end

        described_class.call(question: question, rule_sections: rule_sections)
      end

      it 'includes rule content in the user message' do
        expect_any_instance_of(OpenAI::Client).to receive(:chat) do |_, params|
          user_message = params[:parameters][:messages].find { |m| m[:role] == "user" }
          expect(user_message[:content]).to include("702.9b")
          expect(user_message[:content]).to include("A creature with flying")
          sufficient_llm_response
        end

        described_class.call(question: question, rule_sections: rule_sections)
      end

      it 'sends a system message' do
        expect_any_instance_of(OpenAI::Client).to receive(:chat) do |_, params|
          system_message = params[:parameters][:messages].find { |m| m[:role] == "system" }
          expect(system_message).not_to be_nil
          sufficient_llm_response
        end

        described_class.call(question: question, rule_sections: rule_sections)
      end
    end
  end
end
