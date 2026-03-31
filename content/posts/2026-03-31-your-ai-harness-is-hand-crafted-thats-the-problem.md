---
title: "Your AI Harness Is Hand-Crafted. That's the Problem."
date: 2026-03-31
summary: "Stanford's Meta-Harness paper argues that optimizing the code around the model matters more than optimizing the model itself. I applied it to my Claude Code setup and got the first real numbers: 3,723 tokens always in context, with no evidence they're the right ones."
tags: ["ai", "claude-code", "developer-tools", "automation"]
draft: false
cover:
  image: "images/cover-harness-hand-crafted.png"
  alt: "Your AI Harness Is Hand-Crafted. That's the Problem."
  relative: false
---

Part five in a series on building [claude-forge](https://github.com/maroffo/claude-forge): a modular skills and orchestration system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). This time, the system starts measuring itself.

*3,723 tokens. Always loaded. Zero evidence they're the right ones.*

## The Optimization We Never Did

In [post two]({{< ref "2026-02-12-when-your-ai-skills-library-gets-too-smart-for-its-own-context-window" >}}), I described how the skills library had bloated to the point where it was eating the context window it was supposed to help with. The fix was aggressive: 352 lines added, 2,009 deleted. Shared reference files. Progressive disclosure. Tables instead of prose.

It worked. The harness got leaner.

But here's the thing I never questioned: *how did I know what to cut?*

I eyeballed it. Read through skills, spotted redundancy, compressed sections that felt verbose. Classic developer intuition, applied to a problem that should embarrass anyone who's ever written a benchmark.

I was hand-tuning a system that affects every line of code Claude writes, with no measurement infrastructure, no trace data, and no way to know if the changes actually helped.

Then a paper from Stanford arrived and told me, politely, that this is the wrong way to do it.

***

## What Meta-Harness Actually Says

The paper is ["Meta-Harness: End-to-End Optimization of Model Harnesses"](https://arxiv.org/abs/2603.28052) by Lee, Nair, Zhang, Lee, Khattab, and Finn. The core argument: the performance of an LLM system depends not only on the model weights but on the *harness*, the code that determines what information to store, retrieve, and present to the model.

Their definition of "harness" is broad: the system prompt, the context management strategy, the retrieval logic, the output parsing, the error recovery. Everything between "user sends a request" and "model produces a useful response."

Their claim: **harnesses are still designed by hand, and existing text optimizers compress feedback too aggressively.** So they built Meta-Harness, an outer-loop system that searches over harness code. It uses an agentic proposer that can read the source code, scores, and execution traces of all previous candidates through a filesystem.

The numbers: on text classification, +7.7 points while using *4x fewer context tokens*. On 200 IMO-level math problems, +4.7 points, and the discovered harness transferred to five different models it had never seen. On agentic coding (TerminalBench-2), it beat the best hand-engineered baselines.

The takeaway that hit me: the proposer doesn't need to be smarter than you. It needs access to data you don't have. Specifically, structured execution traces of what actually happened during previous runs.

I looked at my setup. Four rule files, 11 agents, 42 skills. All hand-written markdown. No traces. No token counts. No feedback loop.

***

## The Measurement Gap

Let me be specific about what "no measurement" means in practice.

My orchestrator-protocol rule defines a 10-step loop: refine, research, implement, verify, review, fix, re-verify, score, present, UAT. Each step can spawn specialized agents. The quality gates score output on a 0-100 scale. It looks rigorous.

But I had no idea:
- How many tokens the always-loaded rules consume
- Which orchestrator steps fail most often
- How many fix-loop rounds a typical session needs
- Whether review agents are activated for the right file types
- Which skills are loaded but never useful

Every session vanished into Claude Code's internal logs (raw JSONL, tens of thousands of lines, impractical to read). The knowledge of what worked and what didn't evaporated at the end of each conversation.

Meta-Harness's key insight is that the proposer needs "richer access to prior experience." My harness had no memory of its own performance. Every session was a blank slate, the exact problem I'd solved for *code patterns* in post one, now recurring at the *meta level*.

***

## Phase 1: Teaching the Harness to Remember

The first thing to build wasn't an optimizer. It was a trace format.

I wrote a Python CLI tool (`harness-trace`) that extracts structured traces from Claude Code's raw session JSONL files. Each trace is one line per orchestrator step:

```json
{"v":1,"session":"health-check","ts":"2026-03-31T10:15:00Z","step":"VERIFY","data":{"tests_pass":true,"lint_clean":true,"build_ok":true,"retries":0}}
{"v":1,"session":"health-check","ts":"2026-03-31T10:18:00Z","step":"REVIEW","data":{"agents":["architecture-reviewer","security-reviewer"],"findings":{"CRITICAL":0,"MAJOR":1,"MINOR":2}}}
{"v":1,"session":"health-check","ts":"2026-03-31T10:22:00Z","step":"SCORE","data":{"score":87,"threshold":80,"gate":"commit"}}
```

Twelve step types: REFINE, RESEARCH, IMPLEMENT, VERIFY, REVIEW, FIX, RE_VERIFY, SCORE, LOOP, PRESENT, UAT, SUMMARY. Each with step-specific data payloads validated by Pydantic models.

The extraction is heuristic (parsing assistant messages for orchestrator step indicators via regex), which makes it fragile. But it serves two purposes: bootstrapping an initial trace corpus from past sessions, and validating the live traces that the orchestrator now emits directly.

That second part is the real mechanism. I added 18 lines to `orchestrator-protocol.md` instructing the orchestrator to append a JSONL line after each step. The rule knows which step it's on, which agents were activated, what the score was. The post-processing script is the fallback; the rule is the source of truth.

**Why JSONL and not OpenTelemetry?** This was one of the first decisions, and the Gemini second-opinion was unambiguous: "OpenTelemetry is a trap here. OTel is designed for distributed microservices and dashboards. Your consumer is an LLM agent reading from a filesystem. Optimize for LLM readability."

Fair point. The traces aren't going to Grafana. They're going to another LLM that needs to reason about patterns across sessions. Flat JSONL lines that a language model can parse natively beat nested span hierarchies every time.

***

## Phase 2: Counting Tokens for the First Time

The same CLI includes a `baseline` command that scans every rule, skill, and agent file, counts tokens with tiktoken, and classifies them by tier:

```
file                              tokens  tier      loaded
rules/orchestrator-protocol.md    1075    rule      always
rules/plan-first-workflow.md       816    rule      always
rules/quality-gates.md             283    rule      always
rules/verification-protocol.md     282    rule      always
CLAUDE.md.example                 1267    config    always
────────────────────────────────
Always-on total:                  3,723
On-demand total:                 99,672
Grand total:                    103,395
```

3,723 tokens. That's what the harness costs before a single user message arrives. Every conversation starts with those 3,723 tokens already consumed, whether they're useful for the current task or not.

Some observations:

The orchestrator protocol is the heavyweight at 1,075 tokens. It defines the entire autonomous loop, review routing tables, UAT process, and now trace capture. Is every section worth its token cost? I don't know yet, because I don't have enough traces to measure which sections actually influence behavior.

The top 5 on-demand skills consume more than the entire always-on budget combined: blog-writer (2,738), test-design-reviewer (2,530), pr-review (2,516), cognitive-load-analyzer (2,343), humanizer patterns (2,346). These only load when invoked, so their size matters less. But it's worth knowing.

The total harness is 103,395 tokens of instructions across 87 files. Most of it is on-demand. The always-on fraction (3.6%) is surprisingly lean, which validates the progressive disclosure strategy from post two. But "lean" and "optimal" aren't the same thing.

***

## Phase 3: An Agent That Reads Its Own Performance

This is where it gets Meta-Harness-shaped.

I built a `harness-mechanic` agent: a read-only agent that analyzes execution traces and token baselines, identifies systematic failure patterns, and proposes evidence-based changes to the harness files. It follows the same SCAN, CLASSIFY, PROPOSE, PRESENT cycle that the [knowledge-sync]({{< ref "2026-02-26-when-your-ais-second-brain-starts-talking-back" >}}) skill uses for promoting vault patterns into skills, but with a different data source.

Instead of scanning the Second Brain for recurring code patterns, it scans execution traces for recurring failures:

| Pattern | Signal | Example |
|---------|--------|---------|
| Same step fails across sessions | Rule gap | VERIFY fails on lint in 3/5 sessions |
| Score stuck below threshold | Instruction ambiguity | 2+ fix rounds, same MAJOR finding |
| Agent not activated when expected | Routing gap | No security review for auth code |
| Excessive loop rounds | Unclear success criteria | 4 rounds to reach score 80 |
| Always-on file >1500 tokens | Token waste | Rule with low information density |

Every proposal must cite specific trace data (session slug, step, values). No proposal is auto-applied; all are RED in the decision framework (requires human approval). One change per proposal, same as the autoresearch-prompt optimization loop: isolate variables, measure before and after.

The mechanic hasn't run on real data yet. The traces need a few weeks to accumulate before there's enough signal for pattern detection.

There's an obvious objection: running an LLM agent to optimize your LLM instructions costs tokens too. Is the optimizer's inference cost worth the savings? For the always-on rules (3,723 tokens, loaded in every session), probably yes: a one-time optimization that saves 500 tokens pays for itself after a handful of sessions. For on-demand skills that load twice a month, probably not. The mechanic needs to be selective.

There's also an overfitting risk. If I spend two weeks writing Go and the mechanic analyzes only those traces, it might conclude that the Rails skill is "dead weight" and propose deleting it. Small sample sizes produce confident but wrong conclusions. The safeguard: certain rules are pinned (the `--no-verify` ban, security baselines, the decision framework). The mechanic can compress them but never remove their semantics. And proposals always require human approval, which is the ultimate overfitting detector.

***

## The Gemini Reorder

Here's a confession about planning: I had it wrong.

My original execution order was: (1) build the optimization loop first (extend autoresearch-prompt to optimize harness files), (2) add trace capture, (3) measure tokens. Start with the exciting part, add measurement later.

I asked Gemini for a [second opinion]({{< ref "2026-02-19-the-missing-step-what-a-colleagues-hint-taught-me-about-ai-driven-planning" >}}). The response was blunt: "Reverse your order. You cannot optimize what you cannot measure."

Three specific corrections:

**First**, don't build synthetic benchmarks. If you optimize your React skill against "build a ToDo app," the optimizer will ruthlessly delete all advanced context (concurrent rendering, complex caching) because the benchmark didn't need it. Use real historical sessions instead. The harness should generalize to the work you actually do, not to a toy benchmark.

**Second**, static compression before dynamic loading. The paper's 4x token reduction came from the optimizer finding *denser words*, not from lazy-loading mechanisms. Claude Code manages its own context window. Trying to inject dynamic skill loading would fight the tool.

**Third**, the trace format decision. LLM-readable JSONL, not OpenTelemetry spans. The consumer matters more than the producer.

The reordered plan: traces first (build the measurement), tokens second (take the baseline), optimizer third (use the data). This is just the scientific method, but applied to a domain where developers (including me) habitually skip the measurement step.

Gemini also caught a real bug during code review. The multi-round step deduplication logic only allowed LOOP, FIX, and VERIFY to repeat across orchestrator rounds. But when the orchestrator loops back (score < 80), steps like IMPLEMENT, REVIEW, and SCORE repeat too. The fix was two lines. The bug would have silently dropped trace data from every multi-round session.

***

## What the Traces Will Tell Me

The infrastructure is deployed. The baseline exists. Now I wait for data.

The metrics I'll watch: average fix-loop rounds (should be 1, if the harness is clear enough), first-pass quality score distribution (where do sessions land before any fixes?), and whether the always-on 3,723 tokens can shrink without the scores dropping.

A practical middle ground before the full LLM mechanic runs: a deterministic script that flags obvious patterns. "Skill X loaded in 15 sessions, never influenced the output." "VERIFY failed on lint in 4 of the last 6 sessions." No inference cost, no overfitting risk, and it covers the low-hanging fruit.

Meta-Harness runs on purpose-built evaluation frameworks with thousands of examples. I have 10-20 sessions per week from a single developer. The optimization surface is smaller, the signal noisier. I'm not expecting 4x compression.

But here's what I already know, before the mechanic runs a single trace: I was treating system prompts like prose when they're code. Code gets profiled, benchmarked, version-controlled, and measured against production behavior. Prompts get vibes-checked and shipped. The gap between those two standards is where the easy improvements live.

3,723 tokens is my starting number. I'll report back when it changes.

***

*This post was written with Claude Code (claude-forge orchestrator) and reviewed by Gemini via /second-opinion. The Meta-Harness implementation is at [maroffo/claude-forge#11](https://github.com/maroffo/claude-forge/pull/11). First token baseline: 3,723 always-on, 103,395 total across 87 files. The harness-mechanic agent has not yet run on real trace data; results in a future post.*

*Part of a series: [post 1]({{< ref "2025-11-09-from-asking-claude-to-code-to-teaching-claude-our-patterns-building-modular-ai-skills" >}}) (skills), [post 2]({{< ref "2026-02-12-when-your-ai-skills-library-gets-too-smart-for-its-own-context-window" >}}) (context window), [post 3]({{< ref "2026-02-19-the-missing-step-what-a-colleagues-hint-taught-me-about-ai-driven-planning" >}}) (planning), [post 4]({{< ref "2026-02-26-when-your-ais-second-brain-starts-talking-back" >}}) (second brain).*
