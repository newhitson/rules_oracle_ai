require 'rails_helper'

RSpec.describe EmbeddingService do
  let(:service) { described_class.new }
  let(:fake_vector) { Array.new(1536, 0.1) }
  let(:fake_response) { { "data" => [{ "embedding" => fake_vector }] } }

  before do
    allow_any_instance_of(OpenAI::Client).to receive(:embeddings).and_return(fake_response)
  end

  describe '#call' do
    it 'returns an array' do
      expect(service.call("test")).to be_an(Array)
    end

    it 'returns 1536 dimensions' do
      expect(service.call("test").length).to eq(1536)
    end

    it 'calls the OpenAI embeddings endpoint with the correct model and input' do
      expect_any_instance_of(OpenAI::Client).to receive(:embeddings).with(
        parameters: { model: "text-embedding-3-small", input: "test text" }
      ).and_return(fake_response)

      service.call("test text")
    end
  end
end
