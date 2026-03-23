-- ======================================================================================
-- SUPABASE ROW LEVEL SECURITY (RLS) POLICIES FOR NEWMOM APP
-- ======================================================================================
-- Instructions: 
-- 1. Open your Supabase Dashboard
-- 2. Go to SQL Editor
-- 3. Paste this entire script and run it.
-- This ensures no user can ever read, modify, or delete another mother's data.

-- ENABLE RLS ON ALL TABLES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE feeds ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE diaper_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pumping_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE tummy_time_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE photo_gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE growth_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccines ENABLE ROW LEVEL SECURITY;
ALTER TABLE mom_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE teething_data ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- PROFILES (Users can only see and update their own profile)
-- ==========================================
CREATE POLICY "Users can view own profile" ON profiles
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
FOR UPDATE USING (auth.uid() = id);

-- ==========================================
-- GENERIC USER DATA POLICIES (Applies to all tracker tables)
-- Users can completely control their own rows, and cannot access others.
-- ==========================================

-- Feeds
CREATE POLICY "Feeds CRUD" ON feeds
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Sleep Logs
CREATE POLICY "Sleep CRUD" ON sleep_logs
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Diaper Logs
CREATE POLICY "Diaper CRUD" ON diaper_logs
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Pumping Sessions
CREATE POLICY "Pumping CRUD" ON pumping_sessions
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Tummy Time
CREATE POLICY "Tummy Time CRUD" ON tummy_time_sessions
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Milestones
CREATE POLICY "Milestones CRUD" ON milestones
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Photo Gallery
CREATE POLICY "Photo Gallery CRUD" ON photo_gallery
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Prescriptions
CREATE POLICY "Prescriptions CRUD" ON prescriptions
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Growth Entries
CREATE POLICY "Growth Entries CRUD" ON growth_entries
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Routines
CREATE POLICY "Routines CRUD" ON routines
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Vaccines
CREATE POLICY "Vaccines CRUD" ON vaccines
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Notes
CREATE POLICY "Notes CRUD" ON mom_notes
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Teething Data
CREATE POLICY "Teething Data CRUD" ON teething_data
FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ==========================================
-- STORAGE BUCKET SECURITY
-- ==========================================
-- Ensures users can only upload and view images in folders matching their User ID.
CREATE POLICY "Users can manage their own storage folder"
ON storage.objects FOR ALL
USING (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1])
WITH CHECK (bucket_id = 'images' AND auth.uid()::text = (storage.foldername(name))[1]);

-- DONE! Your app is now military-grade secure.
