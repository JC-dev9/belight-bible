-- ============================================================
-- Remover políticas duplicadas (legado)
-- As novas políticas _select_own/_insert_own/etc já cobrem tudo.
-- Executar no Supabase Dashboard → SQL Editor
-- ============================================================

-- highlights (remover políticas legado "Users can...")
DROP POLICY IF EXISTS "Users can see own highlights" ON public.highlights;
DROP POLICY IF EXISTS "Users can insert own highlights" ON public.highlights;
DROP POLICY IF EXISTS "Users can update own highlights" ON public.highlights;
DROP POLICY IF EXISTS "Users can delete own highlights" ON public.highlights;

-- notes
DROP POLICY IF EXISTS "Users can see own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can insert own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can update own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can delete own notes" ON public.notes;

-- profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- reading_progress
DROP POLICY IF EXISTS "Users can view own reading progress" ON public.reading_progress;
DROP POLICY IF EXISTS "Users can insert own reading progress" ON public.reading_progress;
DROP POLICY IF EXISTS "Users can update own reading progress" ON public.reading_progress;

-- saved_devotionals
DROP POLICY IF EXISTS "Users can view own saved devotionals" ON public.saved_devotionals;
DROP POLICY IF EXISTS "Users can save devotionals" ON public.saved_devotionals;
DROP POLICY IF EXISTS "Users can unsave devotionals" ON public.saved_devotionals;

-- user_reading_plans
DROP POLICY IF EXISTS "Users can view own plans" ON public.user_reading_plans;
DROP POLICY IF EXISTS "Users can enroll in plans" ON public.user_reading_plans;
DROP POLICY IF EXISTS "Users can update own plan progress" ON public.user_reading_plans;
DROP POLICY IF EXISTS "Users can delete own plans" ON public.user_reading_plans;

-- daily_verses (remover redundante autenticado — já há USING true)
DROP POLICY IF EXISTS "Authenticated users can read daily verses" ON public.daily_verses;

-- devotionals
DROP POLICY IF EXISTS "Authenticated users can read devotionals" ON public.devotionals;

-- reading_plans
DROP POLICY IF EXISTS "Authenticated users can read plans" ON public.reading_plans;
