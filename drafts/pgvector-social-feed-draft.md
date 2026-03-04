---
title: "How We Built a Sub-50ms Personalized Feed with pgvector and Go"
date: 2026-03-11
summary: "A production case study: PostgreSQL vector search, two-tier SWR caching, and the Go performance patterns that got us from 800ms Rails latency to sub-50ms."
tags: ["go", "postgresql", "performance", "wishew", "redis"]
draft: true
cover:
  image: ""
  alt: "How We Built a Sub-50ms Personalized Feed with pgvector and Go"
  relative: false
---

## The problem we actually had

Wishew is a social wish-fulfillment platform. Users post wishes, other users fund them. The feed is the core experience: personalized content that matches your interests, not just reverse chronological order.

Our feed was a Rails endpoint. It worked. It was also slow: **800ms-1.2s P95 latency** on feed generation. For a social app where users scroll through dozens of items per session, that's painful. We needed sub-300ms for the global scaling we were planning.

We considered three options:

| Approach | Upside | Ceiling |
|----------|--------|---------|
| Optimize Rails + caching | Fastest to ship | Ruby GIL + ActiveRecord overhead |
| Extract to Rails microservice | Less operational change | Same performance ceiling |
| Build dedicated Go service | Highest performance ceiling | Polyglot complexity |

We picked Go. Not because Rails is bad (it handles all our writes and business logic), but because the Ruby GIL and ActiveRecord's object allocation patterns create a hard ceiling for read-heavy, latency-sensitive workloads. We wanted headroom, not just a fix.

The result after five months in production: **sub-50ms P50, sub-100ms P95 latency, 99.5% cache hit rate**. The Go service (we call it "Outpost API") sits behind Nginx alongside the Rails core API. It only reads. All writes go through Rails to the primary database.

---

## Two feeds, not one

Before diving into pgvector, a clarification. Outpost serves three feed endpoints, and they work differently:

**`/feed`** is the main personalized feed. It interleaves posts and wishes using a scoring algorithm with configurable weights (stored in the database, SWR-cached). The scoring considers recency, engagement signals, connection strength, and a deterministic shuffle seeded per-request for pagination consistency. No vector search here; this is traditional scoring and ranking.

**`/explore`** is where pgvector lives. It has four sections: `for_you` (embedding similarity), `trending` (engagement velocity), `connections` (social graph), and `new` (recency). The `for_you` section uses cosine distance between user and wish embeddings to find semantically similar content. Items are deduplicated across sections.

**`/discover`** is a wishes-only feed, a simpler variant of `/explore`.

The rest of this article focuses on the pgvector-powered `/explore` endpoint and the caching layer that makes all three endpoints fast.

---

## Why pgvector (instead of a dedicated vector DB)

The vector database market has attracted serious VC money. Pinecone raised $100M, Weaviate $50M, and everyone seems to be building dedicated vector infrastructure. So why did we stick with PostgreSQL?

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

### The "Case Against pgvector"

There's a legitimate counterargument. A [Hacker News discussion](https://news.ycombinator.com/item?id=45798479) titled "The Case Against pgvector" raised performance concerns at scale. The criticism is fair: pgvector won't match Pinecone's throughput at millions of vectors with complex filtered queries.

But "at scale" is doing a lot of work in that sentence. For our ~100K embeddings, brute-force cosine distance completes in milliseconds. And our caching layer means the database handles vector search on fewer than 0.5% of requests. If you're building the next Spotify Discover Weekly with 100M+ embeddings and sub-millisecond requirements, yes, use a dedicated vector database. If you're a social platform with six-figure embedding counts and a solid cache, pgvector on your existing Postgres is the boring, correct choice.

---

## Architecture overview

```
┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Mobile Apps │────▶│  Outpost API    │────▶│ PostgreSQL      │
│             │     │  (Go, read-only)│     │ (read replica)  │
└─────────────┘     └────────┬────────┘     │ + pgvector      │
                             │              └─────────────────┘
                             ▼
                    ┌─────────────────┐
                    │ Two-tier Cache  │
                    │ L1: Ristretto   │
                    │ L2: Redis       │
                    │ Pub/Sub inval.  │
                    └─────────────────┘

┌─────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Mobile Apps │────▶│  Rails API      │────▶│ PostgreSQL      │
│ (writes)    │     │  (all writes)   │     │ (primary)       │
└─────────────┘     └─────────────────┘     └─────────────────┘
```

**Read-write separation** is the core architectural decision. Feed traffic (the majority of requests) never touches the primary database. The Go service reads from the replica and caches everything it can. Rails handles all writes, business logic, and the write path for embeddings.

### Page 1 vs Page 2+

The feed request lifecycle has two very different performance profiles:

**Page 1 (cache cold, ~200-400ms):** Outpost queries posts, wishes, follows, and recommendations in parallel using `errgroup`. It composes up to 1000 ranked items and stores them in Redis with key `feed:{user_id}:{seed_id}`. The seed is deterministic per-session, so pagination is consistent even if the underlying data changes.

**Page 2+ (cache warm, ~10-50ms):** Redis lookup by key, in-memory pagination over the pre-computed result set. No database queries at all. Since most users paginate through multiple pages in a session, the expensive Page 1 computation is amortized across dozens of cheap subsequent requests.

---

## The embedding strategy

### What gets embedded

We create embeddings for two entity types:

**Wishes** (content items):
- Source: AI-generated synthesis of title + description (not the raw text)
- Trigger: when a wish is published and passes quality evaluation
- Storage: `wish_embeddings` table with pgvector column

**Users** (preference profiles):
- Source: weighted average of wish embeddings they've interacted with
- Trigger: donations, saves, follows, views
- Storage: `user_embeddings` table with pgvector column

### Why AI synthesis, not raw text

We don't embed the raw wish title and description. Instead, we first generate an AI synthesis using Gemini, then embed that. User-generated content is noisy: typos, mixed languages, incomplete descriptions. The synthesis normalizes all of this into a consistent semantic representation. Every wish gets the same treatment regardless of how well the user wrote it.

### Asymmetric retrieval

One detail that made a measurable difference: we use different task types for embedding stored content vs. user queries. Gemini's embedding API supports `RETRIEVAL_DOCUMENT` (for content being stored) and `RETRIEVAL_QUERY` (for the query used to find similar content). This asymmetric approach produces better similarity matches than using the same task type for both sides.

### The user embedding formula

Instead of reprocessing a user's entire interaction history on every action, we use an **incremental weighted average**:

```
new_embedding = (old_embedding × old_weight + wish_embedding × action_weight) / new_weight
```

The weights reflect engagement depth:

| Action | Weight |
|--------|--------|
| Donation | `base_weight + (amount / wish_goal)` |
| Full view (75%+) | `0.75` |
| Partial view (10-75%) | `0.25` |
| Under 10% watched | `0` (ignored) |

A donation to a wish you care about updates your profile more than a quick scroll-past. No batch recomputation, no event sourcing. Simple, fast, good enough.

---

## Why 768 dimensions (not 1536 or 3072)

When we chose Gemini's text-embedding-004 model with 768 dimensions, it wasn't a compromise. The data shows it's the optimal point on the cost-quality curve.

The [Particula benchmark](https://particula.tech/blog/embedding-dimensions-rag-vector-search) and [Microsoft's Azure SQL analysis](https://devblogs.microsoft.com/azure-sql/embedding-models-and-dimensions-optimizing-the-performance-resource-usage-ratio/) both show accuracy plateaus between 768-1024 dimensions:

| Dimensions | Quality vs 3072 | Storage (10M vectors) | Query Speed |
|------------|-----------------|----------------------|-------------|
| 384 | ~98% | $3.75/mo | 4x faster |
| **768** | **99.74%** | **$7.50/mo** | **2x faster** |
| 1536 | 100% | $15/mo | baseline |
| 3072 | 100% | $30/mo | 0.5x slower |

0.26% quality loss. 2x faster queries. 4x less storage than 3072. For social content (posts, wishes, short-form UGC), the plateau point is squarely in the 512-768 range. Medical literature or scientific papers might justify 1024+. We don't index medical literature.

Microsoft's Azure SQL team reported that switching from 1536 to 384 dimensions cut query latency in half and reduced vector database costs by 75%, with no measurable drop in retrieval accuracy. We stayed at 768 to leave margin for future complexity, but 384 would probably have been fine too.

---

## The candidate pool approach (why we skip HNSW)

Most pgvector tutorials recommend HNSW (Hierarchical Navigable Small World) indexing for approximate nearest neighbor search. We don't use it.

Instead, we run a brute-force scan on a filtered subset with a distance threshold:

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

With ~100K embeddings, brute-force cosine distance completes fast enough. We get exact results (not approximate), no index tuning, no parameter optimization. And since 99.5% of requests hit cache, the database only runs this query on rare cache misses.

The trigger to add HNSW indexing: embedding table > 1M rows, or P95 query latency > 100ms without cache. Until then, YAGNI.

---

## The real performance lever: two-tier SWR caching

Here's the honest truth: **pgvector isn't why we achieve sub-50ms latency. Caching is.**

### Two tiers

Most articles about Redis caching describe a single cache layer. We use two:

**L1: Ristretto (in-memory, per-process).** Zero network latency, limited by process memory. Handles the hottest keys (active users mid-session).

**L2: Redis (ElastiCache).** Shared across all Outpost instances. Handles the full working set. Invalidation propagated via Redis Pub/Sub, so all instances see cache busts immediately.

A request checks L1 first. On miss, checks L2. On miss, hits the database and populates both tiers.

### Stale-While-Revalidate

The SWR pattern is what eliminates latency spikes:

```go
type SWRConfig struct {
    FreshTTL   time.Duration  // 3 minutes - data considered fresh
    StaleTTL   time.Duration  // 10 minutes - data fully expires
    LockTTL    time.Duration  // 30 seconds - prevents cache stampede
}
```

During the stale window (3-10 minutes), users get instant responses with slightly old data while a background goroutine refreshes the cache. The `LockTTL` acquires a distributed lock so only one goroutine refreshes a given key, preventing the thundering herd problem.

| Request Type | Cache Behavior |
|-------------|----------------|
| First page load | Cache miss, fetch, store |
| Subsequent pages | Cache hit (paginate in-memory) |
| Return visitor (< 3 min) | Fresh cache hit |
| Return visitor (3-10 min) | Stale hit + background refresh |
| Return visitor (> 10 min) | Cache miss |

### The safety valve

SWR optimizes for performance, but some changes can't wait. If a user blocks someone or reports content, we can't serve stale data for 10 minutes.

For critical negative signals (blocks, reports, content removal), we bypass SWR entirely with pattern-based invalidation:

```go
cache.InvalidateSWRPattern(ctx, fmt.Sprintf("feed:user:%d:*", userID))
```

The Pub/Sub layer propagates the invalidation to all instances, including their L1 caches. Safety-critical changes take effect immediately.

---

## Go performance patterns that actually mattered

The choice to write Outpost in Go wasn't just about raw speed. It was about having direct control over allocations, concurrency, and serialization. Here's what moved the needle in practice:

**errgroup for parallel queries.** Feed composition requires posts, wishes, follows, and recommendations. With `errgroup`, we run all four queries concurrently with hard error propagation. If any fails, the group cancels the rest.

**pgx batch operations.** After getting the initial feed items, we need to enrich them (author info, engagement counts, media URLs). Instead of N+1 queries, `database.SendBatch()` groups all enrichment queries into a single round-trip to PostgreSQL.

**easyjson for serialization.** The standard `encoding/json` package uses reflection and allocates heavily. `easyjson` generates struct-specific serializers at build time. On a response with 20-30 feed items, each carrying nested objects, the difference adds up.

**sqlc for all SQL.** Every query is a `.sql` file. `sqlc` generates type-safe Go code from it. Zero hand-written query code means zero opportunities for SQL string bugs, and the generated code is allocation-efficient.

**sync.Pool for cache structs.** Feed response objects are large. Allocating and GC-ing them on every request creates pressure. `sync.Pool` recycles these structs between requests, reducing GC pauses in hot paths.

**Worker pool for background tasks.** Enrichment prefetching and cache warming happen in bounded goroutines. A worker pool with configurable concurrency prevents goroutine leaks and controls backpressure.

**Pre-allocated slices and maps.** In hot paths, we allocate slices and maps with known capacity upfront (`make([]Item, 0, expectedSize)`) instead of letting them grow dynamically. Small change, measurable reduction in allocations.

**PGO (Profile-Guided Optimization).** We capture pprof profiles from staging, then rebuild with `go build -pgo=default.pgo`. The compiler optimizes hot paths based on actual execution patterns. Free performance for the cost of a build flag.

None of these are novel. They're Go basics. But applying all of them, in every hot path, across every endpoint, is what got us from 200ms to 50ms.

---

## Production numbers

After five months in production (October 2025 to March 2026):

| Metric | Value |
|--------|-------|
| P50 Latency | < 50ms |
| P95 Latency | < 100ms |
| Cache Hit Rate | 99.5% |
| Page 1 (cache cold) | ~200-400ms |
| Page 2+ (cache warm) | ~10-50ms |

<!-- TODO: Fill in P99 latency, embedding table size, total embedding count from New Relic / PostgreSQL when publishing -->

The latency numbers include the full request lifecycle: auth, feed composition or cache lookup, enrichment, serialization, response. Not just the database query.

---

## What we'd do differently

### Fix the weight decay problem (we just did)

We discovered this *while writing this post*: the incremental user embedding formula accumulates weight indefinitely. After a year of activity, a user might have `cumulative_weight = 500`. A new donation (weight ~1.0) would influence their profile by 0.2%. The profile freezes; new interests barely register.

The fix: apply a decay factor before each update:

```ruby
decayed_weight = old_weight * DECAY_FACTOR  # e.g., 0.99
new_weight = decayed_weight + action_weight
```

Recent actions stay meaningful while history gradually fades. We're implementing this now.

*Writing about your system forces you to examine assumptions you stopped questioning.*

### Start with HNSW earlier

While brute-force works at our scale, we should have added HNSW from day one. The operational overhead is minimal (`CREATE INDEX CONCURRENTLY`), and it provides headroom for growth without code changes.

### Quantization from the start

We could reduce storage by 50% using half-precision vectors. pgvector supports `halfvec(768)` natively. The research on asymmetric retrieval suggests that combining half-precision storage with full-precision queries loses almost nothing in accuracy.

### Pre-warm user embeddings

New users start with a zero vector until they interact with content. Cold-start is a real problem. Pre-populating based on onboarding preferences ("pick your interests") would give new users relevant recommendations from their first session.

### Embedding versioning

When we update the embedding model, we need to regenerate all embeddings. A versioning system (embedding model version stored alongside the vector) would allow gradual rollout and A/B testing instead of a big-bang migration.

---

## The boring conclusion

PostgreSQL with pgvector, Redis with SWR, Go with careful allocation management. No dedicated vector database. No ML pipeline. No Kubernetes. The boring technology won because it let us focus on the product instead of the infrastructure.

The uncomfortable question for anyone evaluating dedicated vector databases: what's your cache hit rate going to be? If the answer is "above 95%," your database choice matters a lot less than your caching strategy. We got sub-50ms latency not because pgvector is fast (it's adequate), but because 99.5% of requests never reach pgvector at all.

Sometimes the best architecture is the one you already have.

---

## References

- [pgvector GitHub](https://github.com/pgvector/pgvector)
- [Embedding Dimensions: The Diminishing Returns](https://particula.tech/blog/embedding-dimensions-rag-vector-search)
- [Azure SQL: Embedding Models and Dimensions](https://devblogs.microsoft.com/azure-sql/embedding-models-and-dimensions-optimizing-the-performance-resource-usage-ratio/)
- [SOTA Embedding Retrieval](https://shav.dev/blog/state-of-the-art-embedding-retrieval)
- [Google Gemini Embedding API](https://ai.google.dev/gemini-api/docs/embeddings)

---

*Massimiliano Aroffo is a Principal Software Engineer at [HikmaAI](https://hikmaai.io/) and Cloud Engineer and Architect at [Wishew](https://wishew.com/), where he builds the infrastructure described in this article and occasionally discovers bugs in production systems by writing about them.*
