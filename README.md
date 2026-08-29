# News4Dummies

## Local development

```bash
npm install
npm run dev
```

Build for production with `npm run build` (output in `dist/`). Pushes to `main` deploy automatically to GitHub Pages via `.github/workflows/deploy.yml`.

The app is a PWA (see `vite.config.ts`'s `VitePWA` block and `public/icons/`). The icons there are placeholders generated for scaffolding — swap them for real branding whenever that's decided.

## Backend (Supabase) setup

This app talks directly to Supabase (Postgres + Edge Functions) from the client — no custom server. Each contributor connects with their own local `.env`, but everyone points at the **same shared Supabase project** (one project, one set of tables, shared by Anna and Lucy — not one project per person).

One-time, whoever provisions the project:

1. Create a project at [supabase.com](https://supabase.com) (free tier is enough for Iteration 1).
2. `supabase link --project-ref <your-project-ref>` (get the ref from the project's dashboard URL or Settings -> General).
3. `supabase db push` to apply everything in `supabase/migrations/` — creates the `users`, `feed_items`, and `articles` tables with RLS enabled. See the migration file and `docs/iteration-1-plan.md` ("Security & Content Decisions") for why the RLS policies are intentionally permissive for Iteration 1.
4. Share the project URL and anon key (Settings -> API) with the other contributor out of band (not via git).

Every contributor, every machine:

```bash
cp .env.example .env
# fill in VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY from step 4 above
```

`.env` is gitignored — never commit real keys. The anon key is safe to expose client-side (it's the publishable key, not the service-role key); don't use the service-role key anywhere in this repo.
