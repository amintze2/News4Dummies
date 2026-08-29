-- Iteration 1 schema: users, feed_items, articles.
-- See docs/iteration-1-plan.md ("Data Model" and "Security & Content
-- Decisions") for the full rationale behind the shape and the RLS policies
-- below. Issue: #13.

create extension if not exists pgcrypto;
create extension if not exists citext;

-- ---------------------------------------------------------------------------
-- users
-- Name-only "login" (#7). `name` is citext so "Anna" and "anna" collide,
-- matching the case-insensitive create-or-reuse behavior R1 requires.
-- ---------------------------------------------------------------------------
create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  name citext not null unique,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- feed_items
-- Cached RSS aggregation (#9). Not user-scoped — one shared feed for
-- everyone. Deduplicated by the RSS entry's GUID.
-- ---------------------------------------------------------------------------
create table if not exists public.feed_items (
  id uuid primary key default gen_random_uuid(),
  guid text not null unique,
  source text not null,
  title text not null,
  summary text,
  url text not null,
  author text,
  published_at timestamptz,
  fetched_at timestamptz not null default now()
);

create index if not exists feed_items_published_at_idx
  on public.feed_items (published_at desc);

-- ---------------------------------------------------------------------------
-- articles
-- Full-text articles a user has saved, via seed script or dev paste form
-- (#10). `(user_id, url)` unique constraint backs the createArticle
-- upsert-on-duplicate-URL behavior described in docs/iteration-1-plan.md.
-- ---------------------------------------------------------------------------
create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  title text not null,
  url text not null,
  source text,
  author text,
  published_at timestamptz,
  body_text text,
  created_at timestamptz not null default now(),
  unique (user_id, url)
);

create index if not exists articles_user_id_created_at_idx
  on public.articles (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- Row Level Security
--
-- INTENTIONALLY PERMISSIVE. Do not tighten these without re-reading
-- docs/iteration-1-plan.md ("Security & Content Decisions") first.
--
-- Name-only login is not authentication: anyone who knows the app URL can
-- pick any name and see that user's articles. RLS is enabled on every table
-- per the issue's acceptance criteria, but because the app only ever talks
-- to Supabase with the anon key (no server, no real auth session), the
-- policies below grant the anon role full access rather than scoping by
-- auth.uid() — there is no auth.uid() to scope by yet.
--
-- This is acceptable only because: the user set is two people (Anna and
-- Lucy), the content is public news articles, and the deployment is
-- effectively unknown to anyone but us. If a third-party user is ever added,
-- or anything personal/private is ever stored, this must be revisited
-- before that happens — it is not accidental, it is a deliberate Iteration 1
-- trade-off recorded here and in the plan doc so we don't forget we made it.
-- ---------------------------------------------------------------------------

alter table public.users enable row level security;
alter table public.feed_items enable row level security;
alter table public.articles enable row level security;

create policy "anon full access (intentionally permissive, see plan doc)"
  on public.users
  for all
  to anon, authenticated
  using (true)
  with check (true);

create policy "anon full access (intentionally permissive, see plan doc)"
  on public.feed_items
  for all
  to anon, authenticated
  using (true)
  with check (true);

create policy "anon full access (intentionally permissive, see plan doc)"
  on public.articles
  for all
  to anon, authenticated
  using (true)
  with check (true);
