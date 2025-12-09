# pgvector Hybrid Search Production Deployment Checklist

Use this checklist when deploying pgvector hybrid search to production.

## Pre-Deployment

### PostgreSQL Configuration

- [ ] **Extension installed**
  ```sql
  CREATE EXTENSION IF NOT EXISTS vector;
  ```

- [ ] **PostgreSQL version** >= 12 (pgvector requirement)
  ```sql
  SELECT version();
  ```

- [ ] **shared_buffers configured** (at least as large as HNSW index)
  ```sql
  -- Check current setting
  SHOW shared_buffers;

  -- Calculate required size
  SELECT pg_size_pretty(pg_relation_size('your_embedding_idx'));

  -- In postgresql.conf:
  shared_buffers = 8GB  -- Adjust based on index size
  ```

- [ ] **work_mem configured** for RRF queries
  ```sql
  -- For sorting/aggregation in hybrid queries
  work_mem = 256MB
  ```

- [ ] **maintenance_work_mem configured** for index creation
  ```sql
  -- For HNSW/IVFFlat index builds
  maintenance_work_mem = 2GB
  ```

- [ ] **Connection pooling** configured (recommended: 20-50 connections)
  - Use pgBouncer, PgPool, or application-level pooling
  - Monitor with: `SELECT count(*) FROM pg_stat_activity;`

### Schema Design

- [ ] **Table created** with vector column
  ```sql
  CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1536),  -- Match your embedding model dimension
    created_at TIMESTAMPTZ DEFAULT NOW(),
    tenant_id INTEGER,
    -- Add your domain-specific columns
    CONSTRAINT embedding_dimension CHECK (array_length(embedding::float[], 1) = 1536)
  );
  ```

- [ ] **Generated tsvector column** for full-text search
  ```sql
  ALTER TABLE documents
  ADD COLUMN content_tsv tsvector
  GENERATED ALWAYS AS (to_tsvector('english', title || ' ' || content)) STORED;
  ```

- [ ] **Appropriate indexes** on filter columns
  ```sql
  CREATE INDEX ON documents (tenant_id);
  CREATE INDEX ON documents (created_at);
  CREATE INDEX ON documents (category);  -- If applicable
  ```

### Index Configuration

- [ ] **Vector index created** (HNSW recommended)
  ```sql
  -- HNSW (recommended for production)
  CREATE INDEX documents_embedding_idx
  ON documents
  USING hnsw (embedding vector_cosine_ops)  -- Or vector_ip_ops for normalized vectors
  WITH (m = 16, ef_construction = 64);

  -- OR IVFFlat (if memory-constrained)
  CREATE INDEX documents_embedding_idx
  ON documents
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 1000);  -- Adjust based on row count: rows/200
  ```

- [ ] **Full-text search index created**
  ```sql
  CREATE INDEX documents_content_tsv_idx
  ON documents
  USING GIN (content_tsv)
  WITH (fastupdate = off);  -- For read-heavy workloads
  ```

- [ ] **Index creation strategy** followed
  - [ ] Data loaded BEFORE creating indexes
  - [ ] Indexes created CONCURRENTLY if on live database
  - [ ] Index build completed successfully (check `pg_stat_progress_create_index`)

### BM25 Configuration (Optional but Recommended)

- [ ] **BM25 extension installed** (choose one)
  ```sql
  -- Option 1: ParadeDB (recommended)
  CREATE EXTENSION pg_search;
  CREATE INDEX ON documents USING bm25(content) WITH (text_config='english');

  -- Option 2: VectorChord-BM25
  CREATE EXTENSION vectorchord_bm25;
  CREATE INDEX ON documents USING bm25(content) WITH (text_config='english');

  -- Option 3: pg_textsearch (Tiger Data)
  CREATE INDEX ON documents USING bm25(content) WITH (text_config='english');
  ```

## Deployment

### Monitoring Setup

- [ ] **pg_stat_statements enabled** for query monitoring
  ```sql
  -- In postgresql.conf:
  shared_preload_libraries = 'pg_stat_statements'
  pg_stat_statements.track = all

  -- Then restart PostgreSQL and:
  CREATE EXTENSION pg_stat_statements;
  ```

- [ ] **Cache hit ratio monitoring** configured
  ```sql
  -- Add to monitoring dashboard
  SELECT
    schemaname, tablename, indexname,
    idx_blks_hit, idx_blks_read,
    round(100.0 * idx_blks_hit / NULLIF(idx_blks_hit + idx_blks_read, 0), 2) as cache_hit_ratio
  FROM pg_stat_user_indexes
  WHERE indexrelname LIKE '%embedding%';
  ```

- [ ] **Query performance monitoring** in place
  ```sql
  -- Top slow queries
  SELECT
    query,
    calls,
    mean_exec_time,
    max_exec_time,
    stddev_exec_time
  FROM pg_stat_statements
  WHERE query LIKE '%embedding%'
  ORDER BY mean_exec_time DESC
  LIMIT 20;
  ```

- [ ] **Index bloat monitoring** configured
  ```sql
  -- Monitor table and index sizes
  SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) -
                   pg_relation_size(schemaname||'.'||tablename)) as index_size
  FROM pg_tables
  WHERE tablename = 'documents';
  ```

### Application Integration

- [ ] **Connection string configured** with SSL (if managed database)
  ```
  postgres://user:pass@host:port/db?sslmode=require
  ```

- [ ] **pgvector-haskell library** added to dependencies
  ```cabal
  build-depends: pgvector >= 0.1
  ```

- [ ] **Hybrid search query tested** with real data
  ```sql
  -- Test query (see references/rrf-queries.md)
  ```

- [ ] **Query timeout configured** (prevent runaway queries)
  ```sql
  -- Application-level timeout
  SET statement_timeout = '30s';
  ```

- [ ] **Error handling** for extension issues
  - Handle "extension not found" gracefully
  - Handle vector dimension mismatches
  - Handle connection pool exhaustion

### Performance Validation

- [ ] **Index usage verified** via EXPLAIN
  ```sql
  EXPLAIN (ANALYZE, BUFFERS)
  SELECT id FROM documents
  ORDER BY embedding <=> $1
  LIMIT 10;

  -- Should see: Index Scan using hnsw/ivfflat
  -- Should NOT see: Seq Scan
  ```

- [ ] **Cache hit ratio** > 95% for embedding index
  ```sql
  -- See "Cache hit ratio monitoring" above
  ```

- [ ] **Query performance benchmarked**
  - Vector search: < 100ms for p95
  - Text search: < 50ms for p95
  - Hybrid RRF: < 150ms for p95

- [ ] **Load tested** at expected concurrent user count
  - Use pgbench or similar tool
  - Monitor connection pool saturation
  - Monitor memory usage

### Data Migration (If Migrating from Another Vector DB)

- [ ] **Migration script tested** on staging data
- [ ] **Vector dimensions verified** (match source DB)
- [ ] **Batch insert optimized** (use COPY or batch INSERTs)
- [ ] **Dual-write strategy** for zero-downtime migration
- [ ] **Data consistency verified** (spot-check embeddings)
- [ ] **Rollback plan** documented

## Post-Deployment

### Maintenance Schedule

- [ ] **Daily VACUUM** scheduled for active tables
  ```sql
  -- In cron or systemd timer
  VACUUM ANALYZE documents;
  ```

- [ ] **Weekly full VACUUM** (or autovacuum tuned appropriately)
  ```sql
  VACUUM FULL ANALYZE documents;  -- Requires table lock, schedule during low traffic
  ```

- [ ] **Periodic REINDEX** for IVFFlat (if used)
  ```sql
  -- Monthly or when significant data changes
  REINDEX INDEX CONCURRENTLY documents_embedding_idx;
  ```

- [ ] **Statistics update** scheduled
  ```sql
  ANALYZE documents;
  ```

### Monitoring Alerts

- [ ] Alert on **cache hit ratio** < 95%
- [ ] Alert on **table bloat** > 20%
- [ ] Alert on **query timeouts** increasing
- [ ] Alert on **connection pool exhaustion**
- [ ] Alert on **slow query threshold** (e.g., > 1s)
- [ ] Alert on **index size growth** anomalies

### Documentation

- [ ] **Schema documented** (table structure, indexes)
- [ ] **Query patterns documented** (RRF queries, filters)
- [ ] **Monitoring dashboards** set up and shared
- [ ] **Runbook created** for common issues
  - Index rebuild procedure
  - Cache warming after restart
  - Migration rollback
  - Performance debugging steps

### Optimization Opportunities

- [ ] **Query plan review** after initial deployment
  - Check for unexpected seq scans
  - Verify join strategies in RRF queries
  - Tune work_mem if seeing disk sorts

- [ ] **Index tuning** based on real workload
  ```sql
  -- For HNSW:
  SET hnsw.ef_search = 40;  -- Default
  -- Try 60-100 for higher recall, 20-30 for faster queries

  -- For IVFFlat:
  SET ivfflat.probes = 10;  -- Default is 1
  -- Higher = better recall, slower queries
  ```

- [ ] **Embedding model optimization**
  - Consider smaller dimensions if possible (768 vs 1536)
  - Use normalized embeddings for inner product optimization
  - Quantization if memory-constrained

### Disaster Recovery

- [ ] **Backup strategy** verified
  - PostgreSQL base backups include pgvector data
  - Point-in-time recovery tested
  - Backup retention policy defined

- [ ] **Restore procedure** tested
  - Verify extension re-enabled after restore
  - Verify indexes rebuilt/valid
  - Test query performance after restore

- [ ] **Failover tested** (if using replication)
  - Verify pgvector extension on standby
  - Verify indexes replicated correctly
  - Test read queries on standby

## Validation Checklist

Run these queries to validate deployment:

```sql
-- 1. Extension installed
SELECT * FROM pg_extension WHERE extname = 'vector';

-- 2. Indexes exist and are valid
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'documents';

-- 3. Data populated
SELECT count(*) FROM documents;
SELECT count(*) FROM documents WHERE embedding IS NOT NULL;

-- 4. Indexes are used
EXPLAIN SELECT id FROM documents ORDER BY embedding <=> '[0,0,0,...]'::vector LIMIT 10;

-- 5. Cache hit ratio > 95%
SELECT
  round(100.0 * sum(idx_blks_hit) / NULLIF(sum(idx_blks_hit + idx_blks_read), 0), 2) as cache_hit_ratio
FROM pg_stat_user_indexes
WHERE indexrelname LIKE '%embedding%';

-- 6. No table bloat
SELECT
  schemaname, tablename,
  n_dead_tup, n_live_tup,
  round(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_ratio
FROM pg_stat_user_tables
WHERE tablename = 'documents';
-- dead_ratio should be < 10%

-- 7. Query performance
EXPLAIN (ANALYZE, BUFFERS)
WITH vector_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY embedding <=> '[...]'::vector) as rank
  FROM documents ORDER BY embedding <=> '[...]'::vector LIMIT 100
),
text_search AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY ts_rank_cd(content_tsv, query) DESC) as rank
  FROM documents, plainto_tsquery('english', 'test query') query
  WHERE content_tsv @@ query LIMIT 100
)
SELECT COALESCE(v.id, t.id), d.title,
       COALESCE(1.0 / (60 + v.rank), 0.0) + COALESCE(1.0 / (60 + t.rank), 0.0) as score
FROM vector_search v
FULL OUTER JOIN text_search t ON v.id = t.id
JOIN documents d ON d.id = COALESCE(v.id, t.id)
ORDER BY score DESC LIMIT 20;
-- Should complete in < 200ms
```

## Rollback Plan

If issues arise after deployment:

1. **Query Issues**
   - Revert to simple vector-only or text-only search
   - Disable RRF temporarily
   - Fall back to application-level ranking

2. **Performance Issues**
   - Increase shared_buffers
   - Drop and recreate index with different parameters
   - Switch HNSW → IVFFlat (or vice versa)

3. **Data Issues**
   - Restore from backup
   - Re-run migration from source vector DB
   - Verify embedding dimensions match

4. **Extension Issues**
   - Check PostgreSQL logs for errors
   - Verify pgvector version compatibility
   - Re-install extension if corrupt

## Success Metrics

After deployment, monitor these metrics:

- [ ] **Query latency** p50 < 50ms, p95 < 150ms, p99 < 300ms
- [ ] **Cache hit ratio** > 95%
- [ ] **Result relevance** (user feedback/click-through rate)
- [ ] **System resource usage** within acceptable limits
  - CPU: < 70% average
  - Memory: shared_buffers fully utilized
  - Disk I/O: minimal (<5% of queries causing disk reads)
- [ ] **Error rate** < 0.1%
- [ ] **Availability** > 99.9%

## Getting Help

- pgvector GitHub issues: https://github.com/pgvector/pgvector/issues
- PostgreSQL mailing lists: https://www.postgresql.org/list/
- Stack Overflow tag: `pgvector`
- ParadeDB Discord (for pg_search): https://discord.gg/paradedb
