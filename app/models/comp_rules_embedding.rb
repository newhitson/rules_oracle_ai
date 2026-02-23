class CompRulesEmbedding < ApplicationRecord
  has_neighbors :embedding

  validates :section_number, presence: true, uniqueness: true
  validates :content, presence: true

  scope :similar_to, ->(embedding, limit: 5) {
    nearest_neighbors(:embedding, embedding, distance: "cosine").limit(limit)
  }

  def self.search(query, limit: 5)
    similar_to(generate_embedding(query), limit: limit)
  end

  def self.generate_embedding(text)
    EmbeddingService.new.call(text)
  end

  before_save :set_embedding, if: -> { embedding.blank? || content_changed? }

  def inspect
    embedding_summary = embedding.present? ? "[#{embedding.length} floats]" : "nil"
    "#<CompRulesEmbedding\n" \
      " id: #{id},\n" \
      " section_number: #{section_number.inspect},\n" \
      " top_level_section: #{top_level_section.inspect},\n" \
      " title: #{title.inspect},\n" \
      " content: #{content&.truncate(80).inspect},\n" \
      " embedding: #{embedding_summary},\n" \
      " created_at: #{created_at.inspect},\n" \
      " updated_at: #{updated_at.inspect}>"
  end

  private

  def set_embedding
    self.embedding = self.class.generate_embedding(content)
  end
end
