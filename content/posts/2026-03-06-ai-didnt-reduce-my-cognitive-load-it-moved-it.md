---
title: "AI Didn't Reduce My Cognitive Load. It Moved It."
date: 2026-03-06
summary: "Everyone says AI makes developers faster. My experience is the opposite: I arrive exhausted not because I wrote more code, but because I evaluated more decisions. The effort didn't shrink. It transformed."
tags: ["ai", "engineering", "leadership", "claude-code"]
draft: false
cover:
  image: "images/cover-cognitive-load.png"
  alt: "AI Didn't Reduce My Cognitive Load. It Moved It."
  relative: false
---

This morning, [Davide Carboni](https://digitaldavide.me) posted something on LinkedIn that I've been turning over in my head since. The gist: AI carries a small paradox. The more we use it for research, summaries, and solutions, the more we risk delegating pieces of our reasoning. But at the same time, the volume of information around us makes AI almost necessary to filter the noise.

AI sits in the middle, he wrote. It reduces cognitive effort on one side, and becomes indispensable on the other.

I read it and my first reaction was: that's not what's happening to me at all.

***

### The exhaustion nobody warned me about

I use AI tools every day for work. Claude Code, Gemini for reviews, various automations. And some days I arrive at the end of the afternoon exhausted. More than I did two years ago when I was writing everything by hand.

The weird part: I'm writing less code than ever. The AI handles the typing, the boilerplate, the scaffolding. So where does the fatigue come from?

My response to Davide's post: "AI speeds up execution, but cognitive effort doesn't disappear. It shifts. It demands constant attention to evaluate whether what the AI returns is correct, to figure out what to ask and how to ask it effectively, to notice when it's going off track."

The best metaphor I've found: it's like having a dozen extremely fast colleagues who occasionally forget chunks of knowledge. You end up playing Architect and CTO all day, staying intensely focused. A lot of work vanishes, but what remains is the kind that requires experience and concentration.

***

### Three kinds of effort (and which one AI kills)

There's a framework that explains what's happening. John Sweller's Cognitive Load Theory splits mental effort into three types: extraneous (friction from bad tools, syntax lookup, boilerplate), intrinsic (the actual complexity of the problem), and germane (the effort of building understanding, the debugging, the wrong turns, the "why doesn't this work?" moments).

AI is excellent at removing extraneous load. No more hunting for API signatures or writing scaffolding for the hundredth time. This is a real improvement, and it's why AI *feels* productive.

Intrinsic load doesn't change. A distributed systems bug doesn't become simpler because an LLM wrote the first draft.

Germane load is where it gets dangerous. In March, I wrote about the [skill tax]({{< ref "2026-03-04-ai-is-breaking-the-engineering-talent-pipeline" >}}): Anthropic's study showing a 17% learning penalty for AI-assisted developers. The mechanism is germane load removal. AI handles the construction, so the developer skips the schema-building that turns exposure into understanding. A 2025 study by Gerlich (666 participants across diverse age groups) found a significant negative correlation between frequent AI usage and critical thinking ability, with younger participants hit hardest, while older participants, who used AI less frequently, maintained higher critical thinking scores.

The net effect: AI swaps the old extraneous load (boilerplate, syntax lookup) for a new, heavier extraneous load (reviewing alien code, managing context, redirecting when it drifts), while killing the germane load that actually made us better engineers. The effort that teaches disappears. The effort that exhausts multiplies. Keep this framework in mind. It explains everything that follows.

***

### The perception trap

In January, I wrote about the [AI Productivity Paradox]({{< ref "2026-01-01-measuring-software-performance-what-changed-in-3-years" >}}): the METR study where experienced developers were 19% slower with AI tools, while believing they were 20% faster. I treated it as a data point back then. Now I think it's describing how our brains account for effort.

Typing code feels like work. Your fingers move, lines appear, you're visibly productive. Evaluating AI output doesn't feel like work the same way. You're reading, thinking, deciding. From the outside (and from the inside), it looks like you're just sitting there. But the cognitive cost is real, and it compounds across a full day.

The METR researchers found that developers spent 9% of total task time reviewing and modifying AI-generated code, with additional time on prompting, waiting, and debugging AI errors. Less than 44% of AI suggestions were accepted. The overhead of evaluating and redirecting the AI overwhelmed any time savings from reduced typing.

But here's the thing that gets me: after experiencing the slowdown, the developers *still believed* AI had sped them up. The subjective experience of effort had decoupled from objective performance. Extraneous load (boilerplate, syntax lookup, repetitive scaffolding) genuinely dropped, and that *felt* like progress. What replaced it, the evaluation load, didn't register as "real work."

***

### What a day actually looks like now

Let me make this concrete. A typical day before AI tools, circa 2023:

- Read requirements, sketch architecture
- Write code, hit compiler errors, fix them
- Debug, add tests, refactor
- Review PRs, push, repeat

A typical day now:

- Listen to requirements, discuss architecture with Claude, have it draft an ADR
- Ask Gemini for a second opinion on the approach
- Review and evaluate the ADR, answer the open questions myself
- Ask Claude to build a detailed implementation plan, send it to Gemini for another pass
- Review the plan, make sure it actually makes sense
- Ask Claude to implement the plan
- Ask Gemini to review the code
- Read code I didn't write and build a mental model of it
- Ask for additional tests, review what comes back, accept parts, reject others
- Run the tests Claude wrote (TDD as truth anchor, but now I'm verifying someone else's understanding of my intent)
- Context-switch to a different task, re-explain the entire project to a fresh AI session

The typing part shrank dramatically. The thinking part expanded. And the thinking is harder, because I'm building mental models of code written by something that doesn't share my context, my constraints, or my priorities. There's also a hidden cost in prompting itself: writing code allows for implicit assumptions, but prompting requires exhausting explicitness. You have to translate architectural context that lives in your head into words that fit a context window.

A clarification: not all AI tools create the same cognitive load. Inline autocomplete (Copilot-style) is relatively light, you accept or reject a suggestion and keep flowing. The real weight comes from conversational and agentic tools: Claude Code, Gemini CLI, autonomous agents. These require you to context-switch between coding and prompting dozens of times per hour, each transition carrying a small cognitive penalty that adds up.

There's something else nobody talks about. Writing code from scratch gives you a continuous loop of small wins: a function works, a test passes, a refactor clicks into place. Reviewing AI output replaces that loop with a continuous stream of corrections. You go from creator to editor, and the emotional reward system of programming changes completely. The dopamine hits stop. What's left is vigilance.

***

### The "almost right" problem

The most draining part of AI-assisted work isn't when the AI gets something wrong. Wrong is easy. You see it, you reject it, you move on.

The killer is "almost right."

Two out of three developers in the Stack Overflow 2025 survey (49,000+ respondents) say they're spending more time fixing almost-right AI code. Trust in AI accuracy dropped from 40% to 29% in a single year; overall favorability fell from 72% to 60%. The industry's enthusiasm is cooling because the daily reality doesn't match the pitch.

You can see the effect in the codebase itself. GitClear analyzed 211 million changed lines of code between 2020 and 2024, and one stat stands out: copy-pasted code rose from 8% to over 12%, while refactored code (the kind that signals someone actually understood the code and improved it deliberately) collapsed from 25% to under 10%. We're producing more code and understanding less of it. That's the germane load problem showing up in version control.

At the team level, Faros AI found that high-AI-adoption teams shipped 47% more PRs per day, but PR review times spiked 91%. More output, more scrutiny per piece. The cognitive cost didn't disappear; it moved from the writer to the reviewer.

This is why "almost right" is so expensive. Obviously wrong code triggers instant rejection. Almost-right code forces you to hold the correct implementation in your head while scanning for deviations. That's sustained, focused attention against plausible-looking output. It's the hardest kind of thinking to sustain, and it's what fills my afternoons now.

***

### Bainbridge called it in 1983

In 1983, Lisanne Bainbridge published a five-page paper called "Ironies of Automation" that reads like a prophecy. She was writing about process control and flight-deck automation, but the ironies she identified map onto AI-assisted development with uncomfortable precision.

The first irony is about monitoring. Bainbridge cites Mackworth (1950): it is impossible for even a highly motivated human to maintain effective attention "towards a source of information on which very little happens, for more than about half an hour." AI code that's correct 80% of the time means the reviewer must maintain focused attention through long stretches of valid output to catch the 20%. The paper is clear: this is unsustainable by design, not by lack of discipline.

The second is about skill decay. "Physical skills deteriorate when they are not used," she writes, and an experienced operator who has been monitoring automation "may now be an inexperienced one" if asked to take over manually. When developers stop writing code from scratch, the same thing happens: the deep familiarity needed to evaluate AI-generated code erodes through disuse.

The third is about the next generation. The "present generation of automated systems," Bainbridge warns, "are riding on [operators'] skills, which later generations of operators cannot be expected to have." Today's AI supervisors built their expertise in pre-AI environments. Tomorrow's developers won't have that foundation.

Uwe Friedrichsen applied Bainbridge directly to LLMs in 2025, noting that LLMs cannot achieve error-free operation by design, making the "human in the loop" monitoring pattern exactly the scenario Bainbridge proved was flawed. The aviation parallel is stark: Air France 447 crashed in 2009 when ice blocked the pitot tubes and the autopilot disengaged. The BEA investigation found that the pilots, startled and disoriented, were unable to diagnose the situation and recover manually. Air France's own internal review had already flagged "a generalized loss of common sense and general flying knowledge" among its long-haul pilots. The skills had atrophied through years of automated flight, and they were needed in the one moment automation couldn't help.

We're not crashing airplanes in software. But the pattern is the same: automation doesn't eliminate the need for human skill, it makes that skill harder to maintain and more critical when it's needed.

***

### What I actually do about it

I don't have a clean framework for this. But I've noticed patterns in how I work that track with the research.

**When AI works well**: I'm in a domain I know deeply (Go, cloud infrastructure, systems I've built). I can evaluate output instantly because I already have the mental model. The AI accelerates execution within a structure I control. I challenge its suggestions, I know when it's wrong, I can weigh trade-offs.

**When AI hurts**: I'm learning something new. I caught myself doing exactly what the low-scoring group did in the Anthropic study: accepting outputs, moving fast, feeling productive, understanding nothing. The moment I noticed, I turned off the AI and read documentation instead. The friction was the point.

**TDD as a truth anchor**: I write tests before the AI touches anything. Not because I don't trust the AI (I don't, but that's not the main reason). Because the tests encode *my* understanding of what the code should do. When the AI generates an implementation, the tests tell me whether it matches my intent, not whether it compiles or "looks right."

**Session discipline**: I don't let AI sessions run indefinitely. Context degrades, the AI starts contradicting earlier decisions, and I start accepting worse output because I'm tired. Short sessions with clear objectives. If I can't articulate what I want in one sentence, I'm not ready to prompt.

**Knowing when to stop**: Some days the cognitive load of managing AI is higher than just writing the code myself. I've learned to recognize that moment and switch modes. It feels slower. It usually isn't.

***

### The effort transformed

Here's what I told Davide, and what I believe more strongly after digging into the research: AI didn't reduce my cognitive effort. It transformed it. The typing got easier. The thinking got harder. And the thinking is the part that matters.

The teams that will do well with AI aren't the ones generating the most code. They're the ones that recognize the shift and manage it deliberately. That means being honest about the days when the AI is costing more than it saves.

The permanent Architect mode isn't a feature of AI-assisted development. It's a cost. It's real, it compounds, and pretending it doesn't exist is how you end up with teams that feel productive while their understanding erodes underneath them.

***

### Methodology note

This article was written with AI assistance (Claude Code for research gathering and drafting, with manual editing throughout). The irony of using AI to write about AI's cognitive costs is not lost on me. For what it's worth, the evaluation load of reviewing this draft was significant.

### Sources

- [METR: Measuring the Impact of AI on Experienced OS Developer Productivity](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/) (Jul 2025)
- [Stack Overflow 2025 Developer Survey](https://stackoverflow.blog/2025/12/29/developers-remain-willing-but-reluctant-to-use-ai-the-2025-developer-survey-results-are-here/) (Dec 2025)
- [GitClear: AI Copilot Code Quality 2025](https://www.gitclear.com/ai_assistant_code_quality_2025_research) (Feb 2025)
- [Faros AI: Developer Productivity Report](https://faros.ai) (Jul 2025)
- [Gerlich, M. - AI Tools in Society: Impacts on Cognitive Offloading and Critical Thinking](https://www.mdpi.com/2075-4698/15/1/6) (MDPI Societies, 2025)
- [Bainbridge, L. - Ironies of Automation](https://ckrybus.com/static/papers/Bainbridge_1983_Automatica.pdf) (1983)
- [Friedrichsen, U. - AI and the Ironies of Automation](https://www.ufried.com/blog/ironies_of_ai_1/) (2025)
- [Frontiers in Cognition: Understanding Vigilance and Its Decrement](https://www.frontiersin.org/journals/cognition/articles/10.3389/fcogn.2025.1617561/full) (2025)
