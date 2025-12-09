# Reciprocal Rank Fusion Query Patterns

This document provides production-ready SQL query patterns for implementing RRF hybrid search with PostgreSQL and pgvector.

## Basic RRF Query (Vector + Text)

```sql
WITH vector_search AS (
  -- Semantic search using vector similarity
  SELECT
    id,
    ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) as rank
  FROM documents
  ORDER BY embedding <=> $1::vector
  LIMIT 100  -- Fetch more candidates for better RRF results
),
text_search AS (
  -- Keyword search using full-text search
  SELECT
    id,
    ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, query) DESC) as rank
  FROM documents, plainto_tsquery('english', $2) query
  WHERE content_tsv @@ query
  LIMIT 100
)
SELECT
  COALESCE(v.id, t.id) as id,
  d.title,
  d.content,
  -- RRF score calculation (k=60 is standard)
  COALESCE(1.0 / (60 + v.rank), 0.0) +
  COALESCE(1.0 / (60 + t.rank), 0.0) as rrf_score,
  v.rank as vector_rank,
  t.rank as text_rank
FROM vector_search v
FULL OUTER JOIN text_search t ON v.id = t.id
JOIN documents d ON d.id = COALESCE(v.id, t.id)
ORDER BY rrf_score DESC
LIMIT 20;  -- Final result count
```

**Parameters:**
- `$1`: Query embedding (vector)
- `$2`: Query text (string)

## Weighted RRF (Prioritize One Method)

Sometimes you want to give more weight to one search method:

```sql
WITH vector_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) as rank
  FROM documents
  ORDER BY embedding <=> $1::vector
  LIMIT 100
),
text_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, query) DESC) as rank
  FROM documents, plainto_tsquery('english', $2) query
  WHERE content_tsv @@ query
  LIMIT 100
)
SELECT
  COALESCE(v.id, t.id) as id,
  d.title,
  -- Weighted RRF: 70% vector, 30% text
  COALESCE(0.7 / (60 + v.rank), 0.0) +
  COALESCE(0.3 / (60 + t.rank), 0.0) as rrf_score
FROM vector_search v
FULL OUTER JOIN text_search t ON v.id = t.id
JOIN documents d ON d.id = COALESCE(v.id, t.id)
ORDER BY rrf_score DESC
LIMIT 20;
```

## RRF with Filtering

Add filters (tenant, category, date range, etc.) before RRF:

```sql
WITH vector_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) as rank
  FROM documents
  WHERE
    tenant_id = $3 AND
    created_at >= $4 AND
    category = ANY($5)
  ORDER BY embedding <=> $1::vector
  LIMIT 100
),
text_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, query) DESC) as rank
  FROM documents, plainto_tsquery('english', $2) query
  WHERE
    content_tsv @@ query AND
    tenant_id = $3 AND
    created_at >= $4 AND
    category = ANY($5)
  LIMIT 100
)
SELECT
  COALESCE(v.id, t.id) as id,
  d.title,
  d.category,
  COALESCE(1.0 / (60 + v.rank), 0.0) +
  COALESCE(1.0 / (60 + t.rank), 0.0) as rrf_score
FROM vector_search v
FULL OUTER JOIN text_search t ON v.id = t.id
JOIN documents d ON d.id = COALESCE(v.id, t.id)
ORDER BY rrf_score DESC
LIMIT 20;
```

**Parameters:**
- `$1`: Query embedding
- `$2`: Query text
- `$3`: Tenant ID
- `$4`: Minimum creation date
- `$5`: Array of categories

## RRF with BM25 Extension (ParadeDB)

If using ParadeDB pg_search for true BM25 scoring:

```sql
WITH vector_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) as rank
  FROM documents
  ORDER BY embedding <=> $1::vector
  LIMIT 100
),
bm25_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY paradedb.score(id) DESC) as rank
  FROM documents
  WHERE content @@@ $2  -- ParadeDB search operator
  LIMIT 100
)
SELECT
  COALESCE(v.id, b.id) as id,
  d.title,
  COALESCE(1.0 / (60 + v.rank), 0.0) +
  COALESCE(1.0 / (60 + b.rank), 0.0) as rrf_score
FROM vector_search v
FULL OUTER JOIN bm25_search b ON v.id = b.id
JOIN documents d ON d.id = COALESCE(v.id, b.id)
ORDER BY rrf_score DESC
LIMIT 20;
```

## Multi-Vector RRF (Multiple Embedding Types)

For systems using multiple embedding models (e.g., title embeddings + content embeddings):

```sql
WITH title_vector_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY title_embedding <=> $1::vector) as rank
  FROM documents
  ORDER BY title_embedding <=> $1::vector
  LIMIT 100
),
content_vector_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY content_embedding <=> $2::vector) as rank
  FROM documents
  ORDER BY content_embedding <=> $2::vector
  LIMIT 100
),
text_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, query) DESC) as rank
  FROM documents, plainto_tsquery('english', $3) query
  WHERE content_tsv @@ query
  LIMIT 100
)
SELECT
  COALESCE(tv.id, cv.id, t.id) as id,
  d.title,
  -- Combine all three methods
  COALESCE(1.0 / (60 + tv.rank), 0.0) +
  COALESCE(1.0 / (60 + cv.rank), 0.0) +
  COALESCE(1.0 / (60 + t.rank), 0.0) as rrf_score
FROM title_vector_search tv
FULL OUTER JOIN content_vector_search cv ON tv.id = cv.id
FULL OUTER JOIN text_search t ON COALESCE(tv.id, cv.id) = t.id
JOIN documents d ON d.id = COALESCE(tv.id, cv.id, t.id)
ORDER BY rrf_score DESC
LIMIT 20;
```

## RRF with Contextual Chunks

For RAG systems that retrieve document chunks with surrounding context:

```sql
WITH vector_search AS (
  SELECT
    chunk_id,
    document_id,
    ROW_NUMBER() OVER (ORDER BY embedding <=> $1::vector) as rank
  FROM document_chunks
  ORDER BY embedding <=> $1::vector
  LIMIT 100
),
text_search AS (
  SELECT
    chunk_id,
    document_id,
    ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, query) DESC) as rank
  FROM document_chunks, plainto_tsquery('english', $2) query
  WHERE content_tsv @@ query
  LIMIT 100
),
rrf_results AS (
  SELECT
    COALESCE(v.chunk_id, t.chunk_id) as chunk_id,
    COALESCE(v.document_id, t.document_id) as document_id,
    COALESCE(1.0 / (60 + v.rank), 0.0) +
    COALESCE(1.0 / (60 + t.rank), 0.0) as rrf_score
  FROM vector_search v
  FULL OUTER JOIN text_search t ON v.chunk_id = t.chunk_id
)
SELECT
  r.chunk_id,
  r.document_id,
  r.rrf_score,
  c.content,
  -- Get surrounding chunks for context
  prev_chunk.content as previous_chunk,
  next_chunk.content as next_chunk,
  d.title as document_title
FROM rrf_results r
JOIN document_chunks c ON c.chunk_id = r.chunk_id
LEFT JOIN document_chunks prev_chunk
  ON prev_chunk.document_id = r.document_id
  AND prev_chunk.chunk_index = c.chunk_index - 1
LEFT JOIN document_chunks next_chunk
  ON next_chunk.document_id = r.document_id
  AND next_chunk.chunk_index = c.chunk_index + 1
JOIN documents d ON d.id = r.document_id
ORDER BY r.rrf_score DESC
LIMIT 20;
```

## Haskell Query Functions

Example Haskell functions wrapping these queries:

```haskell
import Database.PostgreSQL.Simple
import Database.PostgreSQL.Simple.Vector
import qualified Data.Text as T

data SearchResult = SearchResult
  { resultId :: Int
  , resultTitle :: T.Text
  , resultContent :: T.Text
  , rrfScore :: Double
  , vectorRank :: Maybe Int
  , textRank :: Maybe Int
  } deriving (Show)

instance FromRow SearchResult where
  fromRow = SearchResult
    <$> field <*> field <*> field
    <*> field <*> field <*> field

-- Basic RRF hybrid search
hybridSearch
  :: Connection
  -> Vector Float  -- Query embedding
  -> T.Text        -- Query text
  -> IO [SearchResult]
hybridSearch conn embedding queryText = query conn
  "WITH vector_search AS ( \
  \  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> ?) as rank \
  \  FROM documents ORDER BY embedding <=> ? LIMIT 100 \
  \), \
  \text_search AS ( \
  \  SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, q) DESC) as rank \
  \  FROM documents, plainto_tsquery('english', ?) q \
  \  WHERE content_tsv @@ q LIMIT 100 \
  \) \
  \SELECT COALESCE(v.id, t.id), d.title, d.content, \
  \       COALESCE(1.0 / (60 + v.rank), 0.0) + COALESCE(1.0 / (60 + t.rank), 0.0) as score, \
  \       v.rank, t.rank \
  \FROM vector_search v \
  \FULL OUTER JOIN text_search t ON v.id = t.id \
  \JOIN documents d ON d.id = COALESCE(v.id, t.id) \
  \ORDER BY score DESC LIMIT 20"
  (embedding, embedding, queryText)

-- Filtered RRF search
filteredHybridSearch
  :: Connection
  -> Vector Float
  -> T.Text
  -> Int           -- Tenant ID
  -> UTCTime       -- Min date
  -> [T.Text]      -- Categories
  -> IO [SearchResult]
filteredHybridSearch conn embedding queryText tenantId minDate categories =
  query conn
    "WITH vector_search AS ( \
    \  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> ?) as rank \
    \  FROM documents \
    \  WHERE tenant_id = ? AND created_at >= ? AND category = ANY(?) \
    \  ORDER BY embedding <=> ? LIMIT 100 \
    \), \
    \text_search AS ( \
    \  SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, q) DESC) as rank \
    \  FROM documents, plainto_tsquery('english', ?) q \
    \  WHERE content_tsv @@ q AND tenant_id = ? AND created_at >= ? AND category = ANY(?) \
    \  LIMIT 100 \
    \) \
    \SELECT COALESCE(v.id, t.id), d.title, d.content, \
    \       COALESCE(1.0 / (60 + v.rank), 0.0) + COALESCE(1.0 / (60 + t.rank), 0.0), \
    \       v.rank, t.rank \
    \FROM vector_search v \
    \FULL OUTER JOIN text_search t ON v.id = t.id \
    \JOIN documents d ON d.id = COALESCE(v.id, t.id) \
    \ORDER BY score DESC LIMIT 20"
    (embedding, tenantId, minDate, In categories,
     embedding, queryText, tenantId, minDate, In categories)
```

## Performance Notes

1. **Candidate Limit**: Fetching 100-200 candidates from each method before RRF typically gives best results. Lower limits (10-20) may miss relevant results.

2. **k Parameter**: The standard k=60 works well for most cases. Lower k (20-40) gives more weight to top-ranked items. Higher k (80-100) flattens the score distribution.

3. **Index Usage**: The `ORDER BY` and `LIMIT` in each CTE ensure index scans. Without them, PostgreSQL may use sequential scans.

4. **FULL OUTER JOIN**: Ensures documents appearing in only one search method are included. Change to INNER JOIN if you only want documents matching both methods.

5. **Result Count**: LIMIT 100 in CTEs should be >> LIMIT 20 in final result for best quality.
