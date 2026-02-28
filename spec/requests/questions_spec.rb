require 'rails_helper'

RSpec.describe "Questions", type: :request do
  let(:fake_rule) do
    double(
      section_number: "702.9b",
      title: "Flying",
      top_level_section: "Keyword Abilities",
      content: "A creature with flying can't be blocked except by creatures with flying and/or reach.",
      neighbor_distance: 0.1
    )
  end

  let(:fake_results) { Array.new(5, fake_rule) }

  let(:fake_answer_result) do
    {
      answer: "Yes, a creature with reach can block a creature with flying.",
      sources: [ { section_number: "702.9b", title: "Flying" } ]
    }
  end

  before do
    allow(CompRulesEmbedding).to receive(:search).and_return(fake_results)
    allow(AnswerService).to receive(:call).and_return(fake_answer_result)
  end

  describe "POST /questions" do
    context "with valid text" do
      it "returns 200" do
        post "/questions", params: { text: "can a creature with flying be blocked" }
        expect(response).to have_http_status(:ok)
      end

      it "returns 5 results" do
        post "/questions", params: { text: "can a creature with flying be blocked" }
        expect(response.parsed_body["results"].length).to eq(5)
      end

      it "passes the text to CompRulesEmbedding.search" do
        expect(CompRulesEmbedding).to receive(:search).with("flying rules")
        post "/questions", params: { text: "flying rules" }
      end

      it "includes all rule fields in each result" do
        post "/questions", params: { text: "flying" }
        result = response.parsed_body["results"].first
        expect(result).to include(
          "section_number" => "702.9b",
          "title" => "Flying",
          "top_level_section" => "Keyword Abilities",
          "content" => fake_rule.content
        )
      end

      it "returns similarity as 1 - neighbor_distance" do
        post "/questions", params: { text: "flying" }
        result = response.parsed_body["results"].first
        expect(result["similarity"]).to eq(1 - fake_rule.neighbor_distance)
      end

      it "includes an answer in the response" do
        post "/questions", params: { text: "can a creature with flying be blocked" }
        expect(response.parsed_body["answer"]).to eq(fake_answer_result[:answer])
      end

      it "includes sources in the response" do
        post "/questions", params: { text: "can a creature with flying be blocked" }
        expect(response.parsed_body["sources"]).to be_an(Array)
      end

      it "passes the question and results to AnswerService" do
        expect(AnswerService).to receive(:call).with(
          question: "flying rules",
          rule_sections: array_including(hash_including(section_number: "702.9b"))
        ).and_return(fake_answer_result)
        post "/questions", params: { text: "flying rules" }
      end
    end

    context "with missing text" do
      it "returns 422" do
        post "/questions", params: {}
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns an error message" do
        post "/questions", params: {}
        expect(response.parsed_body["error"]).to eq("text is required")
      end
    end

    context "with blank text" do
      it "returns 422" do
        post "/questions", params: { text: "" }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
