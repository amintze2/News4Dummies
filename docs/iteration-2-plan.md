# Iteration 2 Plan

**Dates:** TBD
**Goal:** Connect the pipe and make the text interactive. Get real articles into the app via the iOS Shortcut, then let the reader highlight a phrase, ask AI about it, save what they learn, and get it back as a flashcard when it's due.

**Depends on:** All of Iteration 1 shipped. Reading Mode, the `articles` table, and the shared `createArticle` insert path are the foundations everything here attaches to.

> **This iteration is overloaded.** Eight requirements, including the riskiest thing in the product (Shortcut ingestion, moved here from Iteration 1) and the two hardest to build (touch selection on mobile Safari, FSRS). Read the Risks section before committing to all of it.

## Requirements & Acceptance Criteria

### Requirement 7 — Article Ingestion via iOS Shortcut

**Description:** An iOS Shortcut sends the current Safari article's text as JSON to an endpoint; the article appears in My Articles. Moved from Iteration 1 — this is the highest-risk requirement in the plan and the one everything else assumed was already done.

- **Acceptance Criteria:**
  - [ ] A Supabase Edge Function accepts `POST` with `{ ingestToken, title, url, source, author, publishedAt, text }`
  - [ ] The endpoint is a thin wrapper over Iteration 1's shared `createArticle` function, not a second insert implementation
  - [ ] Requests authenticate via a per-user ingest token (`users.ingest_token`); a bad or missing token returns 401
  - [ ] A valid request returns 201 with the article id on create, 200 on update of an existing URL
  - [ ] Re-sending the same URL for the same user updates the existing row instead of duplicating it
  - [ ] Malformed JSON or missing `text` returns 400 with a readable error
  - [ ] The Shortcut `.shortcut` file (or setup instructions + screenshots) is committed to `docs/shortcut/`
  - [ ] Ingesting an article that exists in the feed marks that feed item as saved
  - [ ] Anna and Lucy have each successfully ingested a real article from all four sources
  - [ ] Iteration 1's dev-only paste form is removed once this ships

### Requirement 8 — Interactive Mode

**Description:** In Reading Mode, a top-panel button freezes the article and lets the user drag a finger across text to select it.

- **Acceptance Criteria:**
  - [ ] The Interactive Mode button in the top panel (placeholder from Iteration 1) is now live
  - [ ] Entering Interactive Mode freezes scrolling — the article does not move while a drag is in progress
  - [ ] Dragging across text highlights that range with a visible background color
  - [ ] The selected range can be adjusted or cleared by tapping elsewhere
  - [ ] The Interactive Mode button becomes an "✕" that exits back to normal scrolling
  - [ ] Exiting clears any active selection
  - [ ] A selection surfaces an action bar with three options: **AI Explain**, **AI Chat**, **Add to Study Set**
  - [ ] Selections spanning multiple paragraphs are captured correctly
  - [ ] Highlights persist to `highlights` and reappear when the article is reopened

### Requirement 9 — AI Explain

**Description:** With text selected, AI Explain returns a plain-language explanation of the term or phrase.

- **Acceptance Criteria:**
  - [ ] Tapping AI Explain sends the selected text plus surrounding article context to the model
  - [ ] A system prompt instructs the model to explain in plain language for a reader who does not know the term
  - [ ] The explanation appears in a bottom sheet without leaving the article
  - [ ] Response streams in rather than appearing all at once after a wait
  - [ ] The API key is never exposed in the client bundle — calls proxy through a Supabase Edge Function
  - [ ] API errors and timeouts show a readable message with a retry, not a silent failure or a spinner forever
  - [ ] The explanation can be saved to the Word Bank from the sheet
  - [ ] Median response starts within 2 seconds

### Requirement 10 — AI Chat

**Description:** With text selected, AI Chat opens a conversation scoped to that phrase.

- **Acceptance Criteria:**
  - [ ] Opens a chat window seeded with the selected phrase and its article context
  - [ ] Multi-turn conversation with visible user/assistant message distinction
  - [ ] Responses stream token by token
  - [ ] Conversation history persists for the session; closing and reopening the same selection resumes it
  - [ ] The article stays reachable — closing chat returns to the same scroll position with the selection intact
  - [ ] Long responses scroll within the chat window without breaking the layout
  - [ ] Model errors surface as a message in the thread, not a crash

### Requirement 11 — Double-Tap Define & Word Bank

**Description:** Double-tapping any word in Reading Mode defines it; every defined word is saved and browsable in Learn.

- **Acceptance Criteria:**
  - [ ] Double-tapping a single word in Reading Mode (not only Interactive Mode) triggers Define
  - [ ] The definition appears in the same bottom sheet used by AI Explain
  - [ ] Every defined word is written to `word_bank` with the term, definition, and source article
  - [ ] Defining a word already in the bank does not duplicate it
  - [ ] The Learn tab has a Word Bank section listing all defined words, newest first
  - [ ] Each entry links back to the article it came from
  - [ ] Word Bank entries can be deleted
  - [ ] A Word Bank entry can be promoted into a study set as a card

### Requirement 12 — Study Sets

**Description:** Selected text can be added as a card to a new or existing study set.

- **Acceptance Criteria:**
  - [ ] "Add to Study Set" opens a dropdown listing all of the user's existing study sets plus "Create a new study set"
  - [ ] Choosing an existing set adds the selected text as a card and confirms with a toast
  - [ ] "Create a new study set" opens a modal for the set name
  - [ ] Submitting creates the set with the selected text as its first card
  - [ ] Card creation captures the source article id so cards trace back to their origin
  - [ ] Study sets are listed in the Learn tab with a card count
  - [ ] A study set can be renamed and deleted (deleting warns about card loss)
  - [ ] Cards can be edited (front/back) and deleted individually

### Requirement 13 — Learn: FSRS Flashcard Review

**Description:** Review study set cards on an FSRS schedule, like Anki or Quizlet.

- **Acceptance Criteria:**
  - [ ] FSRS scheduling integrated from `open-spaced-repetition/fsrs4anki` (or the `ts-fsrs` port)
  - [ ] Review session shows the card front; tapping reveals the back
  - [ ] Four rating buttons: Again, Hard, Good, Easy
  - [ ] Each rating updates the card's FSRS state (stability, difficulty, due date, reps, lapses) and persists it
  - [ ] Only cards due today enter the session
  - [ ] The Learn tab shows a due count per study set
  - [ ] A session with nothing due shows a "nothing due" state, not an empty review screen
  - [ ] Session progress (n of m) is visible during review
  - [ ] Ratings survive a mid-session app close — the card's state is written on each rating, not at session end

### Requirement 14 — Custom Tags & Filtering

**Description:** Tag articles in My Articles and filter the collection by tag, source, or author.

- **Acceptance Criteria:**
  - [ ] A tag can be added to an article from the collection view or Reading Mode
  - [ ] Tag input autocompletes against the user's existing tags
  - [ ] An article can carry multiple tags; tags can be removed
  - [ ] My Articles has a filter control for tag, source, and author
  - [ ] Filters combine (e.g. source = NPR **and** tag = "climate")
  - [ ] The active filter is visible and clearable in one tap
  - [ ] A filter matching nothing shows an empty state naming the active filter
  - [ ] Tags are scoped per user

## Coordination & Design Decisions

### Schema Changes

```sql
alter table users add column ingest_token text unique;

tags          (id uuid pk, user_id fk, name text, unique (user_id, name))
article_tags  (article_id fk, tag_id fk, primary key (article_id, tag_id))
highlights    (id uuid pk, article_id fk, user_id fk, selected_text text,
               start_offset int, end_offset int, created_at)
word_bank     (id uuid pk, user_id fk, term text, definition text,
               article_id fk null, created_at, unique (user_id, lower(term)))
study_sets    (id uuid pk, user_id fk, name text, created_at)
cards         (id uuid pk, study_set_id fk, front text, back text,
               source_article_id fk null, fsrs_state jsonb, due timestamptz, created_at)
reviews       (id uuid pk, card_id fk, rating smallint, reviewed_at)
```

`cards.fsrs_state` holds the FSRS object verbatim (`stability`, `difficulty`, `reps`, `lapses`, `state`, `last_review`). `due` is denormalized out of it into its own column so "what's due today" is a single indexed query rather than a JSON scan.

### Ingest Endpoint — reuse, don't reimplement

Iteration 1 built `createArticle()` and used it from the seed script and the dev paste form. R7 is authentication and validation wrapped around that same function. If the endpoint ends up with its own normalization or its own upsert logic, that's a bug: highlights anchor to character offsets in `body_text`, and two insert paths that normalize differently will silently misalign every highlight on a re-ingested article.

The ingest token is the only real secret in the system — it's the sole barrier between the endpoint and the open internet. It lives in the Shortcut on each phone, never in the client bundle, never in git.

### Text Offsets — decide this before R8 starts

Highlights need to survive reopening an article, which means anchoring selections to stable positions in `articles.body_text`. **Decision:** store character offsets into the normalized `body_text` string, normalized exactly once at insert (Iteration 1's `createArticle` already does this). Do not anchor to DOM nodes — any change to the render layer invalidates every stored highlight. If the same article is re-ingested with different text, its highlights are dropped rather than silently misaligned.

### AI Proxy Contract

All model calls go through one Edge Function so keys stay server-side.

**`POST /functions/v1/ai`**

```json
{
  "mode": "explain" | "define" | "chat",
  "selectedText": "string",
  "articleContext": "string (surrounding paragraphs, truncated)",
  "messages": "Message[] (chat mode only)"
}
```

Returns a streaming response (SSE). Model routing: **Gemini Flash Lite** for `define` and `explain` (short, high volume, latency-sensitive), **Claude** for `chat` (multi-turn quality). Per the PRD's stack — one decision to confirm: if Flash Lite's explanations read poorly in practice, move `explain` to Claude and accept the cost.

The system prompt lives server-side in a single module so it can be tuned without a client deploy. This also sets up the nice-to-have of user-customizable prompts later.

### Cost & Rate Limiting

Two users won't generate meaningful cost, but the AI endpoint is public and token-authenticated the same way as ingest. Add a per-user rate limit (e.g. 60 calls/hour) so a runaway loop or a leaked token can't run up a bill.

### Responsibilities

| Area | Owner |
|---|---|
| Ingest endpoint, iOS Shortcut | @annamintzer |
| Interactive Mode selection engine, offset anchoring, highlights | @lucy |
| AI proxy Edge Function, model routing, streaming, rate limiting | @annamintzer |
| AI Explain + Define bottom sheet, Word Bank UI | @lucy |
| AI Chat window | @annamintzer |
| Study sets, cards, FSRS integration, review session | @annamintzer |
| Tags and filtering | @lucy |

### Dependencies

- **R7 blocks realistic testing of everything else.** Interactive Mode and the AI features can be built against Iteration 1's seeded articles, but none of it is validated on real ingested text until R7 lands. Ship R7 in week 1.
- **R8 blocks R9, R10, and R12** — no selection means no AI actions and no "add to study set". Selection is the critical path.
- **R9 and R11 share the bottom sheet component.** One component, two entry points. Build it once with R9.
- **R12 blocks R13** — no study sets means nothing to review. Ship a seed set of hardcoded cards so FSRS work can start in parallel.
- **R14 is independent of everything else here.** It touches only My Articles and is the natural cut line if the iteration runs long.

### Risks

- **Eight requirements and 18 tasks against Iteration 1's six and 14.** This is not a balanced split, and it got worse when ingestion moved here. If Iteration 1 finishes early, pull R7 forward into it. If this iteration runs long, cut in this order: **R14 (tags)** first, **R10 (AI Chat)** second, **R11's Word Bank UI** third — Explain and Define deliver most of the reading-comprehension value on their own.
- **R7's real risk is the Shortcut, not the endpoint.** The endpoint is a day's work; whether Safari can reliably hand us clean body text from AP, Reuters, NPR, and BBC is the open question. Iteration 1's task 13 spike should have answered this — **if that spike was skipped, do it before anything else in this iteration.**
- **Touch selection on iOS Safari is genuinely fiddly.** Native selection UI will fight a custom implementation. Spike this in the first two days; if a custom drag handler proves unworkable, fall back to hooking the native `selectionchange` event and rendering our own action bar over it.
- **Streaming through a Supabase Edge Function** needs to be verified early — confirm SSE passes through cleanly before building two features on top of it.

## Task Breakdown

| # | Task | Type | Assignee(s) | Requirement |
|---|---|---|---|---|
| 15 | Schema migration: `users.ingest_token`, tags, highlights, word_bank, study_sets, cards, reviews | task | @annamintzer | R7, R11–R14 |
| 16 | Edge Function: ingest endpoint wrapping `createArticle`, with token auth | feature | @annamintzer | R7 |
| 17 | iOS Shortcut build, test against all four sources, commit to `docs/shortcut/` | task | @annamintzer | R7 |
| 18 | Remove the Iteration 1 dev paste form | task | @annamintzer | R7 |
| 19 | Spike: touch text selection on iOS Safari, pick the approach | task | @lucy | R8 |
| 20 | Interactive Mode: enter/exit, scroll freeze, drag selection, action bar | feature | @lucy | R8 |
| 21 | Highlight offset anchoring and persistence | feature | @lucy | R8 |
| 22 | AI proxy Edge Function: routing, streaming, system prompts, rate limiting | feature | @annamintzer | R9, R10, R11 |
| 23 | Bottom sheet component with streaming response rendering | feature | @lucy | R9, R11 |
| 24 | AI Explain wiring and error/retry states | feature | @lucy | R9 |
| 25 | AI Chat window: multi-turn, streaming, session persistence | feature | @annamintzer | R10 |
| 26 | Double-tap Define gesture in Reading Mode | feature | @lucy | R11 |
| 27 | Word Bank section in Learn: list, delete, link to article, promote to card | feature | @lucy | R11 |
| 28 | Add to Study Set: dropdown, create-new modal, card creation | feature | @annamintzer | R12 |
| 29 | Study set management in Learn: list, rename, delete, edit cards | feature | @annamintzer | R12 |
| 30 | FSRS integration and card scheduling state | feature | @annamintzer | R13 |
| 31 | Review session UI: reveal, four ratings, progress, due counts | feature | @annamintzer | R13 |
| 32 | Tags: add, autocomplete, remove, per-article display | feature | @lucy | R14 |
| 33 | My Articles filtering by tag, source, and author | feature | @lucy | R14 |

Issue numbers to be filled in once the issues are created.

## Definition of Done for Iteration 2

Anna taps a headline in the feed, runs the Shortcut from Safari, returns to the app and reads the article. She hits a term she doesn't know, double-taps it for a definition, highlights the surrounding sentence and asks the AI to explain it, adds it to a study set — and the next day the Learn tab tells her that card is due.

## Deferred to Iteration 3+

From the PRD's nice-to-haves, explicitly not in scope here: source avatars, in-app article scraping, AI auto-tagging, AI-generated multiple choice, mind maps, article audio playback, export to Notebook LM, user-customizable system prompts.
