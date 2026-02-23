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

  def call_batch(texts)
    client = OpenAI::Client.new
    response = client.embeddings(
      parameters: {
        model: MODEL,
        input: texts
      }
    )
    response["data"].sort_by { |d| d["index"] }.map { |d| d["embedding"] }
  end
end
