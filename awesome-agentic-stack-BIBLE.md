# awesome-agentic-stack — PROJECT BIBLE
> **Single source of truth. Every decision, tradeoff, constraint, and sprint prompt lives here.**
> **AI agents cold-read this. Zero clarification needed. Zero chat history assumed.**

---

## TABLE OF CONTENTS

1. [Vision & Positioning](#1-vision--positioning)
2. [What This Repo IS and IS NOT](#2-what-this-repo-is-and-is-not)
3. [Competitive Analysis — Why a Gap Exists](#3-competitive-analysis--why-a-gap-exists)
4. [Repo Architecture](#4-repo-architecture)
5. [Content Architecture — Full Taxonomy](#5-content-architecture--full-taxonomy)
6. [The Moat — What Makes This Win](#6-the-moat--what-makes-this-win)
7. [README Spec — Section by Section](#7-readme-spec--section-by-section)
8. [Distribution Strategy — Platform by Platform](#8-distribution-strategy--platform-by-platform)
9. [Site Integration — akashpriyadarshi.vercel.app](#9-site-integration--akashpriyadarshistackvercelapp)
10. [Maintenance Protocol](#10-maintenance-protocol)
11. [Decision Log](#11-decision-log)
12. [Sprint Plan — 4 Sprints](#12-sprint-plan--4-sprints)
13. [##PROMPTS — Paste-Ready Sprint Prompts](#prompts--paste-ready-sprint-prompts)
14. [##CLAUDE.md — Drop Into Project Root](#claudemd--drop-into-project-root)

---

## 1. VISION & POSITIONING

### The One-Line Pitch
> **"386 repos audited. 96 survived. The only agentic coding stack engineered for ₹0 budget and 50× output."**

### Who This Is For
Not beginners. Not corporate devs with $500/mo tooling budgets.

**Primary:** Solo vibe coders, indie hackers, students in India and the Global South who are building production-grade systems on zero budget using AI agents as their entire team.

**Secondary:** Any developer drowning in agentic tool discovery — there are 386+ repos in this space. They need someone who already did the 6-week filter.

**Tertiary:** Open source community on Twitter/X, Reddit (`r/ClaudeAI`, `r/vibecoding`), and GitHub who want a canonical reference they can contribute to and cite.

### Why Akash Priyadarshi owns this angle
- Has actually run Claude Code + Gemini CLI + OpenCode + Codex + Antigravity in parallel on a ₹0 budget
- Built out of direct daily necessity under tight hardware constraints
- Has shipped KRONOS, RELAY, Resonance, BharatTalks, STASH etc. using exactly this stack
- Runs this on a Realme GT7 (phone) and MacBook Air M5 simultaneously — extreme cross-device constraint that most list curators have never faced

This is not a list made by someone who skimmed GitHub Trending. This is a list made by someone who runs this stack daily.

---

## 2. WHAT THIS REPO IS AND IS NOT

### IS
- A **workflow-first** curated list — organized by *when* you use a tool in your session, not just category
- **Opinionated** — every entry has a one-line "why this survived the cut" verdict
- **₹0 enforced** — every tool is free tier, zero payment method required (exceptions flagged explicitly)
- **Audit-grade** — 386 scanned, 96 survived. The 290 that were cut matter. Rejection reasons surface credibility.
- **Living document** — monthly update cycle, community PRs via Issue template
- **Cross-device verified** — every tool tested on or considered for M5 + GT7 reality

### IS NOT
- A directory of everything that exists (that's `affaan-m/ECC` or `hesreallyhim/awesome-claude-code`)
- A beginner tutorial or course
- Platform-locked (not just Claude Code — covers Gemini CLI, OpenCode, Codex, Cursor, Antigravity)
- A sponsored or affiliate link farm

### The Single Differentiator in One Sentence
Every other awesome list curates by **existence**. This list curates by **survival under constraint**.

---

## 3. COMPETITIVE ANALYSIS — WHY A GAP EXISTS

| Repo | Stars (2026) | Gap This Exploits |
|------|-------------|-------------------|
| `hesreallyhim/awesome-claude-code` | ~45K | Claude Code only. No cross-IDE. No workflow order. No ₹0 filter. |
| `techiediaries/awesome-vibe-coding` | ~8K | Tool listing only. No workflow. No token economy. Broad/shallow. |
| `roboco-io/awesome-vibecoding` | ~6K | Auto-generated content. No human curation signal. |
| `0xWelt/Awesome-Vibe-Coding` | ~4K | App-builder focused (Lovable, Bolt). Not terminal/agent workflow. |
| `danielrosehill/Awesome-AI-Coding-Tools` | ~2K | Point-in-time snapshot. Not maintained. No verdict per tool. |
| `affaan-m/ECC` (Everything Claude Code) | ~196K | Firehose aggregator. Signal-to-noise ratio near zero. No workflow. |

**The gap:** Nobody has done *workflow-first + multi-IDE + ₹0-enforced + rejection-explained + cross-device verified* in a single repo. That combination is the moat.

---

## 4. REPO ARCHITECTURE

```
awesome-agentic-stack/
│
├── README.md                     ← Main file. The weapon.
├── WORKFLOW.md                   ← The 4-phase dev loop (full detail)
├── CONTRIBUTING.md               ← How to submit tools / raise rejections
├── CHANGELOG.md                  ← Monthly update log with added/removed counts
│
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── suggest_tool.md       ← Structured PR template for new tools
│   │   └── report_dead_tool.md   ← Flag dead repos / changed pricing
│   └── workflows/
│       └── validate_links.yml    ← GitHub Action: check all links monthly
│
├── assets/
│   ├── banner.png                ← 1280×640, dark, terminal aesthetic
│   ├── workflow-diagram.png      ← The 4-phase loop as visual
│   └── og-card.png               ← Twitter/OG card image
│
└── lists/
    ├── rejected.md               ← The 290 repos that didn't survive + why
    └── watching.md               ← Promising repos not yet stable enough
```

**Key architectural decision:** `lists/rejected.md` is the secret weapon. No other awesome list publishes what they cut and why. This file alone will get you cited in Reddit threads and dev blogs.

---

## 5. CONTENT ARCHITECTURE — FULL TAXONOMY

The README is organized by **workflow phase**, not category. This is the structural moat.

### PHASE 0 — IDENTITY LAYER (drop in every project, once)
Skills, CLAUDE.md rules, harness files that define *how* agents behave on your project.

Categories:
- Skill backbones (superpowers, ECC, Karpathy rules)
- Context files (AGENTS.md, SPEC.md, DESIGN.md)
- Anti-slop layers (taste-skill, humanizer, stop-slop)
- Harness / cycle managers (burn-baby-burn, revfactory/harness)

### PHASE 1 — SESSION START (run before first prompt)
Tools that prepare the AI's context window and your token budget.

Categories:
- Repo packers (repomix → single-file codebase)
- Memory recall (claude-mem, auto-memory, agentmemory)
- Token killers (rtk, caveman, context-mode, sigmap, semble)
- Knowledge graphs (codegraph, safishamsi/graphify)

### PHASE 2 — ACTIVE CODING (open alongside your tool)
Agent managers, multi-IDE orchestration, mobile coding.

Categories:
- Agent managers / dashboards (cc-switch, emdash, multica)
- Loop-until-done runners (ralph, oh-my-claudecode)
- Multi-agent orchestration (tessera, VibeAround, cmux)
- Token observability (codeburn, headroom)
- Free access bridges (free-claude-code, opencode-antigravity-auth)

### PHASE 3 — MOBILE & CROSS-DEVICE
GT7-specific, Android coding, sync layer.

Categories:
- Mobile coding clients (slopus/happy, getpaseo/paseo)
- ADB/Android automation (droidclaw, mobile-mcp)
- Cross-device sync (syncthing, localsend, Sefirah)
- Android development on Android (android-code-studio)

### PHASE 4 — SESSION END (run before git push)
Security scans, memory save, push safety.

Categories:
- Secret scanners (gitleaks, trufflehog)
- Security firewalls (clawpatrol, foxguard)
- Memory save (auto-memory save, memoir)
- Git primitives for agents (git-surgeon, git-ai)

### REFERENCE TABS (always open in browser)
- Free API catalogs (awesome-free-llm-apis, public-apis)
- Best practices (claude-code-best-practice, prompt-engineering-guide)
- Android dev (Shizuku, android-hidden-api, android-foss)

---

## 6. THE MOAT — WHAT MAKES THIS WIN

### Signal 1: "386 Scanned, 96 Survived"
This number is everywhere — README title, banner, first tweet, Reddit post title. It communicates rigorous curation before anyone reads a single entry. No other list has this.

### Signal 2: `lists/rejected.md`
Publishing the 290 that didn't make it — with one-line rejection reasons — is the single most credible thing an awesome list can do. Examples:
- `obra/superpowers` — **included** — skill backbone, actively maintained, 210K stars
- `some-random-skills-repo` — **rejected** — last commit 14 months ago, zero issues activity
- `tool-x` — **rejected** — requires CC for free tier (violates ₹0 constraint)

This file will be shared by devs on Reddit as "this guy actually did the work."

### Signal 3: Token Savings Quantified
Every token-related tool has a savings % inline:
> `rtk` — **60–90% token reduction** | Rust binary, zero deps | Verified via benchmark

Numbers get screenshotted. Screenshots get tweeted.

### Signal 4: Free Tier Column
Every entry has a free tier indicator. No ambiguity:
- ✅ **Free** — zero payment method required
- ⚠️ **Free-ish** — free tier exists but CC required to unlock
- ❌ **Paid** — no meaningful free tier

This is the only list that makes this explicit for every entry.

### Signal 5: Cross-IDE Coverage
`r/ClaudeAI` + `r/vibecoding` + Codex + Gemini CLI users all find themselves here. Most lists are Claude Code-only. This covers Claude Code, Gemini CLI, OpenCode, Codex CLI, Cursor, Antigravity IDE — all multi-IDE tools tagged accordingly.

### Signal 6: The Workflow Diagram
The 4-phase loop (Phase 0 → Session Start → Active Coding → Session End) rendered as a clean ASCII/visual diagram will be the most screenshotted thing in the repo. People print this. People put it in their CLAUDE.md.

---

## 7. README SPEC — SECTION BY SECTION

### Header Block
```markdown
<div align="center">

# ⚡ awesome-agentic-stack

**386 repos audited. 96 survived.**
The only agentic coding stack built for ₹0 budget and 50× output.

[![Awesome](https://awesome.re/badge.svg)](https://awesome.re)
![Last Updated](https://img.shields.io/github/last-commit/AkashPriyadarshii/awesome-agentic-stack)
![Stars](https://img.shields.io/github/stars/AkashPriyadarshii/awesome-agentic-stack)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

*Curated by [Akash Priyadarshi](https://akashpriyadarshi.vercel.app)*
*Running this stack daily on MacBook Air M5 + Realme GT7*

</div>
```

### Why This List Exists (3 bullets max, brutal)
- Most awesome lists curate by existence. This curates by survival under constraint.
- Every tool here runs on free tier, zero payment method required. The 290 that didn't pass are in `lists/rejected.md`.
- Organized by *when* you use it in your session — not by category — because workflow beats taxonomy.

### The Dev Loop (visual first, explanation second)
ASCII diagram of the 4-phase loop. Then link to `WORKFLOW.md` for full detail.

### Content Sections
Each section header = phase name. Each entry format:

```
| [repo-name](url) | ⭐ Stars | ✅/⚠️/❌ Free | One-line survival verdict |
```

### Footer
Links to: `CONTRIBUTING.md` | `lists/rejected.md` | `CHANGELOG.md` | author site

---

## 8. DISTRIBUTION STRATEGY — PLATFORM BY PLATFORM

### Cadence Decision
**3x/week max.** Quality over frequency. <1000 followers = consistency matters more than volume. Every post must add something — never filler.

---

### GITHUB (the core — everything feeds back here)

**Week 1 actions:**
1. Push repo with full README (all 96 entries, all phases)
2. Submit PR to `sindresorhus/awesome` — this gets you the badge + passive discovery from the official awesome list index
3. Enable GitHub Discussions — community suggests tools here
4. Add `awesome-list`, `agentic-coding`, `claude-code`, `vibe-coding`, `free-tier`, `developer-tools` as topics
5. Pin `lists/rejected.md` in README — this is the credibility anchor

**Ongoing:**
- Respond to every Issue within 24 hours for the first 30 days — this triggers GitHub's "active" signals
- Monthly: update CHANGELOG.md with added/removed counts, push a commit — keeps repo appearing in recency feeds

---

### REDDIT (highest ROI, zero follower dependency)

Target subreddits ranked by ROI:
1. `r/ClaudeAI` — Claude Code = 226 mentions tracked in 2026, most active agentic coding community
2. `r/vibecoding` — 89K members, fastest-growing dev community on Reddit right now
3. `r/SideProject` — indie builders, responds well to "I did the work so you don't have to" framing
4. `r/programming` — general dev, high volume, harder to break through but huge upside
5. `r/indiehackers` — budget-conscious builders, ₹0 angle lands perfectly here
6. `r/artificial` — AI enthusiasts, good secondary amplifier

**Post title formula that wins:**
> "I scanned 386 repos to find the 96 agentic coding tools that actually survive a ₹0 constraint — here's what made it [OC]"

**Body formula:**
- Para 1: The problem (too many tools, no one did the filter)
- Para 2: The methodology (386 scanned, filters applied, rejection reasons published)
- Para 3: The workflow (4-phase loop, not category soup)
- Link to repo
- Ask: "What tool am I missing?" — invites comments, drives engagement

**Rule:** Post to ONE subreddit per day. Space 24 hours minimum. Respond to every comment for the first 2 hours after posting — Reddit's algo rewards comment velocity.

**Secondary play:** Find existing threads asking "what agentic coding tools do you use" and drop a non-spammy comment linking the list. This is evergreen traffic.

---

### TWITTER/X — Handle: @Akash__ydv001

**Post types (rotate):**

**Type A — Launch thread (once, day of publish):**
Tweet 1 (hook, max 140 chars): *"386 repos. 6 weeks. 1 rule: ₹0 only. Here's the only agentic coding stack that actually survives the constraint 🧵"*
Tweets 2–7: One phase per tweet. Best 2 tools, savings %, free tier status.
Tweet 8: The workflow ASCII loop (screenshot of the diagram)
Tweet 9: *"290 repos didn't make it. Their rejection reasons are in lists/rejected.md — this file alone is worth reading."*
Tweet 10: Repo link + "PRs welcome"

**Type B — Weekly tool spotlight (Mon):**
*"Tool I couldn't build without this week: [name]. [what it does in 1 sentence]. [savings % or key metric]. Free: ✅. [link]"*

**Type C — Number posts (Wed):**
*"This tool cut my token burn 98%. Here's the exact setup:"* → screenshot of config

**Type D — Rejection posts (every 2 weeks):**
*"Cut another 8 repos from awesome-agentic-stack this week. Rejection reasons:"* → list them → *"The bar is: works in 2026, free tier, cross-IDE. Most fail reason 1."*

**Tags to use:** `#vibecoding` `#ClaudeCode` `#agentcoding` `#buildinpublic` `#opensource`

**People to tag on launch thread (their repos are in the list):**
- `@addyosmani` — `agent-skills` is in the list
- `@AnthropicAI` — Claude Code is the center of gravity
- `@karpathy` — coined vibe coding, Karpathy skills in the list
- `@yamadashy` — repomix creator, in the list

---

### THREADS — Handle: @free_dev2026

Mirror Twitter content. Slightly more casual. Threads rewards longer posts more than X right now. The `@free_dev2026` handle is already perfectly positioned for the ₹0 angle — lean into it explicitly.

**Unique Threads angle:** Post the "rejected.md" entries as carousels. "Tools I said NO to and why" performs extremely well on Threads dev community.

---

### LINKEDIN

Different tone, different angle. LinkedIn audience = recruiters + senior engineers + tech leads.

**Angle:** Not "vibe coder builds tool list." Instead: "I built a system for evaluating 386 developer tools — here's the framework I used."

**Post format:**
- No external links in post body (LinkedIn buries these). Put link in first comment.
- Paragraph format, no bullets in the post itself — LinkedIn algo prefers prose
- Hook line must be standalone surprising fact: *"290 developer tools failed a single filter: does it work for free, no credit card required."*

**Cadence:** 1x/week. Quality only.

---

### DEV.TO + HASHNODE + BLOG (akashpriyadarshi.vercel.app)

**First post (publish same day as repo launch):**
Title: *"Why I Scanned 386 Repos to Find 96 Agentic Coding Tools — And What the 290 Failures Taught Me"*

This post is the origin story. Structure:
1. The problem I was solving (drowning in tool discovery)
2. The filter criteria (₹0, cross-IDE, actively maintained, workflow-phase relevant)
3. The surprising things I found in the 290 rejections
4. The 4-phase workflow that emerged
5. Link to repo

Cross-post identical article to Dev.to, Hashnode, and your own blog. Dev.to and Hashnode have their own distribution — your article appears in feeds of thousands of developers who never visit GitHub.

**Ongoing:** One deep-dive article per month. Each article = one tool category fully explained with real usage examples. These rank on Google for search terms like "best agentic coding tools free 2026."

---

### INSTAGRAM (visual carousels only)

One carousel per week. Template:
- Slide 1: Tool name + category. Dark AMOLED background (#000000), white text, minimal.
- Slide 2: What problem it solves (1 sentence)
- Slide 3: Key metric (token savings %, star count, install command)
- Slide 4: Free tier status ✅/⚠️/❌ + why it survived the cut
- Slide 5: *"Find 95 more at: github.com/AkashPriyadarshii/awesome-agentic-stack"*

Hashtags: `#vibecoding` `#agentcoding` `#developertools` `#opensource` `#indiahacks` `#buildinpublic` `#claudecode`

---

## 9. SITE INTEGRATION — akashpriyadarshi.vercel.app

### Current State (observed from scrape)
- ✅ Hero tagline: strong ("I build systems nobody asked for, until they can't live without them")
- ✅ Social links connected: GitHub, X, Reddit, Threads
- ❌ Zero featured projects — showing placeholder
- ❌ Zero blog posts published
- ❌ "COMPILING ASSETS..." on projects section

### Actions (do these in Sprint 1)

**Projects section:** Add `awesome-agentic-stack` as the first featured project. Tagline: *"386 repos audited. 96 survived. The ₹0 agentic coding stack."* Link to GitHub repo.

**Blog section:** The origin story post (see Dev.to section above) goes here first. This converts every GitHub visitor who clicks your profile into a blog reader.

**Uses page:** This page is perfect for linking the list naturally. `/uses` should reference `awesome-agentic-stack` as your actual tooling reference.

**SEO note:** Your `meta-description` is currently *"Solo builder. AI agents · Android internals · systems tools · open source."* After launching the repo, add a reference to it here for organic search.

---

## 10. MAINTENANCE PROTOCOL

### Monthly (first Monday of every month)
1. Scan GitHub trending for new agentic/vibe coding repos
2. Check star counts on all 96 entries — anything that dropped to inactive (<1 commit in 6 months) gets moved to `lists/watching.md`
3. Check all free tier claims — these change frequently (e.g. OpenCode, Antigravity pricing)
4. Push `CHANGELOG.md` update with: repos added, repos removed, pricing changes
5. Post "monthly update" tweet thread + Reddit comment in relevant threads

### Per-PR (community submissions)
Every Issue using the suggest_tool template gets:
1. Verified: actively maintained (commit in last 3 months)?
2. Verified: free tier, zero CC required?
3. Verified: cross-IDE or tool-specific (if tool-specific, does it add enough value)?
4. Assigned to correct workflow phase
5. Added with survival verdict inline

### Quality gate for new entries
A tool does NOT make the cut if:
- Last commit > 6 months ago
- Free tier requires CC (even if they claim "no charge")
- Does the same thing as an existing entry without being meaningfully better
- Stars < 100 AND author unknown (exception: exceptionally useful niche tools)

---

## 11. DECISION LOG

| Decision | Options Considered | Chosen | Why |
|----------|-------------------|--------|-----|
| Repo name | `awesome-vibe-stack`, `agentic-zero`, `vibecoder-toolkit`, `awesome-agentic-stack` | `awesome-agentic-stack` | "agentic" is the dominant 2026 keyword in developer discourse. "stack" signals opinionated curation. "vibe" is crowded (4+ existing repos). Searchable, memorable, no collision with existing top lists. |
| README structure | By category (like all existing lists), By workflow phase | By workflow phase | Workflow-first is the structural moat. No existing list does this. Phases = immediate utility. Category = directory. |
| Include rejected.md | Keep rejections private, Publish rejections with reasons | Publish with reasons | The 290 rejections are the single biggest credibility signal. No other list does this. Will drive Reddit/Twitter engagement independently. |
| Content source | Build from scratch, Start from the uploaded curated doc | Start from uploaded doc, restructure into phases | The uploaded doc already has the audit work done (386→96). The restructuring from category-soup into phase-based workflow is where the value is added. |
| Multi-IDE vs Claude-only | Claude Code only (like hesreallyhim), Multi-IDE (Claude/Gemini/OpenCode/Codex/Antigravity) | Multi-IDE | Claude Code-only lists already exist with huge stars. The gap is multi-IDE. Also aligns with Akash's actual stack. |
| Rejected persona for tool | Plain audit list, Tools included from uploaded doc's fake star inflated repos | Acknowledge the uploaded doc lists many repos with inflated/unverifiable star counts | The uploaded document contains repos with star counts that appear inflated (e.g. 210K for obra/superpowers is implausible). The bible treats the uploaded doc as a *starting point for research*, not ground truth. All star counts and claims must be independently verified before publishing. |

### Critical Note on the Uploaded Document
The document submitted references star counts like 210K, 196K, 160K, 109K for relatively obscure repos. These are **not verifiable** and likely inflated. **Before Sprint 1**, independently verify every star count via GitHub. The content taxonomy and workflow structure are useful. The specific numbers are not trusted. The `lists/rejected.md` will reflect real, verified data only.

---

## 12. SPRINT PLAN — 4 SPRINTS

### Sprint 1 — Foundation (Days 1–3)
**Goal:** Repo is live, verified, credible, and SEO-ready. Zero fake data.

Tasks:
- [ ] Independently verify top 20 repos from uploaded doc via GitHub (star counts, last commit, free tier)
- [ ] Write full README.md (all 4 phases, verified entries only, format spec from Section 7)
- [ ] Write WORKFLOW.md (4-phase loop, full detail, ASCII diagram)
- [ ] Write CONTRIBUTING.md
- [ ] Write lists/rejected.md (start with 20 verified rejections + reasons)
- [ ] Write lists/watching.md
- [ ] Create .github/ISSUE_TEMPLATE/ files
- [ ] Create GitHub Actions workflow for link validation
- [ ] Generate banner.png (dark terminal aesthetic, "386 scanned 96 survived" tagline)
- [ ] Push to GitHub: `github.com/AkashPriyadarshii/awesome-agentic-stack`
- [ ] Add GitHub topics: `awesome-list`, `agentic-coding`, `claude-code`, `vibe-coding`, `free-tier`
- [ ] Submit PR to `sindresorhus/awesome`
- [ ] Add repo to `akashpriyadarshi.vercel.app` projects section

### Sprint 2 — Launch (Days 4–6)
**Goal:** First wave of visibility on all platforms.

Tasks:
- [ ] Write origin story blog post (see Section 8)
- [ ] Publish on Dev.to + Hashnode + personal blog simultaneously
- [ ] Post to Reddit (r/ClaudeAI first, then r/vibecoding next day, then r/SideProject)
- [ ] Post launch thread on Twitter/X
- [ ] Post on Threads
- [ ] Post on LinkedIn (different angle — framework post)
- [ ] Create first Instagram carousel (tool spotlight from Phase 1)
- [ ] Engage with every comment/reply for 48 hours post-launch

### Sprint 3 — Depth (Days 7–21)
**Goal:** Content rhythm established. Community forming.

Tasks:
- [ ] Complete `lists/rejected.md` to 50+ entries with reasons
- [ ] Add "tool of the week" section to README (rotates monthly)
- [ ] Write second blog post: deep dive into Phase 1 (Session Start) tools
- [ ] Post 3x/week on Twitter, 1x/week on Reddit (different subreddits), 1x/week on LinkedIn
- [ ] Respond to every community suggestion Issue
- [ ] Add 10 more verified tools from community suggestions (if any)

### Sprint 4 — Sustain (Day 22+)
**Goal:** Monthly cycle running. Passive star growth via sindresorhus/awesome listing.

Tasks:
- [ ] First monthly CHANGELOG.md update
- [ ] Write third blog post: deep dive into Phase 4 (Security + Session End) tools
- [ ] Monitor sindresorhus/awesome PR — follow up if no merge in 14 days
- [ ] Check all free tier claims — update any that changed
- [ ] Evaluate: are there sub-lists worth spinning off? (e.g. `awesome-agentic-stack-android`, `awesome-agentic-stack-mobile`)

---

## ##PROMPTS — PASTE-READY SPRINT PROMPTS

> **How to use:** Copy the entire block for the relevant sprint/task. Paste directly into Claude Code, Gemini CLI, OpenCode, or any other agent. Each prompt is self-contained — no prior context needed.

---

### PROMPT: Sprint 1 — Build Full README.md

```
You are building a GitHub awesome list called `awesome-agentic-stack`.

REPO: github.com/AkashPriyadarshii/awesome-agentic-stack
TAGLINE: "386 repos audited. 96 survived. The only agentic coding stack for ₹0 budget and 50× output."
AUTHOR: Akash Priyadarshi, solo builder, MacBook Air M5 + Realme GT7

TASK: Write the complete README.md for this repo.

STRUCTURE RULES:
1. Header block with: title, "386 audited 96 survived" tagline, badges (awesome.re badge, last-commit, stars, PRs welcome), author credit with site link
2. Section: "Why This List Is Different" — 3 brutal bullets only
3. Section: "The Dev Loop" — ASCII diagram of 4 phases:
   PHASE 0: Identity Layer (drop once per project)
   PHASE 1: Session Start (run before first prompt)
   PHASE 2: Active Coding (open alongside tool)
   PHASE 3: Mobile & Cross-Device
   PHASE 4: Session End (run before git push)
   Then: "→ See WORKFLOW.md for full phase detail"
4. One section per phase with a table of tools. Table columns: Repo | Stars | Free | Why It Survived
   Free column: ✅ (zero CC) / ⚠️ (CC required) / ❌ (paid only)
5. Section: "Reference Tabs — Always Open"
6. Footer: links to CONTRIBUTING.md, lists/rejected.md, CHANGELOG.md, author site

TOOL LIST: [paste the content of the uploaded document here as your source material]

IMPORTANT: Every star count must show as "⭐ verify" placeholder — do NOT copy star numbers from the source. They need independent verification. Format: `⭐ verify`

FORMAT: Clean markdown. Tables for tools. Minimal prose. No filler. No AI writing patterns. Write like a senior engineer published this, not a content marketer.

OUTPUT: Full README.md content only. No preamble, no explanation.
```

---

### PROMPT: Sprint 1 — Build WORKFLOW.md

```
You are writing WORKFLOW.md for the `awesome-agentic-stack` GitHub repo.

This file is the full detail version of the 4-phase dev loop. It is the most screenshot-able and sharable file in the repo.

AUTHOR CONTEXT: Solo vibe coder, MacBook Air M5 + Realme GT7, ₹0 budget, uses Claude Code + Gemini CLI + OpenCode + Codex + Cursor + Antigravity IDE in rotation.

TASK: Write WORKFLOW.md with these exact sections:

1. The Full Loop (large ASCII diagram showing all 4 phases with tool names at each step)
2. Phase 0 — Identity Layer
   - When: Once per new project
   - What: Drop AGENTS.md, DESIGN.md, CLAUDE.md, install skills
   - Tools listed with one-line usage
3. Phase 1 — Session Start  
   - When: Every session, every device, before first prompt
   - What: Pack repo → load memory → kill tokens → start agent
   - Tools listed with exact commands
4. Phase 2 — Active Coding
   - When: During the session
   - What: Agent managers, multi-agent orchestration, token watching
   - Tools listed with one-line usage
5. Phase 3 — Mobile & Cross-Device
   - When: On phone (GT7) or syncing M5 ↔ GT7
   - What: Mobile clients, ADB tools, sync tools
6. Phase 4 — Session End
   - When: Before every git push
   - What: Scan secrets → save memory → push
   - Tools listed with exact commands
7. "Steal This Workflow" section — the exact bash-friendly sequence as copy-pasteable commands for each phase

TONE: Terse. Technical. No fluff. Written for developers who want to copy-paste and go.

OUTPUT: Full WORKFLOW.md content only.
```

---

### PROMPT: Sprint 1 — Build lists/rejected.md

```
You are writing lists/rejected.md for the `awesome-agentic-stack` GitHub repo.

This file is one of the repo's biggest credibility signals. It documents tools that were evaluated and cut, with the exact reason.

TASK: Write lists/rejected.md with:

1. Intro paragraph (3 sentences max): "These are the 290 repos that didn't survive the audit. Rejection reasons are explicit. If you think a rejection was wrong, open an Issue."

2. Table with columns: Repo | Stars | Rejection Reason | Category It Was Competing In

3. REJECTION REASON TAXONOMY (use these exact labels):
   - DEAD: Last commit >6 months ago
   - CC_REQUIRED: Free tier exists but requires credit card
   - OVERLAP: Does same job as an included tool, worse
   - SCOPE_CREEP: Interesting but not workflow-relevant for terminal/agent coding
   - UNVERIFIABLE: Star count or claims could not be independently verified
   - UNMAINTAINED: Active issues but no maintainer response >3 months
   - PAID_ONLY: No meaningful free tier

4. Start with 30 representative rejections across all reason types. Mix well-known repos and obscure ones.

NOTE: Do NOT invent real GitHub repo URLs. Use placeholder format `github.com/example/tool-name` for any repo you cannot verify exists with those exact characteristics.

TONE: No judgment, no snark. Just the verdict.

OUTPUT: Full lists/rejected.md content only.
```

---

### PROMPT: Sprint 1 — Build CONTRIBUTING.md

```
Write CONTRIBUTING.md for the `awesome-agentic-stack` GitHub repo.

RULES for this contributing guide:
1. To suggest a new tool: open an Issue using the suggest_tool template (auto-populates)
2. Quality gate (ALL must pass):
   - Last commit within 3 months
   - Free tier with zero CC/payment method required (⚠️ flag if CC required, don't auto-reject)
   - Not a duplicate of an existing entry
   - Adds to a specific workflow phase (Phase 0–4) — state which one
3. To report a dead tool: open Issue using report_dead_tool template
4. PRs go directly to main after Issue is approved
5. One tool per PR
6. Format for table entry: | [repo-name](url) | ⭐ STARS | ✅/⚠️/❌ | Survival verdict in one line |

Keep it under 80 lines. Developer-terse. No filler.
```

---

### PROMPT: Sprint 1 — GitHub Actions Link Validator

```
Write a GitHub Actions workflow file at .github/workflows/validate_links.yml

PURPOSE: Monthly check that all URLs in README.md, WORKFLOW.md, and lists/ files return 200 status.

SPEC:
- Trigger: schedule (1st of every month at 00:00 UTC) + manual workflow_dispatch
- Runner: ubuntu-latest
- Steps:
  1. Checkout repo
  2. Install markdown-link-check via npm
  3. Run against README.md, WORKFLOW.md, CONTRIBUTING.md, lists/rejected.md, lists/watching.md
  4. On failure: open a GitHub Issue titled "Broken links detected — [month year]" with the output
- Use GITHUB_TOKEN for Issue creation
- Fail gracefully: link errors create Issues, they do not fail the build (a broken link ≠ a broken repo)

Output the full YAML workflow file only.
```

---

### PROMPT: Sprint 2 — Reddit Launch Post (r/ClaudeAI)

```
Write a Reddit post for r/ClaudeAI to launch the awesome-agentic-stack repo.

REPO: github.com/AkashPriyadarshii/awesome-agentic-stack
AUTHOR: Solo builder

RULES:
- Title: must include the "386 audited, 96 survived" framing. Max 300 chars. No clickbait.
- Body: 4 paragraphs max. No bullets in body — Reddit prose reads better.
- Para 1: The problem (tool discovery is broken — too many lists, no constraint filter)
- Para 2: The methodology (the filter criteria: ₹0 / free tier / actively maintained / workflow-phase relevant)
- Para 3: The one thing that doesn't exist anywhere else: lists/rejected.md — the 290 that didn't make it with reasons
- Para 4: Link + "what tool am I missing?" question to invite comments
- End: Do NOT use "hope you find it useful" or any sycophantic closer.

TONE: Direct. Peer-to-peer. Not marketing. Written like a developer talking to developers.

OUTPUT: Title on line 1. Blank line. Body. Nothing else.
```

---

### PROMPT: Sprint 2 — Twitter/X Launch Thread

```
Write a Twitter/X launch thread for the awesome-agentic-stack repo.

ACCOUNT: @Akash__ydv001
REPO: github.com/AkashPriyadarshii/awesome-agentic-stack

RULES:
- 10 tweets total
- Tweet 1 (hook): max 140 chars. No thread-bait openers ("I've been building for X years"). Start with the most surprising fact. Front-load everything.
- Tweets 2–6: one workflow phase per tweet. Name the phase, name 2 best tools, give the free tier status and key metric (token savings %, stars, etc.)
- Tweet 7: the rejected.md angle — the 290 that didn't make it. This is the most retweetable tweet.
- Tweet 8: the workflow diagram (describe it as: "[screenshot of workflow diagram]" — actual image will be attached)
- Tweet 9: the ₹0 angle — this list was built and is run entirely on free tier. All 96 tools verified zero payment required (with ⚠️ flagging where CC is needed).
- Tweet 10: repo link + "PRs welcome" + tags for @addyosmani @AnthropicAI @karpathy

FORMAT: Each tweet numbered (1/10), (2/10), etc. Include hashtags only on tweet 10: #vibecoding #ClaudeCode #buildinpublic #opensource

NO: Thread-bait openers. Generic "a thread 🧵" starters. Em dashes used as decoration. Excessive emojis.
```

---

### PROMPT: Sprint 2 — LinkedIn Post (Framework Angle)

```
Write a LinkedIn post for the launch of awesome-agentic-stack.

ACCOUNT: Akash Priyadarshi
URL: github.com/AkashPriyadarshii/awesome-agentic-stack

ANGLE: NOT "I made a list." Instead: "Here is the framework I used to evaluate 386 developer tools."

RULES:
- Opening line must be a standalone surprising statement (no "I'm excited to share...")
- 4–6 short paragraphs, prose only (no bullets in post body — LinkedIn algo penalizes them)
- Cover: the filter criteria, the rejection rate (290/386 didn't pass), the workflow-phase structure, why ₹0 constraint is the right forcing function for real-world utility
- End with a question that invites professional response: e.g. "What's your filter for adopting a new dev tool?"
- DO NOT include the URL in the post body — state: "Link in first comment"
- Max 1200 characters

TONE: Professional. Confident. Not hustle-culture. Written like an engineer, not a marketer.
```

---

### PROMPT: Sprint 2 — Origin Story Blog Post

```
Write a long-form blog post for akashpriyadarshi.vercel.app/blog

TITLE: "Why I Scanned 386 Repos to Find 96 Agentic Coding Tools — And What the 290 Failures Taught Me"
AUTHOR: Akash Priyadarshi
REPO: github.com/AkashPriyadarshii/awesome-agentic-stack

STRUCTURE:
1. The Problem (the tool discovery crisis in agentic coding — too many repos, no signal)
2. The Filter (the 4 criteria: free tier zero CC, actively maintained, workflow-phase relevant, cross-IDE)
3. What I Found in the 290 Rejections (surprising patterns — most fail on "actively maintained" not pricing)
4. The 4-Phase Workflow That Emerged (brief overview of Phase 0–4 loop)
5. The Most Underrated Find (pick one tool from the 96 and do a genuine mini deep-dive)
6. What's Next (community contributions, monthly update cycle)
7. Link to repo

WORD COUNT: 900–1200 words
TONE: First-person. Reflective but technical. No AI writing patterns. No hedging language ("I think", "perhaps", "it seems"). No sycophantic openers. Write like a developer journaling their process, not a content creator writing for SEO.

OUTPUT: Full blog post markdown. No frontmatter needed.
```

---

### PROMPT: Sprint 3 — Monthly CHANGELOG Entry

```
Write a CHANGELOG.md entry for the awesome-agentic-stack repo.

ENTRY FORMAT:
## [Month Year] — Audit #N

**Added:** N tools
- List each with: `repo-name` — [Phase X] — why added in one line

**Removed:** N tools
- List each with: `repo-name` — [reason from taxonomy: DEAD/CC_REQUIRED/OVERLAP/etc]

**Free Tier Changes:**
- Any tools where pricing changed since last month

**Community:**
- N Issues opened, N merged

---

[Prior entry below this line]

Generate a realistic example entry for May 2026. Make it feel like a real monthly audit — some tools added, some removed, one pricing change. Use placeholder repo names in format `author/repo-name`.
```

---

### PROMPT: Sprint 3 — Instagram Carousel Script (Tool Spotlight)

```
Write a 5-slide Instagram carousel script for a tool spotlight post.

FORMAT: Each slide = one block with:
SLIDE N
[Headline text — max 6 words]
[Body text — max 20 words]
[Visual note — what the designer should show: screenshot, icon, code snippet, etc.]

TOOL TO FEATURE: repomix (yamadashy/repomix)
CONTEXT: It packs an entire repo into a single AI-friendly file before every session. Part of Phase 1 (Session Start) in awesome-agentic-stack.

SLIDES:
1. Attention-grabbing headline. No question format. State the benefit.
2. The problem it solves (1 sentence)
3. The key metric (star count, what it saves, install command)
4. Free tier status + why it survived the 386→96 audit
5. CTA: "96 tools like this at: [repo link]" + hashtags

TONE: Terminal aesthetic. Black background implied. Minimal text. Developer-native.
```

---

### PROMPT: Sprint 4 — Sub-List Evaluation

```
Evaluate whether awesome-agentic-stack should spin off a sub-list.

CONTEXT:
- Main list: 96 tools, 4 workflow phases
- Growing community with mobile/Android tool submissions
- Author runs on GT7 (Android 16) + M5 simultaneously

TASK: Write a decision framework for whether to create:
1. `awesome-agentic-stack-android` — Android/mobile-specific agentic coding tools
2. `awesome-agentic-stack-india` — tools with India-specific considerations (₹0, low bandwidth, free tier availability in India)
3. `awesome-agentic-stack-zero` — ₹0/free-tier-only subset as a standalone list

For each sub-list evaluate:
- Does it have enough tools to justify a separate repo? (minimum 30 unique entries)
- Does it serve a distinct audience not served by the main list?
- Does splitting dilute the main list or strengthen it?
- What's the SEO/discovery implication?

VERDICT: For each: Create now / Create at 200+ stars / Don't create + why.
```

---

## ##CLAUDE.md — DROP INTO PROJECT ROOT

> **Paste this file as `.claude/CLAUDE.md` in the `awesome-agentic-stack` repo root when running any agent on this project.**

```markdown
# CLAUDE.md — awesome-agentic-stack

## Identity
This repo is a curated GitHub awesome list. It is NOT a software project.
There is no code to build, no tests to run, no build pipeline.
The only files that matter: README.md, WORKFLOW.md, CONTRIBUTING.md, CHANGELOG.md, lists/rejected.md, lists/watching.md, .github/ workflows and templates.

## Owner
Akash Priyadarshi. Solo. Full control. No team. No approval chain.

## Stack
- All files: Markdown only
- GitHub Actions: YAML for link validation
- No npm, no pip, no Cargo, no build system

## Key Files
- `README.md` — Main list. Source of truth for all 96 tools.
- `WORKFLOW.md` — 4-phase dev loop. Most screenshot-able file.
- `lists/rejected.md` — 290 tools that didn't make the cut + reasons.
- `lists/watching.md` — Tools under evaluation, not yet confirmed.
- `CHANGELOG.md` — Monthly update log.
- `.github/workflows/validate_links.yml` — Link health check.

## Current State
Sprint 1: Building foundation files. No entries have been independently verified yet.
Star counts in source material are UNVERIFIED. Use ⭐ verify placeholder until confirmed via direct GitHub API or page visit.

## Constraints
- ₹0 budget. No paid APIs, no paid GitHub Actions minutes beyond free tier.
- Every tool listed must have free tier with zero CC/payment method required.
- Tools requiring CC for free tier get ⚠️ flag, not removal.
- Cross-IDE: covers Claude Code, Gemini CLI, OpenCode, Codex, Cursor, Antigravity IDE.

## Agent Rules
- NEVER rewrite README.md in full unless explicitly asked. Use targeted search-replace for edits.
- NEVER add a tool to README.md that has not been verified (at minimum: GitHub URL resolves, last commit date visible).
- NEVER change the workflow phase structure (Phase 0–4) without explicit instruction.
- NEVER add a tool to lists/rejected.md that is currently in README.md.
- NEVER output full file contents for a change that is under 20 lines — use diff/patch format.
- DO flag any tool entry where the "free tier" claim looks incorrect based on current GitHub/docs state.
- DO maintain the table format exactly: | [name](url) | ⭐ Stars | ✅/⚠️/❌ | Survival verdict |

## Anti-Patterns
- No "I've updated the README" summaries. Make the change, state the file path and line range.
- No unsolicited restructuring of sections.
- No adding tools not present in the source material or community Issues.
- No star count guessing. Every star count must be verified or shown as ⭐ verify.

## Content Standard
Survival verdicts must be: specific, one line, no filler.
BAD: "A great tool for managing tokens in Claude Code"
GOOD: "60–90% token reduction via Rust binary — fastest in category, zero deps"
```

---

*Bible version: 1.0.0 — May 2026*
*Next review: After Sprint 1 completion*
