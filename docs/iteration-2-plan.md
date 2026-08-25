# Iteration 2 Plan

**Dates:** TBD
**Goal:** Turn the reader into the product. Make the article interactive — highlight text, ask AI about it, save what you learn — and close the loop with an FSRS-backed Learn tab.

**Depends on:** All of Iteration 1 shipped. Reading Mode and the `articles` table are the foundation everything here attaches to.

## Requirements & Acceptance Criteria

### Requirement 7 — Interactive Mode

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

### Requirement 8 — AI Explain

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

### Requirement 9 — AI Chat

**Description:** With text selected, AI Chat opens a conversation scoped to that phrase.

- **Acceptance Criteria:**
  - [ ] Opens a chat window seeded with the selected phrase and its article context
  - [ ] Multi-turn conversation with visible user/assistant message distinction
  - [ ] Responses stream token by token
  - [ ] Conversation history persists for the session; closing and reopening the same selection resumes it
  - [ ] The article stays reachable — closing chat returns to the same scroll position with the selection intact
  - [ ] Long responses scroll within the chat window without breaking the layout
  - [ ] Model errors surface as a message in the thread, not a crash

### Requirement 10 — Double-Tap Define & Word Bank

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

### Requirement 11 — Study Sets

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

### Requirement 12 — Learn: FSRS Flashcard Review

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

### Requirement 13 — Custom Tags & Filtering

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

### New Tables

```sql
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

### Text Offsets — decide this before R7 starts

Highlights need to survive reopening an article, which means anchoring selections to stable positions in `articles.body_text`. **Decision:** store character offsets into the normalized `body_text` string, and normalize that text exactly once at ingest (Iteration 1 already stores it). Do not anchor to DOM nodes — any change to the render layer invalidates every stored highlight. If the same article is re-ingested with different text, its highlights are dropped rather than silently misaligned.

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
| Interactive Mode selection engine, offset anchoring, highlights | @lucy |
| AI proxy Edge Function, model routing, streaming, rate limiting | @annamintzer |
| AI Explain + Define bottom sheet, Word Bank UI | @lucy |
| AI Chat window | @annamintzer |
| Study sets, cards, FSRS integration, review session | @annamintzer |
| Tags and filtering | @lucy |

### Dependencies

- **R7 blocks R8, R9, and R11** — no selection means no AI actions and no "add to study set". Selection is the critical path; build it first, in week 1.
- **R8 and R10 share the bottom sheet component.** One component, two entry points. Build it once with R8.
- **R11 blocks R12** — no study sets means nothing to review. Ship a seed set of hardcoded cards so FSRS work can start in parallel.
- **R13 is independent of everything else here.** It touches only My Articles and is the natural cut line if the iteration runs long.

### Risks

- **This iteration is heavier than Iteration 1.** Seven requirements, and the two hardest things in the whole product (touch selection on mobile Safari, FSRS) are both in it. If something has to give, drop **R13 (tags)** first and **R9 (AI Chat)** second — Explain and Define deliver most of the reading-comprehension value on their own.
- **Touch selection on iOS Safari is genuinely fiddly.** Native selection UI will fight a custom implementation. Spike this in the first two days; if a custom drag handler proves unworkable, fall back to hooking the native `selectionchange` event and rendering our own action bar over it.
- **Streaming through a Supabase Edge Function** needs to be verified early — confirm SSE passes through cleanly before building two features on top of it.

## Task Breakdown

| # | Task | Type | Assignee(s) | Requirement |
|---|---|---|---|---|
| 14 | Iteration 2 schema migration: tags, highlights, word_bank, study_sets, cards, reviews | task | @annamintzer | R7, R10, R11, R12, R13 |
| 15 | Spike: touch text selection on iOS Safari, pick the approach | task | @lucy | R7 |
| 16 | Interactive Mode: enter/exit, scroll freeze, drag selection, action bar | feature | @lucy | R7 |
| 17 | Highlight offset anchoring and persistence | feature | @lucy | R7 |
| 18 | AI proxy Edge Function: routing, streaming, system prompts, rate limiting | feature | @annamintzer | R8, R9, R10 |
| 19 | Bottom sheet component with streaming response rendering | feature | @lucy | R8, R10 |
| 20 | AI Explain wiring and error/retry states | feature | @lucy | R8 |
| 21 | AI Chat window: multi-turn, streaming, session persistence | feature | @annamintzer | R9 |
| 22 | Double-tap Define gesture in Reading Mode | feature | @lucy | R10 |
| 23 | Word Bank section in Learn: list, delete, link to article, promote to card | feature | @lucy | R10 |
| 24 | Add to Study Set: dropdown, create-new modal, card creation | feature | @annamintzer | R11 |
| 25 | Study set management in Learn: list, rename, delete, edit cards | feature | @annamintzer | R11 |
| 26 | FSRS integration and card scheduling state | feature | @annamintzer | R12 |
| 27 | Review session UI: reveal, four ratings, progress, due counts | feature | @annamintzer | R12 |
| 28 | Tags: add, autocomplete, remove, per-article display | feature | @lucy | R13 |
| 29 | My Articles filtering by tag, source, and author | feature | @lucy | R13 |

Issue numbers to be filled in once the issues are created.

## Definition of Done for Iteration 2

Anna reads an ingested article, hits a term she doesn't know, double-taps it for a definition, highlights the surrounding sentence and asks the AI to explain it, adds it to a study set — and the next day the Learn tab tells her that card is due.

## Deferred to Iteration 3+

From the PRD's nice-to-haves, explicitly not in scope here: source avatars, in-app article scraping, AI auto-tagging, AI-generated multiple choice, mind maps, article audio playback, export to Notebook LM, user-customizable system prompts.
