-- FIX: Add missing RLS policies for V1 and V2 tables
-- Enabling RLS without policies denies all access by default.

-- Feeds
create policy "Users can view own feeds" on public.feeds for select using (auth.uid() = user_id);
create policy "Users can insert own feeds" on public.feeds for insert with check (auth.uid() = user_id);
create policy "Users can update own feeds" on public.feeds for update using (auth.uid() = user_id);
create policy "Users can delete own feeds" on public.feeds for delete using (auth.uid() = user_id);

-- Sleep Logs
create policy "Users can view own sleep_logs" on public.sleep_logs for select using (auth.uid() = user_id);
create policy "Users can insert own sleep_logs" on public.sleep_logs for insert with check (auth.uid() = user_id);
create policy "Users can update own sleep_logs" on public.sleep_logs for update using (auth.uid() = user_id);
create policy "Users can delete own sleep_logs" on public.sleep_logs for delete using (auth.uid() = user_id);

-- Mom Notes
create policy "Users can view own mom_notes" on public.mom_notes for select using (auth.uid() = user_id);
create policy "Users can insert own mom_notes" on public.mom_notes for insert with check (auth.uid() = user_id);
create policy "Users can update own mom_notes" on public.mom_notes for update using (auth.uid() = user_id);
create policy "Users can delete own mom_notes" on public.mom_notes for delete using (auth.uid() = user_id);

-- Milestones
create policy "Users can view own milestones" on public.milestones for select using (auth.uid() = user_id);
create policy "Users can insert own milestones" on public.milestones for insert with check (auth.uid() = user_id);
create policy "Users can update own milestones" on public.milestones for update using (auth.uid() = user_id);
create policy "Users can delete own milestones" on public.milestones for delete using (auth.uid() = user_id);
