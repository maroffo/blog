# ABOUTME: Operating guide for Claude in the Maroffo Hugo blog repo
# ABOUTME: Build/run commands, content conventions, draft workflow, and the gotchas that bite

# CLAUDE.md

Maroffo's personal blog. Hugo + PaperMod, deployed to GitHub Pages. Content is mostly first-person essays on AI-assisted development, engineering leadership, and the occasional opinion piece. The audience is technical.

For the deeper retrospective (decisions, history, war stories) see `LEARNING.md`. This file is the short operational version.

## Commands

```bash
make check        # hugo --gc --minify --quiet  (the build that must pass; also the pre-commit gate)
make build        # full production build into public/
make clean        # rm -rf public resources
hugo server -D    # local preview at :1313, INCLUDING drafts (draft: true)
hugo --buildDrafts --quiet --renderToMemory   # fast "does it compile" check without writing files
```

Hugo must be the **extended** build (theme needs it). Local dev is on 0.162.x; CI pins 0.155.3. After a fresh clone, init the theme submodule and the repo hook:

```bash
git submodule update --init --recursive
git config core.hooksPath .githooks
```

## Layout

```
content/posts/YYYY-MM-DD-slug.md   ← published posts (25+). Slug = lowercase-hyphenated
content/posts/images/              ← inline post images
content/{about,archives,search}.md ← standalone pages
static/images/                     ← cover images and other static assets
content/drafts/                    ← work-in-progress (GITIGNORED, never pushed)
drafts/                            ← top-level scratch, untracked, ignore it
themes/PaperMod/                   ← base theme (git submodule)
themes/hugo-theme-papermod-nur/    ← custom overrides, layered FIRST in hugo.toml
hugo.toml, Makefile, LEARNING.md
```

Permalinks are `/posts/:contentbasename/`. Link between posts with `{{< ref "YYYY-MM-DD-slug" >}}`, not hard URLs.

## Front matter (post template)

```yaml
---
title: "..."
date: YYYY-MM-DD
summary: "1-2 concrete sentences, no fluff"
tags: ["ai", "llm", "..."]      # lowercase; reuse existing tags where possible
draft: true                      # true while writing (see workflow below)
cover:
  image: "images/cover-<slug>.png"   # lives in static/images/
  alt: "..."
  relative: false
---
```

Cover images: black-and-white hand-drawn ink-sketch style, 16:9, generated with `~/.claude/skills/_generate_image.py` and saved to `static/images/cover-<slug>.png`. They carry no text, so the same cover can be reused across language variants of a post.

## Draft workflow (this bites if you ignore it)

- `.githooks/pre-commit` **blocks any commit** that stages a `content/posts/*.md` file with `draft: true`. It reads the git index, so it catches the exact staged version.
- To keep something as a draft, it belongs in `content/drafts/` (gitignored). Move with plain `mv`, **never `git mv`** (gitignore only covers untracked files), then `git add` once it is ready.
- To publish: set `draft: false`, then commit. Push to `main` triggers deploy.
- A post can be written and reviewed in `content/posts/` with `draft: true` (so `hugo server -D` previews it), but it cannot be committed there until `draft: false`.

## Deploy

Push to `main` → `.github/workflows/hugo.yml` builds with Hugo extended, indexes with Pagefind, publishes to GitHub Pages. No manual step. There is no staging environment.

## Writing conventions

> The `blog-writer`, `humanizer`, and `cover-image` skills and the `_generate_image.py` script mentioned here are the author's personal Claude tooling, kept in the public [claude-forge](https://github.com/maroffo/claude-forge) repo. They are not dependencies of this blog and the build does not need them; they just describe how posts get made.

- Write posts via the `blog-writer` skill. Voice: first person, opinionated, evidence-backed, self-aware. See the skill's style guide.
- **No em dashes.** Use commas, colons, semicolons, or parentheses (global rule, enforced by habit here).
- Run the `humanizer` pass on every post before publishing; for research-heavy pieces, end with a Sources section and a methodology note, and verify every figure against a real source (do not trust numbers handed to you).
- Posts may exist in multiple language variants as separate files with their own slug (e.g. an English post and its Italian companion). The blog is single-language in `hugo.toml` (no i18n), so each variant is just another post.
- Content markdown files do **not** get `ABOUTME:` headers (that convention is for build/source files like `Makefile` and `LEARNING.md`); posts use front matter instead.

## Gotchas

- Theme is a submodule: a clone without `--recursive` produces a broken, theme-less build.
- Two themes are layered in `hugo.toml`; `hugo-theme-papermod-nur` holds overrides and must come before `PaperMod`. Order matters.
- `make check` / `make test-e2e` both just run a quiet Hugo build, that is the bar: the site must compile.
- Never work directly on `main`; branch, then PR.
