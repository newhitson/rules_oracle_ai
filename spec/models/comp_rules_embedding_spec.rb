require 'rails_helper'

RSpec.describe CompRulesEmbedding do
  let(:fake_vector) { Array.new(1536, 0.1) }

  before do
    allow(EmbeddingService).to receive(:new).and_return(
      instance_double(EmbeddingService, call: fake_vector)
    )
  end

  describe '.similar_to' do
    it 'returns an ActiveRecord relation' do
      expect(described_class.similar_to(fake_vector)).to be_a(ActiveRecord::Relation)
    end
  end

  describe '.search' do
    it 'generates an embedding from the query string' do
      expect(described_class).to receive(:generate_embedding).with("flying").and_return(fake_vector)
      allow(described_class).to receive(:similar_to).and_return(described_class.none)
      described_class.search("flying")
    end

    it 'delegates to similar_to with the generated embedding' do
      allow(described_class).to receive(:generate_embedding).and_return(fake_vector)
      expect(described_class).to receive(:similar_to).with(fake_vector, limit: 5).and_return(described_class.none)
      described_class.search("flying")
    end

    it 'passes the limit argument through to similar_to' do
      allow(described_class).to receive(:generate_embedding).and_return(fake_vector)
      expect(described_class).to receive(:similar_to).with(fake_vector, limit: 3).and_return(described_class.none)
      described_class.search("flying", limit: 3)
    end
  end
end
