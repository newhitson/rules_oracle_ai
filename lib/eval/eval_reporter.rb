class EvalReporter
  Result = Struct.new(:question, :passed, :matched_section, :matched_rank, :expected)

  def initialize
    @results = []
  end

  def record(question, expected_prefixes, retrieved_results)
    match = nil
    rank  = nil

    retrieved_results.each_with_index do |r, i|
      if expected_prefixes.any? { |prefix| r[:section_number].start_with?(prefix) }
        match = r[:section_number]
        rank  = i + 1
        break
      end
    end

    @results << Result.new(question, match.present?, match, rank, expected_prefixes)
  end

  def all_passed?
    @results.all?(&:passed)
  end

  def print_report
    passed = @results.count(&:passed)
    puts ""
    puts "=" * 70
    puts "EVAL RESULTS: #{passed}/#{@results.length} passed"
    puts "=" * 70

    @results.each_with_index do |r, i|
      status = r.passed ? "PASS" : "FAIL"
      puts ""
      puts "[#{status}] #{i + 1}. #{r.question}"
      puts "       Expected: #{r.expected.join(', ')}"
      if r.passed
        puts "       Matched: #{r.matched_section} (rank #{r.matched_rank}/10)"
      else
        puts "       No match in top-10 results"
      end
    end

    puts ""
    puts "=" * 70
    if all_passed?
      puts "All #{@results.length} questions passed."
    else
      puts "#{@results.reject(&:passed).length} question(s) failed."
    end
    puts "=" * 70
    puts ""
  end
end
