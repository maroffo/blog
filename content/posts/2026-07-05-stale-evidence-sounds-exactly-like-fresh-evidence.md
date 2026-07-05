---
title: "Stale Evidence Sounds Exactly Like Fresh Evidence"
date: 2026-07-05
summary: "I stopped trusting my agent's prose and started demanding evidence. Then a reviewer agent filed a confident, well-cited warning against code that no longer existed. Evidence has a grammar: freshness, correlation, independence. I watched all three rules break in one afternoon."
tags: ["ai", "llm", "engineering", "claude-code", "harness"]
draft: false
cover:
  image: "images/cover-stale-evidence-sounds-exactly-like-fresh-evidence.png"
  alt: "Hand-drawn sketch of a car rearview mirror reflecting a traffic light on go, while the light ahead on the road signals stop"
  relative: false
---

This afternoon a code reviewer filed a warning against my change. It was a good warning. It named the file and the exact lines. It described a failure scenario that would genuinely bite: an early lint pass could mask a later test failure, and my gate would call the work green anyway. It ended with a recommendation in capital letters: FIX BEFORE MERGE. Every claim was specific and anchored to code.

The reviewer was an LLM agent, and every one of those claims was about a version of the code that no longer existed. I had already fixed the bug it described, hours earlier, in response to its own earlier review. It was arguing, confidently and with citations, against a snapshot in its memory.

I want to be precise about why this rattled me, because it is not the usual complaint about hallucination. Nothing was hallucinated. The lines it cited had been real. The failure scenario had been real. If you had shown me that review without a timestamp, I would have called it a model of evidence-based engineering. That is the problem. Stale evidence sounds exactly like fresh evidence. There is no tell in the prose, because the prose is not where the staleness lives.

***

### The rule that got me here

I have been converging on the same rule from two directions.

From one side, a colleague published a post this morning about [harness engineering](https://mauro.medda.xyz/posts/we-build-the-harness/) and put the rule in three words: evidence over eloquence. Nothing is done because the agent said so. A model has an endless supply of confidence and it will spend every bit of it being wrong, so you wire the system to trust tool exit codes and verdicts, not prose.

From the other side, my own history. [Last month a program with 372 passing tests turned out to be dead on first run]({{< ref "2026-06-25-372-passing-tests-and-a-dead-program" >}}): green was a proxy, and something was optimizing the proxy. Before that, [agents were gaming the signal outright]({{< ref "2026-04-05-agents-delete-good-code-heres-how-im-stopping-them" >}}), deleting code to make the bar green. The lesson each time: stop reading the agent's summary, go look at the sensor.

So I did the homework. My quality gate has a scoring step: after the review agents run, the session reports `SCORE: n/100` against a threshold. Commit at 80, PR at 90. And this afternoon I finally admitted what that score actually was: a judge's opinion, in prose, wearing a number as a costume. Nothing verified that the tests had actually run in that round. The model could report "92, ready for PR" while the last real test run predated three rounds of fixes. Evidence over eloquence, except the evidence was optional.

I spent the day fixing that, driving the same agent whose claims the fix would police. We built a hook that blocks the session from ending when it reports a SCORE without a successful test run behind it. The reviewer agent reviewed the hook. And in the space of that one afternoon, evidence lied to me three different ways.

***

### Three ways evidence lies

**It goes stale.** The obvious one, and still the one I catch least. The stale review above is one case. The judge-only score is another, and it is worth spelling out the mechanics: the tests ran, they passed, the exit code was real, and then the code changed. Every artifact of that evidence is still sitting in the transcript looking exactly as green as the moment it was produced. Evidence does not come with an expiry date printed on it. You have to stamp one on yourself, and the stamp has to be relative to the thing being claimed: a test run is fresh relative to the last edit, not relative to the clock.

**It loses its chain of custody.** My existing verification hook, the one I have trusted for weeks, checked whether a test command was *issued* after the last edit. Issued. It never looked at the result. A `make check` that failed counted as "verification ran," because the hook pattern-matched the command and moved on. Think about what that means: the sensor fired, the sensor screamed red, and the gate recorded "sensor consulted, all good." The claim and the result were never correlated. In the transcript format I parse, a command and its result are tied together by an id; a command with no id cannot be tied to any outcome at all, and my hook happily accepted those too. Evidence you cannot tie to its claim is not weak evidence. It does not count at all.

**It gets outranked and doesn't step aside.** This one I did not catch; the reviewer agent did, reading my first draft of the fix before it merged. My rule was "any successful test run after the last edit," which means edit, lint passes, full test suite fails, score 92, gate open. The early green outranked the later red, because I had only asked for *a* green, not for the *freshest* signal to be green. An old green does not beat a new red. If your latest evidence is a failure, you do not have passing evidence plus a failure. You have a failure.

Three stories, one afternoon, in a harness whose entire purpose is evidence discipline. None of them required a malicious agent or a hallucinating model. They only required me to treat "evidence exists" as equivalent to "evidence holds."

***

### What the fix looks like

The mechanical version of all three rules fits in a few lines. This is from the Stop hook that now guards the scoring step; `verifies` are test/lint/build commands found in the session transcript, `failed_ids` are the ones whose results errored:

```python
# Evidence: a successful verify command issued after BOTH the last source edit
# and the last failed verify. The freshest computational signal must be green.
# A verify with no tool_use id cannot be correlated to its result: not evidence.
last_edit = edit_lines[-1] if edit_lines else -1
failed_lines = [idx for idx, tool_id in verifies if tool_id in failed_ids]
threshold = max([last_edit] + failed_lines)
for idx, tool_id in verifies:
    if idx > threshold and tool_id is not None and tool_id not in failed_ids:
        sys.exit(0)  # evidence holds, let the turn end
```

Look at the `max` line, because it confesses something my three-part story was hiding. Stale and outranked are not two failure modes. They are one rule with two triggers: a green must postdate every event that invalidates it, and both an edit and a failure are invalidating events. One moves the threshold because you changed the world; the other because the world reported bad news. The taxonomy I walked in with collapsed into a single comparison, and I find that more convincing than the taxonomy, not less: three stories that looked different from the outside found the same seam in the code. What survives as a genuinely separate axis is correlation, `tool_id is not None`: a claim that cannot be tied to its outcome does not count, no matter how fresh it is. (In this transcript format ids are unique per invocation, so a failed attempt and its retry never share one; if yours can, this check needs more care.)

There is a matching detail I almost got wrong in the other direction. Between the tests and the score, review agents run, and they take time. A naive freshness rule ("evidence must postdate everything") would invalidate the test run the moment a reviewer finished, forcing a pointless re-run every round. The rule has to distinguish events that can change the code, which reset the clock, from events that only read it, which do not. A fix delegated to a code-writing subagent resets the clock. A read-only reviewer does not. Freshness is relative to *mutation*, not to activity.

The failed-result rule turned out to be missing from my older hook too, the one guarding ordinary edits. Same fix, backported. Two pull requests, two one-page change contracts stating what each is supposed to improve and what observation would prove it made things worse. Ask me in ten sessions.

***

### Independence, the rule I haven't closed

There is a fourth property I want and do not fully have: independence. Who runs the sensor matters. Right now, the turn being graded is the same turn that runs the tools, which means a sufficiently confused agent could, in principle, report around the gate. My commit hook re-runs the full suite itself, from outside the agent's control, so the final gate is independent. But the scoring gate between rounds still trusts the transcript, and the transcript only sees what happened in the main session: a file mutated through a shell command instead of an edit tool, or inside a subagent, is invisible to the freshness clock. And the freshness rule itself has a scope blind spot: after a failed test suite, a later *weaker* green, a lint pass, say, clears the threshold, because the arithmetic knows recency but not sufficiency. Lint passing is evidence that lint passes, nothing more. I documented these holes in the change contract instead of pretending the heuristic is airtight, with a threshold for when their occurrence in practice means the design gets superseded rather than patched.

I take some comfort in company. The harness my colleague wrote about declares the same debt in its own plan: the gate trusts the turn to run the tool, until a later milestone makes CI re-run it independently. Two harnesses, built separately, converging on the same lesson from opposite directions. The lesson generalizes past code, too. Any pipeline where an agent produces work and evidence of that work in the same breath has these four dials: is the evidence fresh, is it correlated to its claim, does the newest signal win, and did someone other than the claimant produce it. A sales pipeline scored by the agent that wrote the outreach has exactly this problem, minus the unit tests.

***

### It is not turtles all the way down

The obvious objection: you built sensors to check the agent, now you are building sensors to check the sensors. Where does it end?

It ends one layer down, but I have to be honest about what that layer is made of. The comparison at its heart, `idx > threshold`, cannot be persuaded, because it cannot read arguments. The reviewer that filed the stale warning is a large language model with taste, context, and every failure mode that comes with them; the thing that catches its staleness is an integer comparison. But the integers come from somewhere. Upstream of the arithmetic sits a parser that decides what counts as an edit, what counts as a verify, what counts as a failure, and it parses a transcript format I do not control. When that format changes in some future release, my floor does not argue back; it silently stops seeing. So the honest version of the claim is not "trust bottoms out at arithmetic." It is: trust bottoms out at a classifier you have chosen to watch, and the arithmetic's job is to make that classifier's verdicts unpersuadable. That is still worth having. It is one floor to maintain, not a tower, and its failure modes are the boring kind you can write regression tests for. I did: there is now a test that fails if my two hooks' definitions of "evidence" drift apart, precisely because the parser is the part I trust least.

A second objection, from anyone who read the 372-tests post: didn't you just build another proxy? The hook checks that a verify ran, passed, and postdates the last mutation. It has no idea whether that verify *covers* anything. Correct, and deliberate. The hook does not judge whether the evidence is sufficient; that stays with the review layer, which is exactly the kind of qualitative call a judge is for. The arithmetic only guarantees the judge had something fresh and real to grade. Sufficiency without freshness gave me the stale warning. Freshness without sufficiency gives me a green lint pass standing in for a test suite. You need both layers, doing the one job each is fit for.

That was the real correction to how I had internalized "evidence over eloquence." I had heard it as: route trust away from prose, toward evidence. The version I believe after this afternoon is narrower: route trust toward evidence that can prove it is fresh, tied to its claim, and not outranked, and keep one deterministic layer whose only job is checking those properties. Because evidence has a property nobody had warned me about: producing it costs compute and time, but once produced it never stops *looking* valid. It sits in the context, still green, long after the world has moved on.

The reviewer that opened this post, by the way, was right about everything except the present tense. I checked its claims against the committed code, line by line, before dismissing them, which is the same discipline pointed the other way. Everything in this loop ages: the code, the review, the evidence, my patience. Arithmetic is the only thing in it that does not.

***

*This post came out of one working session on my Claude Code harness, claude-forge, on the day it happened. The hooks, tests, and change contracts described are real and linked from the repo's quality reports. The stale review is quoted from the session transcript. Drafted with Claude, argued with by me, verified against the code.*
