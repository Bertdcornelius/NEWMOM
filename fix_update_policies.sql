-- Enable UPDATE policies for all tracking tables

-- Feeds
DROP POLICY IF EXISTS "Users can update own feeds" ON public.feeds;
CREATE POLICY "Users can update own feeds" ON public.feeds FOR UPDATE USING (auth.uid() = user_id);

-- Sleep Logs
DROP POLICY IF EXISTS "Users can update own sleep_logs" ON public.sleep_logs;
CREATE POLICY "Users can update own sleep_logs" ON public.sleep_logs FOR UPDATE USING (auth.uid() = user_id);

-- Milestones
DROP POLICY IF EXISTS "Users can update own milestones" ON public.milestones;
CREATE POLICY "Users can update own milestones" ON public.milestones FOR UPDATE USING (auth.uid() = user_id);

-- Routines
DROP POLICY IF EXISTS "Users can update own routines" ON public.routines;
CREATE POLICY "Users can update own routines" ON public.routines FOR UPDATE USING (auth.uid() = user_id);

-- Prescriptions
DROP POLICY IF EXISTS "Users can update own prescriptions" ON public.prescriptions;
CREATE POLICY "Users can update own prescriptions" ON public.prescriptions FOR UPDATE USING (auth.uid() = user_id);

-- Mom Notes (Double check)
DROP POLICY IF EXISTS "Users can update own mom_notes" ON public.mom_notes;
CREATE POLICY "Users can update own mom_notes" ON public.mom_notes FOR UPDATE USING (auth.uid() = user_id);
