A Rails API that uses RAG (Retrieval-Augmented Generation) to answer complex Magic: The Gathering rules questions, powered by the Comprehensive Rules document and backed by your experience as a judge.

## Populating the Database

**1. Parse the Comprehensive Rules into the database:**

```bash
bundle exec rake rules:seed
```

This reads `comprehensive_rules_modified.txt` from the project root and upserts all rule sections into the `comp_rules_embeddings` table (without generating embeddings).

**2. Generate and store embeddings for all rules:**

```bash
bundle exec rake rules:embed
```

This finds every record with a missing embedding, processes them in batches of 100, and stores the resulting vectors via the OpenAI `text-embedding-3-small` model. Requires a valid OpenAI API key in Rails credentials (`openai.api_key`).

## Evaluating Search Quality

Run the evaluation suite to verify that questions are retrieving the correct rules sections:

```bash
bundle exec rake eval:questions
```

This compares the top-10 search results for each fixture question against expected section number prefixes (e.g. `"702.9"` matches `702.9`, `702.9a`, `702.9b`, etc.) and prints a pass/fail report with the rank of each match.

**Token caching:** The first run embeds all questions via the OpenAI API and saves the vectors to `tmp/eval_cache.json`. Subsequent runs read from the cache and make no API calls. Adding a new question only re-embeds that question.

**Adding questions:** Edit `config/eval/questions.yml`:

```yaml
- question: "Can a creature with flying be blocked by a creature with reach?"
  expected_sections:
    - "702.9"
  notes: "Core flying/reach interaction"
```

`expected_sections` are prefix-matched, so `"702.9"` passes if any top-10 result has a section number starting with `702.9`.