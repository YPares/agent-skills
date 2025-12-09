---
name: pgvector-hybrid-search
description: Expert guidance for implementing hybrid search (vector similarity + full-text) using PostgreSQL with pgvector. Covers index selection (HNSW vs IVFFlat), BM25 ranking, Reciprocal Rank Fusion (RRF), performance tuning, and production deployment. Use when building RAG systems, semantic search, or document retrieval with PostgreSQL.
---

# pgvector Hybrid Search

This skill provides comprehensive guidance for implementing production-grade hybrid search systems using PostgreSQL with pgvector, combining semantic vector search with keyword-based full-text search.

## When to Use This Skill

- Building RAG (Retrieval-Augmented Generation) systems with PostgreSQL
- Implementing semantic search over documents, products, or content
- Migrating from dedicated vector databases (Qdrant, Pinecone, Weaviate) to PostgreSQL
- Optimizing existing pgvector deployments for production
- Combining keyword matching with semantic similarity
- Working with technical domains where exact terminology matters

## Core Concepts

**Hybrid search** combines two complementary approaches:
1. **Vector similarity search** - Semantic understanding via embeddings (catches conceptually similar content)
2. **Full-text search** - Keyword/phrase matching (catches exact terminology, part numbers, codes)

**Why hybrid beats pure vector search:**
- 8-15% accuracy improvement over pure semantic or pure keyword methods
- Handles both conceptual queries ("how does authentication work?") and precise queries ("part number XYZ-123")
- Robust against embedding model limitations
- Better for technical domains with standardized terminology

## Quick Start

### 1. Enable pgvector Extension

**For managed PostgreSQL (OVH, AWS RDS, Google Cloud SQL, etc.):**
```sql
CREATE EXTENSION vector;
```

**For self-hosted NixOS:**
```nix
services.postgresql = {
  enable = true;
  package = pkgs.postgresql_17;
  extensions = ps: with ps; [ pgvector ];
};
```

### 2. Create Table with Vector and Text Columns

```sql
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  embedding vector(1536),  -- For OpenAI ada-002 or similar
  content_tsv tsvector GENERATED ALWAYS AS (
    to_tsvector('english', title || ' ' || content)
  ) STORED
);
```

### 3. Create Indexes

```sql
-- Vector similarity index (HNSW recommended for production)
CREATE INDEX ON documents
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Full-text search index
CREATE INDEX ON documents
USING GIN (content_tsv)
WITH (fastupdate = off);  -- For read-heavy workloads
```

### 4. Hybrid Search Query with RRF

See [references/rrf-queries.md](references/rrf-queries.md) for complete query patterns.

## Index Selection: HNSW vs IVFFlat

### HNSW (Hierarchical Navigable Small World)

**When to use:**
- Production workloads with query performance priority
- High-recall requirements (>95%)
- Dynamic datasets with frequent inserts
- Sufficient memory available

**Advantages:**
- Superior query performance (logarithmic scaling)
- No training phase required
- Incrementally builds as data arrives
- Better recall at similar query speeds

**Tuning parameters:**
```sql
CREATE INDEX ON table USING hnsw (embedding vector_cosine_ops)
WITH (
  m = 16,              -- Max connections per layer (default 16, higher = better recall, more memory)
  ef_construction = 64 -- Build quality (default 64, higher = better index, slower build)
);

-- Query-time tuning
SET hnsw.ef_search = 40;  -- Higher = better recall, slower queries (default 40)
```

**Memory requirements:**
- Approximately 2-3x the size of raw vector data
- Critical: Index **must fit in shared_buffers** for optimal performance
- Monitor with: `SELECT pg_size_pretty(pg_relation_size('index_name'));`

### IVFFlat (Inverted File Flat)

**When to use:**
- Memory-constrained environments
- Static or infrequently updated datasets
- Faster build times required
- Lower memory budget

**Advantages:**
- Faster index creation
- Lower memory footprint
- Acceptable performance for smaller datasets (<1M vectors)

**Tuning parameters:**
```sql
CREATE INDEX ON table USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 1000);  -- Number of clusters

-- Recommended: lists = rows/200 (not rows/1000 as older docs suggest)
-- For 100k rows: lists = 500
-- For 1M rows: lists = 5000
```

**Limitations:**
- Requires periodic REINDEX as data changes
- Lower recall than HNSW at same query speed
- Needs representative data before index creation

### Distance Operators

Choose based on your embedding model:
- `vector_cosine_ops` - Cosine similarity (most common, normalized vectors)
- `vector_ip_ops` - Inner product (faster if vectors are already normalized to length 1, e.g., OpenAI embeddings)
- `vector_l2_ops` - Euclidean distance (less common for embeddings)

## BM25 Full-Text Search

PostgreSQL's native `ts_rank` lacks proper BM25 scoring. Use one of these extensions:

### Option 1: ParadeDB pg_search (Recommended for New Projects)

```sql
CREATE EXTENSION pg_search;

CREATE INDEX ON documents
USING bm25(content)
WITH (text_config='english');

-- Query with BM25 scoring
SELECT id, title, paradedb.score(id)
FROM documents
WHERE content @@@ 'authentication AND password'
ORDER BY paradedb.score(id) DESC;
```

### Option 2: VectorChord-BM25

```sql
CREATE EXTENSION vectorchord_bm25;

CREATE INDEX ON documents
USING bm25(content)
WITH (text_config='english');
```

### Option 3: pg_textsearch (Tiger Data)

```sql
CREATE INDEX articles_content_idx
ON articles
USING bm25(content)
WITH (text_config='english');
```

### Option 4: Native PostgreSQL (Optimized)

If extensions aren't available, optimize native full-text search:

```sql
-- Pre-compute tsvector (don't compute at query time!)
ALTER TABLE documents
ADD COLUMN content_tsv tsvector
GENERATED ALWAYS AS (to_tsvector('english', content)) STORED;

-- GIN index with fastupdate=off for read-heavy workloads
CREATE INDEX ON documents
USING GIN (content_tsv)
WITH (fastupdate = off);

-- Use ts_rank_cd (coverage density) for better ranking
SELECT id, title, ts_rank_cd(content_tsv, query) as rank
FROM documents, plainto_tsquery('english', 'search terms') query
WHERE content_tsv @@ query
ORDER BY rank DESC;
```

## Reciprocal Rank Fusion (RRF)

RRF combines rankings from multiple search methods into a unified score. It's **scale-independent** - works regardless of whether your BM25 scores are 0-10 or 0-1000.

### RRF Formula

```
score(doc) = Σ (1 / (k + rank_i))

where:
  k = constant (typically 60)
  rank_i = rank from search method i (1 for best result, 2 for second, etc.)
```

### PostgreSQL Implementation

See [references/rrf-queries.md](references/rrf-queries.md) for complete query examples.

**Basic pattern:**
```sql
WITH vector_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> $1) as rank
  FROM documents
  ORDER BY embedding <=> $1
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
  COALESCE(1.0 / (60 + v.rank), 0.0) +
  COALESCE(1.0 / (60 + t.rank), 0.0) as rrf_score
FROM vector_search v
FULL OUTER JOIN text_search t ON v.id = t.id
ORDER BY rrf_score DESC
LIMIT 20;
```

**Performance tip:** Fetch more candidates (100-200) from each search method before RRF to improve final result quality.

## Haskell Integration

### Using pgvector-haskell

```haskell
import Database.PostgreSQL.Simple
import Database.PostgreSQL.Simple.Vector

-- Define your document type
data Document = Document
  { docId :: Int
  , docTitle :: Text
  , docContent :: Text
  , docEmbedding :: Vector Float  -- From pgvector package
  }

-- Insert with vector
insertDocument :: Connection -> Text -> Text -> Vector Float -> IO Int
insertDocument conn title content embedding = do
  [Only docId] <- query conn
    "INSERT INTO documents (title, content, embedding) \
    \VALUES (?, ?, ?) RETURNING id"
    (title, content, embedding)
  pure docId

-- Hybrid search with RRF
hybridSearch :: Connection -> Vector Float -> Text -> IO [(Int, Text, Double)]
hybridSearch conn queryEmbedding queryText = do
  query conn
    "WITH vector_search AS ( \
    \  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> ?) as rank \
    \  FROM documents ORDER BY embedding <=> ? LIMIT 100 \
    \), \
    \text_search AS ( \
    \  SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, q) DESC) as rank \
    \  FROM documents, plainto_tsquery('english', ?) q \
    \  WHERE content_tsv @@ q LIMIT 100 \
    \) \
    \SELECT COALESCE(v.id, t.id) as id, d.title, \
    \       COALESCE(1.0 / (60 + v.rank), 0.0) + COALESCE(1.0 / (60 + t.rank), 0.0) as score \
    \FROM vector_search v \
    \FULL OUTER JOIN text_search t ON v.id = t.id \
    \JOIN documents d ON d.id = COALESCE(v.id, t.id) \
    \ORDER BY score DESC LIMIT 20"
    (queryEmbedding, queryEmbedding, queryText)
```

### Connection Pool Configuration

```haskell
import Data.Pool
import Database.PostgreSQL.Simple

createPgPool :: IO (Pool Connection)
createPgPool = newPool $ defaultPoolConfig
  (connectPostgreSQL "host=localhost dbname=mydb")
  close
  60  -- Idle timeout (seconds)
  20  -- Max connections
```

## Performance Optimization

### Memory Configuration

**Critical for HNSW performance** - the index must fit in memory:

```sql
-- Check index size
SELECT pg_size_pretty(pg_relation_size('documents_embedding_idx'));

-- Configure shared_buffers (set to at least index size + working set)
-- In postgresql.conf:
shared_buffers = 8GB          -- At least as large as your HNSW index
work_mem = 256MB              -- For sorting/aggregation in RRF queries
maintenance_work_mem = 2GB    -- For index creation

-- Check if index fits in cache
SELECT
  schemaname, tablename, indexname,
  pg_size_pretty(pg_relation_size(indexrelid)) as size,
  idx_blks_read, idx_blks_hit,
  round(100.0 * idx_blks_hit / NULLIF(idx_blks_hit + idx_blks_read, 0), 2) as cache_hit_ratio
FROM pg_stat_user_indexes
WHERE indexrelname LIKE '%embedding%';
-- Aim for >95% cache hit ratio
```

### Index Creation Strategy

```sql
-- Create index AFTER loading initial data
INSERT INTO documents (title, content, embedding)
SELECT ... FROM source;  -- Load all data first

-- Create index concurrently (doesn't block writes)
CREATE INDEX CONCURRENTLY documents_embedding_idx
ON documents USING hnsw (embedding vector_cosine_ops);

-- For IVFFlat, ensure representative data before indexing
-- Bad: CREATE INDEX immediately on empty table
-- Good: Load 10k+ rows first, then CREATE INDEX
```

### Query Optimization

```sql
-- Use EXPLAIN to verify index usage
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM documents
ORDER BY embedding <=> $1
LIMIT 10;

-- Look for:
-- 1. Index Scan (not Seq Scan)
-- 2. Buffers: shared hit (not read) - means data in cache
-- 3. Low execution time

-- Optimize for normalized vectors (OpenAI, Cohere, etc.)
-- Inner product is faster than cosine when vectors are length 1
CREATE INDEX ON documents
USING hnsw (embedding vector_ip_ops);  -- Instead of vector_cosine_ops

-- Query with inner product
SELECT id FROM documents
ORDER BY embedding <#> $1  -- <#> is inner product
LIMIT 10;
```

### Maintenance

```sql
-- Regular VACUUM to prevent bloat
VACUUM ANALYZE documents;

-- Monitor table bloat
SELECT
  schemaname, tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
  n_dead_tup, n_live_tup,
  round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_ratio
FROM pg_stat_user_tables
WHERE tablename = 'documents';
-- If dead_ratio > 10%, run VACUUM

-- Update statistics for query planner
ANALYZE documents;

-- For IVFFlat: Rebuild index periodically as data changes
REINDEX INDEX CONCURRENTLY documents_embedding_idx;
```

## Production Deployment Checklist

See [references/production-checklist.md](references/production-checklist.md) for complete checklist.

**Key points:**
- [ ] pgvector extension enabled
- [ ] HNSW index chosen (unless memory-constrained)
- [ ] shared_buffers >= HNSW index size
- [ ] Index created AFTER loading initial data
- [ ] BM25 extension installed (ParadeDB, VectorChord, or pg_textsearch)
- [ ] Generated tsvector column with GIN index
- [ ] RRF query tested and optimized
- [ ] Monitoring configured (pg_stat_statements, cache hit ratios)
- [ ] VACUUM scheduled (daily for active tables)
- [ ] Connection pooling configured
- [ ] Query explain plans reviewed

## Common Pitfalls

### 1. Creating Index Before Loading Data
**Problem:** Index builds slowly and may have poor quality
**Solution:** Load data first, then create index

### 2. HNSW Index Doesn't Fit in Memory
**Problem:** Terrible query performance (disk I/O on every search)
**Solution:** Increase shared_buffers or switch to IVFFlat

### 3. IVFFlat with Too Many Lists
**Problem:** Low recall, poor results
**Solution:** Use `lists = rows/200` formula, not rows/1000

### 4. Computing tsvector at Query Time
**Problem:** Slow full-text searches
**Solution:** Use GENERATED ALWAYS AS ... STORED column

### 5. Ignoring Index Selection in RRF
**Problem:** Sequential scans instead of index scans
**Solution:** Add explicit ORDER BY to CTEs, ensure LIMIT is reasonable (100-200)

### 6. Not Monitoring Cache Hit Ratio
**Problem:** Slow queries due to disk I/O
**Solution:** Query pg_stat_user_indexes, aim for >95% cache hits

### 7. Using Cosine Similarity for Normalized Vectors
**Problem:** Slower than necessary
**Solution:** Use inner product (`vector_ip_ops`, `<#>`) for normalized embeddings

## Troubleshooting

### Slow Query Performance

```sql
-- Check if index is being used
EXPLAIN (ANALYZE, BUFFERS) SELECT id FROM documents ORDER BY embedding <=> $1 LIMIT 10;

-- If seeing Seq Scan instead of Index Scan:
-- 1. Ensure index exists: \di documents*
-- 2. Check if statistics are up to date: ANALYZE documents;
-- 3. Verify query uses correct operator (<=> for cosine, <#> for inner product)

-- If seeing index scan but slow:
-- 1. Check cache hit ratio (see Memory Configuration section)
-- 2. Increase shared_buffers
-- 3. Tune hnsw.ef_search (higher = more accurate, slower)
```

### Poor Result Quality

```sql
-- For vector search:
-- 1. Verify embeddings are generated correctly (check dimensions)
SELECT id, array_length(embedding::float[], 1) FROM documents LIMIT 1;

-- 2. Try increasing LIMIT in vector search CTE (fetch more candidates)
-- 3. Adjust hnsw.ef_search for better recall

-- For text search:
-- 1. Verify tsvector is populated
SELECT id, content_tsv FROM documents WHERE content_tsv IS NULL LIMIT 1;

-- 2. Test different text search configurations
SELECT to_tsvector('english', content) FROM documents LIMIT 1;
SELECT to_tsvector('simple', content) FROM documents LIMIT 1;  -- No stemming

-- For RRF:
-- 1. Check if both searches are returning results
-- 2. Adjust k parameter (higher k = less difference between ranks)
-- 3. Add score weighting if one method should dominate
```

## Further Reading

- Official pgvector documentation: https://github.com/pgvector/pgvector
- ParadeDB hybrid search guide: https://www.paradedb.com/blog/hybrid-search-in-postgresql-the-missing-manual
- AWS pgvector optimization guide: https://aws.amazon.com/blogs/database/optimize-generative-ai-applications-with-pgvector-indexing-a-deep-dive-into-ivfflat-and-hnsw-techniques/
- Supabase pgvector guide: https://supabase.com/docs/guides/ai/hybrid-search

## Sources

This skill synthesizes information from:
- pgvector official documentation and GitHub repository
- AWS RDS, Google Cloud AlloyDB, and Azure Cosmos DB pgvector guides (2025)
- ParadeDB, VectorChord, and Tiger Data BM25 implementation docs
- Production deployment case studies from Supabase, Heroku, and Crunchy Data
- Academic papers on HNSW, IVFFlat, and RRF algorithms
