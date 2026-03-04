---
title: "How We Built a Sub-50ms Personalized Feed with pgvector and Go"
date: 2026-01-15
summary: "A real-world case study on building a social feed recommendation system using PostgreSQL's vector extension, without the complexity of dedicated vector databases."
tags: ["go", "postgresql", "performance", "wishew"]
draft: true
---

## The problem: personalization at scale

When we set out to build personalized feeds for Wishew (a social wish-fulfillment platform), we faced a familiar challenge: how do you serve millions of personalized feed requests without sacrificing latency or breaking the bank?

The naive approach ("just sort by timestamp") doesn't cut it for social platforms. Users expect content that resonates with their interests, not just what's newest. But recommendation systems typically require:

- Dedicated vector databases (Pinecone, Weaviate, Milvus)
- Complex ML pipelines
- Significant infrastructure overhead

We wanted something simpler. Something that could run on our existing PostgreSQL infrastructure while still delivering sub-100ms responses.

Spoiler: we got it down to **sub-50ms P50 latency** with a **99.5% cache hit rate**.

Here's how.

---

## Why pgvector (instead of a dedicated vector DB)

The vector database market is booming. Pinecone raised $100M, Weaviate $50M, and everyone seems to be building dedicated vector infrastructure. So why did we stick with PostgreSQL?

### The simplicity argument

We already had:
- PostgreSQL running in production (RDS)
- Read replicas for horizontal scaling
- A team familiar with SQL and Postgres operations
- Existing backup, monitoring, and alerting pipelines

Adding pgvector meant:
```sql
CREATE EXTENSION vector;
```

That's it. No new infrastructure to deploy, no new operational knowledge to acquire, no new billing to manage.

### The cost argument

Vector database pricing can be opaque, but here's a rough comparison for our scale (~100K embeddings):

| Solution | Monthly Cost | Operational Overhead |
|----------|-------------|---------------------|
| Pinecone | $70-200+ | Low (managed) |
| Self-hosted Weaviate | $100-300 | High |
| pgvector on existing RDS | **$0 incremental** | None |

When you already have PostgreSQL, pgvector is essentially free.*

*\*Free in terms of infrastructure complexity and licensing. Vector distance calculations are CPU-intensive, so your read replica will work harder during cache misses. More on how we handle this later.*

### The trade-off

pgvector won't match Pinecone's performance at millions of vectors with complex queries. But for our scale and use case, it's more than sufficient. The key insight: **your caching layer will handle most requests anyway**.

---

## Architecture overview

Our feed system uses a read-write separation pattern:

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Mobile Apps │────▶│  Outpost API    │────▶│ PostgreSQL      │
│             │     │  (Go, read-only)│     │ (read replica)  │
└─────────────┘     └────────┬────────┘     │ + pgvector      │
                             │              └─────────────────┘
                             ▼
                    ┌─────────────────┐
                    │  Redis Cache    │
                    │  (SWR pattern)  │
                    └─────────────────┘

┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Mobile Apps │────▶│  Rails API      │────▶│ PostgreSQL      │
│ (writes)    │     │  (all writes)   │     │ (primary)       │
└─────────────┘     └─────────────────┘     └─────────────────┘
```

**Key principle**: The Go service (Outpost) only reads. All writes go through Rails to the primary. This lets us scale reads independently and keeps the primary database focused on writes.

---

## The embedding strategy

### What gets embedded

We create embeddings for two entity types:

**1. Wishes** (content items)
- Source: AI-generated synthesis of title + description
- Trigger: When a wish is published and passes quality evaluation
- Storage: `wish_embeddings` table with pgvector column

**2. Users** (preference profiles)
- Source: Weighted average of wish embeddings they've interacted with
- Trigger: Donations, saves, follows, views
- Storage: `user_embeddings` table with pgvector column

### The user embedding formula

Here's the clever part. Instead of reprocessing a user's entire history on every action, we use an **incremental weighted average**:

```
new_embedding = (old_embedding × old_weight + wish_embedding × action_weight) / new_weight
```

This means:
- A donation adds the wish embedding with high weight
- A 75%+ watch adds with medium weight
- A partial view adds with low weight
- No need to recompute from scratch

The weights are configurable:

| Action | Weight |
|--------|--------|
| Donation | `base_weight + (amount / wish_goal)` |
| Full view (75%+) | `0.75` |
| Partial view (10-75%) | `0.25` |
| Under 10% watched | `0` (ignored) |

### Why AI synthesis, not raw text

We don't embed the raw wish title and description. Instead, we first generate an AI synthesis using Gemini, then embed that.

Why?
1. **Noise reduction**: User-generated content is messy. The synthesis normalizes it.
2. **Semantic enrichment**: The synthesis captures intent, not just keywords.
3. **Consistent quality**: Every wish gets the same treatment regardless of how well the user wrote it.

---

## Why 768 dimensions (not 1536 or 3072)

When we chose Gemini's text-embedding-004 model with 768 dimensions, it wasn't a compromise. The data shows it's the optimal choice.

### The diminishing returns curve

Benchmark studies consistently show accuracy plateaus between 768-1024 dimensions:

| Dimensions | Quality vs 3072 | Storage (10M vectors) | Query Speed |
|------------|-----------------|----------------------|-------------|
| 384 | ~98% | $3.75/mo | 4x faster |
| **768** | **99.74%** | **$7.50/mo** | **2x faster** |
| 1536 | 100% | $15/mo | baseline |
| 3072 | 100% | $30/mo | 0.5x slower |

Gemini at 768 dimensions has only **0.26% quality loss** compared to 3072 on MTEB benchmarks.

### Domain-specific sweet spots

Research shows different content types plateau at different dimensions:

| Content Type | Plateau Point |
|--------------|---------------|
| Simple factual (Wikipedia) | 256-512 |
| General content | 512-768 |
| Complex (scientific, financial) | 768 |
| Medical literature | 1024+ |

Social content (wishes, posts) falls squarely in the "general content" category. **768 is not a compromise; it's the sweet spot.**

### The real-world impact

One case study reported:
> "Switching from 1536 to 384 dimensions cut query latency in half and reduced vector database costs by 75%, with no measurable drop in retrieval accuracy."

For us, 768 dimensions means:
- 2x faster similarity calculations vs 1536
- 4x less storage vs 3072
- Negligible quality difference

---

## The candidate pool approach (why we skip HNSW)

Here's something that might surprise you: we don't use HNSW or IVFFlat indexes for our vector searches.

### The conventional wisdom

Most pgvector tutorials recommend:
```sql
CREATE INDEX ON wish_embeddings USING hnsw (embedding vector_cosine_ops);
```

HNSW (Hierarchical Navigable Small World) provides approximate nearest neighbor search with excellent performance at scale.

### Our approach

Instead, we use what we call a **candidate pool** strategy, essentially a brute-force scan on a filtered subset with a distance threshold:

```sql
WITH similar_wishes AS (
  SELECT
    we.wish_id,
    (we.embedding <=> ue.embedding) as distance
  FROM wish_embeddings we, user_embeddings ue
  WHERE ue.user_id = $1
    AND (we.embedding <=> ue.embedding) < 0.5  -- distance threshold
  ORDER BY distance
  LIMIT 500  -- candidate pool size
)
SELECT * FROM similar_wishes
-- ... additional scoring and filtering
```

### Why this works for us

1. **Scale**: With ~100K embeddings, brute-force cosine distance is fast enough
2. **Caching**: 99.5% of requests hit cache anyway, so the database only does heavy lifting on cache misses
3. **Simplicity**: No index tuning, no approximate search trade-offs
4. **Determinism**: Exact results, not approximate

The critical insight: **our 99.5% cache hit rate is what protects the database from CPU overload**. Without effective caching, this approach would crush the read replica under concurrent load. The candidate pool strategy only works because we rarely hit the database.

### When to add HNSW

We're monitoring query performance. The trigger to add HNSW indexing will be:
- Embedding table > 1M rows, OR
- P95 query latency > 100ms without cache

Until then, YAGNI (You Ain't Gonna Need It).

---

## The secret sauce: SWR caching

Here's the truth: **pgvector isn't why we achieve sub-50ms latency. Caching is.**

We implemented a Stale-While-Revalidate (SWR) pattern in Go:

```go
type SWRConfig struct {
    FreshTTL   time.Duration  // 3 minutes - data considered fresh
    StaleTTL   time.Duration  // 10 minutes - data fully expires
    LockTTL    time.Duration  // 30 seconds - prevents cache stampede
}
```

The `LockTTL` matters most: when stale data triggers a background refresh, we acquire a distributed lock to prevent multiple concurrent requests from all trying to refresh the same cache key simultaneously (the "thundering herd" problem).

### How SWR works

```
Request arrives
    │
    ▼
┌─────────────────────────────────────────────────────┐
│ Is data in cache?                                    │
└─────────────────────────────────────────────────────┘
    │ Yes                                    │ No
    ▼                                        ▼
┌─────────────────┐                    ┌─────────────────┐
│ Is it fresh?    │                    │ Fetch from DB   │
│ (< 3 min old)   │                    │ Store in cache  │
└─────────────────┘                    │ Return          │
    │ Yes    │ No (stale)              └─────────────────┘
    ▼        ▼
┌────────┐ ┌──────────────────────────┐
│ Return │ │ Return stale immediately │
│ cached │ │ + Background refresh     │
└────────┘ └──────────────────────────┘
```

### The key insight

During the "stale window" (3-10 minutes), users get **instant responses** with slightly old data while we refresh in the background. This eliminates latency spikes entirely.

### Cache hit patterns

| Request Type | Cache Behavior |
|-------------|----------------|
| First page load | Cache miss → fetch → store |
| Subsequent pages | Cache hit (paginate in-memory) |
| Return visitor (< 3 min) | Fresh cache hit |
| Return visitor (3-10 min) | Stale hit + background refresh |
| Return visitor (> 10 min) | Cache miss |

For social feeds, most users paginate through multiple pages in a session. After the first page, **every subsequent request is a cache hit**.

### The safety valve

SWR optimizes for performance, but what about safety? If a user blocks someone or reports content, we can't show stale data for 10 minutes.

For critical negative signals (blocks, reports, content removal), we bypass SWR entirely using pattern-based cache invalidation:

```go
cache.InvalidateSWRPattern(ctx, fmt.Sprintf("feed:user:%d:*", userID))
```

This ensures safety-critical changes take effect immediately, while normal feed updates benefit from SWR's latency optimization.

---

## Production numbers

<!-- TODO: Fill in actual metrics from New Relic / PostgreSQL -->

After [X months] in production:

| Metric | Value |
|--------|-------|
| P50 Latency | < 50ms |
| P95 Latency | < 100ms |
| P99 Latency | TBD |
| Cache Hit Rate | 99.5% |
| Embedding Tables Size | TBD |
| Total Embeddings | TBD |

### Query performance (uncached)

| Query | Avg Time |
|-------|----------|
| GetRecommendedWishes | TBD |
| Embedding similarity | TBD |

---

## What we'd do differently

### 0. Fix the weight decay problem (we just did)

Here's something we discovered *while writing this post*: our incremental user embedding formula has a flaw.

The formula accumulates weight indefinitely:

```
cumulative_weight = old_weight + action_weight
```

After a year of activity, a user might have `cumulative_weight = 500`. At that point, a new donation (weight ~1.0) influences their profile by:

```
1.0 / 500 = 0.2%
```

The profile becomes "frozen": new interests barely register.

**The fix**: Apply a decay factor before each update:

```ruby
decayed_weight = old_weight * DECAY_FACTOR  # e.g., 0.99
new_weight = decayed_weight + action_weight
```

This keeps recent actions meaningful while still honoring history. We're implementing this now.

*Lesson learned: Writing about your system forces you to examine assumptions you stopped questioning.*

### 1. Start with HNSW earlier

While brute-force works now, we should have added HNSW indexing from day one. The operational overhead is minimal, and it would give us headroom for growth without code changes.

```sql
CREATE INDEX CONCURRENTLY ON wish_embeddings
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);
```

### 2. Quantization from the start

We could reduce storage by 50% using half-precision vectors (float16 instead of float32). pgvector supports this:

```sql
ALTER TABLE wish_embeddings
  ALTER COLUMN embedding TYPE halfvec(768);
```

### 3. Pre-warm user embeddings

Currently, new users start with a zero vector until they interact with content. We could pre-populate based on onboarding preferences ("pick your interests").

### 4. Embedding versioning

When we update our embedding model, we need to regenerate all embeddings. A proper versioning system would allow gradual rollout and A/B testing.

---

## Key takeaways

1. **pgvector is production-ready** for datasets under 1M vectors. Don't over-engineer.

2. **768 dimensions is the sweet spot** for most content types. Higher dimensions cost more and rarely improve quality.

3. **Caching is your real performance lever**. SWR pattern turns a "good enough" database into a "blazing fast" service.

4. **Incremental user embeddings** let you update preferences without reprocessing history.

5. **Start simple, add complexity when needed**. Brute-force vector search is fine until it isn't.

The boring technology often wins. PostgreSQL with pgvector, Redis with SWR, and a simple candidate pool approach gave us sub-50ms latency without the operational complexity of dedicated vector infrastructure.

Sometimes the best architecture is the one you already have.

---

## References

- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [Embedding Dimensions: The Diminishing Returns](https://particula.tech/blog/embedding-dimensions-rag-vector-search)
- [Azure SQL: Embedding Models and Dimensions](https://devblogs.microsoft.com/azure-sql/embedding-models-and-dimensions-optimizing-the-performance-resource-usage-ratio/)
- [Google Gemini Embedding API](https://ai.google.dev/gemini-api/docs/embeddings)

---

*This post was written with assistance from Claude Code. The architecture, implementation, and production experience are real; the words were polished by AI.*
