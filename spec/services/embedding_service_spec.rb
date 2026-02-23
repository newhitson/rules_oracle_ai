require 'rails_helper'

RSpec.describe EmbeddingService do
  let(:service) { described_class.new }
  let(:fake_vector) { Array.new(1536, 0.1) }
  let(:fake_response) { { "data" => [ { "embedding" => fake_vector } ] } }

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

  describe '#call_batch' do
    let(:fake_vector_a) { Array.new(1536, 0.1) }
    let(:fake_vector_b) { Array.new(1536, 0.2) }
    let(:fake_batch_response) do
      {
        "data" => [
          { "index" => 1, "embedding" => fake_vector_b },
          { "index" => 0, "embedding" => fake_vector_a }
        ]
      }
    end

    before do
      allow_any_instance_of(OpenAI::Client).to receive(:embeddings).and_return(fake_batch_response)
    end

    it 'returns an array of embeddings' do
      expect(service.call_batch([ "text a", "text b" ])).to be_an(Array)
    end

    it 'returns one embedding per input' do
      expect(service.call_batch([ "text a", "text b" ]).length).to eq(2)
    end

    it 'sorts results by index so order matches input order' do
      result = service.call_batch([ "text a", "text b" ])
      expect(result[0]).to eq(fake_vector_a)
      expect(result[1]).to eq(fake_vector_b)
    end

    it 'calls the OpenAI embeddings endpoint with an array input' do
      expect_any_instance_of(OpenAI::Client).to receive(:embeddings).with(
        parameters: { model: "text-embedding-3-small", input: [ "text a", "text b" ] }
      ).and_return(fake_batch_response)

      service.call_batch([ "text a", "text b" ])
    end
  end
end
