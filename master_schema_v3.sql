-- MASTER SCHEMA REPAIR SCRIPT (V3)
-- Run this entire script to ensure ALL tables and permissions exist.

-- 1. Enable UUIDs
create extension if not exists "uuid-ossp";

-- 2. Create Tables (IF NOT EXISTS)

-- Profiles
create table if not exists public.profiles (
  id uuid references auth.users not null primary key,
  name text,
  baby_name text,
  baby_dob date,
  device_ids text[], 
  is_premium boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Feeds
create table if not exists public.feeds (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  type text check (type in ('breast', 'bottle', 'solid')),
  side text check (side in ('L', 'R', 'Both', 'None')), 
  amount_ml int,
  duration_min int,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Sleep Logs
create table if not exists public.sleep_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Mom Notes
create table if not exists public.mom_notes (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  title text,
  content text,
  tags text[], 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Milestones
create table if not exists public.milestones (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  title text not null,
  date date not null,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Routines (V3)
create table if not exists public.routines (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  title text not null,
  time time not null,
  enabled boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Vaccines (V3)
create table if not exists public.vaccines (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  name text not null,
  due_date date,
  given_date date,
  status text check (status in ('pending', 'given', 'skipped')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Prescriptions (V3)
create table if not exists public.prescriptions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  medicine_name text not null,
  dosage text,
  frequency text,
  notes text,
  image_url text, -- Ensure this column exists
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Enable RLS (Security)
alter table public.profiles enable row level security;
alter table public.feeds enable row level security;
alter table public.sleep_logs enable row level security;
alter table public.mom_notes enable row level security;
alter table public.milestones enable row level security;
alter table public.routines enable row level security;
alter table public.vaccines enable row level security;
alter table public.prescriptions enable row level security;

-- 4. Create Policies (Drop first to avoid duplication errors)

-- Profiles
drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);

-- Feeds
drop policy if exists "Users can view own feeds" on public.feeds;
create policy "Users can view own feeds" on public.feeds for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own feeds" on public.feeds;
create policy "Users can insert own feeds" on public.feeds for insert with check (auth.uid() = user_id);

drop policy if exists "Users can delete own feeds" on public.feeds;
create policy "Users can delete own feeds" on public.feeds for delete using (auth.uid() = user_id);

-- Sleep Logs
drop policy if exists "Users can view own sleep_logs" on public.sleep_logs;
create policy "Users can view own sleep_logs" on public.sleep_logs for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own sleep_logs" on public.sleep_logs;
create policy "Users can insert own sleep_logs" on public.sleep_logs for insert with check (auth.uid() = user_id);

drop policy if exists "Users can delete own sleep_logs" on public.sleep_logs;
create policy "Users can delete own sleep_logs" on public.sleep_logs for delete using (auth.uid() = user_id);

-- Milestones
drop policy if exists "Users can view own milestones" on public.milestones;
create policy "Users can view own milestones" on public.milestones for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own milestones" on public.milestones;
create policy "Users can insert own milestones" on public.milestones for insert with check (auth.uid() = user_id);

drop policy if exists "Users can delete own milestones" on public.milestones;
create policy "Users can delete own milestones" on public.milestones for delete using (auth.uid() = user_id);

-- V3 Tables (Routines, Vaccines, Prescriptions) - Standardize
-- Routines
drop policy if exists "Users can view own routines" on public.routines;
create policy "Users can view own routines" on public.routines for select using (auth.uid() = user_id);
drop policy if exists "Users can insert own routines" on public.routines;
create policy "Users can insert own routines" on public.routines for insert with check (auth.uid() = user_id);
drop policy if exists "Users can delete own routines" on public.routines;
create policy "Users can delete own routines" on public.routines for delete using (auth.uid() = user_id);

-- Vaccines
drop policy if exists "Users can view own vaccines" on public.vaccines;
create policy "Users can view own vaccines" on public.vaccines for select using (auth.uid() = user_id);
drop policy if exists "Users can insert own vaccines" on public.vaccines;
create policy "Users can insert own vaccines" on public.vaccines for insert with check (auth.uid() = user_id);
drop policy if exists "Users can delete own vaccines" on public.vaccines;
create policy "Users can delete own vaccines" on public.vaccines for delete using (auth.uid() = user_id);
drop policy if exists "Users can update own vaccines" on public.vaccines;
create policy "Users can update own vaccines" on public.vaccines for update using (auth.uid() = user_id);

-- Prescriptions
drop policy if exists "Users can view own prescriptions" on public.prescriptions;
create policy "Users can view own prescriptions" on public.prescriptions for select using (auth.uid() = user_id);
drop policy if exists "Users can insert own prescriptions" on public.prescriptions;
create policy "Users can insert own prescriptions" on public.prescriptions for insert with check (auth.uid() = user_id);
drop policy if exists "Users can delete own prescriptions" on public.prescriptions;
create policy "Users can delete own prescriptions" on public.prescriptions for delete using (auth.uid() = user_id);

-- 5. Storage BUCKET (Images)
insert into storage.buckets (id, name, public) 
values ('images', 'images', true)
on conflict (id) do nothing;

create policy "Images are publicly accessible" on storage.objects for select using (bucket_id = 'images');
create policy "Users can upload images" on storage.objects for insert with check (bucket_id = 'images' and auth.uid() = owner);
