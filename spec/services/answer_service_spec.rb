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

  let(:fake_answer) { "Yes, a creature with reach can block a creature with flying." }
  let(:fake_response) do
    { "choices" => [ { "message" => { "content" => fake_answer } } ] }
  end

  before do
    allow_any_instance_of(OpenAI::Client).to receive(:chat).and_return(fake_response)
  end

  describe '.call' do
    it 'returns a hash with an answer key' do
      result = described_class.call(question: question, rule_sections: rule_sections)
      expect(result[:answer]).to eq(fake_answer)
    end

    it 'returns a hash with a sources key' do
      result = described_class.call(question: question, rule_sections: rule_sections)
      expect(result[:sources]).to be_an(Array)
    end

    it 'includes section_number and title in each source' do
      result = described_class.call(question: question, rule_sections: rule_sections)
      expect(result[:sources].first).to eq({ section_number: "702.9b", title: "Flying" })
    end

    it 'returns one source per rule section' do
      result = described_class.call(question: question, rule_sections: rule_sections)
      expect(result[:sources].length).to eq(rule_sections.length)
    end

    it 'does not include content or similarity in sources' do
      result = described_class.call(question: question, rule_sections: rule_sections)
      result[:sources].each do |source|
        expect(source).not_to have_key(:content)
        expect(source).not_to have_key(:similarity)
      end
    end

    it 'calls the OpenAI chat endpoint with the correct model' do
      expect_any_instance_of(OpenAI::Client).to receive(:chat).with(
        parameters: hash_including(model: "gpt-4o-mini")
      ).and_return(fake_response)

      described_class.call(question: question, rule_sections: rule_sections)
    end

    it 'includes the question in the user message' do
      expect_any_instance_of(OpenAI::Client).to receive(:chat) do |_, params|
        user_message = params[:parameters][:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).to include(question)
        fake_response
      end

      described_class.call(question: question, rule_sections: rule_sections)
    end

    it 'includes rule content in the user message' do
      expect_any_instance_of(OpenAI::Client).to receive(:chat) do |_, params|
        user_message = params[:parameters][:messages].find { |m| m[:role] == "user" }
        expect(user_message[:content]).to include("702.9b")
        expect(user_message[:content]).to include("A creature with flying")
        fake_response
      end

      described_class.call(question: question, rule_sections: rule_sections)
    end

    it 'sends a system message' do
      expect_any_instance_of(OpenAI::Client).to receive(:chat) do |_, params|
        system_message = params[:parameters][:messages].find { |m| m[:role] == "system" }
        expect(system_message).not_to be_nil
        fake_response
      end

      described_class.call(question: question, rule_sections: rule_sections)
    end
  end
end
