---
title: "The Word 'Permanent' Isn't in the Paper"
date: 2026-05-07
summary: "A viral tweet says ChatGPT permanently damaged your creativity. It cites two real studies. Neither paper says that. A close reading of what got dropped between the abstracts and the post."
tags: ["ai", "llm", "science", "opinion", "cognitive-load"]
draft: false
cover:
  image: "images/cover-permanent-isnt-in-the-paper.png"
  alt: "The Word 'Permanent' Isn't in the Paper"
  relative: false
---

A tweet showed up in my feed this week. It was a repost by Cher Scarlett of a post by someone called Elara Grace, with the kind of opener that tells you exactly what you're about to read:

> Just IN: If you've used ChatGPT for writing or brainstorming in the last 6 months, your creative ability may already be permanently damaged. A controlled experiment just proved the effect doesn't reverse when you stop using it. 3,302 creative ideas. 61 people. 30 days of tracking.

The thread went on for a while, with the kicker: "You're not renting a productivity boost. You're financing it with your originality. The interest rate is permanent."

My first reaction was the one-word kind. The second reaction, after I noticed the specific numbers, was that the tweet was citing real studies. Dismissing it as bullshit isn't enough then. The numbers exist. The papers exist. The question worth asking is what got dropped between the abstracts and the post.

***

### What the first paper actually says

The 3,302 ideas and 61 people come from Liu, Zhou, Huang, and Li, *When ChatGPT is gone: Creativity reverts and homogeneity persists*. It's on arXiv as 2401.06816, with an extended version in *Technology in Society* in 2025. It's a real paper. The numbers are real. Here is the abstract verbatim, because the verbatim version is where the rhetorical move starts:

> [...] human creative performance reverted to baseline when ChatGPT was down on the 7th and the 30th day. More critically, the use of ChatGPT in creative tasks resulted in increasingly homogenized contents, and this homogenization effect persisted even when ChatGPT was absence.

Three things are worth pointing out, and the tweet hides all three.

**One: "reverts to baseline" is not "drops below baseline."** The abstract is precise. Performance returns to where it was before. The tweet implies a worsening that the paper does not document. "Permanently damaged" is a statement about creative capability falling below pre-treatment level. The paper measures the opposite: that the *boost* from ChatGPT does not persist when ChatGPT goes away. Subtract the boost, you get the original creative performance back. That is not damage. That is the boost being a rental rather than a purchase. The tweet's framing inverts the measurement.

**Two: the word "permanent" does not appear in the abstract, and the maximum follow-up is 30 days.** I checked. The closest the paper comes to a long-run claim is the phrase "boxes human creative capability in the long run", which is the authors' interpretation of the homogenization persistence, not of any measurement past 30 days. There is no follow-up at six months, or twelve, or thirty. There is no sample large enough or design longitudinal enough to support the word "permanent". It is a word the tweet supplies. The paper does not.

I should be fair: the authors themselves stretch their phrasing past their measurements. "Boxes human creative capability in the long run" is interpretation, not data. The tweet didn't invent the apocalyptic register, it amplified one already there. That strengthens, rather than weakens, the point: 30 days of follow-up cannot license the word "permanent", whoever uses it.

**Three: the design.** Sixty-one college students at a single university, a seven-day lab experiment, a 30-day follow-up survey. The "dependency" the tweet describes is built in seven days of a lab task. This isn't a flaw of the study; lab experiments are how you isolate variables. It is a flaw to take a seven-day lab effect and frame it as a description of what is happening to anyone who has used ChatGPT in the last six months. The generalization is the tweet's, not the paper's.

Now, here is where I have to be careful, because there is one finding in the paper that is real and worth taking seriously, and I do not want to talk past it: **homogenization persists**. After people stop using ChatGPT, the *content* they produce remains more similar to the content other ChatGPT users produce than the control group's content was. The boost reverts; the homogenization sticks. That is a finding I respect. It says that exposure to a generative model trains a kind of stylistic and ideational gravity that doesn't fully release.

It is not the same finding as "your creative ability is permanently damaged." It is a finding about the *distribution* of ideas across people who used the tool, not about the individual's *capacity*. A homogenized population can still contain people whose individual creative output is unchanged or improved. The paper measures convergence between subjects, not loss within them.

If I were writing the tweet honestly, the sentence would be: "After a week of ChatGPT use, people's creative output becomes more similar to other ChatGPT users' output, and this convergence persists for at least 30 days after they stop using it." That would be accurate. It would also generate roughly zero retweets.

***

### What the second paper actually says

The "doesn't reverse when you stop using it" framing comes from the second study the tweet folds in: Barcaui (2025), *ChatGPT as a cognitive crutch: Evidence from a randomized controlled trial on knowledge retention*, in *Social Sciences & Humanities Open*. RCT, n = 120 enrolled, n = 85 at the surprise retention test 45 days later. Cohen's d = 0.68. The ChatGPT group scored 57.5% on the retention test, the traditional-study group scored 68.5%. t(83) = -3.19, p = .002.

This is also a real paper. The numbers are also real. The misuse is more subtle.

The Barcaui paper does not measure creativity. It measures **conceptual retention**: how much of what you studied is still in your head 45 days later. The tweet treats Barcaui's retention finding as evidence of a creativity finding from Liu et al. They are different measures, on different populations, with different mechanisms. Cognitive retention can decline through reduced effortful encoding (the "desirable difficulties" account from Bjork) without any implication for creative ideation. Mixing them lets the tweet extend Liu's 30-day window with Barcaui's 45-day window and call it "doesn't reverse." But the two are not measuring the same thing reverting or not reverting.

Generalizability matters here too. Barcaui's sample is business undergraduates at a Brazilian university, studying AI concepts as the subject matter. The d = 0.68 is on that population, learning that material, with that style of unrestricted ChatGPT use during study. Whether the effect transfers to other materials, populations, and styles of AI integration is an open question the paper does not claim to answer.

None of this discredits the study. It's a clean RCT and the effect size is meaningful. It just doesn't license the move from "students who used ChatGPT to study an AI course remembered 11 percentage points less six weeks later" to "your creative ability is permanently damaged".

***

### The rhetorical move

What the tweet does is the kind of move I keep running into in AI discourse, on both sides:

1. Take real numbers from Study A.
2. Take a different, plausible-sounding finding from Study B.
3. Glue them together with a connecting word that neither paper used.
4. Frame the synthesis as "controlled experiment proved X."

Liu et al.'s 30-day window (creativity reverts to baseline; homogeneity persists) gets the word "permanent" attached to it by transitively citing Barcaui's 45-day window (retention of unrelated material). The synthesis becomes "permanent damage" even though neither paper measures permanence and the two papers measure different things.

You can see the seams if you read the tweet carefully. "A controlled experiment just proved the effect doesn't reverse when you stop using it." Singular: a controlled experiment. The 3,302 ideas and 61 people are from Liu et al. But their 30-day measurement is the *reverting* part, not the *not reverting* part. The "doesn't reverse" framing has to be borrowed from somewhere else, and that somewhere else is the second study. Two studies, presented as one experiment. That's the move.

***

### The mechanism is real. The framing isn't.

I want to be specific about what I'm not claiming, because the easy mistake here is to overcorrect into AI apologia.

The underlying mechanism the tweet gestures at is documented. Bastani and colleagues (Wharton / Turkey, 2024, n ≈ 1,000 high schoolers) gave students access to two GPT variants while solving math problems. The "GPT Base" group scored 48% higher *with* AI access. When access was taken away for the exam, they scored 17% *worse* than the control group. Same students, opposite directions, same intervention. The kicker: a "GPT Tutor" variant designed with scaffolding to keep the student doing the cognitive work mitigated the loss almost entirely. Bastani is the cleanest demonstration I know that the *design of the AI interaction* is doing the work, not the presence or absence of AI.

Lee and colleagues (Microsoft Research / CMU, CHI '25, n = 319 knowledge workers) found the cognitive effort doesn't disappear, it shifts, with confidence in the AI predicting reduced critical evaluation. That tracks with what Bjork & Bjork have spent decades documenting under the heading "desirable difficulties": the effortful processes that produce durable learning are the ones you don't feel like doing in the moment. Skip them and you trade short-term ease for long-term retention. None of this is novel. Sparrow's Google-effect work goes back to 2011.

I've written about this twice already, in [*AI Didn't Reduce My Cognitive Load. It Moved It.*]({{< ref "2026-03-06-ai-didnt-reduce-my-cognitive-load-it-moved-it" >}}) and [*From Cognitive Load to Cognitive Surrender*]({{< ref "2026-03-23-from-cognitive-load-to-cognitive-surrender" >}}). The thesis I keep coming back to, and that I think the evidence supports, is that workflow is the variable that moves the outcome, not the tool. So this isn't a contrarian post about how AI is fine actually. It's a post about a tweet getting the framing wrong on top of papers I take seriously.

***

### Steel-manning the tweet

A fair reading of all this is that the tweet picked the wrong word, but the direction it points in has support. Homogenization in Liu et al. persists past 30 days. Retention drops in Barcaui at 45 days. Bastani's GPT Base group lost ground once scaffolding was removed. The Lancet endoscopist study I cited in the cognitive-surrender post showed measurable deskilling after three months of AI-assisted polyp detection. None of these prove permanence. A reader sympathetic to the original tweet can fairly say the trend line points where the author said it points.

My objection is to the specific word, not to the direction. The reason the specific word matters is that "permanent" is what makes the claim viral, and "permanent" is the part nobody measured. Strip that word out and you keep the direction the evidence actually supports, plus most of the alarm the situation actually merits. What you lose is the rhetorical fuel that gets the post to a million views. That's a feature of careful claims, not a bug.

***

### The other direction makes the same mistake

I owe the symmetry. The tweet's framing is bad, but the opposite framing (AI gives you a free productivity boost) makes the same kind of move in reverse, and the recent retraction record proves it.

The most cited meta-analysis on the positive side, Wang and Fan (2025, *Humanities and Social Sciences Communications*), reported g = 0.867 across 51 studies, a "large positive impact" on learning performance. It accumulated 486,000 views, 266 citations, and an Altmetric score over 1,000 before *Nature* **retracted it on April 22, 2026**, two weeks ago at the time I'm writing this. The retraction note cites discrepancies that "ultimately undermined the confidence the Editor could place in the validity of the analysis and resulting conclusions." Critics pointed to no quality assessment of included studies, no reporting of whether they were peer-reviewed or randomized, and 33 of 51 studies with fewer than 35 students in the experimental group.

So if you wanted to respond to the apocalyptic tweet by citing the big positive meta-analysis, that meta-analysis is no longer available to cite. The euphoric pole and the apocalyptic pole both made the same kind of move: take effects measured in narrow conditions, smooth over the methodological caveats, present the synthesis as a clean conclusion. Engagement on X likes clean conclusions.

There is a less-cited but methodologically tighter meta-analysis (35 studies, 4,193 participants, g = 0.670) finding a moderate positive effect on learning outcomes, with subject, duration, and instructional mode as significant moderators. It's the kind of finding that doesn't compress well into a 280-character claim. Which is the actual problem.

***

### The right question, briefly

I don't want to redo a thesis I've laid out in earlier posts, so this is a one-paragraph version. The question "is ChatGPT bad for learning, or for creativity?" is malformed. The empirically tractable question is which combinations of task, AI interaction design, and process phase produce which outcome. Bastani's GPT Base vs GPT Tutor split is the cleanest concrete instance: same students, same model, same problem set, opposite outcomes, depending on how the interaction was scaffolded. The tool plus the way the interaction is set up is what's doing the work. Strip out the design variable, and both polar narratives become incoherent.

This is also why both polar narratives feel so unsatisfying when you're actually using the thing. They erase the variable that matters.

***

### The irony

The tweet's central claim is that ChatGPT homogenizes its users' output: takes the variance in human ideas and compresses it toward the mean. Liu et al. actually document this, in a narrow sense, on a small sample. It's the part of the paper I take most seriously.

The tweet then takes two different studies, with different methods, populations, and outcome variables, and compresses them into a single clean apocalyptic claim suitable for X engagement. It produces a homogenized, high-fluency, low-information artifact aimed at the median reader's appetite for a confident verdict.

The mechanism the tweet attributes to AI is the mechanism the tweet itself uses. I don't think this is a coincidence. Both LLMs and engagement-optimized social media are systems that select for fluent, confident, conclusion-shaped outputs. They smooth out qualifications, they drop conditions, they keep the punchline. Reading the original papers is the part that doesn't compress. It's also the part that takes effort. Bjork has a name for that.

If a tweet says a controlled experiment proved your brain is permanently damaged, the move is to find the paper. Open the abstract. Look for the word "permanent." If it isn't there, the apocalypse is the tweet's, not the science's.

***

### Methodology note

This article was written with AI assistance (Claude Code for research synthesis, paper retrieval, and drafting; manual editing throughout). Verifying the abstracts directly, and cross-checking which words appear in which paper, was the part I would not delegate. The irony of using an AI to write a piece arguing against an AI-discourse pattern is not lost on me. It's also exactly what the post is about: the tool isn't doing the work. The way the interaction is scaffolded is.

### Sources

- Liu, Q., Zhou, Y., Huang, J., & Li, G. (2024). [When ChatGPT is gone: Creativity reverts and homogeneity persists](https://arxiv.org/abs/2401.06816). arXiv:2401.06816.
- Barcaui, A. (2025). [ChatGPT as a cognitive crutch: Evidence from a randomized controlled trial on knowledge retention](https://www.sciencedirect.com/science/article/pii/S2590291125010186). *Social Sciences & Humanities Open*, 12, 102287.
- Bastani, H., Bastani, O., Sungu, A., Ge, H., Kabakcı, Ö., & Mariman, R. (2025). [Generative AI without guardrails can harm learning: Evidence from high school mathematics](https://www.pnas.org/doi/10.1073/pnas.2422633122). *PNAS*, 122.
- Wang, J., & Fan, W. (2025). [The effect of ChatGPT on students' learning performance, learning perception, and higher-order thinking: insights from a meta-analysis](https://www.nature.com/articles/s41599-025-04787-y). *Humanities and Social Sciences Communications*. **Retracted 22 April 2026** ([retraction note](https://www.nature.com/articles/s41599-026-07310-z)).
- Lee, H. P. et al. (2025). [The Impact of Generative AI on Critical Thinking: Self-Reported Reductions in Cognitive Effort and Confidence Effects From a Survey of Knowledge Workers](https://www.microsoft.com/en-us/research/wp-content/uploads/2025/01/lee_2025_ai_critical_thinking_survey.pdf). *CHI '25*.
- Bjork, R. A., & Bjork, E. L. (2011). [Making things hard on yourself, but in a good way: Creating desirable difficulties to enhance learning](https://www.researchgate.net/publication/284097727_Making_things_hard_on_yourself_but_in_a_good_way_Creating_desirable_difficulties_to_enhance_learning). *Psychology and the Real World*.
- Sparrow, B., Liu, J., & Wegner, D. M. (2011). Google effects on memory: Cognitive consequences of having information at our fingertips. *Science*, 333(6043).
