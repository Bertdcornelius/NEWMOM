-- Fix Mom's Brain (mom_notes) Table & Security Policies

-- 1. Create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.mom_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users NOT NULL,
    title TEXT,
    content TEXT,
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.mom_notes ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own notes" ON public.mom_notes;
DROP POLICY IF EXISTS "Users can insert their own notes" ON public.mom_notes;
DROP POLICY IF EXISTS "Users can update their own notes" ON public.mom_notes;
DROP POLICY IF EXISTS "Users can delete their own notes" ON public.mom_notes;

-- 4. Create new, correct policies
-- Allow users to see only their own notes
CREATE POLICY "Users can view their own notes" 
ON public.mom_notes FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- Allow users to create notes (MUST match their user_id)
CREATE POLICY "Users can insert their own notes" 
ON public.mom_notes FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Allow users to update only their own notes
CREATE POLICY "Users can update their own notes" 
ON public.mom_notes FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

-- Allow users to delete only their own notes
CREATE POLICY "Users can delete their own notes" 
ON public.mom_notes FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);
