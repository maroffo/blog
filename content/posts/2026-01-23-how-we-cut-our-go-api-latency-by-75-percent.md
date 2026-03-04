---
title: "How We Cut Our Go API Latency by 75%"
date: 2026-01-23
summary: "A practical guide to modern Go performance patterns we applied to our feed service at Wishew. P50 latency from ~200ms to ~50ms."
tags: ["go", "performance", "optimization", "wishew"]
draft: false
cover:
  image: "images/cover-go-latency.png"
  alt: "How We Cut Our Go API Latency by 75%"
  relative: false
---

## The starting point

When I [returned to hands-on development at Wishew]({{< ref "2025-10-03-building-a-smart-ecs-deployment-notifier-with-aws-lambda-gitlab-and-slack" >}}), one of my first major projects was our **Outpost API**: a high-performance Go service that generates personalized feeds. It queries PostgreSQL, enriches data with user relationships and media, caches aggressively in Redis, and serves ~10K requests/minute at peak.

**A confession:** I'm not a Go developer. My experience with the language was limited to a handful of utilities, automation tools, and a few REST APIs I'd built over the years. I proposed Go for Outpost API for pragmatic reasons: it's a simple language, compiles to a single binary (truly performant), has minimal memory footprint, and could eventually be deployed on the edge. The other factor? How easy it was to build the first PoC with Gemini and Claude Code (Sonnet 3.5). AI-assisted development made Go feel accessible even without deep expertise.

The initial architecture worked. We had [taught Claude our patterns]({{< ref "2025-11-09-from-asking-claude-to-code-to-teaching-claude-our-patterns-building-modular-ai-skills" >}}), implemented proper dependency injection, wrote thorough tests. But over time, I realized that not all the early choices were good ones. The service was fast, sure, but it had obvious bottlenecks: consequences of decisions made without fully understanding Go's idioms and ecosystem.

We were seeing P50 latencies around 200ms. For a feed service, that's... sluggish. At our scale, 200ms latency means higher infrastructure costs, users noticing the lag on slower connections, and a feed that feels "heavy" instead of snappy.

Over the past months, we worked through a systematic optimization effort. No magic bullets, just disciplined application of Go best practices and modern stdlib features. The result? **P50 latency dropped from ~200ms to ~50ms.** Here's everything we did.

*Note: Production latency metrics were identified through structured debug logging (thank goodness I implemented that properly from the start). Micro-benchmarks were run locally using Go's built-in `testing.B` framework.*

***

# Part 1: The smoking gun

## 1. Fast JSON serialization with easyjson

**The problem:** JSON rendering was eating almost 100ms per request.

When I first analyzed the debug logs, I expected the bottleneck to be database queries or Redis lookups. Instead, the timing breakdowns pointed at `encoding/json`. Almost half of our request time was spent serializing the response.

Go's standard library uses reflection for JSON marshaling, which is flexible but slow. For a feed response with dozens of nested objects (posts, wishes, user data, media URLs), this adds up fast. We were essentially paying a "reflection tax" on every single request.

**The solution:** Replace `encoding/json` with [easyjson](https://github.com/mailru/easyjson), which generates serialization code at build time.

```go
//go:generate easyjson -all types.go

type FeedResponse struct {
    Items    []FeedItem `json:"items"`
    NextPage string     `json:"next_page,omitempty"`
    Seed     int64      `json:"seed"`
}
```

After adding the `//go:generate` directive, run `make generate` to create the `*_easyjson.go` files. The generated code handles marshaling without reflection.

```go
// Handler using easyjson
func (h *FeedHandler) GetFeed(w http.ResponseWriter, r *http.Request) {
    // ... fetch feed ...

    w.Header().Set("Content-Type", "application/json")
    out, _ := easyjson.Marshal(response)
    w.Write(out)
}
```

**Results:**

| Metric | encoding/json | easyjson | Improvement |
|--------|---------------|----------|-------------|
| Feed serialization | ~100ms | ~8ms | **~12x faster** |

**Why easyjson over alternatives?** We benchmarked several options: [sonic](https://github.com/bytedance/sonic), [json-iterator](https://github.com/json-iterator/go), [goccy/go-json](https://github.com/goccy/go-json). easyjson performed best with our specific schema (deeply nested structs with many optional fields). The tradeoff is code generation: you need to run `make generate` after modifying response structs. To prevent "forgot to regenerate" bugs, we added a CI job that regenerates the serializers and uses `git diff --exit-code` to fail if the output differs from what's committed. For a ~90ms gain, the minor inconvenience is absolutely worth it.

**Lesson learned:** Don't assume the bottleneck is where you expect it. Profile first.

***

# Part 2: The I/O layer

## 2. Database migration: lib/pq → pgx with batch queries

**The problem:** lib/pq is solid but doesn't support batch queries. Multiple queries = multiple round-trips.

Our enrichment process needs to fetch user flags, media URLs, and tags for each feed item. That's three queries per request. Three network round-trips to PostgreSQL.

**The solution:** Migrate to [pgx/v5](https://github.com/jackc/pgx) and batch related queries.

```go
// Before: 3 round-trips to database
users, _ := db.Query("SELECT * FROM users WHERE id = ANY($1)", userIDs)
flags, _ := db.Query("SELECT * FROM user_flags WHERE user_id = ANY($1)", userIDs)
media, _ := db.Query("SELECT * FROM media WHERE user_id = ANY($1)", userIDs)

// After: 1 round-trip with batch
batch := &pgx.Batch{}
batch.Queue("SELECT * FROM users WHERE id = ANY($1)", userIDs)
batch.Queue("SELECT * FROM user_flags WHERE user_id = ANY($1)", userIDs)
batch.Queue("SELECT * FROM media WHERE user_id = ANY($1)", userIDs)

results := conn.SendBatch(ctx, batch)
defer results.Close()

// Each Query() call retrieves the next result set in order
// Error handling omitted for brevity
userRows, _ := results.Query()
users := scanUsers(userRows)
userRows.Close()

flagRows, _ := results.Query()
flags := scanFlags(flagRows)
flagRows.Close()

mediaRows, _ := results.Query()
media := scanMedia(mediaRows)
mediaRows.Close()
```

**Results:**

| Metric | lib/pq (3 queries) | pgx batch | Improvement |
|--------|-------------------|-----------|-------------|
| Time | 2.8ms | 1.0ms | **2.8x faster** |
| Allocs | 45 | 10 | **78% reduction** |

The migration was more involved than expected. pgx has different semantics for null handling and type scanning. We ended up adopting [sqlc](https://sqlc.dev/) for type-safe SQL generation, which solved both the safety and the scanning boilerplate.

***

## 3. L1 in-memory cache with Ristretto

**The problem:** Every cache lookup hit Redis, even for data accessed milliseconds ago.

Redis is fast. But "fast" is relative. A Redis lookup over the network is still ~300-500μs. When you're doing dozens of cache lookups per request, that adds up.

**The solution:** Add a local in-memory cache layer using [Ristretto](https://github.com/dgraph-io/ristretto) as L1, with Redis as L2.

```go
// Before: Every lookup goes to Redis
func (s *Service) getUserFlags(ctx context.Context, userID int64) (*UserFlags, error) {
    return s.redis.Get(ctx, fmt.Sprintf("user_flags:%d", userID))
}

// After: Check L1 first, fall back to Redis
func (s *Service) getUserFlags(ctx context.Context, userID int64) (*UserFlags, error) {
    key := fmt.Sprintf("user_flags:%d", userID)

    // L1 cache hit?
    if cached, found := s.l1Cache.Get(key); found {
        if flags, ok := cached.(*UserFlags); ok {
            return flags, nil
        }
    }

    // Fall back to Redis
    flags, err := s.redis.Get(ctx, key)
    if err != nil {
        return nil, err
    }

    // Populate L1 for next time
    s.l1Cache.Set(key, flags, 1)
    return flags, nil
}
```

**Results:**

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Lookup time | ~500ns | ~50ns | **~10x faster** |
| Allocations | 2 allocs | 0 allocs | **100% reduction** |

**Why Ristretto?** It uses [TinyLFU](https://arxiv.org/abs/1512.00727) for admission and [SampledLFU](https://dgraph.io/blog/refs/ristretto/) for eviction. TinyLFU is a frequency-based filter that decides whether a new item is "worth" caching: it only admits items that are accessed more frequently than what's already cached, preventing one-hit wonders from polluting the cache. SampledLFU handles eviction by sampling a subset of items and removing the least frequently used among them, avoiding the overhead of tracking every single access. Together, they make Ristretto very good at keeping the "right" items in cache. We benchmarked against `sync.Map` and `bigcache`; Ristretto won on both speed and memory efficiency.

The tradeoff is cache coherence. With two cache layers, you need to think about invalidation more carefully. For our use case (user flags that change infrequently), a short L1 TTL (60 seconds) was acceptable.

***

# Part 3: Stability & architecture

## 4. Worker pool for background enrichment

**The problem:** Unbounded goroutines for background enrichment could OOM the service under load.

We have a background enrichment system that pre-warms cache for the next page of feed items. Originally, it spawned a goroutine for each enrichment job. Under a traffic spike, this could spawn thousands of goroutines simultaneously, consuming all available memory.

**The solution:** Bounded worker pool with channel-based job queue.

```go
type WorkerPool struct {
    jobs    chan EnrichmentJob
    workers int
}

func NewWorkerPool(workers, queueSize int) *WorkerPool {
    pool := &WorkerPool{
        jobs:    make(chan EnrichmentJob, queueSize),
        workers: workers,
    }

    for i := 0; i < workers; i++ {
        go pool.worker()
    }

    return pool
}

func (p *WorkerPool) worker() {
    for job := range p.jobs {
        job.Execute()
    }
}

func (p *WorkerPool) Submit(job EnrichmentJob) bool {
    select {
    case p.jobs <- job:
        return true
    default:
        return false // Queue full, drop job
    }
}
```

**Result:** No more OOM under load spikes. The service now degrades gracefully: if the queue is full, we skip pre-warming and let the next request fetch data on-demand.

We also pair this with a complementary strategy: **dynamic TTLs based on load**. When the queue is full, we double the TTL for pre-warmed cache entries (up to a sensible maximum). If the system is under pressure, cached data stays valid longer, reducing database load precisely when it matters most. When we successfully pre-warm again, the TTL resets to its original value, and the system actively recovers as load decreases. This adaptive approach means the service self-regulates: users might see slightly staler data during peak load, but the service stays up, and the database doesn't get hammered.

***

## 5. Structured concurrency with errgroup

**The problem:** Manual goroutine management with WaitGroups is error-prone.

Our data loading code had classic WaitGroup + error channel patterns. They worked, but they were verbose and easy to mess up.

**The solution:** Use `golang.org/x/sync/errgroup` for structured concurrency.

```go
// Before: Manual WaitGroup + error channel
var wg sync.WaitGroup
errChan := make(chan error, 3)

wg.Add(3)
go func() { defer wg.Done(); errChan <- loadUsers() }()
go func() { defer wg.Done(); errChan <- loadMedia() }()
go func() { defer wg.Done(); errChan <- loadFlags() }()
wg.Wait()
close(errChan)

for err := range errChan {
    if err != nil {
        return err
    }
}

// After: errgroup handles everything
g, ctx := errgroup.WithContext(ctx)

g.Go(func() error { return loadUsers(ctx) })
g.Go(func() error { return loadMedia(ctx) })
g.Go(func() error { return loadFlags(ctx) })

if err := g.Wait(); err != nil {
    return err // First error cancels context, stops other goroutines
}
```

**Benefits:**

- Automatic error propagation
- Context cancellation on first error
- Cleaner, more maintainable code
- `SetLimit()` for bounded parallelism

This wasn't a performance optimization per se, but it reduced bugs and made the concurrent code easier to reason about. Fewer bugs = fewer emergency debugging sessions = more time for actual optimization work.

***

# Part 4: The "modern Go" refactor

## 6. Router migration: gorilla/mux → net/http.ServeMux

**The problem:** gorilla/mux is battle-tested, but it allocates on every request.

This was a classic case of cargo-culting. We used gorilla/mux because "that's what you use for Go APIs." But Go 1.22 changed the game by adding method-based routing to the standard library.

**The solution:** Migrate to `net/http.ServeMux`.

```go
// Before (gorilla/mux)
r := mux.NewRouter()
r.HandleFunc("/api/v1/feed", handler).Methods("GET")
r.HandleFunc("/api/v1/feed/{id}", handler).Methods("GET")

// After (net/http.ServeMux)
mux := http.NewServeMux()
mux.HandleFunc("GET /api/v1/feed", handler)
mux.HandleFunc("GET /api/v1/feed/{id}", handler)
```

**Results:**

| Metric | gorilla/mux | net/http | Improvement |
|--------|-------------|----------|-------------|
| Time/op | 1,847ns | 614ns | **3x faster** |
| Allocs/op | 8 | 2 | **75% reduction** |

**Bonus:** One less external dependency. The stdlib router is fast, thoroughly tested, and will never have a security CVE filed against it as a "dependency vulnerability."

The migration took about an hour. Most of it was updating path parameter extraction from `mux.Vars(r)` to `r.PathValue("id")`.

***

## 7. Type-safe SQL with sqlc

**The problem:** Hand-written SQL queries and manual row scanning are error-prone.

We had a nasty bug where a query returned columns in a different order than the `Scan()` expected. It only manifested when a user had a null value in a specific field. Finding it took hours.

**The solution:** Generate type-safe Go code from SQL with [sqlc](https://sqlc.dev/).

```sql
-- queries/posts.sql
-- name: GetSimplePosts :many
SELECT id, user_id, content, created_at
FROM posts
WHERE user_id = ANY(@user_ids::bigint[])
ORDER BY created_at DESC
LIMIT @limit_count;
```

```go
// Generated code - type-safe, no manual scanning
posts, err := queries.GetSimplePosts(ctx, db.GetSimplePostsParams{
    UserIds:    userIDs,
    LimitCount: 50,
})
```

**Benefits:**

- Compile-time SQL validation
- Auto-generated Go structs matching query results
- No more `rows.Scan()` field order bugs
- IDE autocompletion for query parameters

The migration took few days. We kept our complex batch queries (the pgx.Batch ones) hand-written for performance reasons, but migrated all the simpler queries to sqlc.

***

# Part 5: Micro-optimizations & GC tuning

## 8. sync.Pool for struct reuse

**The problem:** Creating `UserFlagsCache` structs for every request generates GC pressure.

Our enrichment process creates temporary structs to hold relationship data: who follows whom, who's blocked whom, etc. These structs have maps inside them. Creating and destroying them thousands of times per second makes the garbage collector work hard.

**The solution:** Pool and reuse structs with `sync.Pool`.

```go
var userFlagsCachePool = sync.Pool{
    New: func() interface{} {
        return &UserFlagsCache{
            IsFollowed:        make(map[int64]bool, 50),
            IsFollowing:       make(map[int64]bool, 50),
            IsBlocked:         make(map[int64]bool, 10),
            HasBlockedCurrent: make(map[int64]bool, 10),
        }
    },
}

func (s *Service) getUserFlagsCache() *UserFlagsCache {
    cache := userFlagsCachePool.Get().(*UserFlagsCache)
    // Clear maps for reuse
    clear(cache.IsFollowed)
    clear(cache.IsFollowing)
    clear(cache.IsBlocked)
    clear(cache.HasBlockedCurrent)
    return cache
}

func (s *Service) releaseUserFlagsCache(cache *UserFlagsCache) {
    userFlagsCachePool.Put(cache)
}
```

**Results:**

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Time/op | 892ns | 276ns | **3.2x faster** |
| Allocs/op | 5 | ~0 (amortized) | **~100% reduction** |

**Critical caveat:** Always `clear()` maps before reuse. We learned this the hard way when stale data from a previous request leaked into a new one. The bug was subtle and only appeared under load. Now we have a test that explicitly checks for cross-request data contamination.

***

## 9. Memory pre-allocation

**The problem:** Growing slices and maps causes repeated allocations.

This is Go 101, but it's easy to forget in the flow of writing code. Every time a slice grows beyond its capacity, Go allocates a new backing array and copies the data. Same with maps.

**The solution:** Pre-allocate with known or estimated capacity.

```go
// Before: Slice grows dynamically
posts := []Post{}
for _, row := range rows {
    posts = append(posts, convertRow(row))
}

// After: Pre-allocate slice capacity
posts := make([]Post, 0, len(rows))
for _, row := range rows {
    posts = append(posts, convertRow(row))
}
```

**Results:**

| Operation | Before | After | Improvement |
|-----------|--------|-------|-------------|
| Slice append (1000 items) | 13,892ns | 1,245ns | **10x faster** |
| Map insert (100 items) | 4,521ns | 1,723ns | **2.6x faster** |

**Rule of thumb:** If you know the size, tell Go. If you can estimate, estimate high. An extra 20% capacity costs almost nothing compared to dynamic growth.

We went through the entire codebase with `ast-grep` (as mandated by our [skills system]({{< ref "2025-11-09-from-asking-claude-to-code-to-teaching-claude-our-patterns-building-modular-ai-skills" >}})) searching for `make([]` and `make(map[` without capacity hints. Found about 30 places to fix.

***

## 10. Profile-guided optimization (PGO)

**The problem:** The Go compiler makes general-purpose optimization decisions.

Go 1.20 introduced Profile-Guided Optimization. You feed the compiler a CPU profile from production, and it optimizes hot paths more aggressively.

**The solution:** Collect profiles, build with PGO.

```bash
# 1. Collect CPU profile in production
curl http://localhost:6060/debug/pprof/profile?seconds=30 > cpu.pprof

# 2. Build with profile
go build -pgo=cpu.pprof -o api ./cmd/api
```

**Results:** 2-7% improvement across the board.

This is the highest ROI optimization on the list. Five minutes of work for measurable gains. We now include PGO in our CI/CD pipeline: every deploy uses a profile collected from the previous production release.

***

## What we didn't do

### Go iterators (rejected)

Go 1.23 introduced iterators with `iter.Seq`. We evaluated them and decided against adoption.

**Why not:**

- Added complexity for minimal performance gain in our use case
- Our hot paths are batch operations, not iteration
- Team unfamiliarity would slow development and code review

**Lesson:** Not every new feature is worth adopting. Measure first, then decide. Sometimes "boring" is better.

***

## Results summary

| Optimization | Latency Impact | Memory Impact |
|--------------|----------------|---------------|
| **easyjson** | **-90ms avg** | - |
| L1 Cache (Ristretto) | -20ms avg | -96% allocs |
| pgx Batch Queries | -15ms avg | -78% allocs |
| Router Migration | -5ms avg | -75% allocs |
| PGO | -5ms avg | - |
| sync.Pool | -3ms avg | ~100% allocs (amortized) |
| Memory Pre-allocation | -2ms avg | -100% allocs |
| Worker Pool | Stability | OOM prevention |
| errgroup | Maintainability | - |
| sqlc | Safety | - |

**Combined Result:** P50 latency **~200ms → ~50ms** (75% reduction)

***

## Key takeaways

1. **Profile first, optimize second.** We expected the bottleneck to be the database. It was JSON serialization. Half of my initial guesses about "what's slow" were wrong.

2. **The stdlib is good now.** Go 1.22+ has excellent routing, and pgx/v5 is production-ready. Don't cargo-cult old dependencies because "that's what we've always used."

3. **Allocation reduction compounds.** Each individual optimization seems small, but together they dramatically reduce GC pressure. The GC runs less often, and when it runs, it has less work to do.

4. **Pre-allocation is free performance.** If you know the size, tell Go. This is the lowest-effort optimization on the list.

5. **Batch operations beat N+1.** Whether it's database queries or cache lookups, batching wins. Always ask: "Can I combine these operations?"

6. **Profile-Guided Optimization is free.** Five minutes of work for 2-7% improvement. No reason not to do it.

***

## What's next

We're not done. The roadmap includes:

- **OpenTelemetry integration** for distributed tracing
- **Further pgx batch optimization** in enrichment loaders
- **Continuous profiling** with Pyroscope for ongoing performance monitoring

Performance optimization is never "finished." It's a continuous process of measurement, hypothesis, and validation. But these ten optimizations gave us a solid foundation, cutting our latency by 75%.

***

## Acknowledgments

This optimization work happened over about ten days. Without AI assistance, it would have taken months.

**Claude Code** (powered by **Opus 4.5**) was my constant [pair programmer]({{< ref "2025-11-30-from-skills-to-shipping-building-with-claude-as-a-pair-programmer" >}}), understanding our patterns, running benchmarks iteratively, and implementing changes across dozens of files. **Gemini CLI** with **Gemini 3 Pro** handled deep research (navigating thousands of articles to surface the right best practices) and served as a thorough [code reviewer]({{< ref "2025-10-18-from-rubber-ducks-to-gemini-ai-powered-code-reviews-in-gitlab-ci" >}}), catching issues and suggesting improvements that made the final code significantly better. The two work well together: Claude writes, Gemini reviews, and the result is better than either could produce alone.

I can't thank the **Wishew team** enough for trusting me to take time for "invisible" infrastructure work. Performance optimization doesn't create new features, but it makes everything feel better, saves money on infrastructure, and prepares us for when the service needs to scale rapidly (and that moment is closer than you'd think). More than that, they give me the opportunity to learn, experiment, and put into practice what I study. In a world where "ship fast" often means "skip the fundamentals," having a team that values deep technical work is rare and precious.

And thanks to the Go community for excellent libraries like Ristretto, pgx, sqlc, and easyjson. Open source makes this work possible.

***

## Tools & references

- [easyjson](https://github.com/mailru/easyjson): Fast JSON serialization via code generation
- [Ristretto](https://github.com/dgraph-io/ristretto): High-performance in-memory cache
- [pgx/v5](https://github.com/jackc/pgx): PostgreSQL driver for Go
- [sqlc](https://sqlc.dev/): Type-safe SQL code generation
- [errgroup](https://pkg.go.dev/golang.org/x/sync/errgroup): Structured concurrency
- [pprof](https://pkg.go.dev/net/http/pprof): Go profiling
- [Go 1.22 ServeMux](https://go.dev/blog/routing-enhancements): Enhanced routing in stdlib

_This optimization work was done for the Wishew Outpost API but the patterns are applicable to any Go service with similar characteristics: high read volume, caching layers, and PostgreSQL backend._
