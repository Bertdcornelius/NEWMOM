-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- V1 Tables (Existing) --

-- Table: profiles
create table if not exists public.profiles (
  id uuid references auth.users not null primary key,
  name text,
  baby_name text,
  baby_dob date,
  device_ids text[], -- NEW for V3 (Device Limit)
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table: feeds
create table if not exists public.feeds (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  type text check (type in ('breast', 'bottle', 'solid')),
  side text check (side in ('L', 'R', 'Both', 'None')), 
  amount_ml int,
  duration_min int,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table: sleep_logs
create table if not exists public.sleep_logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table: mom_notes
create table if not exists public.mom_notes (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  title text,
  content text,
  tags text[], 
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- V2 Tables (Existing) --

-- Table: milestones
create table if not exists public.milestones (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  title text not null,
  date date not null,
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- V3 Tables (New) --

-- Table: routines
create table if not exists public.routines (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  title text not null, -- e.g. "Bath", "Massage", "Vitamin D"
  time time not null,
  enabled boolean default true,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table: vaccines
create table if not exists public.vaccines (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  name text not null,
  due_date date,
  given_date date,
  status text check (status in ('pending', 'given', 'skipped')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table: prescriptions
create table if not exists public.prescriptions (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  medicine_name text not null,
  dosage text, -- e.g. "5ml"
  frequency text, -- e.g. "Twice daily"
  notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS for all
alter table public.profiles enable row level security;
alter table public.feeds enable row level security;
alter table public.sleep_logs enable row level security;
alter table public.mom_notes enable row level security;
alter table public.milestones enable row level security;

alter table public.routines enable row level security;
alter table public.vaccines enable row level security;
alter table public.prescriptions enable row level security;

-- Policies
create policy "Users can view own routines" on public.routines for select using (auth.uid() = user_id);
create policy "Users can insert own routines" on public.routines for insert with check (auth.uid() = user_id);
create policy "Users can update own routines" on public.routines for update using (auth.uid() = user_id);
create policy "Users can delete own routines" on public.routines for delete using (auth.uid() = user_id);

create policy "Users can view own vaccines" on public.vaccines for select using (auth.uid() = user_id);
create policy "Users can insert own vaccines" on public.vaccines for insert with check (auth.uid() = user_id);
create policy "Users can update own vaccines" on public.vaccines for update using (auth.uid() = user_id);
create policy "Users can delete own vaccines" on public.vaccines for delete using (auth.uid() = user_id);

create policy "Users can view own prescriptions" on public.prescriptions for select using (auth.uid() = user_id);
create policy "Users can insert own prescriptions" on public.prescriptions for insert with check (auth.uid() = user_id);
create policy "Users can update own prescriptions" on public.prescriptions for update using (auth.uid() = user_id);
create policy "Users can delete own prescriptions" on public.prescriptions for delete using (auth.uid() = user_id);

-- Update profiles policy to allow update (if not already there)
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
