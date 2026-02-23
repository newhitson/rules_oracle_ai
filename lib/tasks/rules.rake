namespace :rules do
  desc "Parse comprehensive_rules_modified.txt into comp_rules_embeddings (no embeddings)"
  task seed: :environment do
    file_path = Rails.root.join("comprehensive_rules_modified.txt")

    unless File.exist?(file_path)
      puts "File not found: #{file_path}"
      exit 1
    end

    current_top_level = nil
    current_title = nil
    count = 0

    File.foreach(file_path) do |raw_line|
      line = raw_line.strip
      next if line.empty?
      break if line == "Glossary"

      if (m = line.match(/^(\d)\. (.+)$/))
        current_top_level = m[2]
      elsif (m = line.match(/^(\d{3})\. (.+)$/))
        current_title = m[2]
      elsif (m = line.match(/^(\d{3}\.\d+[a-z]{0,2})\.? (.+)$/))
        CompRulesEmbedding.upsert(
          {
            section_number: m[1],
            top_level_section: current_top_level,
            title: current_title,
            content: m[2],
            updated_at: Time.current,
            created_at: Time.current
          },
          unique_by: :section_number
        )
        count += 1
      end
    end

    puts "Imported #{count} rules."
  end

  desc "Generate and store embeddings for all CompRulesEmbedding records without one"
  task embed: :environment do
    batch_size = 100
    scope = CompRulesEmbedding.where(embedding: nil)
    total = scope.count

    puts "Embedding #{total} rules sections in batches of #{batch_size}..."

    scope.find_in_batches(batch_size: batch_size).with_index do |batch, i|
      embeddings = EmbeddingService.new.call_batch(batch.map(&:content))
      batch.each_with_index do |record, j|
        record.update_column(:embedding, embeddings[j])
      end
      puts "  Batch #{i + 1}: #{[ (i + 1) * batch_size, total ].min}/#{total}"
    end

    puts "Done."
  end
end
