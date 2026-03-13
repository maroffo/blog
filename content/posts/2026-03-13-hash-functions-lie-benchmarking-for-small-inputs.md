---
title: "Hash Functions Lie: Benchmarking for Small Inputs"
date: 2026-03-13
summary: "xxHash3 is supposed to be 300% faster than FNV. We benchmarked it on 5-40 byte inputs and it was 23% slower. Here's why GB/s league tables are meaningless for small data, and what actually matters."
tags: [golang, performance, hashing, hikmaai]
draft: true
cover:
  image: "images/cover-hash-functions-lie.png"
  alt: "A broken speedometer next to tiny scattered bytes"
  relative: false
---

"xxHash3 will be 300-400% faster than FNV-1a. Switching is mandatory."

That was the confident recommendation from an AI code reviewer analyzing our MinHash implementation. It came with citations, throughput numbers, and the kind of certainty that makes you reach for `go get` before thinking twice.

We benchmarked it instead. xxHash3 was 23% *slower*.

This is a post about small inputs, wrong assumptions, and the gap between what benchmarks measure and what your code actually does.

***

### What we're building

At [HikmaAI](https://hikmaai.io) I'm working on a Go service that needs to compute [MinHash](https://en.wikipedia.org/wiki/MinHash) signatures on every incoming request, at high throughput. The service sits on the hot path: every millisecond of latency is a millisecond the user waits.

MinHash is simple in principle: break your input into overlapping n-grams (subsequences), hash each one with K different hash functions, keep the minimum hash value for each function. Two inputs that share many n-grams produce similar signatures.

The trick is that K is large. We use 128 hash permutations. Hashing every n-gram 128 times would be expensive, so we use the [Kirsch-Mitzenmacher optimization](https://www.eecs.harvard.edu/~michaelm/postscripts/rsa2008.pdf): compute just 2 independent hash values (h1, h2) per n-gram, then derive all 128 permutations as `g(j) = h1 + j * h2`.

This means the hash function runs on every n-gram of every request. Token 3-grams are 15-40 bytes. Character 5-grams are exactly 5 bytes. This is the hot path. Every nanosecond counts.

***

### The benchmark that broke assumptions

The hash function literature is dominated by throughput benchmarks. SMHasher, xxHash's own benchmarks, blog posts comparing algorithms: they all measure gigabytes per second on megabyte-sized inputs. On those benchmarks, xxHash3 obliterates FNV-1a. It's not even close.

But our inputs are not megabytes. They're 5-40 bytes. At that size, the physics change.

Here's what happened when we benchmarked. For token 3-grams (15-40 bytes):

| Implementation | ns/op | allocs/op |
|---|---|---|
| Inline FNV-1a | 812 | 1 |
| xxHash3 (zeebo/xxh3) | 998 | 234 |

xxHash3 was 23% slower with 234x more allocations.

For character 5-grams (5 bytes), the two were statistically identical.

The reason is not that xxHash3 is a bad hash function. It's excellent for what it's designed for. The reason is *input preparation*.

xxHash3, like most hash libraries, takes a `[]byte` or `string` as input. It needs contiguous memory. Our token n-grams are slices of strings: `["ignore", "all", "previous"]`. To feed this to xxHash, you need `strings.Join(tokens[i:i+3], " ")`, which allocates a new string for every single n-gram. With hundreds of n-grams per request, that's hundreds of allocations.

Our inline FNV approach iterates the token bytes directly without ever building the joined string:

```go
gram := tokens[i : i+n]
h1, h2 := fnvOffset32, fnvOffset32
for t, tok := range gram {
    if t > 0 {
        h1 ^= uint32(' ')
        h1 *= fnvPrime32
        h2 *= fnvPrime32
        h2 ^= uint32(' ')
    }
    for k := 0; k < len(tok); k++ {
        b := uint32(tok[k])
        h1 ^= b    // FNV-1a: XOR then multiply
        h1 *= fnvPrime32
        h2 *= fnvPrime32 // FNV-1: multiply then XOR
        h2 ^= b
    }
}
```

Zero allocations. The hash walks the tokens in-place, inserting a virtual space separator between them. No `strings.Join`, no `[]byte` conversion, no temporary buffer.

To be fair, this benchmark isn't really "FNV vs xxHash." It's "inline loop with zero allocations vs library call with `strings.Join`." The allocation is the culprit, not xxHash3 itself. You could use xxHash3's streaming API to avoid `strings.Join`, but you'd still pay interface dispatch overhead on every `Write` call, which adds up when the input is 5 bytes.

The throughput advantage of xxHash3 (SIMD instructions, wider state, better avalanche) is real, but it only kicks in at input sizes where the hash computation itself dominates. At 5-40 bytes, function call overhead and input preparation are the bottleneck. The hash math is basically free at that scale.

***

### The dual-hash trade-off

The same reviewer had a follow-up: since xxHash3 produces a 64-bit output, split it into two 32-bit halves for h1 and h2. One hash call, two values. The Kirsch-Mitzenmacher paper itself suggests this approach, and with a high-quality 64-bit hash that has good avalanche properties, the two halves are statistically independent enough for practical use.

So why didn't we do it? Because splitting a 64-bit hash still requires calling the hash function, which still requires contiguous input, which still requires `strings.Join`. The allocation problem doesn't go away.

Our approach uses FNV-1a and FNV-1 as the two base hashes, computed inline during the same byte iteration:

- **FNV-1a**: XOR the byte into the hash, *then* multiply by the prime
- **FNV-1**: multiply by the prime, *then* XOR the byte

Same constants, same input, different operation order. We get two hash values from a single pass over the bytes, with zero allocations.

The honest trade-off: FNV has weak avalanche properties compared to xxHash3 or MurmurHash3. The statistical quality of our MinHash signatures is probably slightly worse than what we'd get from a better hash family. For our use case (detecting structural similarity for pattern matching, not exact Jaccard estimation), this is acceptable. We're not computing similarity coefficients to three decimal places; we're asking "does this input look like something we've seen before?" A few percentage points of Jaccard estimation error doesn't change that answer.

If we needed higher accuracy, we'd inline a better mixing function (MurmurHash3's `fmix32` or wyhash's multiply-xor-multiply) into the same zero-allocation loop. The point isn't "FNV is the best hash." It's not. The point is that *any* hash you can compute inline over non-contiguous data will beat a superior hash that forces you to build a contiguous buffer first.

***

### Bounds check elimination: the sub-slice trick

Go's compiler eliminates bounds checks when it can prove an access is safe. This is called BCE (Bounds Check Elimination), and it matters in tight loops that run millions of times.

The intuitive approach doesn't work:

```go
// This does NOT eliminate bounds checks in the inner loop.
_ = tokens[i+n-1]  // "prove" we're in bounds
for t := i; t < i+n; t++ {
    tok := tokens[t]  // bounds check on every iteration
    // ...
}
```

The compiler sees `i+n-1 < len(tokens)` from the hint, and it sees `t < i+n` from the loop condition. But it can't connect these two facts to conclude `t < len(tokens)`. The proof doesn't propagate across variable indirection.

The fix is a sub-slice:

```go
gram := tokens[i : i+n] // one bounds check here
for t, tok := range gram {
    // no bounds check: compiler knows t < len(gram) from range
    for k := 0; k < len(tok); k++ {
        b := uint32(tok[k]) // no bounds check: k < len(tok)
        // ...
    }
}
```

Creating `gram` performs one bounds check (is `i+n <= len(tokens)`?). After that, `range gram` is provably safe: the compiler knows the iteration variable is always within bounds. One check replaces N checks per n-gram.

Every BCE optimization I've seen in Go boils down to this: **create a bounded sub-slice, then iterate it with range**. Value hints don't help. The compiler needs a slice with a known length, not a chain of inequalities it can't connect.

***

### Manual loop unrolling in 2026

After computing h1 and h2 for each n-gram, we derive 128 permutations via the Kirsch-Mitzenmacher formula and update the MinHash signature:

```go
for j := 0; j < 128; j++ {
    val := h1 + uint32(j)*h2
    if val < sig[j] {
        sig[j] = val
    }
}
```

Simple, clean, and leaving performance on the table. Manual 4x unrolling gives a consistent 6-7% speedup:

```go
_ = sig[numHashes-1] // BCE: prove full sig is in bounds
j := 0
for ; j+3 < numHashes; j += 4 {
    v0 := h1 + uint32(j)*h2
    v1 := h1 + uint32(j+1)*h2
    v2 := h1 + uint32(j+2)*h2
    v3 := h1 + uint32(j+3)*h2
    if v0 < sig[j]   { sig[j] = v0 }
    if v1 < sig[j+1] { sig[j+1] = v1 }
    if v2 < sig[j+2] { sig[j+2] = v2 }
    if v3 < sig[j+3] { sig[j+3] = v3 }
}
// Handle remainder.
for ; j < numHashes; j++ {
    val := h1 + uint32(j)*h2
    if val < sig[j] { sig[j] = val }
}
```

Why does this help? Four independent computations (v0-v3) let the CPU pipeline them: while v0's multiply is in the ALU, v1's can start in a second execution unit. The original loop has a data dependency chain (each iteration depends on `j`, then on `sig[j]`), but the 4x version breaks this into independent chains that the CPU can overlap.

The Go compiler (as of 1.26) doesn't do this automatically. It's conservative about loop transformations, especially when the loop body contains conditional writes (`if val < sig[j]`). Other compilers (GCC, LLVM) are more aggressive, but Go prioritizes compilation speed and predictable output over maximum optimization.

6-7% on a loop that runs for every n-gram of every request adds up. On a service processing 10,000 requests per second with 50 n-grams each, that's 500,000 loop executions per second. The unrolling saves roughly 35 microseconds of CPU per second. Not life-changing, but free.

***

### PGO: 5-7% for free (almost)

Profile-Guided Optimization (PGO) has been stable in Go since 1.21. You collect a CPU profile from a representative workload, feed it to the compiler, and it makes better inlining and branch prediction decisions. On our hash-heavy workload, PGO gives a consistent 5-7% throughput improvement.

The "almost" is about a gotcha. PGO auto-detection works by looking for a `default.pgo` file in the `main` package directory. For `go build ./cmd/myservice`, placing the profile at `cmd/myservice/default.pgo` works. But `go test` doesn't find it.

Why? `go test` creates a synthetic `main` package in a temporary directory. That temp directory doesn't have your profile. The fix is to pass the path explicitly:

```bash
go test -pgo=./default.pgo -bench=. ./internal/lsh/
```

Not hard, but if you expect auto-detection to work for benchmarks (a natural place to measure PGO's impact), you'll be confused when the numbers don't change.

Our workflow:

```bash
# Generate profile from realistic load.
make pgo     # runs the gateway under load, saves default.pgo

# Build with PGO.
go build -pgo=default.pgo -o bin/myservice ./cmd/myservice

# Benchmark with PGO.
make bench-pgo   # passes -pgo flag to go test
```

***

### What we measured vs what we expected

Here's the summary of techniques and their impact on our MinHash hot path:

| Technique | Expected impact | Measured impact | Surprise factor |
|---|---|---|---|
| xxHash3 replacing FNV | +300% throughput | -23% (slower) | High |
| Inline FNV (no allocation) | Moderate improvement | Baseline (the winner) | None |
| BCE sub-slicing | Marginal | ~3-5% on n-gram loop | Low |
| 4x loop unrolling | Unlikely to help | 6-7% on K-M loop | Medium |
| PGO | Unknown | 5-7% overall | Low |
| K-M (2 hashes -> 128) | 64x fewer hash calls | 64x fewer hash calls | None (it's math) |

The biggest win was keeping the inline approach (not switching to a library call that would force allocations). The second biggest was Kirsch-Mitzenmacher (which is algorithmic, not a micro-optimization). The micro-optimizations (BCE, unrolling, PGO) compound to roughly 15% combined, which is meaningful but secondary.

***

### Three rules for small-input hashing

**1. Measure at your actual input size.** A hash function that processes 10 GB/s on 1 MB inputs might process 200 MB/s on 10-byte inputs. That's still fast, but the 50x difference tells you the throughput number was never about the hash math; it was about amortizing setup costs over large inputs.

**2. Count allocations, not just nanoseconds.** On our benchmark, xxHash3's raw hash computation was probably faster than FNV. But `strings.Join` added 234 allocations that FNV avoided entirely. At small input sizes, the allocation is more expensive than the hash.

**3. The preparation cost often dominates.** Building the input (joining strings, converting types, copying to contiguous memory) can easily cost more than hashing it. If your hash function requires a contiguous `[]byte` and your data isn't contiguous, the conversion is part of the cost. An "inferior" hash that works on your native data representation will win.

None of this is specific to Go or to hashing. Serialization, compression, encryption: at small input sizes, the setup cost is the cost. Next time someone shows you a benchmark with impressive GB/s numbers, check the input size. If it's megabytes and yours is bytes, that number means nothing.

***

*The code shown in this post is from a production Go service. Variable names are unchanged from the real codebase.*

***

#### Methodology note

This post was drafted with AI assistance (Claude), reviewed by a second AI (Gemini) for factual accuracy, and edited for voice and clarity. All benchmarks were run on real hardware with production code. The opinions and errors are mine.
