---
title: "I Built an Italian Prison Monitor in 9 Days with AI. Here's What Broke."
date: 2026-02-06
summary: 'A personal project that started as "can I automate an RSS digest?" and became a full-stack monitoring platform with narrative memory, semantic search, and AI-generated editorial commentary.'
tags: ["ai", "python", "side-project", "claude-code"]
draft: false
cover:
  image: "images/cover-prison-monitor.png"
  alt: "I Built an Italian Prison Monitor in 9 Days with AI"
  relative: false
---

## Why prisons?

**The result:** 77 commits over 9 days (less than 10 hours of actual work). 11,000+ lines of Python. A production system at [behindbars.news](https://behindbars.news) that fetches articles about the Italian prison system, extracts structured data, tracks ongoing narratives, generates daily editorial bulletins, and sends weekly newsletters to subscribers. All with a two-person team: me and an AI.

I should clarify: the two-person team is me and Claude Code.

The Italian prison system is in a perpetual state of crisis. Overcrowding at 130%, a suicide rate that makes headlines every week, reform bills that stall in Parliament. The news coverage exists, scattered across dozens of sources, but nobody synthesizes it. Nobody tracks which stories are ongoing, which political figures changed positions, which deadlines are approaching.

I wanted to build that synthesis. And I wanted to see how far I could push AI-assisted development on a real, non-trivial project.

My previous articles covered pieces of this journey at Wishew: [modular AI skills](https://medium.com/@maroffo/from-asking-claude-to-code-to-teaching-claude-our-patterns-building-modular-ai-skills-83680a2e3708), [AI-powered code reviews](https://maroffo.medium.com/from-rubber-ducks-to-gemini-ai-powered-code-reviews-in-gitlab-ci-a1bc44309c21), [building with Claude as a pair programmer](https://medium.com/@maroffo/from-skills-to-shipping-building-with-claude-as-a-pair-programmer-d1ec11eb1c3c). BehindBarsPulse is the next chapter: a personal project where I applied everything I'd learned about AI collaboration, but with no team to fall back on. Just me, Claude Code, and a blank repository.

## From editorial problem to technical requirements

Before writing any code, I had to translate a journalistic problem into engineering constraints. The synthesis I wanted had three properties:

1. **Continuity**: don't just summarize today's news: remember what happened last week, which bills are pending, which politicians changed position
2. **Structure**: extract machine-readable data from prose (incident counts, facility names, dates) for trend analysis
3. **Editorial voice**: not a list of headlines, but commentary that cites sources by name and connects the dots

Each of these mapped to a technical subsystem: a narrative memory store, a structured event extraction pipeline, and a prompt engineering approach that produces synthesis, not summation. What started as three requirements became the architecture below.

## The architecture (or: how an RSS reader became a platform)

What I initially sketched on paper was simple:

```
RSS Feed → Fetch articles → Summarize with Gemini → Send email
```

What I shipped 9 days later (yes, days, not weeks):

```
RSS Feeds → Fetch/Extract → Enrich (Gemini) → Extract Stories/Characters/Events
                                                        ↓
                                              Narrative Context (JSON)
                                                        ↓
                                   PostgreSQL + pgvector (768-d embeddings)
                                                        ↓
   Generate Press Review (AI) → Generate Content (AI) → Review → Render → Send
                                                        ↓
                                   Daily Bulletin + Weekly Newsletter
                                                        ↓
                                   Web frontend: archive, search, statistics
```

This is what happens when you have an AI pair programmer that doesn't complain about scope creep.

<!-- TODO: Screenshot of behindbars.news homepage -->

### The core pipeline

The system runs on Cloud Scheduler (GCP), executing four main jobs:

| Job | Schedule | What it does |
|-----|----------|-------------|
| **Collect** | Every 30 min | Fetch RSS, enrich articles with AI, extract events, update narrative context |
| **Bulletin** | Daily 9:00 CET | Generate editorial bulletin from today's articles |
| **Newsletter** | Daily 9:00 CET | Generate and archive the full newsletter |
| **Weekly** | Sunday 10:00 CET | Send digest to subscribers via AWS SES |

Each job hits a FastAPI endpoint on Cloud Run. The interesting part is what happens inside.

## Gemini structured output: the foundation that makes everything work

Early in the project, I made a decision that shaped everything: use Gemini's `response_json_schema` for every AI call.

Instead of asking Gemini to "write a summary" and parsing free text, I define Pydantic models and pass their JSON schema:

```python
class EnrichedArticle(BaseModel):
    author: str | None
    source: str | None
    summary: str
    category: str
    importance: Literal["Alta", "Media", "Bassa"]
    published_date: date | None
```

```python
response = client.models.generate_content(
    model="gemini-3-flash-preview",
    contents=prompt,
    config=GenerateContentConfig(
        response_json_schema=EnrichedArticle.model_json_schema(),
        temperature=1.0,
    ),
)
enriched = EnrichedArticle.model_validate_json(response.text)
```

**Zero JSON parsing errors.** The model is constrained to produce valid JSON matching the schema. No regex extraction, no "please format as JSON", no retry-on-parse-failure. Just valid data, every time.

This pattern scales. The system uses it for seven different AI tasks: article enrichment, story extraction, entity extraction, follow-up detection, press review generation, newsletter content generation, and content review. Each has its own Pydantic model, each produces guaranteed-valid output.

## The narrative memory system

This is the feature that makes BehindBarsPulse more than an RSS aggregator.

Every day, when articles are collected, the AI doesn't just summarize them. It extracts three types of narrative elements:

**Story Threads**: Ongoing narratives being tracked. "Decreto Carceri 2025" first appeared in January, has been mentioned 23 times, and has an impact score of 0.92. The AI knows this story is still active.

**Key Characters**: Political figures and their evolving positions. Carlo Nordio (Minister of Justice) is tracked with timestamped stances extracted from articles. When he contradicts a previous position, the system knows.

**Follow-Ups**: Upcoming events and deadlines. "Senate vote on Decreto Carceri expected by February 15": the system tracks these and marks them resolved when they happen.

All of this lives in a JSON file (`narrative_context.json`) that gets loaded into every AI prompt:

```json
{
  "ongoing_storylines": [
    {
      "topic": "Decreto Carceri 2025",
      "status": "active",
      "first_seen": "2025-01-05",
      "last_update": "2026-02-05",
      "keywords": ["decreto", "riforma", "carceri"],
      "mention_count": 23,
      "impact_score": 0.92
    }
  ],
  "key_characters": [...],
  "pending_followups": [...]
}
```

When the AI generates tomorrow's bulletin, it knows what happened yesterday. It knows which stories are ongoing. It knows which political figures are relevant. This is what enables editorial commentary like:

> "Come sottolinea Damiano Aliprandi su Il Dubbio, il 2025 si chiude con un bilancio drammatico. Ma è la posizione di Carlo Nordio, che solo tre settimane fa parlava di 'riforme necessarie', a rendere il quadro paradossale."

<!-- TODO: Screenshot of a daily bulletin showing editorial commentary with source citations -->

The AI cites sources by name, references previous positions, and tracks narrative arcs. Not because it's inherently capable of remembering, but because we engineered a memory system that feeds it the right context.

## Batch inference: cutting costs by 50%

The collector makes N+5 Gemini API calls per run: one per article for enrichment, plus one each for stories, entities, follow-ups, events, and capacity data. With 15 articles, that's 20 API calls with 30-second rate limiting between them. Ten minutes per run. Expensive.

Vertex AI batch inference changes the equation:

```python
def build_collector_batch(self, articles, narrative_context):
    requests = []

    # N enrichment requests (1 per article)
    for article_id, article in articles.items():
        requests.append(self._build_request(
            custom_id=f"enrich_article_{article_id[:12]}",
            prompt=EXTRACT_INFO_PROMPT.format(article=article),
            schema=EnrichedArticle.model_json_schema(),
        ))

    # 5 extraction requests
    requests.append(self._build_request(
        custom_id="extract_stories_...",
        prompt=EXTRACT_STORIES_PROMPT.format(...),
        schema=StoriesResponse.model_json_schema(),
    ))
    # ... entities, followups, events, capacity

    return self._to_jsonl(requests)
```

All 20 requests go into a single JSONL file, uploaded to GCS, submitted as one Vertex AI batch job. Cost: ~50% less than synchronous calls. No rate limiting needed.

The result lands in GCS, which triggers a Cloud Function via Eventarc:

```
GCS upload (predictions.jsonl) → Eventarc → Cloud Function
  → Parse enrichment results → Save articles to DB with embeddings
  → Parse stories/entities/followups → Update narrative context
  → Parse events/capacity → Save to DB (deduplicated)
```

### The schema dereferencing problem

Here's something we didn't anticipate. Pydantic generates JSON schemas with `$ref` and `$defs` for nested models:

```json
{
  "properties": {
    "stories": {
      "items": { "$ref": "#/$defs/StoryThread" }
    }
  },
  "$defs": {
    "StoryThread": { ... }
  }
}
```

Vertex AI batch format doesn't support `$ref`. Every batch job failed silently until we built a `_dereference_schema()` function that inlines all references before submission. Small detail, significant debugging time.

## Semantic search with pgvector

Every article saved to the database gets a 768-dimension embedding vector generated by `gemini-embedding-001`. Editorial comments from bulletins and newsletters get embeddings too.

This enables semantic search: type "sovraffollamento carcerario" (prison overcrowding) and get results ranked by vector similarity, not keyword matching. Articles about "capienza al 130%" (130% capacity) surface even though they don't contain the search term.

<!-- TODO: Screenshot of semantic search results showing articles ranked by vector similarity -->

```sql
-- IVFFlat index for fast cosine similarity search
CREATE INDEX ix_articles_embedding ON articles
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);
```

### The embedding model deprecation incident

On February 6, search stopped working. No errors visible to users (the catch-all exception handler returned empty results silently). (A design choice I now regret.)

Cloud Run logs told the story:

```
404 NOT_FOUND. models/text-embedding-004 is not found for API version v1beta
```

Google had deprecated `text-embedding-004`. The fix: migrate to `gemini-embedding-001`, regenerate all 895 article embeddings and 14 editorial comment embeddings. We added an admin endpoint, temporarily disabled CPU throttling on Cloud Run (which was limiting background tasks to 7 seconds per embedding), and re-embedded everything in about 4 minutes.

**Lesson learned:** silent failures in search are worse than errors. Users see "no results" and assume their query was bad, not that the system is broken. I should have at least logged a warning in the UI.

## Prison event extraction and statistics

Beyond editorial content, the system extracts structured data from articles:

```python
class PrisonEvent(BaseModel):
    event_type: str      # suicide, self_harm, assault, protest, natural_death
    event_date: date | None
    facility: str | None
    region: str | None
    count: int | None
    description: str
    confidence: float
    is_aggregate: bool   # "80 suicides in 2025" vs. individual incidents
```

This powers a statistics dashboard at `/stats` with Chart.js visualizations: incidents by type, by region, by facility, monthly trends, capacity data.

<!-- TODO: Screenshot of /stats dashboard showing incident charts and facility ranking -->

### The deduplication challenge

Multiple sources report the same incident. "Suicide at Brescia prison" appears in three articles from three newspapers. Without deduplication, the statistics dashboard shows three suicides instead of one.

Two-level dedup:

1. **Ingestion**: Check for existing events with the same `(event_date, normalized_facility, event_type)` before saving
2. **Aggregate filtering**: Articles sometimes report aggregate statistics ("80 suicides in 2025"). These are marked `is_aggregate=True` and excluded from individual incident counts

### Facility name normalization

Italian prisons have inconsistent names across sources. "Brescia Canton Mombello", "Canton Mombello", "Brescia - Canton Mombello" all refer to the same facility.

An alias mapping normalizes them before aggregation:

```python
FACILITY_ALIASES = {
    "Canton Mombello (Brescia)": [
        "brescia canton mombello",
        "canton mombello",
        "brescia - canton mombello",
    ],
    # ... 50+ facilities
}
```

Small feature, but without it, the top-10-facilities ranking is meaningless.

## Building with Claude Code: what actually happened

Here's the honest account of working with AI on a project of this scale.

### The CLAUDE.md as system prompt

The project has a 300-line `CLAUDE.md` that is persistent context for every Claude Code session:

- Architecture overview and component map
- Configuration settings and their defaults
- Deployment workflow (Docker buildx → Cloud Run → migrate endpoint)
- Database migration strategy ("Migrations CANNOT be run locally against Cloud SQL")
- Admin endpoint documentation

This isn't documentation for humans. It's a system prompt for the AI. When I start a new session and say "add event deduplication to the collector", Claude already knows the table schema, the existing dedup patterns, and that it needs to generate an Alembic migration.

### The permissions registry

The `.claude/settings.local.json` file has 88 explicitly allowed permissions. Each one was added when Claude needed a new capability:

```json
{
  "permissions": {
    "allow": [
      "Bash(uv run pytest:*)",
      "Bash(gcloud run deploy:*)",
      "Bash(terraform apply:*)",
      "Bash(gcloud functions deploy:*)",
      "Bash(docker buildx build:*)",
      // ... 83 more
    ]
  }
}
```

This is a trust log. You can read the project's history through it: first came testing, then deployment, then Terraform, then Cloud Functions. Each new capability was delegated deliberately.

### The "asynchronous" workflow

The most surprising part was the rhythm. Because I was building this in my spare time, I often spent 20 minutes before bed describing a complex feature or a refactoring to Claude, then woke up to a working prototype or a set of passed tests. Having an AI pair programmer that "works" while you sleep changes your relationship with the codebase. You stop thinking about the effort of typing and start focusing on the clarity of your intent.

### What Claude did well

**Infrastructure as Code:** The Terraform modules (Cloud Run, Cloud SQL, Cloud Functions, Cloud Scheduler, networking, secrets) were all written with Claude. Modular, with clear variable interfaces. When I needed to add Eventarc triggers for batch processing, Claude proposed the architecture and implemented it.

**The boring stuff, fast:** Alembic migrations, CRUD endpoints, template rendering, CSS styling. Claude generates these in seconds. The FastAPI web frontend with 12 route modules, 20+ templates, and Chart.js dashboards was built in a few sessions.

**Debugging production issues:** "Search is broken" → Claude checks Cloud Run logs → finds the 404 for the deprecated embedding model → proposes fix → implements → tests → deploys. The full cycle, from bug report to production fix, took about an hour.

### What required human judgment

**Editorial prompt design:** The prompts that generate press reviews and bulletins required iteration. The AI's first attempts were too generic: "Article X reports Y, Article Z reports W." I wanted synthesis: "Come sottolinea Aliprandi su Il Dubbio..." Getting the right level of editorial voice took multiple rounds of manual tweaking.

**Architecture decisions:** When to add batch inference, how to structure the narrative memory, whether to use a database or stay file-based: these were human calls. Claude can implement any architecture, but choosing the right one requires understanding the problem domain.

**Scope control:** An AI pair programmer that never says "this is getting too complex" is dangerous. I had to actively resist feature creep. The narrative memory system alone could have been a project of its own. Keeping it as a JSON file instead of a graph database was a conscious simplicity choice.

## The meta aspect: AI building AI tools

There's something recursive about using Claude Code to build a system that uses Gemini to generate content. The development tool is AI. The product is AI-generated. The embeddings that power search are AI. The batch inference pipeline is AI.

At some point I stopped thinking of them as "AI tools" and started thinking of them as infrastructure. Gemini's structured output is just an API that returns typed data. The embedding model is just a function that maps text to vectors. Claude Code is just a pair programmer with excellent recall.

The magic isn't in any individual AI capability. It's in the composition: feeding narrative memory into editorial prompts, using embeddings for semantic search, triggering Cloud Functions from batch outputs. The AI components become building blocks, and the system design is what creates value.

## Key learnings

**1. Structured output changes everything**

Once you stop fighting JSON parsing and start treating AI as a typed API, the reliability equation changes. Schema validation at the model level means your downstream code can trust its inputs. This is the single decision that made the entire pipeline viable.

**2. Memory systems are the differentiator**

Any chatbot can summarize today's news. Tracking that Carlo Nordio contradicted himself from three weeks ago, that the Decreto Carceri has been mentioned 23 times, that a Senate vote is approaching; that's what makes the output editorial rather than aggregative. The narrative context file is 22KB of JSON. It's the most valuable file in the project.

**3. Silent failures are the worst kind**

The search feature broke and nobody noticed for days because exceptions were caught and empty results returned. In AI-powered features, where output quality varies, users can't distinguish "no results because your query is bad" from "no results because the system is broken." Surface errors early.

**4. AI pair programming scales to non-trivial projects**

77 commits in 9 days. 11,000+ lines. PostgreSQL, pgvector, Cloud Run, Cloud Functions, Terraform, Vertex AI batch, AWS SES, semantic search, editorial generation. This isn't a toy project. And the development pace was fast enough that I sometimes had to slow down to think about what I actually wanted.

**5. The human job is architecture and taste**

Claude writes the code. Gemini generates the content. But someone needs to decide that articles should be deduped by normalized facility name, that press reviews should cite sources by name, that narrative context should be a flat JSON file rather than a graph. Architecture and editorial taste are still human territory.

## What's next

The embedding infrastructure opens doors I haven't walked through yet:

- **RAG for editorial context**: When generating tomorrow's bulletin, retrieve the 5 most similar historical bulletins for context
- **Story clustering**: Use embedding similarity to automatically detect new story threads
- **Cross-issue references**: "See also: our coverage from January 15" generated automatically
- **Vector-based Alerts**: "Notify me about suicides in Tuscany." Save the search vector, match incoming articles against it, send a customized weekly digest.

And yes, I could add a chatbot. "Hey AI, what happened in Brescia?" It would be trivial to implement with this stack. But do we really need another chat interface? Or do we need information pushed to us when it matters?

## Conclusion

BehindBarsPulse started as a weekend experiment and became a production system that people actually read. The Italian prison crisis deserves consistent, synthesized coverage, and AI makes that possible at a scale that no individual journalist could sustain.

But the deeper takeaway, for me, is about the development process itself. Building a full-stack application with AI assistance isn't the future: it's the present. The patterns I developed at Wishew (skills, TDD, structured collaboration) translated directly to a personal project with zero adaptation.

The controversial claim: **a single developer with AI tools can build and maintain systems that would have required a small team five years ago.** Not because AI writes perfect code (it doesn't). But because the bottleneck was never typing speed. It was context switching, boilerplate, deployment friction, debugging cycles. AI compresses all of those.

The entire infrastructure runs on Google's $300 free GCP credits. Cloud Run, Cloud SQL, Cloud Functions, Vertex AI batch, GCS: all within the free tier budget. The only real cost is a few dollars a month for AWS SES email delivery. A full-stack monitoring platform with AI editorial generation, semantic search, and a statistics dashboard, for the price of a coffee.

Is the code perfect? No. Are there architectural decisions I'd revisit? Absolutely. But the system works, it's in production, and it took less than 10 hours of work over 9 days from blank repository to daily editorial delivery.

Admittedly, the Italian prison system isn't exactly a topic that draws crowds. But that's almost the point: AI-assisted development makes it viable to build serious tools for niche problems that would never justify a team or a budget. The economics of solo development just changed.

That's worth something.

## Tools & references

**Project Stack:**

* [FastAPI](https://fastapi.tiangolo.com/): Web framework (Python)
* [SQLAlchemy 2.0](https://www.sqlalchemy.org/) + [pgvector](https://github.com/pgvector/pgvector): ORM with vector search
* [Google Gemini API](https://ai.google.dev/): Structured output, content generation
* [Vertex AI Batch](https://cloud.google.com/vertex-ai/docs/generative-ai/batch-prediction): Async inference at 50% cost
* [Cloud Run](https://cloud.google.com/run) + [Cloud Functions](https://cloud.google.com/functions): Serverless compute
* [Terraform](https://www.terraform.io/): Infrastructure as Code (GCP + AWS)
* [uv](https://github.com/astral-sh/uv): Python package management
* [AWS SES](https://aws.amazon.com/ses/): Email delivery

**AI Collaboration:**

* [Claude Code](https://claude.ai/code): AI pair programmer (development)
* [claude-forge](https://github.com/maroffo/claude-forge): Modular AI skills collection

**Referenced Articles:**

* [Building Modular AI Skills](https://medium.com/@maroffo/from-asking-claude-to-code-to-teaching-claude-our-patterns-building-modular-ai-skills-83680a2e3708): The skills system
* [From Skills to Shipping](https://medium.com/@maroffo/from-skills-to-shipping-building-with-claude-as-a-pair-programmer-d1ec11eb1c3c): Claude as pair programmer
* [From Rubber Ducks to Gemini](https://maroffo.medium.com/from-rubber-ducks-to-gemini-ai-powered-code-reviews-in-gitlab-ci-a1bc44309c21): AI code reviews

***

_BehindBarsPulse is a personal project, not affiliated with Wishew. The monitoring system is live at [behindbars.news](https://behindbars.news). The source code is available on [GitHub](https://github.com/maroffo/behindbarspulse)._

_This article was written by a human who built the system with AI assistance. The irony of writing about AI-assisted development without AI assistance was not lost on me, so Claude helped edit this too._
