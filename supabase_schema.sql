-- ============================================================
-- COMPLETE NEWMOM BACKEND SCHEMA (FIXED)
-- Run in Supabase SQL Editor
-- Safe to re-run: uses IF NOT EXISTS for tables, 
-- DROP + CREATE for policies
-- ============================================================

-- 1. Profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    baby_name TEXT,
    is_premium BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 2. Sleep Logs
CREATE TABLE IF NOT EXISTS public.sleep_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    duration_min INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sleep_logs_select" ON public.sleep_logs;
CREATE POLICY "sleep_logs_select" ON public.sleep_logs FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "sleep_logs_insert" ON public.sleep_logs;
CREATE POLICY "sleep_logs_insert" ON public.sleep_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "sleep_logs_delete" ON public.sleep_logs;
CREATE POLICY "sleep_logs_delete" ON public.sleep_logs FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "sleep_logs_update" ON public.sleep_logs;
CREATE POLICY "sleep_logs_update" ON public.sleep_logs FOR UPDATE USING (auth.uid() = user_id);

-- 3. Feeds
CREATE TABLE IF NOT EXISTS public.feeds (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT,
    side TEXT,
    amount_ml INTEGER,
    duration_min INTEGER,
    next_due TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.feeds ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "feeds_select" ON public.feeds;
CREATE POLICY "feeds_select" ON public.feeds FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "feeds_insert" ON public.feeds;
CREATE POLICY "feeds_insert" ON public.feeds FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "feeds_delete" ON public.feeds;
CREATE POLICY "feeds_delete" ON public.feeds FOR DELETE USING (auth.uid() = user_id);

-- 4. Diaper Logs
CREATE TABLE IF NOT EXISTS public.diaper_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    type TEXT,
    color TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.diaper_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "diaper_logs_select" ON public.diaper_logs;
CREATE POLICY "diaper_logs_select" ON public.diaper_logs FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "diaper_logs_insert" ON public.diaper_logs;
CREATE POLICY "diaper_logs_insert" ON public.diaper_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "diaper_logs_delete" ON public.diaper_logs;
CREATE POLICY "diaper_logs_delete" ON public.diaper_logs FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "diaper_logs_update" ON public.diaper_logs;
CREATE POLICY "diaper_logs_update" ON public.diaper_logs FOR UPDATE USING (auth.uid() = user_id);

-- 5. Growth Entries
CREATE TABLE IF NOT EXISTS public.growth_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    weight_kg NUMERIC,
    height_cm NUMERIC,
    head_circ_cm NUMERIC,
    timestamp TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.growth_entries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "growth_entries_select" ON public.growth_entries;
CREATE POLICY "growth_entries_select" ON public.growth_entries FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "growth_entries_insert" ON public.growth_entries;
CREATE POLICY "growth_entries_insert" ON public.growth_entries FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "growth_entries_delete" ON public.growth_entries;
CREATE POLICY "growth_entries_delete" ON public.growth_entries FOR DELETE USING (auth.uid() = user_id);

-- 6. Pumping Sessions
CREATE TABLE IF NOT EXISTS public.pumping_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    side TEXT,
    duration_min INTEGER,
    amount_ml INTEGER,
    timestamp TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.pumping_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pumping_sessions_select" ON public.pumping_sessions;
CREATE POLICY "pumping_sessions_select" ON public.pumping_sessions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "pumping_sessions_insert" ON public.pumping_sessions;
CREATE POLICY "pumping_sessions_insert" ON public.pumping_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "pumping_sessions_delete" ON public.pumping_sessions;
CREATE POLICY "pumping_sessions_delete" ON public.pumping_sessions FOR DELETE USING (auth.uid() = user_id);

-- 7. Tummy Time Sessions
CREATE TABLE IF NOT EXISTS public.tummy_time_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    duration_sec INTEGER,
    timestamp TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.tummy_time_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tummy_time_select" ON public.tummy_time_sessions;
CREATE POLICY "tummy_time_select" ON public.tummy_time_sessions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "tummy_time_insert" ON public.tummy_time_sessions;
CREATE POLICY "tummy_time_insert" ON public.tummy_time_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "tummy_time_delete" ON public.tummy_time_sessions;
CREATE POLICY "tummy_time_delete" ON public.tummy_time_sessions FOR DELETE USING (auth.uid() = user_id);

-- 8. Photo Gallery
CREATE TABLE IF NOT EXISTS public.photo_gallery (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    image_url TEXT,
    caption TEXT,
    timestamp TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.photo_gallery ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "photo_gallery_select" ON public.photo_gallery;
CREATE POLICY "photo_gallery_select" ON public.photo_gallery FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "photo_gallery_insert" ON public.photo_gallery;
CREATE POLICY "photo_gallery_insert" ON public.photo_gallery FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "photo_gallery_delete" ON public.photo_gallery;
CREATE POLICY "photo_gallery_delete" ON public.photo_gallery FOR DELETE USING (auth.uid() = user_id);

-- 9. Milestones
CREATE TABLE IF NOT EXISTS public.milestones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT,
    date TIMESTAMPTZ,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "milestones_select" ON public.milestones;
CREATE POLICY "milestones_select" ON public.milestones FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "milestones_insert" ON public.milestones;
CREATE POLICY "milestones_insert" ON public.milestones FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "milestones_delete" ON public.milestones;
CREATE POLICY "milestones_delete" ON public.milestones FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "milestones_update" ON public.milestones;
CREATE POLICY "milestones_update" ON public.milestones FOR UPDATE USING (auth.uid() = user_id);

-- 10. Mom Notes
CREATE TABLE IF NOT EXISTS public.mom_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT,
    body TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.mom_notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "mom_notes_select" ON public.mom_notes;
CREATE POLICY "mom_notes_select" ON public.mom_notes FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "mom_notes_insert" ON public.mom_notes;
CREATE POLICY "mom_notes_insert" ON public.mom_notes FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "mom_notes_delete" ON public.mom_notes;
CREATE POLICY "mom_notes_delete" ON public.mom_notes FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "mom_notes_update" ON public.mom_notes;
CREATE POLICY "mom_notes_update" ON public.mom_notes FOR UPDATE USING (auth.uid() = user_id);

-- 11. Mom Care Checklist
CREATE TABLE IF NOT EXISTS public.mom_care_checklist (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT,
    checked BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.mom_care_checklist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "mom_care_select" ON public.mom_care_checklist;
CREATE POLICY "mom_care_select" ON public.mom_care_checklist FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "mom_care_insert" ON public.mom_care_checklist;
CREATE POLICY "mom_care_insert" ON public.mom_care_checklist FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "mom_care_delete" ON public.mom_care_checklist;
CREATE POLICY "mom_care_delete" ON public.mom_care_checklist FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "mom_care_update" ON public.mom_care_checklist;
CREATE POLICY "mom_care_update" ON public.mom_care_checklist FOR UPDATE USING (auth.uid() = user_id);

-- 12. Menstrual Cycles
CREATE TABLE IF NOT EXISTS public.menstrual_cycles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.menstrual_cycles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "menstrual_select" ON public.menstrual_cycles;
CREATE POLICY "menstrual_select" ON public.menstrual_cycles FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "menstrual_insert" ON public.menstrual_cycles;
CREATE POLICY "menstrual_insert" ON public.menstrual_cycles FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "menstrual_delete" ON public.menstrual_cycles;
CREATE POLICY "menstrual_delete" ON public.menstrual_cycles FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "menstrual_update" ON public.menstrual_cycles;
CREATE POLICY "menstrual_update" ON public.menstrual_cycles FOR UPDATE USING (auth.uid() = user_id);

-- 13. Milk Stash
CREATE TABLE IF NOT EXISTS public.milk_stash (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount_ml NUMERIC,
    storage_type TEXT,
    expiration_date TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.milk_stash ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "milk_stash_select" ON public.milk_stash;
CREATE POLICY "milk_stash_select" ON public.milk_stash FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "milk_stash_insert" ON public.milk_stash;
CREATE POLICY "milk_stash_insert" ON public.milk_stash FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "milk_stash_delete" ON public.milk_stash;
CREATE POLICY "milk_stash_delete" ON public.milk_stash FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "milk_stash_update" ON public.milk_stash;
CREATE POLICY "milk_stash_update" ON public.milk_stash FOR UPDATE USING (auth.uid() = user_id);

-- 14. Teething Data
CREATE TABLE IF NOT EXISTS public.teething_data (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    tooth_index INTEGER,
    erupted_date TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.teething_data ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "teething_select" ON public.teething_data;
CREATE POLICY "teething_select" ON public.teething_data FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "teething_insert" ON public.teething_data;
CREATE POLICY "teething_insert" ON public.teething_data FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "teething_delete" ON public.teething_data;
CREATE POLICY "teething_delete" ON public.teething_data FOR DELETE USING (auth.uid() = user_id);

-- 15. Vaccines
CREATE TABLE IF NOT EXISTS public.vaccines (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT,
    due_date TIMESTAMPTZ,
    given_date TIMESTAMPTZ,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.vaccines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "vaccines_select" ON public.vaccines;
CREATE POLICY "vaccines_select" ON public.vaccines FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "vaccines_insert" ON public.vaccines;
CREATE POLICY "vaccines_insert" ON public.vaccines FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "vaccines_delete" ON public.vaccines;
CREATE POLICY "vaccines_delete" ON public.vaccines FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "vaccines_update" ON public.vaccines;
CREATE POLICY "vaccines_update" ON public.vaccines FOR UPDATE USING (auth.uid() = user_id);

-- 16. Prescriptions
CREATE TABLE IF NOT EXISTS public.prescriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    medicine_name TEXT,
    dosage TEXT,
    frequency TEXT,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "prescriptions_select" ON public.prescriptions;
CREATE POLICY "prescriptions_select" ON public.prescriptions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "prescriptions_insert" ON public.prescriptions;
CREATE POLICY "prescriptions_insert" ON public.prescriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "prescriptions_delete" ON public.prescriptions;
CREATE POLICY "prescriptions_delete" ON public.prescriptions FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "prescriptions_update" ON public.prescriptions;
CREATE POLICY "prescriptions_update" ON public.prescriptions FOR UPDATE USING (auth.uid() = user_id);

-- 17. Routines
CREATE TABLE IF NOT EXISTS public.routines (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT,
    time TEXT,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "routines_select" ON public.routines;
CREATE POLICY "routines_select" ON public.routines FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "routines_insert" ON public.routines;
CREATE POLICY "routines_insert" ON public.routines FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "routines_delete" ON public.routines;
CREATE POLICY "routines_delete" ON public.routines FOR DELETE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "routines_update" ON public.routines;
CREATE POLICY "routines_update" ON public.routines FOR UPDATE USING (auth.uid() = user_id);

-- 18. Mood Logs (Postpartum Wellness)
CREATE TABLE IF NOT EXISTS public.mood_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    score INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.mood_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "mood_logs_select" ON public.mood_logs;
CREATE POLICY "mood_logs_select" ON public.mood_logs FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "mood_logs_insert" ON public.mood_logs;
CREATE POLICY "mood_logs_insert" ON public.mood_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "mood_logs_delete" ON public.mood_logs;
CREATE POLICY "mood_logs_delete" ON public.mood_logs FOR DELETE USING (auth.uid() = user_id);

-- 19. Food Introductions
CREATE TABLE IF NOT EXISTS public.food_introductions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    category TEXT,
    reaction TEXT DEFAULT 'none',
    date TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.food_introductions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "food_intro_select" ON public.food_introductions;
CREATE POLICY "food_intro_select" ON public.food_introductions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "food_intro_insert" ON public.food_introductions;
CREATE POLICY "food_intro_insert" ON public.food_introductions FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "food_intro_delete" ON public.food_introductions;
CREATE POLICY "food_intro_delete" ON public.food_introductions FOR DELETE USING (auth.uid() = user_id);

-- 20. Storage Bucket for images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('images', 'images', true) 
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "images_insert" ON storage.objects;
CREATE POLICY "images_insert" ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);

DROP POLICY IF EXISTS "images_select" ON storage.objects;
CREATE POLICY "images_select" ON storage.objects FOR SELECT 
USING (bucket_id = 'images');

DROP POLICY IF EXISTS "images_delete" ON storage.objects;
CREATE POLICY "images_delete" ON storage.objects FOR DELETE 
USING (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);

