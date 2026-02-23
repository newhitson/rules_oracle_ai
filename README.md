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