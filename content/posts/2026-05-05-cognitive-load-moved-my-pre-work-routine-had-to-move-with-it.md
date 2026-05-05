---
title: "Cognitive Load Moved. My Pre-Work Routine Had to Move With It."
date: 2026-05-05
summary: "Three weeks ago I argued AI moved cognitive load instead of reducing it. If the load moved, what changes about how you set up the day? A decade of replication points to a five-minute habit, and a clearer picture of when it doesn't help."
tags: ["ai", "engineering", "cognitive-load", "habits"]
draft: false
cover:
  image: "images/cover-pre-work-walk.png"
  alt: "Cognitive Load Moved. My Pre-Work Routine Had to Move With It."
  relative: false
---

Three weeks ago I [wrote about how AI didn't reduce my cognitive load](/blog/posts/2026-03-06-ai-didnt-reduce-my-cognitive-load-it-moved-it/), it moved it. The typing got easier. The thinking got harder. The afternoons fill up with evaluation, architectural judgment, holding a correct mental model in place while scanning AI output for *almost right* deviations.

What I didn't write about: the part of the day when that work goes well, and the part when it doesn't.

The pattern was hard to miss once I started paying attention. On the mornings I sat down and opened Claude Code immediately, the cognitive drag hit by mid-morning. On the mornings I walked first, even five minutes around the building, the architecture calls were sharper, the prompts were better-framed, and the afternoon left me less wrecked. There was also a smaller pattern at the desk itself: stepping away from the standing desk for two or three lengths of the corridor, then coming back, was enough to reset something when I felt my filter degrading.

I treated it as placebo for a long time. Then I went looking, and the literature turned out to be more specific than I expected, and also more limited than the popular write-ups suggest.

---

### Two phases, two cognitive modes[#](#two-phases-two-cognitive-modes)

Before talking about walking, I need to be specific about what the hard part of an AI-assisted day actually demands, because it isn't one thing.

Cognitive psychology splits creative thinking into two modes.

**Divergent thinking**: generating multiple, novel solutions, breaking out of conventional categories, holding many possibilities in tension. The standard measure is Guilford's Alternate Uses Test, how many unconventional uses can you think of for a brick. Scoring combines fluency (how many ideas), flexibility (how many distinct categories), and originality (how rare).

**Convergent thinking**: narrowing down to the single correct answer. The standard measure is the Remote Associates Test, find the one word that connects "time", "hair", "stretch" (answer: long).

In a typical AI-assisted day, both modes show up, in two distinct phases.

**Phase 1, generative.** Choosing an architecture, framing the problem, deciding which alternative is worth pursuing, writing the prompt that kicks off a Claude Code session. The work rewards broad associative reach and the ability to hold multiple framings in parallel before committing. It is divergent work.

**Phase 2, evaluative.** Reading what the AI produced and comparing it against an internal model of what it should have done. Catching the *almost right* deviation buried in line 47 of a 200-line diff, deciding whether to accept, reject, or rewrite. This is the opposite of broad associative reach. It is narrow, focused, sustained attention against plausible-looking output, and it maps closer to convergent or critical evaluation than to divergent thinking.

I conflated these two phases for a long time, and most posts about "AI cognitive load" still do. The fatigue is real but it is not one thing, and the interventions that help the generative half don't carry over to the evaluative half. One of them, as it turns out, may even make it worse.

That is what makes walking interesting as an intervention, and also what limits it.

---

### What the literature actually says (and doesn't)[#](#what-the-literature-actually-says-and-doesnt)

The starting point is Oppezzo and Schwartz 2014 at Stanford GSE. Four experiments, 176 participants, creative thinking tasks while sitting and while walking. The headline result is the asymmetry between modes: 81% of participants improved on Guilford's Alternate Uses test (the divergent-thinking measure) when walking, while only 23% improved on the Compound Remote Associates test (the convergent measure). Walking didn't lift creative output across the board, it lifted one mode and left the other roughly alone.

That specific asymmetry is what brought me back to a literature I had filed under "lifestyle content". The studies aren't claiming walking makes people sharper at everything. They are claiming it helps the cognitive mode I now spend my Phase 1 in, and roughly nothing for the mode AI already handles.

The follow-on literature is smaller than the popular write-ups make it sound, but it exists.

The 2022 multilevel meta-analysis by Rominger and colleagues pooled 28 studies (1,624 participants, 115 effect sizes) on acute physical activity and creative ideation. The aggregated effect on divergent thinking came out at Hedges' *g* = 0.47, in the medium range. Activity type moderated the effect, and convergent thinking was not the meta-analysis' focus, though the underlying literature doesn't show the same magnitude there.

Also in 2022, Murali and Händel at Würzburg ran the experiment that matters most for the mechanism. They compared free walking against restricted walking (a fixed back-and-forth path), and free sitting against a fixated-gaze sitting condition. Free walking produced the strongest divergent-thinking improvement, and the restriction effect held inside the walking condition: constrained walking did less than free walking. The eye-blink data they collected differed across conditions but did not correlate with task performance, so the "broadened internally-directed attention" reading is suggestive at best, not established. The cleaner interpretation is the behavioural one: lack of motor restriction matters, not raw cardiovascular load.

Chen's 2024 narrative review in *Discover Psychology* organized the field by activity type and intensity (21 studies, 24 experiments). The most consistent positive signal came from natural, unstructured walking; low-intensity structured exercise tended toward null results, and higher-intensity structured exercise was mixed. A narrative review is not a meta-analysis, so I take this as direction-of-evidence rather than effect size.

The most relevant paper for daily use is Rominger 2024 in *American Psychologist*. They put accelerometers on 157 young adults and combined step counts with ecological momentary assessment to track creative ideation in everyday life, not in a lab. Both acute step-count bouts and habitual step-count patterns predicted higher originality on verbal divergent-thinking tasks. The framing I want to keep from this paper is that acute and chronic effects appear to compound, not that this is the first ambulatory study of creativity, because it isn't.

The honest summary is about a decade of converging but modest evidence, almost all of it on healthy young adults using verbal divergent-thinking tasks, with effect sizes clustering around *g* = 0.4. The finding has replicated, but the slice of behaviour it covers is narrow.

---

### The mechanism (best current guess)[#](#the-mechanism-best-current-guess)

Why would walking specifically help divergent thinking, and why specifically *free* walking?

The most cited account is Zhou, Hommel and colleagues 2017, the "control-depletion" framing. Divergent thinking benefits from a loosening of top-down executive control, which is what cognitive flexibility requires. The more an activity competes for control resources, the more flexible the residual control style becomes, and the better divergent-thinking tasks unfold. Their experiments tested standing, predetermined-pattern walking, and free walking; free walking produced the strongest performance, predetermined-pattern walking did less, standing alone did less still.

Murali and Händel's free-versus-restricted result fits this picture: a fixed path forces a small amount of monitoring (am I about to turn?), and that monitoring draws back exactly the executive control the divergent task wanted to lose. A free walk asks for none.

The two accounts converge on the same prediction: what helps divergent thinking is not cardiovascular load or "more blood to the brain", it is having executive control occupied by something undemanding so attention can broaden.

The implication for Phase 2 is uncomfortable. If broadening attention and loosening control is what helps Phase 1, then the same intervention should hurt Phase 2, where the work is sustained, narrow, focused attention against plausible-looking output. The literature is consistent with this: walking does roughly nothing for convergent-thinking measures, and could plausibly hurt the kind of vigilance that catches *almost right*. So this is not a generic "walking makes AI work better" claim. It is a specific intervention, for one of the two phases, before specific kinds of work.

---

### What I actually do[#](#what-i-actually-do)

Two distinct interventions, one for each phase. The first is supported by the literature above. The second is what I observe in my own week and label more cautiously.

**Phase 1: a free walk before the generative work.**

Five to ten minutes, before opening any AI tool. Not a treadmill, not a timed loop, not while reading on a phone. Out the door, around a block, into a corridor if it's raining, with no destination and no pace target. The point is to move without thinking about how you're moving; if I find myself checking my watch, I'm doing it wrong.

I try to sit down to the work within ten minutes of returning. Oppezzo's residual-boost data is the reason: people who sat after walking still outscored people who never walked, but the effect isn't all-day, so the earlier the better. The work that benefits is the generative half (architecture decisions, problem framing, ADR drafting, the prompt that kicks off a long Claude Code session), not the kind of day where I'm implementing against a frozen spec or working a known bug.

One practical detail: I resist the temptation to start the Claude Code session on the walk via voice. The walk is supposed to broaden attention; prompting an LLM does the opposite, and running both at once cancels the benefit.

**Phase 2: micro-walks at the desk, for vigilance recovery.**

This one I label more cautiously, because the divergent-thinking literature does not predict it and may even predict the opposite. The pattern in my own week is consistent, but I'm describing observation, not evidence.

The signal I've learned to recognise: I'm at the standing desk, halfway through a long Claude Code diff, and somewhere around the 20-minute mark my filter starts to slip. The acceptances come faster than the scrutiny, and the suggestions begin to look better than they actually are. The mistakes I'd catch fresh slide past. When I notice it I step away from the desk and walk two or three lengths of the office corridor, maybe two minutes. Then I come back, restart the diff from the top of the section I was on, and the second pass tends to pick up what the first one missed.

This is not the same intervention as the morning walk. It is shorter, it is at the desk, and the literature it most resembles is on vigilance and attention restoration, not divergent thinking. The 1950 Mackworth result I cited in the predecessor post is the anchor: sustained focused attention degrades within roughly half an hour, and brief breaks help reset it. Take this as a habit I run because it tracks with what I observe, not as something the divergent-thinking studies vouch for.

**The chronic and acute effects compound.**

The Rominger 2024 ecological data is the part of the literature I found most useful. Both the acute effect (walking before a creative task) and the chronic effect (walking regularly) predict higher originality, and they appear to add. A daily five-minute pre-work walk is not a one-shot intervention; it's also a deposit into a baseline that the next morning's walk draws on. Skipping for a week probably costs more than the missed five minutes.

---

### When this fails[#](#when-this-fails)

A few cases where this routine doesn't help, or hurts.

If the day is purely convergent work, debugging a known issue or implementing against a frozen spec, the morning walk costs a context switch I didn't need. The matched intervention is sleep, caffeine, and the corridor break, not a five-minute attention-broadening session.

If I'm already in flow when I arrive at the desk, I don't break it. The routine matters before the hard part starts, not in the middle of it.

On a day after bad sleep the walk doesn't compensate. The acute effect in the literature stacks on top of habitual activity and a normal baseline, and none of those layers substitute for the others.

And the effect size is what it is: a meta-analytic *g* around 0.4 on divergent-thinking tasks in healthy young adults. That is a real effect, not a transformative one. There are null results in the broader exercise-and-cognition literature, and the file-drawer concern that applies to any small-effect field applies here too. Walking moves the dial on Phase 1; it does not turn anyone into a different engineer, and it does not fix Phase 2.

---

### Closing[#](#closing)

Three weeks ago I argued that AI moved cognitive load rather than reducing it. The follow-up question was: if the load moved, what changes about how I set up the day?

Most of the "AI productivity" advice I see online keeps optimising the part that's already optimised: more tools and orchestration around the convergent work AI already handles well. The part that got harder is the thinking. And the thinking, once you actually look at it, splits into two phases that don't respond to the same intervention. For the generative half, the morning walk has about a decade of converging evidence behind it at a modest effect size. For the evaluative half, walking is probably the wrong tool, and what I use instead is a two-minute corridor break, on much weaker grounds.

Neither one is a transformative habit. They are smaller and more specific than the version of this story I'd expect to read on LinkedIn, which is roughly why I trust them.

---

### Sources[#](#sources)

* Oppezzo, M., & Schwartz, D. L. (2014). Give your ideas some legs: The positive effect of walking on creative thinking. *Journal of Experimental Psychology: Learning, Memory, and Cognition*, 40(4), 1142–1152. [PDF](https://www.apa.org/pubs/journals/releases/xlm-a0036577.pdf)
* Rominger, C., Schneider, M., Fink, A., Tran, U. S., Perchtold-Stefan, C. M., & Schwerdtfeger, A. R. (2022). Acute and chronic physical activity increases creative ideation performance: A systematic review and multilevel meta-analysis. *Sports Medicine - Open*, 8(62). [Open access](https://sportsmedicine-open.springeropen.com/articles/10.1186/s40798-022-00444-9)
* Murali, S., & Händel, B. (2022). Motor restrictions impair divergent thinking during walking and during sitting. *Psychological Research*, 86, 2144–2157. [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC8742166/)
* Chen, C. (2024). Exploring the impact of acute physical activity on creative thinking: A comprehensive narrative review with a focus on activity type and intensity. *Discover Psychology*, 4(3). [Open access](https://link.springer.com/article/10.1007/s44202-024-00114-9)
* Rominger, C., Fink, A., Weber, B., Benedek, M., Perchtold-Stefan, C. M., & Schwerdtfeger, A. R. (2024). Step-by-step to more creativity: The number of steps in everyday life is related to creative ideation performance. *American Psychologist*, 79(6), 863–875. [Reference](https://psycnet.apa.org/record/2024-26043-001)
* Zhou, Y., Zhang, Y., Hommel, B., & Zhang, H. (2017). The impact of bodily states on divergent thinking: Evidence for a control-depletion account. *Frontiers in Psychology*, 8, 1546. [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5626876/)
