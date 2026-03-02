-- Diaper Logs Table
CREATE TABLE IF NOT EXISTS public.diaper_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users NOT NULL,
    type TEXT CHECK (type IN ('pee', 'poop', 'both')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.diaper_logs ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own diaper logs" 
ON public.diaper_logs FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own diaper logs" 
ON public.diaper_logs FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own diaper logs" 
ON public.diaper_logs FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own diaper logs" 
ON public.diaper_logs FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);
