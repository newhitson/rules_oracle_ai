require Rails.root.join("lib/eval/embedding_cache")
require Rails.root.join("lib/eval/eval_reporter")

namespace :eval do
  desc "Evaluate semantic search quality against fixture questions (uses OpenAI API for new questions)"
  task questions: :environment do
    fixture_path = Rails.root.join("config/eval/questions.yml")
    cache_path   = Rails.root.join("tmp/eval_cache.json")

    unless File.exist?(fixture_path)
      puts "Fixture file not found: #{fixture_path}"
      puts "Create config/eval/questions.yml to get started."
      exit 1
    end

    questions = YAML.safe_load_file(fixture_path)

    if questions.blank?
      puts "No questions found in #{fixture_path}"
      exit 1
    end

    puts "Loaded #{questions.length} questions."

    cache = EmbeddingCache.load(cache_path)
    uncached = questions.reject { |q| cache.hit?(q["question"]) }

    if uncached.any?
      puts "Fetching embeddings for #{uncached.length} new question(s)..."
      vectors = EmbeddingService.new.call_batch(uncached.map { |q| q["question"] })
      uncached.each_with_index { |q, i| cache.store(q["question"], vectors[i]) }
      cache.save(cache_path)
      puts "Cache saved to #{cache_path}."
    else
      puts "All embeddings cached — no API calls needed."
    end

    reporter = EvalReporter.new

    questions.each do |fixture|
      question  = fixture["question"]
      expected  = fixture["expected_sections"]
      embedding = cache.get(question)

      results = CompRulesEmbedding.similar_to(embedding, limit: 10).map do |r|
        { section_number: r.section_number, similarity: 1 - r.neighbor_distance }
      end

      reporter.record(question, expected, results)
    end

    reporter.print_report
    exit 1 unless reporter.all_passed?
  end
end
