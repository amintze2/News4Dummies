# Iteration 1 Plan

**Dates:** TBD
**Goal:** Prove the full ingestion pipeline end-to-end — a headline discovered in the app, opened in Safari, pushed back in via the iOS Shortcut, and readable inside the app. Nothing AI, nothing interactive yet.

**Why this slice:** The Shortcut round-trip is the single riskiest assumption in the PRD. Everything in Iteration 2 (Interactive Mode, AI Explain, Word Bank, study sets) is worthless if we can't reliably get full article text into the app. This iteration de-risks that first and leaves a genuinely usable reader behind.

## Requirements & Acceptance Criteria

### Requirement 1 — Name-Based Login

**Description:** On open, the user picks or types a name. All data in the app is scoped to that user. No password, no email.

- **Acceptance Criteria:**
  - [ ] First launch shows a name entry screen with "Anna" and "Lucy" as one-tap options plus a free-text field
  - [ ] Submitting a name creates the user row in Supabase if it doesn't exist, otherwise reuses it (case-insensitive match on name)
  - [ ] The chosen user persists across app restarts via `localStorage`
  - [ ] A "switch user" control exists in the app (settings or long-press on the tab bar) and clears the persisted user
  - [ ] Feed, My Articles, and Learn only ever show data belonging to the logged-in user
  - [ ] Reloading mid-session does not log the user out

### Requirement 2 — PWA Shell & Three-Tab Navigation

**Description:** An installable Progressive Web App with a bottom tab bar for What's New, My Articles, and Learn.

- **Acceptance Criteria:**
  - [ ] `manifest.json` with name, icons (192/512), `display: standalone`, and theme color
  - [ ] "Add to Home Screen" on iOS produces a full-screen app with no Safari chrome
  - [ ] Bottom tab bar with three tabs; the active tab is visually distinct
  - [ ] Tab state survives navigation (returning to a tab restores its scroll position)
  - [ ] Service worker registered; the app shell loads offline (article content may be empty offline)
  - [ ] Safe-area insets respected on iPhone (no content under the home indicator or notch)
  - [ ] Learn tab renders a placeholder "Coming in Iteration 2" state rather than erroring

### Requirement 3 — What's New Feed (RSS Aggregation)

**Description:** A scrollable feed of headlines and summaries aggregated from AP, Reuters, NPR, and BBC RSS.

- **Acceptance Criteria:**
  - [ ] A Supabase Edge Function fetches and parses all four RSS feeds server-side (browsers cannot fetch them directly — CORS)
  - [ ] Parsed items are cached in a `feed_items` table, deduplicated by GUID
  - [ ] Feed renders headline, source, summary, and relative publish time, sorted newest first
  - [ ] Tapping a headline opens the original article URL in Safari
  - [ ] Pull-to-refresh re-fetches; a stale cache is served instantly while the refresh runs
  - [ ] If one source fails, the other three still render (partial failure is not total failure)
  - [ ] Empty and loading states are designed, not blank screens
  - [ ] Feed items already ingested into My Articles are visually marked as saved

### Requirement 4 — Article Ingestion via iOS Shortcut

**Description:** An iOS Shortcut sends the current Safari article's text as JSON to an endpoint; the article appears in My Articles.

- **Acceptance Criteria:**
  - [ ] A Supabase Edge Function accepts `POST` with `{ ingestToken, title, url, source, author, publishedAt, text }`
  - [ ] Requests authenticate via a per-user ingest token; a bad or missing token returns 401
  - [ ] A valid request inserts into `articles` scoped to that token's user and returns 200 with the article id
  - [ ] Re-sending the same URL for the same user updates the existing row instead of duplicating it
  - [ ] Malformed JSON or missing `text` returns 400 with a readable error
  - [ ] The Shortcut `.shortcut` file (or setup instructions + screenshots) is committed to `docs/shortcut/`
  - [ ] Ingesting an article that exists in the feed marks that feed item as saved
  - [ ] Anna and Lucy have each successfully ingested at least one real article from each of the four sources

### Requirement 5 — My Articles Collection View

**Description:** A list of every article the user has full text for, most recently added first.

- **Acceptance Criteria:**
  - [ ] Renders the same article card component used in the What's New feed
  - [ ] Sorted by ingestion time, newest first
  - [ ] Only shows articles with non-empty full text
  - [ ] Tapping a card opens Reading Mode
  - [ ] Swipe-to-delete (or an explicit delete control) removes an article after a confirmation
  - [ ] Empty state explains how to add an article via the Shortcut
  - [ ] New articles appear without a manual refresh if the app is open (Supabase realtime or poll on focus)

### Requirement 6 — Reading Mode

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
users        (id uuid pk, name text unique citext, ingest_token text unique, created_at)
feed_items   (id uuid pk, guid text unique, source text, title text, summary text,
              url text, author text, published_at timestamptz, fetched_at)
articles     (id uuid pk, user_id fk, title text, url text, source text, author text,
              published_at timestamptz, body_text text, created_at,
              unique (user_id, url))
```

Iteration 2 adds `highlights`, `word_bank`, `study_sets`, `cards`, `tags`, `article_tags`. We are **not** creating those tables yet, but `articles.id` is the foreign key everything in Iteration 2 will hang off — treat it as stable.

### API Contracts

**Feed refresh** — `GET /functions/v1/feed`
Returns `{ items: FeedItem[] }`, newest first, max 100. Refreshes from source if the cache is older than 15 minutes.

**Ingest** — `POST /functions/v1/ingest`

```json
{
  "ingestToken": "string (required)",
  "title": "string (required)",
  "url": "string (required)",
  "source": "string | null",
  "author": "string | null",
  "publishedAt": "ISO 8601 string | null",
  "text": "string (required, non-empty)"
}
```

Returns `201 { "articleId": "uuid" }` on create, `200 { "articleId": "uuid" }` on update of an existing URL.

### Security Decision (read this one)

The PRD asks for name-only login **and** "#no data leaks". Those are in tension. Our decision for Iteration 1:

- Name-only login is **not authentication**. Anyone who knows the app URL can pick any name and see that user's articles.
- The ingest token *is* a real secret — it's the only thing standing between the endpoint and the open internet. It lives in the Shortcut on each phone, never in the client bundle, and never in git.
- Row Level Security is enabled on all tables, but the anon-key policies are permissive by necessity given there's no real auth.
- **Acceptable because** the user set is two people and the content is public news articles. If we ever add a third-party user or store anything personal, this must be revisited before that happens. Noted here so we don't forget we made this trade deliberately.

### Responsibilities

| Area | Owner |
|---|---|
| Supabase schema, Edge Functions (feed + ingest), iOS Shortcut | @annamintzer |
| PWA shell, tab navigation, article card component, Reading Mode | @lucy |
| Name login, My Articles collection view | pair |

Handles above are placeholders — confirm Lucy's actual GitHub username before creating issues.

### Dependencies

- **R2 (shell) blocks R3, R5, R6** — nothing renders without the tab shell. Build it first.
- **R3 and R4 share the article card component.** Lucy owns the component; it must land before either feed or collection view is finished. Agree on its props early: `{ title, source, author, publishedAt, summary?, isSaved }`.
- **R4 blocks R5 and R6** — no ingested articles means nothing to read. Ship a seed script that inserts two hardcoded articles so reading UI work isn't blocked waiting on the Shortcut.
- Supabase project must be provisioned and keys shared before any backend work starts.

### Open Questions

- Does the iOS Shortcut reliably extract full body text from all four sources, or does Safari's Reader-mode extraction fail on some? **Test this in the first two days** — if it fails, R4's acceptance criteria change.
- Reuters' public RSS has been unreliable; if it's dead, we substitute or drop to three sources and note it.

## Task Breakdown

| # | Task | Type | Assignee(s) | Requirement |
|---|---|---|---|---|
| 1 | Provision Supabase project, create Iteration 1 schema + RLS policies | task | @annamintzer | R1, R3, R4 |
| 2 | Scaffold Vite + React + TS + Tailwind + shadcn, deploy to GitHub Pages | task | @lucy | R2 |
| 3 | PWA manifest, icons, service worker, iOS safe-area handling | feature | @lucy | R2 |
| 4 | Bottom tab bar navigation with three tabs and route persistence | feature | @lucy | R2 |
| 5 | Name login screen, user create-or-reuse, localStorage session, switch user | feature | pair | R1 |
| 6 | Edge Function: RSS fetch + parse + cache for AP, Reuters, NPR, BBC | feature | @annamintzer | R3 |
| 7 | Shared article card component | task | @lucy | R3, R5 |
| 8 | What's New feed: list, pull-to-refresh, open in Safari, empty/loading states | feature | @lucy | R3 |
| 9 | Edge Function: article ingest endpoint with token auth and upsert | feature | @annamintzer | R4 |
| 10 | iOS Shortcut build, test against all four sources, commit to `docs/shortcut/` | task | @annamintzer | R4 |
| 11 | Seed script for sample articles (unblocks reading UI) | task | @annamintzer | R5, R6 |
| 12 | My Articles collection view with delete and empty state | feature | pair | R5 |
| 13 | Reading Mode: typography, scroll restore, top panel, original-article link | feature | @lucy | R6 |

Issue numbers to be filled in once the issues are created.

## Definition of Done for Iteration 1

Anna and Lucy can each install the PWA on their phone, browse a live news feed, tap a headline, run the Shortcut from Safari, return to the app, and read the full article inside it.
