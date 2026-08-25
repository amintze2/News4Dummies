# Iteration 1 Plan

**Dates:** TBD
**Goal:** Build the whole reading experience on seeded content — login, feed, collection, and a real Reading Mode — so that Iteration 2 only has to connect the pipe and make the text interactive.

**Scope note:** iOS Shortcut ingestion was deliberately moved to Iteration 2 (see Risks). Iteration 1 therefore gets article text in through a seed script and a dev-only paste form, both of which write through the same insert path the Iteration 2 ingest endpoint will use.

## Requirements & Acceptance Criteria

### Requirement 1 — Name-Based Login (#7)

**Description:** On open, the user picks or types a name. All data in the app is scoped to that user. No password, no email.

- **Acceptance Criteria:**
  - [ ] First launch shows a name entry screen with "Anna" and "Lucy" as one-tap options plus a free-text field
  - [ ] Submitting a name creates the user row in Supabase if it doesn't exist, otherwise reuses it (case-insensitive match on name)
  - [ ] The chosen user persists across app restarts via `localStorage`
  - [ ] A "switch user" control exists in the app (settings or long-press on the tab bar) and clears the persisted user
  - [ ] Feed, My Articles, and Learn only ever show data belonging to the logged-in user
  - [ ] Reloading mid-session does not log the user out

### Requirement 2 — PWA Shell & Three-Tab Navigation (#8)

**Description:** An installable Progressive Web App with a bottom tab bar for What's New, My Articles, and Learn.

- **Acceptance Criteria:**
  - [ ] `manifest.json` with name, icons (192/512), `display: standalone`, and theme color
  - [ ] "Add to Home Screen" on iOS produces a full-screen app with no Safari chrome
  - [ ] Bottom tab bar with three tabs; the active tab is visually distinct
  - [ ] Tab state survives navigation (returning to a tab restores its scroll position)
  - [ ] Service worker registered; the app shell loads offline (article content may be empty offline)
  - [ ] Safe-area insets respected on iPhone (no content under the home indicator or notch)
  - [ ] Learn tab renders a placeholder "Coming in Iteration 2" state rather than erroring

### Requirement 3 — What's New Feed (RSS Aggregation) (#9)

**Description:** A scrollable feed of headlines and summaries aggregated from AP, Reuters, NPR, and BBC RSS.

- **Acceptance Criteria:**
  - [ ] A Supabase Edge Function fetches and parses all four RSS feeds server-side (browsers cannot fetch them directly — CORS)
  - [ ] Parsed items are cached in a `feed_items` table, deduplicated by GUID
  - [ ] Feed renders headline, source, summary, and relative publish time, sorted newest first
  - [ ] Tapping a headline opens the original article URL in Safari
  - [ ] Pull-to-refresh re-fetches; a stale cache is served instantly while the refresh runs
  - [ ] If one source fails, the other three still render (partial failure is not total failure)
  - [ ] Empty and loading states are designed, not blank screens
  - [ ] Feed items whose URL already exists in My Articles are visually marked as saved

### Requirement 4 — Article Loading (Seed Script & Dev Paste Form) (#10)

**Description:** With Shortcut ingestion deferred to Iteration 2, Iteration 1 still needs real article text in the database so My Articles and Reading Mode can be built, tested, and demoed. Two paths: a repeatable seed script, and a temporary in-app form that accepts pasted text.

**Not scraping.** Neither path fetches or parses pages from AP/Reuters/NPR/BBC programmatically. Seed content is hand-curated: Anna and Lucy each read an article normally in their browser, copy the text (same personal, non-commercial use the Shortcut performs in Iteration 2), and save it into a local fixture file the seed script inserts verbatim. This matters because AP and Reuters both restrict automated reproduction of their content in their terms of service, and because "in-app article scraping" is explicitly deferred out of scope for this product (see Iteration 2's deferred list) — a scraping seed script would quietly build the deferred feature under a different name.

- **Acceptance Criteria:**
  - [ ] A fixture file (`seed/articles.json` or similar) holds six hand-curated real articles spanning all four sources, including at least one over 3,000 words and one under 400, copied by hand from pages actually read in-browser — not fetched by any script
  - [ ] The seed script only reads that fixture and inserts it; it makes no outbound HTTP requests to AP/Reuters/NPR/BBC
  - [ ] Seeded articles are attributed to a named user, so per-user scoping is genuinely exercised
  - [ ] Re-running the seed script is idempotent — no duplicate rows
  - [ ] A dev-only "Add article" form accepts title, URL, source, author, publish date, and pasted body text
  - [ ] Submitting the form creates an `articles` row identical in shape to one the Iteration 2 Shortcut will create
  - [ ] Both paths write through a single shared insert function, so the Iteration 2 ingest endpoint is a thin wrapper over it rather than a second implementation
  - [ ] The form is reachable but clearly marked as temporary — it is removed or hidden once R7 ships in Iteration 2
  - [ ] Pasted and seeded articles are indistinguishable to the rest of the app

### Requirement 5 — My Articles Collection View (#11)

**Description:** A list of every article the user has full text for, most recently added first.

- **Acceptance Criteria:**
  - [ ] Renders the same article card component used in the What's New feed
  - [ ] Sorted by ingestion time, newest first
  - [ ] Only shows articles with non-empty full text
  - [ ] Tapping a card opens Reading Mode
  - [ ] Swipe-to-delete (or an explicit delete control) removes an article after a confirmation
  - [ ] Empty state points the user at the dev "Add article" form (rewritten to describe the Shortcut once Iteration 2 ships)
  - [ ] New articles appear without a manual refresh if the app is open (Supabase realtime or poll on focus)

### Requirement 6 — Reading Mode (#12)

**Description:** Read the full article text inside the app, in a clean typographic layout.

- **Acceptance Criteria:**
  - [ ] Displays title, source, author, publish date, and full body text
  - [ ] Body text is paragraph-segmented and readable — measured line length, comfortable line height, no wall of text
  - [ ] Scrolls smoothly through a 3,000+ word article
  - [ ] Top panel has a back control and a disabled/placeholder Interactive Mode button (wired up in Iteration 2)
  - [ ] A link to the original article on the source's site
  - [ ] Scroll position is remembered when leaving and returning to the same article
  - [ ] Renders correctly in both portrait and landscape

## Coordination & Design Decisions

### Architecture

- **Frontend:** React + Vite + TypeScript, shadcn/ui, Tailwind. PWA via `vite-plugin-pwa`.
- **Backend:** Supabase (Postgres + Edge Functions). No custom server.
- **Hosting:** GitHub Pages from the `main` branch build output.
- **Routing:** Client-side, three top-level tab routes plus `/article/:id`.

### Data Model (Iteration 1 tables)

```sql
users        (id uuid pk, name text unique citext, created_at)
feed_items   (id uuid pk, guid text unique, source text, title text, summary text,
              url text, author text, published_at timestamptz, fetched_at)
articles     (id uuid pk, user_id fk, title text, url text, source text, author text,
              published_at timestamptz, body_text text, created_at,
              unique (user_id, url))
```

Iteration 2 adds `users.ingest_token` plus `highlights`, `word_bank`, `study_sets`, `cards`, `reviews`, `tags`, and `article_tags`. We are **not** creating those yet, but `articles.id` is the foreign key everything in Iteration 2 hangs off — treat it as stable.

### The Shared Insert Path (matters for Iteration 2)

The seed script and the dev paste form must both call one `createArticle({ userId, title, url, source, author, publishedAt, bodyText })` function that owns normalization and the upsert-on-duplicate-URL behavior. Iteration 2's ingest endpoint then becomes auth + validation wrapped around this same function.

Body text normalization happens **here, once**, at insert. Iteration 2 anchors highlights to character offsets in the stored `body_text`, so this normalization is effectively a stable contract from now on — changing it later invalidates stored highlights.

### Security & Content Decisions (read this one)

The PRD asks for name-only login **and** "#no data leaks". Those are in tension. Our decision for Iteration 1:

- Name-only login is **not authentication**. Anyone who knows the app URL can pick any name and see that user's articles.
- Row Level Security is enabled on all tables, but the anon-key policies are permissive by necessity given there's no real auth.
- The dev paste form is unauthenticated and writes to the database. It is acceptable only because it is temporary and the deployment is effectively unknown to anyone but us — it must be removed when Iteration 2's real ingest endpoint lands, not left in place.
- **Acceptable because** the user set is two people and the content is public news articles. If we ever add a third-party user or store anything personal, this must be revisited before that happens. Noted here so we don't forget we made this trade deliberately.

On content: publicly accessible is not the same as freely reproducible. RSS aggregation (R3) is fine — these outlets publish RSS specifically to be aggregated, and it carries only headline/summary/link, never full text. Seed data (R4) is different: it needs full article bodies, and getting those by writing a script that fetches and parses AP/Reuters/NPR/BBC pages would be scraping their sites' content wholesale, which their terms of service restrict (AP and Reuters especially) — and would just be the deferred "in-app scraping" feature built early under a different name. R4's fixture file is hand-copied from articles read normally in-browser instead, for exactly the reason the Shortcut model works in Iteration 2: a human reading one article at a time and choosing to save it is a different act, legally and ethically, from a server bulk-fetching a publisher's content.

### Responsibilities

Split by feature issue, chosen for an even-ish mix of backend and frontend work on each side rather than grouping all backend work with one person:

| Feature | Owner | Supporting |
|---|---|---|
| R1 Name-Based Login (#7) | @amintze2 | @lmalmud |
| R2 PWA Shell & Navigation (#8) | @amintze2 | @lmalmud |
| R3 What's New Feed (#9) | @lmalmud | @amintze2 |
| R4 Article Loading (#10) | @amintze2 | @lmalmud |
| R5 My Articles Collection View (#11) | @lmalmud | @amintze2 |
| R6 Reading Mode (#12) | @lmalmud | @amintze2 |

Anna's set (R1, R2, R4) pairs a small mixed feature, a frontend-heavy one, and a backend-heavy one. Lucy's set (R3, R5, R6) is anchored by R3's real backend work (the RSS Edge Function) alongside two frontend-heavier features. Individual task assignees within each feature follow whoever's doing that specific piece of work — see the Task Breakdown table — and don't always match the feature owner.

### Dependencies

- **R2 (shell) blocks R3, R5, R6** — nothing renders without the tab shell. Build it first.
- **R3 and R5 share the article card component.** Lucy owns the component; it must land before either feed or collection view is finished. Agree on its props early: `{ title, source, author, publishedAt, summary?, isSaved }`.
- **R4 blocks R5 and R6** — no articles means nothing to list or read. The seed script is the first half of R4 and should land in week 1, ahead of the paste form.
- Supabase project must be provisioned and keys shared before any backend work starts.

### Risks

- **Iteration 1 can no longer demo the product's core loop.** With ingestion in Iteration 2, nothing in this iteration proves that a real article can get from Safari into the app — the thing everything else depends on. We're mitigating rather than accepting: task 13 spikes Safari text extraction across all four sources during this iteration, so if it doesn't work we learn it now instead of in Iteration 2 week 1.
- **Iteration 2 is now carrying eight requirements** including the riskiest one. Iteration 1 has slack; if it finishes early, pull R7 (ingestion) forward rather than starting Interactive Mode.
- **The dev paste form is throwaway code** that touches the database. Budget for deleting it, and don't let anything else grow a dependency on it.
- Reuters' public RSS has been unreliable; if it's dead, we substitute or drop to three sources and note it.

## Task Breakdown

| # | Issue | Task | Type | Assignee(s) | Requirement | Parent |
|---|---|---|---|---|---|---|
| 1 | #13 | Provision Supabase project, create Iteration 1 schema + RLS policies | task | @amintze2 | R1, R3, R4 | #7 |
| 2 | #14 | Scaffold Vite + React + TS + Tailwind + shadcn, deploy to GitHub Pages | task | @lmalmud | R2 | #8 |
| 3 | #15 | PWA manifest, icons, service worker, iOS safe-area handling | task | @lmalmud | R2 | #8 |
| 4 | #16 | Bottom tab bar navigation with three tabs and route persistence | task | @lmalmud | R2 | #8 |
| 5 | #17 | Name login screen, user create-or-reuse, localStorage session, switch user | task | @amintze2, @lmalmud | R1 | #7 |
| 6 | #18 | Edge Function: RSS fetch + parse + cache for AP, Reuters, NPR, BBC | task | @amintze2 | R3 | #9 |
| 7 | #19 | Shared article card component | task | @lmalmud | R3, R5 | #9 |
| 8 | #20 | What's New feed: list, pull-to-refresh, open in Safari, empty/loading states | task | @lmalmud | R3 | #9 |
| 9 | #21 | Shared `createArticle` insert path with normalization and URL upsert | task | @amintze2 | R4 | #10 |
| 10 | #22 | Curate fixture file (hand-copied, not fetched) + seed script to insert it, idempotent | task | @amintze2 | R4 | #10 |
| 11 | #23 | Dev-only "Add article" paste form | task | @amintze2, @lmalmud | R4 | #10 |
| 12 | #24 | My Articles collection view with delete and empty state | task | @lmalmud, @amintze2 | R5 | #11 |
| 13 | #25 | Spike: can an iOS Shortcut extract full body text from all four sources? | task | @amintze2 | R4, de-risks I2 | #10 |
| 14 | #26 | Reading Mode: typography, scroll restore, top panel, original-article link | task | @lmalmud | R6 | #12 |

All 6 requirements are tracked as feature issues (#7–#12) with these 14 tasks linked as GitHub sub-issues. Milestone: Iteration 1.

## Definition of Done for Iteration 1

Anna and Lucy each install the PWA on their phone, browse a live news feed, and read a seeded full-length article inside the app in a Reading Mode that's genuinely pleasant. The Shortcut extraction spike has a written yes-or-no answer.
