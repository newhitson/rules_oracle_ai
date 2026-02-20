class CompRulesEmbedding < ApplicationRecord
  has_neighbors :embedding

  validates :section_number, presence: true, uniqueness: true
  validates :content, presence: true

  def self.search(query, limit: 5)
    embedding = generate_embedding(query)
    nearest_neighbors(:embedding, embedding, distance: "cosine").limit(limit)
  end

  def self.generate_embedding(text)
    client = OpenAI::Client.new
    response = client.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: text
      }
    )
    response.dig("data", 0, "embedding")
  end

  before_save :set_embedding, if: -> { embedding.blank? || content_changed? }

  private

  def set_embedding
    self.embedding = self.class.generate_embedding(content)
  end
end
