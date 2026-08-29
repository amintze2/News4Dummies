-- citext installed into `public` by the previous migration trips Supabase's
-- "Extension in Public" security lint (WARN, external-facing). Move it to
-- the `extensions` schema, matching where pgcrypto already lives by
-- Supabase convention. No functional change — `users.name` stays citext.
alter extension citext set schema extensions;
