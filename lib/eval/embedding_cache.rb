require "digest"
require "json"

class EmbeddingCache
  def self.load(path)
    data = File.exist?(path) ? JSON.parse(File.read(path)) : {}
    new(data)
  end

  def initialize(data = {})
    @data = data
  end

  def hit?(text)
    @data.key?(key_for(text))
  end

  def get(text)
    @data[key_for(text)]
  end

  def store(text, vector)
    @data[key_for(text)] = vector
  end

  def save(path)
    File.write(path, JSON.generate(@data))
  end

  private

  def key_for(text)
    Digest::SHA256.hexdigest(text)
  end
end
