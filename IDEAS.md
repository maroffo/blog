# ABOUTME: Structured editorial backlog for the blog (angle / gap / unique value per idea)
# ABOUTME: Consumed by the blog-writer skill; sourced from cross-repo LEARNING.md mining

# Editorial Backlog

Structured idea backlog for the blog. Each idea carries a **proposed angle**, the **gap** it fills (what's missing in the existing coverage out there), and its **unique value** (why I, specifically, can write it). `blog-writer` reads this file.

Sourced from mining 18 `LEARNING.md` retrospectives across my repos (Jun 2026), then ranked with two isolated second-opinion reviewers (Claude + Gemini) and a value-vs-saturation web pass. The ranking below reflects that pass: AI-skeptic and process pieces scored highest on void + topicality; the security gotcha got absorbed because the misconfig is already well-documented.

Cadence target: ~weekly. Keep the mix balanced (don't let the retrospective pipeline turn the blog all-incident). Default language EN for the technical/AI-eng pieces; IT reserved for opinion/Italian-market pieces.

---

## Active queue

### 1. AI Benchmarks Are Confident, Plausible, and 23% Slower
- **Slot:** ~2026-06-20
- **Type:** AI-skeptic
- **Angle:** An AI assistant confidently claimed xxHash3 would be "300-400% faster" than FNV-1a and called the switch mandatory. Benchmarked on the real workload (small 15-40 byte inputs, token n-grams), it was 23% *slower*, because `strings.Join` allocates per n-gram and function-call overhead dominates at that size. Parallel beat: porting deterministic PGTune formulas instead of asking an LLM to suggest Postgres tuning. Thesis: an LLM knows statistics, it doesn't *measure*; use it to generate hypotheses, never to delegate deterministic math or micro-optimization.
- **Gap:** The web is wall-to-wall "LLM leaderboard 2026" and generic benchmark comparisons. Nobody publishes the first-person empirical takedown of an LLM's confidently-wrong performance advice.
- **Unique value:** I have the actual benchmark numbers from a real codebase, and an established AI-skeptic register (Cognitive Surrender, Agents Delete Good Code).
- **Caveat:** Stay in the AI-trust lane, NOT the benchmarking-methodology lane, or it retreads the published performance posts.
- **Source:** hikma-mirsad, hikma-pgpilot LEARNING.md

### 2. 372 Passing Tests and a Dead Program
- **Slot:** ~2026-06-27
- **Type:** Engineering thesis
- **Angle:** A CLI with 372 green tests, fully non-functional: three subsystems never wired together (empty provider registry, API keys stored but never forwarded, settings manager never instantiated). Escalate the evidence: then the config plane that served stale config while every dashboard stayed green (HTTP ETag committed before parsing → 304 Not Modified forever); close on the OIDC logout that "looks like it works" but leaves the session alive (a *security* failure). Thesis: tests prove units work in isolation and say almost nothing about the seams; "all green" is a Goodhart target, and agents optimize relentlessly for it.
- **Gap:** The unit-vs-integration topic is saturated with generic "use both" sermons (GeeksforGeeks, TestRail, CircleCI). The agent/Goodhart angle and the dashboards-lie-too escalation are unwritten.
- **Unique value:** Three concrete production examples from my own systems + the AI-agent framing.
- **Absorbs:** the Cloud Run WAF-bypass beat as a 4th piece of evidence ("dashboard green, tests passed, front door wide open") — so the standalone security post is retired.
- **Frame:** plants the running through-line *"the system reports success and never verifies it"* — callbacks in idea 3.
- **Source:** golem, hikmaAI config plane, hikmaai-frontend LEARNING.md

### 3. We DDoS'd Ourselves on Launch Day
- **Slot:** ~2026-07-04
- **Type:** War story
- **Angle:** Production cutover to GCP. At 17:00 UTC a re-engagement cron iterated ~100K migrated users sending push notifications. Every device token belonged to the OLD Firebase project, so it fired 100K guaranteed-to-fail FCM calls, each retrying, on a backend pinned to `max_instances=1`. The single instance saturated and starved everything else, including Google login. Two morals: post-migration state is guilty until proven valid (the migration "succeeded" and carried 100K dead tokens), and failure domains (a batch cron must not share a blast radius with user-facing traffic).
- **Gap:** Retry-storm/self-DoS is a documented antipattern (Azure, danlebrero, a 2025 arxiv). The *concept* is commodity; the specific Firebase-token-migration twist is not.
- **Unique value:** A real, dated, specific war story with the migration-state twist. Pure HN-bait — but only if it lands the two morals, not just the anecdote.
- **Frame:** callback to the "everything reports success" through-line (the migration reported success; the tokens were invalid).
- **Source:** Wishew go-live LEARNING.md

### 4. 18 Retrospectives, One Feedback Loop (working title)
- **Slot:** ~2026-07-11 (gated on building the learning extractor first)
- **Type:** Culture / process
- **Angle:** I have 18 scattered `LEARNING.md` files. Mining them cross-repo, the value isn't the count, it's the *recurrence*: the same failure shape shows up across unrelated repos (everything-reports-green ×3, fail-open-on-removal ×3, build-time-env-var-baked ×2, async-isn't-concurrent ×3). Recurrence is the signal that should drive a process change: a hook, a rule, a skill update, a review-checklist item, each with a falsifiable change-contract. The post is the loop: retrospective → recurrence detection → harness change → falsification.
- **Gap:** The "learn from incidents" space is SRE-vendor-heavy (incident.io, Rootly, FireHydrant). The solo-dev / AI-harness angle (LEARNING.md → harness changes) is unoccupied.
- **Unique value:** External anchor — industry repeat-incident rate is 35-50% and almost nobody tracks it — paired with my own cross-repo data. Original because I'm doing it on a personal AI harness, not a team incident tool.
- **Source:** meta (all LEARNING.md) + the cross-repo extractor

### 5. (open) Culture take — TBD
- **Slot:** ~2026-07-18
- **Type:** Culture / opinion
- **Angle:** Deliberately open. The four ideas above are all technical-incident posts; my strongest work is half incident, half AI/engineering-culture take. This slot keeps the mix honest. Candidate to be mined separately (not from the incident retrospectives).

---

## Parking lot

- **The Great Web UI Purge** (deleted 1800 lines of a FastAPI+htmx UI nobody used, replaced with 7 CLI commands; build for actual usage, not imagined usage). Benched: the YAGNI/delete-dead-code sermon is well-trodden and circles territory already covered by "Agents Delete Good Code" and the cognitive-load posts. Revisit only if tied to a larger paradigm shift. Source: feed-brain.

## Dropped

- **Build-time vs runtime env vars** (`NEXT_PUBLIC_`/`EXPO_PUBLIC_` baked into the Docker image; 6 hours for a 5-line fix). Pure gotcha, no thesis, and the Doppler→ARG→build-args chain is written to death. Both reviewers said drop. At best a footnote.
- **Cloud Run services bypassing the load balancer** (standalone). The misconfig is well-documented with recent official coverage; commodity knowledge. Absorbed into idea 2 as a single beat instead.
