import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    "Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY. Copy .env.example " +
      "to .env and fill in your project's values (Supabase dashboard -> " +
      "Project Settings -> API).",
  );
}

// Anon key only — this app has no server and no real auth session (see
// docs/iteration-1-plan.md, "Security & Content Decisions"). Every table's
// RLS policy is intentionally permissive for the anon role for the same
// reason; do not add a service-role key to client code.
export const supabase = createClient(supabaseUrl, supabaseAnonKey);
