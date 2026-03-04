---
title: "Measuring Software Performance: What Changed in 3 Years?"
date: 2026-01-01
summary: "From the SPACE Era to the AI & DevEx Revolution: a necessary update."
tags: ["engineering", "productivity", "ai", "metrics"]
draft: false
cover:
  image: "images/cover-performance-3years.png"
  alt: "Measuring Software Performance: What Changed in 3 Years?"
  relative: false
---

![](https://cdn-images-1.medium.com/max/1600/1*ev7Jfe14WsdW_g3FX_tMjw.jpeg)

Three years ago, in January 2023, I published an article titled [_"Measuring and Improving Performance in Software Development."_]({{< ref "2023-01-09-measuring-and-improving-performance-in-software-development" >}}) At the time, I analyzed the difficulty of defining productivity, citing frameworks like SPACE and exploring the link between developer satisfaction and performance.

Re-reading that analysis today, I realize that three years in our industry is a geological era. When I wrote that piece, ChatGPT had just been released to the public, GitHub Copilot was in its infancy, and the concept of _Developer Experience_ (DevEx) was still a niche topic compared to pure DevOps metrics.

The fundamental question remains the same: _"How can we know if a team is working effectively?"_ However, the answers have changed drastically. The famous quote by Kaplan and Norton, _"what gets measured, gets managed"_¹, still holds true, but _what_ we measure, and **how we build**, has had to evolve.

Here is what scientific research and my recent return to the trenches at **Wishew** tell us today, at the end of 2025.

***

### 1. From SPACE to DevEx: psychology becomes a metric

In my previous article, I discussed the **SPACE** framework as a baseline for holistic measurement. While SPACE remains valid for categorization, recent research, led again by figures like Abi Noda, Nicole Forsgren, and Margaret-Anne Storey, has taken a step toward actionability with the **DevEx** framework.

Today we know that merely measuring activity is insufficient. A landmark paper published in _ACM Queue_² demonstrated that productivity is driven by three fundamental psychological dimensions experienced by the developer:

1. **Feedback Loops:** It's not enough to know "how much code we write," but how quickly the system responds. Waiting 20 minutes for a build interrupts rhythm far more than the simple minutes lost suggest.
2. **Cognitive Load:** The complexity of modern tools and architectures drains mental energy. If three years ago I spoke of "reducing waste," today the priority is "simplifying interaction."
3. **Flow State:** The ability to work with deep concentration. This is where complex problem-solving happens, not during multitasking.

Measuring these dimensions (often through specific surveys) has proven more predictive of future performance than simply counting closed tickets.

***

### 2. Output vs. driver metrics: knowing where to look

Before getting into AI and tooling, it's worth clarifying a distinction that has matured significantly since 2023. In my original article, I emphasized that "no single metric exists." Today, mature organizations make a sharp distinction between two types of measurement:

**Output Metrics (DORA)**: _Deployment Frequency, Lead Time for Changes, Change Failure Rate, Mean Time to Recovery._ These tell us _if_ we are moving fast and reliably. They are "lagging" indicators: they describe what already happened.

**Driver Metrics (DevEx)**: Measuring developer perception regarding friction, flow, and cognitive load. These are "leading" indicators: they predict where problems will emerge.

Here's the key insight: if your team releases frequently with low failure rates (good DORA) but developers report constant interruptions and frustrating tools (poor DevEx), you're heading for a wall. The pipeline looks healthy, but the people feeding it are burning out.

Three years ago, we spoke of "developer happiness" as a nice-to-have. Today, we have the data to quantify it as an economic driver, and the DevEx framework gives us the vocabulary to act on it.

**A confession:** at Wishew, we haven't implemented formal measurement yet. We're a small startup, and like many early-stage teams, we've been focused on building rather than measuring. But writing this article has convinced me that now is exactly the right time to lay the foundation, before we scale and bad habits become invisible. DORA metrics are on our near-term roadmap, starting with the basics: deployment frequency and lead time. Sometimes articulating what you _should_ do is the first step toward actually doing it.

***

### 3. The elephant in the room: the AI paradox

The great absentee of my 2023 article was Generative AI. Today, it is impossible to ignore. Early studies suggested that AI assistants (like Copilot) could increase task completion speed by up to 55%. However, by late 2025, the data tells a more nuanced story.

We are facing an **"AI Productivity Paradox."**

The **2025 State of DevOps Report (DORA)** highlights a critical issue: while AI adoption is near 90%, roughly one-third of developers do not trust the generated code³. This leads to inflated output metrics but potential bottlenecks downstream.

Furthermore, a study by **METR (July 2025)** revealed that in complex software engineering tasks, experienced developers using AI sometimes took **19% longer** than those without it⁴. Why? Because the time saved on _typing_ was lost on _reviewing_, debugging subtle hallucinations, and wrestling with context.

But here's the most troubling finding: **participants believed they were 20% faster**, even while being 19% slower⁴. This "Perception Gap" is the smoking gun that explains why DevEx surveys alone can be misleading if not cross-referenced with actual data. The AI reduces the _effort_ of typing (which makes us _feel_ productive), but shifts the burden to verification (which our brain doesn't perceive as "active work," even though it consumes more time). The sensation of "Flow" induced by AI-assisted coding can be an illusion.

This also explains the **"Code Churn"** phenomenon observed in parallel research⁷: an increase in copy-pasted code and a decrease in refactoring. AI makes it easy to _generate_ code, but hard to _integrate_ it well.

In the AI era, productivity has shifted from **writing speed** to **validation speed**.

#### Our counter-measures

At Wishew, we tackled the validation problem by flipping the script: instead of relying solely on AI to _write_ code, we built AI into our **review** process. We integrated a [Gemini-powered code reviewer]({{< ref "2025-10-18-from-rubber-ducks-to-gemini-ai-powered-code-reviews-in-gitlab-ci" >}}) that runs automatically on every Merge Request, catching issues before any human sees the code.

But automated review solves only half the problem. The other half, ensuring AI _generates_ the right code in the first place, required teaching the AI our patterns through what I call [Modular Skills]({{< ref "2025-11-09-from-asking-claude-to-code-to-teaching-claude-our-patterns-building-modular-ai-skills" >}}): reusable markdown files that codify our engineering standards.

The key insight is **Context Curation**: treating the context provided to the AI as code, versioned, reviewed, and standardized. Instead of hoping for the "magic" of the model, we define exactly _how_ we work: parameterized queries only, strict dependency injection, table-driven tests in separate files.

Today, there are many excellent repositories with pre-built Skills better than mine. I encourage you to explore what's out there and find what fits your workflow, or build your own as I did. I still use my own Skills because they've evolved to fit my specific needs perfectly, but I continuously draw inspiration from others' work. The approach matters more than any specific implementation.

Combined with the Gemini reviewer in CI, we now have a two-layer system: **Claude generates code using our patterns; Gemini validates it against our standards.** Generation and validation, each handled by the tool best suited for the job.

***

### 4. The antidote to cognitive overload: Platform Engineering

If "Cognitive Load" is the disease affecting modern developers, **Platform Engineering** is the cure.

Three years ago, the mantra "You build it, you run it" was often interpreted as forcing developers to manage everything. In 2025, we know this approach leads to "Shadow Operations," with developers spending up to 30% of their time fighting infrastructure instead of building features⁵.

Platform Engineering shifts the paradigm. It treats internal infrastructure as a **Product**, an Internal Developer Platform (IDP), that offers "Golden Paths": pre-approved, well-documented ways to accomplish common tasks. The goal is to reduce friction without reducing autonomy.

> **Platform Engineering isn't just cloud infrastructure: it's also knowledge infrastructure for AI.**

Our Skill files are "Golden Paths" for AI interactions, applying the same principles of standardization and friction reduction to how we prompt our tools.

#### From theory to practice

After 25 years in tech as CTO and Tech Lead, I returned to my roots as an Individual Contributor at Wishew. And because I believe in what I'm writing here, I've been putting it into practice. Two concrete examples:

**[The Smart ECS Notifier]({{< ref "2025-10-03-building-a-smart-ecs-deployment-notifier-with-aws-lambda-gitlab-and-slack" >}})**: Instead of forcing developers to check deployment status manually, we built automated Slack notifications with smart filtering. The key wasn't automation itself, but _curation_: stripping noise to deliver only actionable context.

**[ClickLab]({{< ref "2025-11-30-from-skills-to-shipping-building-with-claude-as-a-pair-programmer" >}})**: Every time a developer opens ClickUp, copies a task ID, switches to the terminal, and creates a branch manually, their **Flow State** breaks. We replaced a third-party integration with our own Lambda that creates branches automatically when tasks move to "In Progress". It doesn't just save 30 seconds of typing: it saves 15 minutes of "context recovery."

Every branch created automatically is a context switch saved. Every status synced is a manual update avoided. Small wins, compounding daily.

***

### 5. Bringing it together: a measurement philosophy for 2025

Looking back at my 2023 article, I see a version of myself searching for a measurement methodology. When DevEx was published, I realized the work I wanted to do had already been done, and done well. Since 2023, my focus has been on Infrastructure and Cybersecurity, so I haven't yet had the chance to experiment with these frameworks on a team. But now, in a fast-moving startup, I finally have that opportunity.

Today, my philosophy is simpler, though I'll admit it's partly aspirational:

1. **Measure what predicts, not just what happened.** DORA metrics tell you the past. DevEx metrics tell you the future. Track both. _(We're starting with DORA basics at Wishew, deployment frequency and lead time, because you have to start somewhere.)_
2. **Treat AI as two tools, not one.** Use generative AI for creation (with Skills to guide it). Use AI reviewers for validation (in CI, before humans). Don't expect one model to do both well.
3. **Invest in removing friction, not adding features.** Every hour spent on Platform Engineering pays dividends across every developer, every day.
4. **Codify your patterns.** Institutional knowledge that lives only in people's heads is lost every time someone leaves, or every time you start a new AI session. Write it down. Make it executable.
5. **Start before you think you're ready.** The best time to build measurement foundations is when you're small enough to change easily, not when you're big enough to "need" them. Technical debt in metrics is just as real as technical debt in code.

***

### Conclusion: continuous update

If there is one thing I have learned in these three years, it is that performance measurement is not a one-time project, but a continuous listening process.

Tools and metrics change, but the goal remains: creating an environment where developers can do their best work without unnecessary friction.

I've measured developer performance before, but in organizations that treated developers like factory workers: chargeability rates, billable hours, tickets closed per sprint. That approach optimizes for the wrong thing. It assumes productivity is linear and continuous, when in reality creative work, and software development _is_ creative work, delivers value in bursts. A developer might spend three days "unproductive" by those metrics, wrestling with a problem, only to produce a solution on day four that saves the company months of technical debt.

What I want to build at Wishew is different: measurement as a tool for _helping_ developers work better, not for squeezing more hours out of them. Metrics that expose friction in our processes, not metrics that expose "underperformers." The goal is to fix the system, not to blame the people inside it.

If you want to read more on these topics, I recommend the _Engineering Enablement_ newsletter by Abi Noda. For a practical starting point on AI-assisted development, check out our open-source [**claude-forge**](https://github.com/maroffo/claude-forge) repository.

And if you want to see these principles in action, or help us refine them, feel free to reach out. We're actively tackling these challenges at Wishew, and we're always interested in talking to like-minded engineers.

***

### References

* \[1] R. S. Kaplan and D. P. Norton, 'The Balanced Scorecard: Measures that Drive Performance', _Harvard Business Review_, 1992.
* \[2] M. Greiler, A. Noda, and M.-A. Storey, 'DevEx: What Actually Drives Developer Productivity', _ACM Queue_, vol. 21, no. 2, 2023.
* \[3] Google Cloud, '2025 State of DevOps Report: AI-assisted Software Development', _DORA Research_, Sep. 2025.
* \[4] METR Research, 'Measuring the Impact of Early-2025 AI on Experienced Developer Productivity', _METR Technical Report_, Jul. 2025.
* \[5] Puppet, 'State of Platform Engineering 2024', _Puppet by Perforce_, 2024.
* \[6] Gartner, 'Top Strategic Trends in Software Engineering for 2025', _Gartner Research_, Jul. 2025.
* \[7] GitClear, 'Coding on Copilot: 2024 Data Suggests Downward Pressure on Code Quality', _GitClear Research Report_, 2024.
