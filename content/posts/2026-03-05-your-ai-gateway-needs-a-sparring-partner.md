---
title: "Your AI Gateway Needs a Sparring Partner"
date: 2026-03-05
summary: "promptfoo red-teams your models before deploy. Mirsad guards them in production. We use both, and here's why they need each other."
tags: ["ai", "security", "llm", "mirsad", "red-teaming"]
draft: true
cover:
  image: "images/cover-sparring-partner.png"
  alt: "Your AI Gateway Needs a Sparring Partner"
  relative: true
---

A few weeks ago, a post went viral on LinkedIn claiming promptfoo is "the most underrated tool in AI engineering." The argument: if you're deploying LLMs without systematic evaluation and red-teaming, you're flying blind.

I agree with the premise. I disagree with the framing.

At HikmaAI, we've been building [Mirsad](https://github.com/hikmaai-io/hikma-mirsad), a runtime AI security gateway that sits between your application and the LLM provider. It analyzes every request and response in real time: prompt injection, toxicity, PII, jailbreak detection. The pattern-matching detectors add under 5ms; the ML classifier (DeBERTa v3 via ONNX) adds 10-20ms depending on sequence length and hardware. When I saw the promptfoo hype, my first reaction was defensive. Are we missing something? Should we be worried? I spent a week going through promptfoo's codebase, docs, and enterprise offering, expecting to find overlap.

What I found instead: promptfoo and Mirsad aren't competitors. They solve different halves of a problem most teams only address half of.

***

### Two loops, not one

Here's the mental model I keep coming back to.

| Loop | When | Question | Tool |
|------|------|----------|------|
| Pre-production | Before deploy | "Which model? How does it handle edge cases?" | promptfoo |
| Production | After deploy | "Is this request safe? What's the real-world cost?" | Mirsad |

Pre-production evaluation tells you *what to expect*. Production security tells you *what actually happened*. They feed each other, and neither works well alone.

It's the same reason we don't choose between unit tests and production monitoring. We use both, because they catch different things. But with AI security, most teams pick one and call it done.

***

### What promptfoo does well (and what it doesn't)

promptfoo is a test harness for LLMs. You define test cases, run them against one or more models, and evaluate the results. TypeScript, CLI-driven, fits into CI/CD. The red-teaming surface is genuinely broad: 85+ attack plugins (prompt injection, cross-session leaks, ASCII smuggling, indirect injection via tool outputs), 24 delivery strategies (multilingual, ROT13, leetspeak, Base64, crescendo attacks), and 8 compliance presets covering OWASP, NIST, MITRE ATLAS, and the EU AI Act.

That last one matters if you're in Europe. Which, given the AI Act's extraterritorial reach, is more of you than you think.

For model selection, it does benchmarking, A/B comparison, and assertion-based testing. If you're picking between GPT-4o, Claude Sonnet, and Gemini Pro for a specific use case, promptfoo gives you structured data instead of vibes.

What it doesn't do: run in production. promptfoo Enterprise added runtime guardrails recently, but they rely on LLM-as-judge, which typically adds hundreds of milliseconds per check. At HikmaAI, our privacy contract requires stateless analysis at single-digit to low-double-digit millisecond latency. That's an order-of-magnitude gap, and it's not a tuning problem; it's an architecture choice. LLM-as-judge is thorough but slow. Pattern matching and lightweight ML classifiers are fast but narrower. Different constraints, different tools.

***

### What Mirsad does differently

Mirsad is a reverse proxy. Sits in the request path, analyzes input and output, decides in real time: block, alert, or pass through. Raw text never appears in telemetry (privacy contract). The pattern-matching detectors (regex, keyword, policy) add under 5ms; the DeBERTa classifier adds 10-20ms when the ONNX build is enabled. Builds without CGO skip the ML model entirely and rely on pattern matching only.

Seven detectors run in parallel on every request:

| Detector | What it catches |
|----------|----------------|
| Prompt injection | DeBERTa v3 classifier, multi-vector (direct, indirect, system prompt extraction) |
| Toxicity | Multi-category scoring (hate, violence, sexual, self-harm) |
| PII | 18 entity types, configurable redaction |
| Jailbreak | Pattern-based + LLM evasion tactics |
| Policy violation | 8 configurable policies (medical, legal, financial, weapons...) |
| Secrets | API keys, tokens, credentials in output |
| Canary | Data exfiltration markers |

Each request produces an `OutputSignals` struct classified into a 3-tier verdict: safe, uncertain, or unsafe. The verdict maps to protection modes (BLOCK, ALERT, SHADOW, SANDBOX), so operators tune how aggressively the system intervenes. I like this separation because the security team picks the detectors, the ops team picks the consequences.

Then there's the observability layer, which is where things get interesting for the promptfoo comparison. Mirsad tracks real token consumption, estimated costs, and latency percentiles, all per-model, per-tenant. Prometheus counters, OpenTelemetry spans, Langfuse export. This is the data that answers "how is model X performing with real traffic right now?" Not "how did model X perform on our test suite last Tuesday."

***

### The feedback loop

The two loops aren't independent. They should feed each other, and this is the part I rarely see discussed.

promptfoo → Mirsad: red-teaming discovers your model is vulnerable to a specific injection pattern (say, ASCII smuggling via Unicode homoglyphs). You add a regex to Mirsad's jailbreak detector, or compile a new policy plugin, so that pattern gets caught in production, even when an attacker crafts a variant your test suite didn't cover.

Mirsad → promptfoo: production telemetry shows model X has a 3x higher jailbreak attempt rate than model Y for the same use case. That's a signal to re-evaluate your model choice, and promptfoo is the tool that does that evaluation with structure.

Without the first direction, your production defenses only cover patterns you imagined. Without the second, your test suite only covers attacks you've already seen.

```
promptfoo red-team → discover vulnerability
  → add Mirsad detector rule
    → catch production variant
      → feed back to promptfoo test suite
        → discover next vulnerability
```

This isn't a new idea. SAST/DAST finds vulnerabilities pre-deploy, WAFs catch them in production, incident findings feed back into the test suite. We've been doing this in traditional security for years. AI security just hasn't caught up yet.

***

### What we're actually building at HikmaAI

Mirsad is open-source, Go, stateless, no vendor lock-in. We're not building a red-teaming framework. promptfoo already does that well, and I'd rather integrate with it than rewrite it.

The integration point is a pair of Check API endpoints (`/v1/check`, `/v1/check-output`) that accept text for analysis without proxying. This means promptfoo's assertion layer could call Mirsad's detectors as custom graders. Red-team with promptfoo, grade with Mirsad's classifiers, feed the failures back into production rules.

The plugin architecture uses compile-time Go imports (capability interfaces: InputGuard, OutputGuard, Exporter). No runtime code loading, no reflection. You want a custom detector? Write a Go package, import it, done.

Mirsad is the production half. Use promptfoo (or any red-teaming tool you prefer) for the pre-production half. Together, they close the loop.

***

### Where most teams are

From what I've seen talking to other teams, most fall into one of these:

| Bucket | Pre-production | Production | What they're missing |
|--------|---------------|------------|------|
| Optimists | None | None | Everything |
| Testers | promptfoo / manual red-team | None | Novel attacks, model drift, cost blowups |
| Watchers | None | Basic rate limiting | Untested models, known vulnerabilities |
| Closed-loop | Red-team + regression suite | Gateway + observability | Edge cases (the healthy kind) |

The goal is that last row. Easier said than done, obviously, but the first step is knowing which column you're empty on. If you're a Tester, add a production gateway. If you're a Watcher, run a red-team exercise once. Either move is more useful than perfecting the half you already have.

***

### If you're starting from zero

Install promptfoo, run the OWASP LLM Top 10 preset against your production model config. Takes about an hour. Most teams are surprised by what passes through.

Then deploy a transparent proxy in observe-only mode (Mirsad with ALERT, or any gateway that logs without blocking). Collect a week of real traffic. You'll learn things about your users that your product team never mentioned.

After that, connect the two: take the top findings from the red-team and verify they're caught in production. Take the surprises from production and add them to your test suite. That's the skeleton. Everything after is iteration.

***

### The part I keep thinking about

Every team deploying LLMs will face a security incident. The question is whether you'll catch it in testing, detect it in production, or hear about it from your users. (Or, if you're especially unlucky, from a journalist.)

Pre-production testing without production monitoring is hope. Production monitoring without pre-production testing is firefighting. Neither is a strategy.

Mirsad is open source: [hikmaai-io/hikma-mirsad](https://github.com/hikmaai-io/hikma-mirsad). And yes, we use promptfoo to red-team it. It would be a bit embarrassing not to.

***

### References

1. [promptfoo documentation and red-teaming guide](https://www.promptfoo.dev/docs/)
2. [OWASP LLM Top 10](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
3. [EU AI Act, risk-based classification](https://artificialintelligenceact.eu/)
4. [HikmaAI Mirsad, open-source AI security gateway](https://github.com/hikmaai-io/hikma-mirsad)
5. Previous articles: [AI Productivity Paradox]({{< ref "2026-01-01-measuring-software-performance-what-changed-in-3-years" >}}), [Modular Skills]({{< ref "2025-11-09-from-asking-claude-to-code-to-teaching-claude-our-patterns-building-modular-ai-skills" >}})

***

_**Methodology note:** This article was written with AI assistance (Claude Code). The technical comparison is based on direct analysis of both codebases. The synthesis and editorial choices are mine. Claude helped with structuring and drafting; I used my humanizer pipeline to clean up the prose._
