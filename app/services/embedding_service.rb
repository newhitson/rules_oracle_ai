class EmbeddingService
  MODEL = "text-embedding-3-small"

  def call(text)
    client = OpenAI::Client.new
    response = client.embeddings(
      parameters: {
        model: MODEL,
        input: text
      }
    )
    response.dig("data", 0, "embedding")
  end
end
