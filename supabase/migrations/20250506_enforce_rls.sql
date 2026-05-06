-- ============================================================
-- BELIGHT BIBLE — RLS (Row Level Security)
-- Executar no Supabase Dashboard → SQL Editor
-- ============================================================

-- ============================================================
-- HIGHLIGHTS
-- ============================================================
ALTER TABLE public.highlights ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "highlights_select_own" ON public.highlights;
DROP POLICY IF EXISTS "highlights_insert_own" ON public.highlights;
DROP POLICY IF EXISTS "highlights_update_own" ON public.highlights;
DROP POLICY IF EXISTS "highlights_delete_own" ON public.highlights;

CREATE POLICY "highlights_select_own" ON public.highlights
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "highlights_insert_own" ON public.highlights
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "highlights_update_own" ON public.highlights
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "highlights_delete_own" ON public.highlights
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- NOTES
-- ============================================================
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notes_select_own" ON public.notes;
DROP POLICY IF EXISTS "notes_insert_own" ON public.notes;
DROP POLICY IF EXISTS "notes_update_own" ON public.notes;
DROP POLICY IF EXISTS "notes_delete_own" ON public.notes;

CREATE POLICY "notes_select_own" ON public.notes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notes_insert_own" ON public.notes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notes_update_own" ON public.notes
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "notes_delete_own" ON public.notes
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- PROFILES
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;

CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- ============================================================
-- READING PROGRESS
-- ============================================================
ALTER TABLE public.reading_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reading_progress_select_own" ON public.reading_progress;
DROP POLICY IF EXISTS "reading_progress_insert_own" ON public.reading_progress;
DROP POLICY IF EXISTS "reading_progress_update_own" ON public.reading_progress;

CREATE POLICY "reading_progress_select_own" ON public.reading_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "reading_progress_insert_own" ON public.reading_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "reading_progress_update_own" ON public.reading_progress
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================
-- USER READING PLANS
-- ============================================================
ALTER TABLE public.user_reading_plans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_reading_plans_select_own" ON public.user_reading_plans;
DROP POLICY IF EXISTS "user_reading_plans_insert_own" ON public.user_reading_plans;
DROP POLICY IF EXISTS "user_reading_plans_update_own" ON public.user_reading_plans;
DROP POLICY IF EXISTS "user_reading_plans_delete_own" ON public.user_reading_plans;

CREATE POLICY "user_reading_plans_select_own" ON public.user_reading_plans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_reading_plans_insert_own" ON public.user_reading_plans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_reading_plans_update_own" ON public.user_reading_plans
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "user_reading_plans_delete_own" ON public.user_reading_plans
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- SAVED DEVOTIONALS
-- ============================================================
ALTER TABLE public.saved_devotionals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saved_devotionals_select_own" ON public.saved_devotionals;
DROP POLICY IF EXISTS "saved_devotionals_insert_own" ON public.saved_devotionals;
DROP POLICY IF EXISTS "saved_devotionals_delete_own" ON public.saved_devotionals;

CREATE POLICY "saved_devotionals_select_own" ON public.saved_devotionals
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "saved_devotionals_insert_own" ON public.saved_devotionals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "saved_devotionals_delete_own" ON public.saved_devotionals
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- TABELAS PÚBLICAS (leitura para todos, sem escrita por users)
-- ============================================================
ALTER TABLE public.daily_verses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "daily_verses_public_read" ON public.daily_verses;
CREATE POLICY "daily_verses_public_read" ON public.daily_verses
  FOR SELECT USING (true);

ALTER TABLE public.devotionals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "devotionals_public_read" ON public.devotionals;
CREATE POLICY "devotionals_public_read" ON public.devotionals
  FOR SELECT USING (true);

ALTER TABLE public.reading_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "reading_plans_public_read" ON public.reading_plans;
CREATE POLICY "reading_plans_public_read" ON public.reading_plans
  FOR SELECT USING (true);

-- ============================================================
-- VERIFICAÇÃO FINAL
-- Correr após a migration para confirmar:
-- ============================================================
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- ORDER BY tablename;
