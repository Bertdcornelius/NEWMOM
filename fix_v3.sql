-- FIX: Add missing RLS policies for profiles
-- Allow users to see their own profile
create policy "Users can view own profile" on public.profiles 
for select using (auth.uid() = id);

-- Allow users to insert their own profile (needed for first login/onboarding)
create policy "Users can insert own profile" on public.profiles 
for insert with check (auth.uid() = id);

-- FIX: Add image_url to prescriptions table
alter table public.prescriptions 
add column if not exists image_url text;

-- FIX: Ensure is_premium exists (if missed previously)
alter table public.profiles 
add column if not exists is_premium boolean default false;
