---
title: "18 Retrospectives, One Feedback Loop"
date: 2026-07-13
summary: "I keep a LEARNING.md retrospective in every repo I work on. Eighteen of them, 290 lessons, read exactly once. A deterministic script and one agent pass found seven failure shapes recurring across repos, and four of them became mechanical process changes the same day. Two of those shapes, I had already blogged about without recognizing them."
tags: ["ai", "claude-code", "harness", "engineering"]
draft: false
cover:
  image: "images/cover-18-retrospectives-one-feedback-loop.png"
  alt: "Hand-drawn sketch of many scattered notebooks feeding into a single loop of arrows"
  relative: false
---

Two of the war stories on this blog were not one-off incidents. I could not see it from inside them.

Take {{< ref "2026-06-25-372-passing-tests-and-a-dead-program" >}}: an agent built three subsystems, wrote 372 passing tests, and never wired the subsystems together; every test was green and the program was dead. In a work repo, in a different quarter, an authorization layer failed to load its policy engine and the middleware waved every request through; every check "passed" because no check ran. Different codebases, different languages, no shared line of code. One shape: **the absence of an action is indistinguishable from its success.**

I wrote both retrospectives. I published one of them as a blog post. I never connected them. A 300-line Python script and a single agent pass connected them in an afternoon, along with eleven other incidents I had also filed and forgotten.

This post is about that loop: what it found, what it changed, and where it told me to distrust it.

***

### Write-only memory

Every repo I work on gets a `LEARNING.md`: a retrospective file with lessons learned, pitfalls, and best practices discovered, written at the end of significant work. It is a habit I automated long ago; a skill drafts it from the session history and git log, I edit and commit. By June this year there were 20 such files on my disk. Two were duplicates of repos that had migrated into a monorepo, so: 18 real retrospectives, spanning 12 logical repositories across three families of code (two products I work on, plus a pile of side projects). Split into atomic entries, they held 290 lessons, 245 unique.

Here is the uncomfortable question: how many of those 245 lessons had I read twice?

Approximately zero. Each file gets written with care, reviewed, committed, and then it sits there. The next project starts fresh. The retrospective habit produced a well-organized archive of things I already knew, once, briefly. Write-only memory.

This is not a personal defect, or at least not only mine. Dingsøyr and colleagues studied retrospectives in one of Scandinavia's largest agile projects ("Learning in the Large", XP 2018): across seven iterations, two teams recorded 109 issues and 36 action items, and only 6 of those 36 action items addressed anything beyond the individual team. Their conclusion was that short retrospectives produce what Argyris and Schön called single-loop learning: you fix the thing, you do not fix the process that produced the thing. An earlier study by Lehtinen and colleagues found the natural consequence: topics that teams could not resolve at their own level did not get escalated, they just recurred, meeting after meeting.

My version of "team level" is "repo level". The lesson stays in the file, the file stays in the repo, and the same failure shape shows up in the next repo wearing a different stack trace.

***

### The loop

So I built the missing traversal. It is deliberately two halves, and the boundary between them is the design.

**Half one is deterministic and free.** A Python script walks my development directory, finds every `LEARNING.md`, dedupes working copies, splits each file into atomic entries, and emits one JSONL corpus: repo, section, date, title, body. No LLM, no network, no cost. It runs in under a second and produces the same output every time. When I want to rebuild the corpus, I rebuild it; there is nothing to second-guess.

**Half two is an agent pass, and it is rationed.** One agent reads the corpus and clusters it. It runs on a human schedule, roughly monthly, one session, never autonomously. The instructions it gets are mostly about restraint, because the failure mode of this half is obvious: language models are pattern-completion engines, and if you hand one 245 war stories and ask for patterns, it will find patterns whether they exist or not.

The restraint rules are worth listing, because without them the report would be worthless:

- **Cluster by failure shape, not by topic.** "Everything reports success but nothing verifies it" is a shape. "A Redis bug" is a topic. Topics group incidents that merely share nouns; shapes group incidents that share a mechanism.
- **Collapse the repo paths before counting.** A repo that exists at two paths (pre- and post-monorepo migration) is one repo. Without this rule, my most duplicated project would have "recurred" with itself.
- **Two distinct repos or it does not count.** A shape that appears once is an anecdote and goes to a watch-list. Recurrence is the entire signal.
- **Prefer five real patterns over fifteen forced ones.** The agent is explicitly told that a small honest report beats an impressive one.

To make this concrete, here is what the two halves actually exchange. One line of the corpus (this one is from the incident behind the 372-tests post, so I can quote it without anonymizing):

```json
{"repo": "private/pi-migration/golem", "section": "Lessons Learned",
 "date": "2026-02-23", "title": "Three subsystems, zero wiring, fully passing tests",
 "body": "**Context:** The CLI, the config system, and the provider setup package were all fully implemented and tested independently. 372 tests green. Ship it? **Problem:** The CLI was completely non-functional. ..."}
```

And the format the agent must use for every pattern member in its report, so that each claim points back to a line I can open:

```
- {private/pi-migration/golem, 2026-02-23, Three subsystems, zero wiring,
   fully passing tests}: 372 green tests, CLI dead on first run
```

Every cluster ships with these receipts: each member is a specific retrospective entry with repo, date, and title. Triage does not mean trusting a summary; it means opening the entries and checking that they actually rhyme. I did, for all seven clusters. One kind of evidence I could not manufacture afterward: several members were already published on this blog as full posts, written months apart, with no idea they were siblings.

***

### One operator, not an organization

Before the results, the caveat that decides what the results mean. This is where a skeptical reader has already arrived, so let me get there first.

These are 18 retrospectives from one person's repos. The teams behind the two products are real, but the retrospectives were written by me, about work I was close to, in a toolchain I configured. When the same failure shape appears in three of my codebases, that is not evidence of an industry-wide process bug. It is evidence about *me*: my habits, and the checks I reliably skip. "Silent success" recurring thirteen times may just mean I am the kind of engineer who trusts a passing test a little too much, in every language I touch.

There is a second bias stacked on the first: a `LEARNING.md` records the failures I noticed and found worth writing down. The corpus is not a sample of my failures; it is a sample of my *memorable* failures. The loop can only ever mine what the retrospective habit captured.

I think the honest claim survives both objections, but it is narrower than the one I wanted to write: recurrence among recorded failures, across one operator's repos, is a cheap mechanical signal for where a process fix will pay off. Not "this is how software fails". Rather: "this is how I fail, on the record, repeatedly". For the purpose of deciding which hook to build next, the narrow claim is all I need. A mirror does not have to be a census to be useful.

***

### Seven shapes

The first run produced seven patterns that cleared the two-repo threshold. Four crossed product boundaries, which under the ranking rules makes them the strongest signals.

| Pattern | Repos | Example member |
|---------|-------|----------------|
| Silent success: absence of an action indistinguishable from its success | 5 repos, all 3 families | 372 green tests, dead program; auth middleware waving everyone through |
| Async is not concurrent: cancellation silently dropped | 4 repos, all 3 families | `for range channel` with no way to honor Ctrl+C; a shared async DB session corrupted under `gather` |
| Stale references: docs and audits that lie after a change | 4 repos, 3 families | an audit that reported 12 "missing" endpoints, all implemented in a file the grep never opened |
| Authoritative advice not validated against the real workload | 4 repos, 3 families | the hash swap an AI reviewer called mandatory, measured 23% slower |
| Build-time values baked in, change silently ignored | 3 repos, 2 families | a public API URL cached into a Docker layer, old value still live after "redeploying" |
| Parallel agents collide on shared surfaces | 3 repos, 2 families | four agents, one `go.mod`, one corrupted manifest |
| `.gitignore` glob swallows tracked source | 2 repos, 2 families | a bare binary-name ignore that also matched `cmd/<name>/`, vanishing the main package |

Two rows deserve a sentence each.

The silent-success cluster is the widest and the most expensive: thirteen members, and most of them were found in production or embarrassingly late, precisely because every automated signal was green. This is also the cluster that vindicates mining *retrospectives* instead of only mining execution traces, which I did in {{< ref "2026-04-05-agents-delete-good-code-heres-how-im-stopping-them" >}}. A trace shows tools called, tokens spent, tests run. A green test that verifies nothing looks identical, in a trace, to a green test that verifies everything. The only place that failure exists is in the human-written postmortem.

The advice-not-validated cluster includes {{< ref "2026-06-17-the-ai-said-mandatory-i-measured-23-percent-slower" >}} and three other incidents where a confident recommendation (from an LLM reviewer, a benchmark, or a viral chart) reversed under measurement on the real workload. When I published that post I thought I was writing about hashing. The corpus says I was writing about my recurring willingness to act on authority-shaped claims. That reframe is exactly the kind of thing you cannot see from inside a single incident.

***

### From shape to contract

Finding patterns is the fun half. The loop's actual output is duller and better: for each pattern, exactly one proposed harness change, wrapped in a six-field change contract. Component, failure mode targeted, predicted improvement, invariants preserved, falsification criterion, rollback. One failure mode per contract, no bundles. I adopted this format from the meta-harness work I described in {{< ref "2026-03-31-your-ai-harness-is-hand-crafted-thats-the-problem" >}}, and it has become the most valuable constraint in my setup.

Four patterns got accepted and landed the same day, cheapest and most mechanical first:

| Pattern | Change landed |
|---------|---------------|
| `.gitignore` swallow | A pre-commit lint: warns when a newly staged ignore line is a bare name matching an existing tracked directory. Advisory, never blocks. |
| Silent success | A mandatory question added to my architecture and security review agents: for every branch that returns success/allow/200, is there a test that fails if the action is skipped? |
| Build-time values | A review-checklist item: touching a build arg means tracing the whole substitution chain and confirming the cache is busted. |
| Async cancellation | Named anti-patterns added to my Go and Python review skills: `range` over an external channel without a `select` on context, `nil` contexts, shared async sessions, CPU work on the event loop. |

The ordering rule matters more than any single change: prefer the cheapest fully-mechanical win over the highest-value fuzzy one. The `.gitignore` lint is objectively the least important pattern on the list, and it went in first, because it is the one change that can be made with near-zero false positives. A hook that cries wolf does not just fail; it trains me to ignore hooks, and that damage spreads to every other hook I own.

***

### The falsification row that killed a proposal

My favorite moment of the run was a rejection.

For the silent-success pattern, the report proposed two things: the review-checklist question (landed, above) and a companion pre-commit hook that would grep changed code for fail-open tells, passthrough branches, swallowed errors, that sort of thing. Sounds great. But every proposal must fill in its own falsification row, and this one's row read, roughly: *this hook fails if it fires three times on benign code for every real defect*. Writing that sentence was enough to see it would come true. Fail-open tells are context-dependent; a grep cannot tell graceful degradation designed and tested from graceful degradation nobody chose. The hook was never built.

I want to be precise about the credit here, because "the loop said no to itself" makes a better headline than it deserves. No wisdom emerged from the machine. The contract format did the work: forcing every proposal to state, in advance, the concrete observation that would prove it harmful, makes some proposals refute themselves on paper before costing anything. The same format contains a clause covering the loop itself: if two consecutive runs propose the same patterns and none get implemented, the loop is noise the human ignores, stop running it. That clause has never fired. It cannot fire before run two exists. It is a promise, not evidence, and I am reporting it as exactly that.

***

### What I do not know yet

This is a lab report on n=1 run, not a published result. The metric that would actually validate the loop, the repeat-pattern rate (how many of this run's shapes recur next run, especially the four that now have mechanical fixes), is unobservable until the second run. If the silent-success cluster keeps growing at the same rate after the review-agent change, the change is theater and its own falsification row says to remove it.

There is also a subtler decay to watch. Now that a loop reads my retrospectives, I write retrospectives knowing the loop will read them. The corpus stops being an independent record and starts being input to a system I want to please; entries may drift toward the shapes the loop already rewards. Goodhart does not spare small personal systems. The only defense I have is that the ingest half is deterministic and the entries carry dates, so drift is at least auditable in hindsight.

None of this is a new idea. SRE culture has preached cross-incident analysis over single postmortems for years, and OpenAI recently described running a recurring doc-gardening agent to catch stale internal docs, which is this same instinct pointed at documentation. What felt new to me is how low the barrier has become for one person: the organizational version of this loop needs a team, a forum, and a quarter; mine needs a Python script, one agent session a month, and the retrospective habit I already had. The script and the skill are in my public [claude-forge](https://github.com/maroffo/claude-forge) repo, for whatever an n=1 tool is worth to you.

***

### The pattern is the deliverable

For years I treated the retrospective as the end of the learning process: incident, lesson, file, done. The first run of this loop convinced me the retrospective was the wrong deliverable all along. It is not the product; it is the raw material. A lesson in a file fixes nothing by itself, the same way a bug report closes nothing by itself. Fixing the bug is single-loop learning. The deliverable that compounds is the pattern, plus the one mechanical change, plus the sentence that says how we will know the change failed.

Eighteen files, 245 lessons, seven shapes, four changes, one rejected hook. Whether any of it holds up is a question for run two, and this time the answer will not depend on my memory.

***

*Methodology note: the corpus statistics (18 retrospective files after deduplication, 290 atomic entries, 245 unique, 12 logical repos), the seven patterns, and the four landed changes come from the first learning-loop run in June 2026; the ingest script and skill are public in [claude-forge](https://github.com/maroffo/claude-forge). War-story details from work repositories are anonymized. The retrospective study cited is Dingsøyr, Mikalsen, Solem and Vestues, "Learning in the Large: An Exploratory Study of Retrospectives in Large-Scale Agile Development", XP 2018 ([arXiv:1805.10310](https://arxiv.org/abs/1805.10310)); the recurrence finding is Lehtinen et al., "Recurring opinions or productive improvements", Empirical Software Engineering, 2017. The single-loop/double-loop distinction is Argyris and Schön's. OpenAI's doc-gardening agent is described in their [harness engineering post](https://openai.com/index/harness-engineering/). This post was drafted with AI assistance against my own repos and reports; three isolated AI reviewers (Claude, Gemini, DeepSeek) critiqued the outline, and their strongest shared objection, that a single-operator corpus measures my blind spots rather than the industry's, reshaped the thesis.*
